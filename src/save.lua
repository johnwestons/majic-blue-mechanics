local State = require("src.state")
local SaveSchema = require("src.save_schema")

local Save = {
    version = SaveSchema.version,
    slotCount = 3,
}

local function path(slot) return string.format("slot-%d.lua", slot) end
local function backupPath(slot) return string.format("slot-%d.backup.lua", slot) end
local function temporaryPath(slot) return string.format("slot-%d.pending.lua", slot) end

local function validateSlot(slot)
    return type(slot) == "number" and slot >= 1 and slot <= Save.slotCount
        and slot == math.floor(slot)
end

local function keyOrder(a, b)
    if type(a) == type(b) then return tostring(a) < tostring(b) end
    return type(a) < type(b)
end

local function serialize(value, indent, seen)
    indent, seen = indent or "", seen or {}
    local valueType = type(value)
    if valueType == "nil" then return "nil" end
    if valueType == "boolean" or valueType == "number" then return tostring(value) end
    if valueType == "string" then return string.format("%q", value) end
    assert(valueType == "table", "save data contains unsupported " .. valueType)
    assert(not seen[value], "save data contains a cycle")
    seen[value] = true
    local keys = {}
    for key in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, keyOrder)
    local lines = { "{" }
    local nextIndent = indent .. "    "
    for _, key in ipairs(keys) do
        local encodedKey
        if type(key) == "string" and key:match("^[%a_][%w_]*$") then
            encodedKey = key
        else
            encodedKey = "[" .. serialize(key, nextIndent, seen) .. "]"
        end
        lines[#lines + 1] = string.format("%s%s = %s,", nextIndent, encodedKey,
            serialize(value[key], nextIndent, seen))
    end
    lines[#lines + 1] = indent .. "}"
    seen[value] = nil
    return table.concat(lines, "\n")
end

local function validate(payload)
    return SaveSchema.validate(payload)
end

local function decode(filePath)
    if not love.filesystem.getInfo(filePath) then return nil, "missing" end
    local loaded, chunk, loadError = pcall(love.filesystem.load, filePath)
    if not loaded then return nil, chunk end
    if not chunk then return nil, loadError end
    local ok, payload = pcall(chunk)
    if not ok then return nil, payload end
    local migrated, migrationError = SaveSchema.migrate(payload)
    if not migrated then return nil, migrationError end
    local valid, validationError = validate(migrated)
    if not valid then return nil, validationError end
    return migrated
end

local function persistentPayload(slot, state, worldSnapshot, customerSnapshot)
    return {
        saveVersion = Save.version,
        activeSlot = slot,
        money = state.money,
        revenue = state.revenue,
        expenses = state.expenses,
        reputation = state.reputation,
        nextJobNumber = state.nextJobNumber,
        jobs = state.jobs,
        message = state.message,
        player = worldSnapshot,
        customer = customerSnapshot,
        pendingOffer = state.pendingOffer,
        inventory = state.inventory,
        procurement = state.procurement,
        delivery = state.delivery,
        motorcycleTransport = state.motorcycleTransport,
        calendar = state.calendar,
        clientEmails = state.clientEmails,
    }
end

function Save.newGame(slot)
    assert(validateSlot(slot), "save slot must be 1, 2, or 3")
    return State.newGame(slot)
end

function Save.save(slot, state, worldSnapshot, customerSnapshot)
    if not validateSlot(slot) then return false, "save slot must be 1, 2, or 3" end
    local payload = persistentPayload(slot, state, worldSnapshot, customerSnapshot)
    local ok, encoded = pcall(function() return "return " .. serialize(payload) .. "\n" end)
    if not ok then return false, encoded end

    local pending = temporaryPath(slot)
    local wrote, writeError = love.filesystem.write(pending, encoded)
    if not wrote then return false, writeError end
    local decoded, validationError = decode(pending)
    if not decoded then
        love.filesystem.remove(pending)
        return false, "pending save validation failed: " .. tostring(validationError)
    end

    local primary = path(slot)
    local validPrimary = decode(primary)
    if validPrimary then
        local previous = love.filesystem.read(primary)
        if previous then love.filesystem.write(backupPath(slot), previous) end
    end
    local pendingContents = love.filesystem.read(pending)
    local promoted, promoteError = love.filesystem.write(primary, pendingContents)
    love.filesystem.remove(pending)
    if not promoted then return false, promoteError end
    return true
end

function Save.load(slot)
    if not validateSlot(slot) then return nil, "save slot must be 1, 2, or 3" end
    local payload, primaryError = decode(path(slot))
    if payload then return payload end
    local backup, backupError = decode(backupPath(slot))
    if backup then
        backup.recovered = true
        backup.recoverySource = "backup"
        return backup
    end
    return nil, primaryError == "missing" and "empty"
        or string.format("primary: %s; backup: %s", tostring(primaryError), tostring(backupError))
end

function Save.delete(slot)
    if not validateSlot(slot) then return false end
    love.filesystem.remove(path(slot))
    love.filesystem.remove(backupPath(slot))
    love.filesystem.remove(temporaryPath(slot))
    return true
end

function Save.slotInfo(slot)
    local payload, errorMessage = Save.load(slot)
    if not payload then
        return { slot = slot, exists = errorMessage ~= "empty", damaged = errorMessage ~= "empty" }
    end
    return {
        slot = slot,
        exists = true,
        damaged = false,
        money = payload.money,
        reputation = payload.reputation,
        activeJobs = #payload.jobs.active,
        completedJobs = #payload.jobs.completed,
    }
end

function Save.listSlots()
    local result = {}
    for slot = 1, Save.slotCount do result[slot] = Save.slotInfo(slot) end
    return result
end

function Save.validate(payload) return validate(payload) end

return Save
