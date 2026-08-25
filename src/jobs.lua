-- Pure motorcycle work-order rules. Rendering, saves, and player state are
-- deliberately kept outside this module.
local Jobs = {}

local templates = {
    {
        owner = "Mara Fox", company = "Fox Courier Co.",
        year = 2021, make = "Yamaha", model = "MT-07",
        service = "Oil and filter service",
        complaint = "The oil light flickers after long delivery runs.",
        diagnosis = "Oil is worn and the filter is restricted; no metal found.",
        parts = { "4 qt synthetic oil", "oil filter", "drain washer" },
        partsCost = 72, labor = 180, difficulty = "Routine", hours = 1.2,
        bikeKey = "nakedBlack",
    },
    {
        owner = "Dax Ember", company = "Ember Track Days",
        year = 1983, make = "Yamaha", model = "XV750 Virago",
        service = "Front brake overhaul",
        complaint = "The front lever pulses and feels soft under hard braking.",
        diagnosis = "Front pads are glazed and the fluid contains moisture.",
        parts = { "front brake pads", "DOT 4 fluid", "caliper seals" },
        partsCost = 164, labor = 360, difficulty = "Skilled", hours = 2.8,
        bikeKey = "vintageRedStandard",
    },
    {
        owner = "Toby Copper", company = "Copper Trail Club",
        year = 1997, make = "Honda", model = "Shadow VLX",
        service = "Chain and sprocket replacement",
        complaint = "The chain clunks on takeoff and needs adjustment every ride.",
        diagnosis = "The chain has tight links and both sprockets are hooked.",
        parts = { "sealed drive chain", "front sprocket", "rear sprocket" },
        partsCost = 238, labor = 420, difficulty = "Skilled", hours = 3.1,
        bikeKey = "blackClassic",
    },
    {
        owner = "Cleo Vale", company = "Vale Night Riders",
        year = 2008, make = "Suzuki", model = "GSX-R750",
        service = "Charging-system diagnosis",
        complaint = "The battery goes flat if the bike sits at idle with the lights on.",
        diagnosis = "Stator output is low and the connector shows heat damage.",
        parts = { "replacement stator", "stator gasket", "connector kit" },
        partsCost = 286, labor = 510, difficulty = "Advanced", hours = 3.7,
        bikeKey = "redSupersport",
    },
    {
        owner = "Nia Ridge", company = "Ridgeback Tours",
        year = 2022, make = "BMW", model = "R 1250 GS",
        service = "Adventure suspension setup",
        complaint = "The front end dives under braking with camping gear loaded.",
        diagnosis = "Fork preload is low and the rear sag is outside touring setup.",
        parts = { "fork oil", "preload collar", "suspension seals" },
        partsCost = 214, labor = 455, difficulty = "Advanced", hours = 3.4,
        bikeKey = "adventureSilverRed",
    },
    {
        owner = "Rex Harbor", company = "Harbor Line Customs",
        year = 2016, make = "Harley-Davidson", model = "Street Bob",
        service = "Belt-drive and idle service",
        complaint = "The belt chirps at low speed and the idle hunts at stoplights.",
        diagnosis = "Belt alignment is off and the throttle body needs a clean service.",
        parts = { "drive belt", "idler pulley", "throttle-body gasket" },
        partsCost = 336, labor = 495, difficulty = "Skilled", hours = 3.6,
        bikeKey = "redVtwinCruiser",
    },
    {
        owner = "Jules Summit", company = "Summit Backroads",
        year = 2024, make = "Honda", model = "Africa Twin",
        service = "Spoked-wheel and luggage inspection",
        complaint = "The bike pulls left after a long gravel trip with panniers loaded.",
        diagnosis = "Rear wheel alignment is out and the spoke tension is uneven.",
        parts = { "spoke set", "wheel bearings", "alignment shims" },
        partsCost = 248, labor = 470, difficulty = "Advanced", hours = 3.5,
        bikeKey = "adventureBlueWhite",
    },
    {
        owner = "Owen Birch", company = "Birch & Iron Tours",
        year = 2020, make = "Ural", model = "Classic Solo",
        service = "Carburetor synchronization",
        complaint = "The engine surges at cruise and the idle drops when warm.",
        diagnosis = "The twin carburetors are out of balance and the intake boots are aging.",
        parts = { "intake boots", "carb gaskets", "spark plugs" },
        partsCost = 126, labor = 315, difficulty = "Skilled", hours = 2.4,
        bikeKey = "uralTanClassic",
    },
    {
        owner = "Greta Falk", company = "Falk Vintage Club",
        year = 1940, make = "BMW", model = "R24",
        service = "Vintage magneto and valve service",
        complaint = "The old single starts reluctantly and ticks loudly at idle.",
        diagnosis = "Valve clearances are tight and the magneto points need dressing.",
        parts = { "valve cover gasket", "magneto points", "plug wire" },
        partsCost = 188, labor = 540, difficulty = "Advanced", hours = 4.2,
        bikeKey = "bmwR24Vintage",
    },
    {
        owner = "Kai Mercer", company = "Mercer Night Ride",
        year = 2023, make = "Honda", model = "Rebel 500",
        service = "Cooling and drive-chain service",
        complaint = "The fan runs often and the chain snaps during low-speed shifts.",
        diagnosis = "Coolant is below the mark and the chain has several seized links.",
        parts = { "coolant", "sealed drive chain", "chain adjuster set" },
        partsCost = 196, labor = 330, difficulty = "Routine", hours = 2.3,
        bikeKey = "modernGrayCruiser",
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
        bikeKey = template.bikeKey,
        artwork = template.bikeKey and ("motorcycleService_" .. template.bikeKey) or template.artwork,
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

-- Older saves were created before bike-specific sprite keys existed. Resolve
-- their visual identity from the saved bike data so they still arrive on the
-- correct lift art instead of falling back to the generic GSX-R.
function Jobs.bikeKeyFor(job)
    if type(job) ~= "table" then return nil end
    if job.bikeKey then return job.bikeKey end
    if job.bike and job.bike.make == "Suzuki" and job.bike.model == "GSX-R600" then
        return "redSupersport"
    end
    local sequence = tonumber(job.sequence) or 1
    local template = templates[(sequence - 1) % #templates + 1]
    return template.bikeKey
end

function Jobs.ensureBikeSprite(job)
    local key = Jobs.bikeKeyFor(job)
    if type(job) == "table" and key then
        job.bikeKey = key
        job.artwork = "motorcycleService_" .. key
    end
    return key
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
