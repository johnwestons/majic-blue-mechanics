-- Pure motorcycle work-order rules. Rendering, saves, and player state are
-- deliberately kept outside this module.
local Jobs = {}

local templates = {
    {
        owner = "Mara Fox", company = "Fox Courier Co.",
        year = 2021, make = "Suzuki", model = "GSX-R600",
        service = "Oil and filter service",
        complaint = "The oil light flickers after long delivery runs.",
        diagnosis = "Oil is worn and the filter is restricted; no metal found.",
        parts = { "4 qt synthetic oil", "oil filter", "drain washer" },
        partsCost = 72, labor = 180, difficulty = "Routine", hours = 1.2,
        artwork = "motorcycleSide",
    },
    {
        owner = "Dax Ember", company = "Ember Track Days",
        year = 2019, make = "Suzuki", model = "GSX-R600",
        service = "Front brake overhaul",
        complaint = "The front lever pulses and feels soft under hard braking.",
        diagnosis = "Front pads are glazed and the fluid contains moisture.",
        parts = { "front brake pads", "DOT 4 fluid", "caliper seals" },
        partsCost = 164, labor = 360, difficulty = "Skilled", hours = 2.8,
        artwork = "motorcycleSide",
    },
    {
        owner = "Toby Copper", company = "Copper Trail Club",
        year = 2020, make = "Suzuki", model = "GSX-R600",
        service = "Chain and sprocket replacement",
        complaint = "The chain clunks on takeoff and needs adjustment every ride.",
        diagnosis = "The chain has tight links and both sprockets are hooked.",
        parts = { "sealed drive chain", "front sprocket", "rear sprocket" },
        partsCost = 238, labor = 420, difficulty = "Skilled", hours = 3.1,
        artwork = "motorcycleSide",
    },
    {
        owner = "Cleo Vale", company = "Vale Night Riders",
        year = 2018, make = "Suzuki", model = "GSX-R600",
        service = "Charging-system diagnosis",
        complaint = "The battery goes flat if the bike sits at idle with the lights on.",
        diagnosis = "Stator output is low and the connector shows heat damage.",
        parts = { "replacement stator", "stator gasket", "connector kit" },
        partsCost = 286, labor = 510, difficulty = "Advanced", hours = 3.7,
        artwork = "motorcycleSide",
    },
}

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

function Jobs.formatId(sequence)
    assert(type(sequence) == "number" and sequence >= 1 and sequence == math.floor(sequence),
        "job sequence must be a positive whole number")
    return string.format("MBM-%04d", sequence)
end

function Jobs.createOffer(sequence)
    local template = copy(templates[(sequence - 1) % #templates + 1])
    local shopSupplies = 18 + ((sequence - 1) % 3) * 6
    local subtotal = template.partsCost + template.labor + shopSupplies
    local tax = math.floor(template.partsCost * 0.06 + 0.5)
    return {
        id = Jobs.formatId(sequence),
        sequence = sequence,
        owner = template.owner,
        company = template.company,
        bike = {
            year = template.year,
            make = template.make,
            model = template.model,
            mileage = 6400 + sequence * 1731,
        },
        service = template.service,
        complaint = template.complaint,
        diagnosis = template.diagnosis,
        parts = template.parts,
        partsCost = template.partsCost,
        labor = template.labor,
        shopSupplies = shopSupplies,
        tax = tax,
        quote = subtotal + tax,
        difficulty = template.difficulty,
        hours = template.hours,
        artwork = template.artwork,
        status = "offered",
        stage = "estimate",
        partsPurchased = false,
        checklist = {
            diagnosed = false,
            repaired = false,
            roadTested = false,
        },
    }
end

local function transition(job, expectedStatus, expectedStage, nextStatus, nextStage)
    if type(job) ~= "table" then return false, "job is required" end
    if job.status ~= expectedStatus or job.stage ~= expectedStage then
        return false, string.format("%s is currently %s/%s", job.id or "job",
            tostring(job.status), tostring(job.stage))
    end
    job.status, job.stage = nextStatus, nextStage
    return true
end

function Jobs.accept(job)
    return transition(job, "offered", "estimate", "active", "diagnosis")
end

function Jobs.decline(job)
    return transition(job, "offered", "estimate", "declined", "closed")
end

function Jobs.diagnose(job)
    local ok, message = transition(job, "active", "diagnosis", "active", "repair")
    if ok then job.checklist.diagnosed = true end
    return ok, message
end

function Jobs.repair(job)
    local ok, message = transition(job, "active", "repair", "active", "road_test")
    if ok then
        job.partsPurchased = true
        job.checklist.repaired = true
    end
    return ok, message
end

function Jobs.completeTest(job)
    local ok, message = transition(job, "active", "road_test", "completed", "complete")
    if ok then job.checklist.roadTested = true end
    return ok, message
end

function Jobs.stageLabel(job)
    local labels = {
        estimate = "Estimate",
        diagnosis = "Awaiting diagnosis",
        repair = "Ready for repair",
        road_test = "Ready for road test",
        complete = "Completed",
        closed = "Declined",
    }
    return labels[job and job.stage] or "Unknown"
end

function Jobs.isActive(job) return type(job) == "table" and job.status == "active" end
function Jobs.templates() return copy(templates) end

return Jobs
