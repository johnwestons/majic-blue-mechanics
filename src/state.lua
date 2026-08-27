local Jobs = require("src.jobs")
local SaveSchema = require("src.save_schema")
local Procurement = require("src.procurement")
local DeliveryVehicle = require("src.delivery_vehicle")
local MotorcycleTransport = require("src.motorcycle_transport")
local State = {}

local function fresh()
    return {
        saveVersion = SaveSchema.version,
        screen = "title",
        activeSlot = nil,
        money = 1250,
        revenue = 0,
        expenses = 0,
        reputation = 0,
        nextJobNumber = 1,
        jobs = { active = {}, completed = {}, declined = {} },
        pendingOffer = nil,
        inventory = { parts = {} },
        procurement = { orders = {}, cart = {}, nextOrderId = 1 },
        delivery = { state = "absent", orderIds = {}, timer = 0,
            progress = 0, doorProgress = 0 },
        motorcycleTransport = { state = "absent", mode = nil, jobId = nil,
            timer = 0, progress = 0 },
        selectedJobId = nil,
        calendar = { year = 2026, month = 1, day = 1, weekday = 4, elapsed = 0, totalDays = 0 },
        clientEmails = { inbox = {}, archive = {}, nextId = 1 },
        message = "Open the shop and greet the first rider.",
        player = nil,
    }
end

function State.new() return fresh() end

function State.newGame(slot)
    local payload = fresh()
    payload.activeSlot = slot
    payload.screen = "world"
    return payload
end

function State.applySave(target, payload)
    payload = SaveSchema.migrate(payload)
    if not payload then return false end
    local defaults = fresh()
    for key in pairs(target) do target[key] = nil end
    for key, value in pairs(defaults) do target[key] = value end
    for key, value in pairs(payload or {}) do target[key] = value end
    target.jobs = target.jobs or { active = {}, completed = {}, declined = {} }
    target.jobs.active = target.jobs.active or {}
    target.jobs.completed = target.jobs.completed or {}
    target.jobs.declined = target.jobs.declined or {}
    for _, list in ipairs({ target.jobs.active, target.jobs.completed, target.jobs.declined }) do
        for _, job in ipairs(list) do Jobs.ensureBikeSprite(job) end
    end
    target.pendingOffer = type(payload.pendingOffer) == "table" and payload.pendingOffer or nil
    if target.pendingOffer then Jobs.ensureBikeSprite(target.pendingOffer) end
    target.selectedJobId = nil
    target.screen = "world"
    Procurement.ensure(target)
    DeliveryVehicle.ensure(target)
    MotorcycleTransport.ensure(target)
    SaveSchema.reconcile(target)
    return true
end

return State
