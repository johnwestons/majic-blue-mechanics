local Jobs = require("src.jobs")
local Catalog = require("src.parts_catalog")

local Schema = { version = 5 }

local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then error("save data contains a cycle") end
    seen[value] = true
    local result = {}
    for key, item in pairs(value) do result[copy(key, seen)] = copy(item, seen) end
    seen[value] = nil
    return result
end

local function positiveInteger(value)
    return type(value) == "number" and value >= 1 and value == math.floor(value)
end

local function jobLists(value)
    return type(value) == "table" and type(value.active) == "table"
        and type(value.completed) == "table" and type(value.declined) == "table"
end

local function identityFor(prefix, sequence)
    return string.format("%s-%04d", prefix, math.max(1, tonumber(sequence) or 1))
end

function Schema.reconcile(payload)
    if type(payload) ~= "table" or not jobLists(payload.jobs) then return false end
    local seen = {}
    local function reconcileJob(job)
        if type(job) ~= "table" or type(job.id) ~= "string" or seen[job.id] then return false end
        seen[job.id] = true
        local sequence = tonumber(job.sequence) or tonumber(job.id:match("(%d+)$")) or 1
        job.sequence = sequence
        job.clientId = job.clientId or identityFor("CLIENT", sequence)
        job.motorcycleId = job.motorcycleId or identityFor("BIKE", sequence)
        if job.transportRequired == nil then
            job.transportRequired = job.repairKind == "stator" or job.repairKind == "magneto"
                or job.repairKind == "suspension"
        else
            job.transportRequired = job.transportRequired == true
        end
        job.checklist = type(job.checklist) == "table" and job.checklist or {}
        job.checklist.diagnosed = job.checklist.diagnosed == true
        job.checklist.repaired = job.checklist.repaired == true
        job.checklist.roadTested = job.checklist.roadTested == true
        Jobs.ensureBikeSprite(job)
        return true
    end
    for _, list in ipairs({ payload.jobs.active, payload.jobs.completed, payload.jobs.declined }) do
        for _, job in ipairs(list) do
            if not reconcileJob(job) then return false end
        end
    end
    if payload.pendingOffer ~= nil and not reconcileJob(payload.pendingOffer) then return false end
    if payload.customer ~= nil and type(payload.customer) ~= "table" then return false end
    payload.saveVersion = Schema.version
    payload.revenue = math.max(0, tonumber(payload.revenue) or 0)
    payload.expenses = math.max(0, tonumber(payload.expenses) or 0)
    payload.reputation = math.max(0, tonumber(payload.reputation) or 0)
    payload.inventory = type(payload.inventory) == "table" and payload.inventory or { parts = {} }
    payload.inventory.parts = type(payload.inventory.parts) == "table" and payload.inventory.parts or {}
    payload.procurement = type(payload.procurement) == "table" and payload.procurement
        or { orders = {}, nextOrderId = 1 }
    payload.procurement.orders = type(payload.procurement.orders) == "table"
        and payload.procurement.orders or {}
    payload.procurement.nextOrderId = math.max(1,
        math.floor(tonumber(payload.procurement.nextOrderId) or 1))
    local orderIds = {}
    for _, order in ipairs(payload.procurement.orders) do
        local allowedStatus = { received_counter = true, awaiting_delivery = true,
            assigned_to_van = true, received = true }
        local allowedFulfillment = { counter_pickup = true, parts_van = true }
        if type(order) ~= "table" or type(order.id) ~= "string" or orderIds[order.id]
            or not Catalog.get(order.kind) or not allowedStatus[order.status]
            or not allowedFulfillment[order.fulfillment]
            or type(order.quantity) ~= "number" or order.quantity < 1
            or type(order.total) ~= "number" or order.total < 0
        then
            return false
        end
        orderIds[order.id] = true
    end
    payload.delivery = type(payload.delivery) == "table" and payload.delivery
        or { state = "absent", orderIds = {}, timer = 0, progress = 0, doorProgress = 0 }
    local deliveryStates = { absent = true, scheduled = true, arriving = true,
        parked_closed = true, door_opening = true, cargo_open = true,
        door_closing = true, departing = true }
    if not deliveryStates[payload.delivery.state] then return false end
    payload.delivery.orderIds = type(payload.delivery.orderIds) == "table"
        and payload.delivery.orderIds or {}
    for _, id in ipairs(payload.delivery.orderIds) do
        if type(id) ~= "string" or not orderIds[id] then return false end
    end
    payload.delivery.timer = math.max(0, tonumber(payload.delivery.timer) or 0)
    payload.delivery.progress = math.max(0, math.min(1, tonumber(payload.delivery.progress) or 0))
    payload.delivery.doorProgress = math.max(0,
        math.min(1, tonumber(payload.delivery.doorProgress) or 0))
    payload.motorcycleTransport = type(payload.motorcycleTransport) == "table"
        and payload.motorcycleTransport
        or { state = "absent", mode = nil, jobId = nil, timer = 0, progress = 0,
            loaded = false }
    local transportStates = { absent = true, scheduled = true, arriving = true,
        parked = true, departing = true }
    if not transportStates[payload.motorcycleTransport.state] then return false end
    if payload.motorcycleTransport.mode ~= nil
        and payload.motorcycleTransport.mode ~= "inbound"
        and payload.motorcycleTransport.mode ~= "outbound" then return false end
    payload.motorcycleTransport.timer = math.max(0,
        tonumber(payload.motorcycleTransport.timer) or 0)
    payload.motorcycleTransport.progress = math.max(0,
        math.min(1, tonumber(payload.motorcycleTransport.progress) or 0))
    payload.motorcycleTransport.loaded = payload.motorcycleTransport.loaded == true
    return true
end

function Schema.migrate(payload)
    if type(payload) ~= "table" then return nil, "save payload is not a table" end
    if payload.saveVersion ~= 1 and payload.saveVersion ~= 2 and payload.saveVersion ~= 3
        and payload.saveVersion ~= 4
        and payload.saveVersion ~= Schema.version then
        return nil, "unsupported save version"
    end
    local result = copy(payload)
    if not Schema.reconcile(result) then return nil, "invalid job archive" end
    return result
end

function Schema.validate(payload)
    if type(payload) ~= "table" then return false, "save payload is not a table" end
    if payload.saveVersion ~= Schema.version then return false, "unsupported save version" end
    if type(payload.money) ~= "number" or payload.money < 0 then return false, "invalid shop money" end
    if not positiveInteger(payload.nextJobNumber) then return false, "invalid next job number" end
    if not jobLists(payload.jobs) then return false, "invalid job archive" end
    local checked = copy(payload)
    if not Schema.reconcile(checked) then return false, "invalid or duplicate work-order identity" end
    return true
end

function Schema.copy(value) return copy(value) end

return Schema
