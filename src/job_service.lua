local Jobs = require("src.jobs")
local Procurement = require("src.procurement")

local JobService = {}

local function findById(list, id)
    for index, job in ipairs(list or {}) do
        if job.id == id then return job, index end
    end
end

function JobService.prepareOffer(state)
    if state.pendingOffer then return state.pendingOffer end
    state.pendingOffer = Jobs.createOffer(state.nextJobNumber)
    return state.pendingOffer
end

function JobService.cancelReview(state)
    state.screen = "world"
    state.message = "The estimate is still waiting at reception."
end

function JobService.acceptOffer(state)
    local offer = state.pendingOffer
    if not offer then return false, "There is no estimate to accept." end
    local ok, message = Jobs.accept(offer)
    if not ok then return false, message end
    state.jobs.active[#state.jobs.active + 1] = offer
    state.pendingOffer = nil
    state.nextJobNumber = state.nextJobNumber + 1
    state.reputation = state.reputation + 1
    state.message = offer.id .. " accepted. The motorcycle is in the service queue."
    state.screen = "world"
    return true, offer
end

function JobService.declineOffer(state)
    local offer = state.pendingOffer
    if not offer then return false, "There is no estimate to decline." end
    local ok, message = Jobs.decline(offer)
    if not ok then return false, message end
    state.jobs.declined[#state.jobs.declined + 1] = offer
    state.pendingOffer = nil
    state.nextJobNumber = state.nextJobNumber + 1
    state.message = offer.id .. " declined."
    state.screen = "world"
    return true, offer
end

function JobService.currentJob(state)
    for _, job in ipairs(state.jobs.active) do
        if Jobs.isActive(job) and job.stage ~= "awaiting_dropoff" then
            Jobs.ensureBikeSprite(job)
            return job
        end
    end
end

function JobService.findActive(state, id)
    return findById(state.jobs.active, id)
end

function JobService.diagnose(state, id)
    local job = JobService.findActive(state, id)
    if not job then return false, "That work order is not active." end
    local ok, message = Jobs.diagnose(job)
    if ok then
        state.message = job.id .. ": diagnosis confirmed. Parts and repair are ready."
        return true, job
    end
    return false, message
end

function JobService.canBeginRepair(state, id)
    local job = JobService.findActive(state, id)
    if not job then return false, "That work order is not active." end
    if job.stage ~= "repair" then
        return false, "Diagnosis must be complete before repair work can begin."
    end
    if Procurement.quantity(state, job.repairKind) < 1 then
        return false, "Required " .. tostring(job.repairKind)
            .. " service kit is not in stock. Order it at the computer, then receive it from the parts van."
    end
    return true, job
end

function JobService.repair(state, id)
    local job = JobService.findActive(state, id)
    if not job then return false, "That work order is not active." end
    local ready, message = JobService.canBeginRepair(state, id)
    if not ready then return false, message end
    local ok, message = Jobs.repair(job)
    if ok then
        Procurement.consume(state, job.repairKind)
        state.message = job.id .. ": repair complete. Run the final road test."
        return true, job
    end
    return false, message
end

function JobService.roadTest(state, id)
    local job = JobService.findActive(state, id)
    if not job then return false, "That work order is not active." end
    local ok, message = Jobs.completeTest(job)
    if not ok then return false, message end
    state.selectedJobId = nil
    state.message = job.transportRequired
        and (job.id .. " passed its road test. The return flatbed has been requested.")
        or (job.id .. " passed its road test. The owner is on the way for pickup.")
    return true, job
end


function JobService.receiveDropoff(state, id)
    local job = JobService.findActive(state, id)
    if not job then return false, "That transported motorcycle is not active." end
    local ok, message = Jobs.receiveDropoff(job)
    if not ok then return false, message end
    state.message = job.id .. " unloaded into the service bay. Diagnosis can begin."
    return true, job
end

function JobService.completePickup(state, id)
    local job, index = JobService.findActive(state, id)
    if not job then return false, "That motorcycle is not awaiting pickup." end
    local ok, message = Jobs.completePickup(job)
    if not ok then return false, message end
    table.remove(state.jobs.active, index)
    state.jobs.completed[#state.jobs.completed + 1] = job
    state.money = state.money + job.quote
    state.revenue = state.revenue + job.quote
    state.reputation = state.reputation + 2
    state.selectedJobId = nil
    state.message = string.format("%s returned to %s. Collected $%d.",
        job.id, job.owner, job.quote)
    return true, job
end

function JobService.updateOwnerPickups(state, dt, delay)
    for _, job in ipairs(state.jobs.active) do
        if job.stage == "ready_for_pickup" and not job.transportRequired then
            job.pickupTimer = (tonumber(job.pickupTimer) or 0) + math.max(0, dt or 0)
            if job.pickupTimer >= delay then return JobService.completePickup(state, job.id) end
        end
    end
    return false
end

return JobService
