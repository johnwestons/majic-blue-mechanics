local Jobs = require("src.jobs")
local State = {}

local function fresh()
    return {
        saveVersion = 1,
        screen = "title",
        activeSlot = nil,
        money = 1250,
        revenue = 0,
        expenses = 0,
        reputation = 0,
        nextJobNumber = 1,
        jobs = { active = {}, completed = {}, declined = {} },
        pendingOffer = nil,
        selectedJobId = nil,
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
    target.pendingOffer = nil
    target.selectedJobId = nil
    target.screen = "world"
end

return State
