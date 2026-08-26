-- Data-only definitions for the repair interaction. Keeping these mappings
-- outside the renderer makes new work orders cheap to add and easy to test.
local RepairTasks = {}

local toolOrder = { "ratchet", "spanner", "screwdriver", "filterWrench", "funnel" }

local toolLabels = {
    ratchet = "Ratchet",
    spanner = "Spanner",
    screwdriver = "Driver",
    filterWrench = "Filter",
    funnel = "Funnel",
}

local definitions = {
    oil = {
        location = "oil filter",
        partVerb = "Seat the new filter",
        tool = "filterWrench",
        gesture = "rotate",
        operatePrompt = "Hold the filter wrench and circle the mouse to seat the filter.",
        target = { x = 292, y = 354 },
        workPoints = { { x = 292, y = 354 } },
        goal = math.pi * 1.55,
    },
    brake = {
        location = "front caliper",
        partVerb = "Set the brake pads",
        tool = "ratchet",
        gesture = "stroke",
        operatePrompt = "Hold the ratchet and work it left and right until each bolt clicks.",
        target = { x = 385, y = 360 },
        workPoints = { { x = 377, y = 343 }, { x = 390, y = 367 } },
        goal = 4,
    },
    chain = {
        location = "rear sprocket",
        partVerb = "Route the new chain",
        tool = "spanner",
        gesture = "adjust",
        operatePrompt = "Move the spanner left or right, then release inside the green band.",
        target = { x = 185, y = 365 },
        workPoints = { { x = 190, y = 354, startValue = 0.20 }, { x = 216, y = 365, startValue = 0.76 } },
    },
    stator = {
        location = "stator cover",
        partVerb = "Seat the stator and gasket",
        tool = "ratchet",
        gesture = "stroke",
        operatePrompt = "Hold the ratchet and work it left and right across all three bolts.",
        target = { x = 292, y = 351 },
        workPoints = { { x = 274, y = 338 }, { x = 306, y = 338 }, { x = 292, y = 365 } },
        goal = 4,
    },
    suspension = {
        location = "fork adjuster",
        partVerb = "Install the preload collar",
        tool = "spanner",
        gesture = "adjust",
        operatePrompt = "Sweep the spanner until preload settles inside the green band.",
        target = { x = 374, y = 286 },
        workPoints = { { x = 374, y = 286, startValue = 0.18 } },
    },
    belt = {
        location = "drive pulley",
        partVerb = "Align the drive belt",
        tool = "spanner",
        gesture = "adjust",
        operatePrompt = "Move the spanner until the belt alignment marker is centered.",
        target = { x = 195, y = 358 },
        workPoints = { { x = 194, y = 353, startValue = 0.80 }, { x = 222, y = 363, startValue = 0.24 } },
    },
    spoke = {
        location = "rear wheel",
        partVerb = "Fit the replacement spokes",
        tool = "spanner",
        gesture = "stroke",
        operatePrompt = "Work the spoke wrench left and right at each highlighted nipple.",
        target = { x = 178, y = 365 },
        workPoints = { { x = 164, y = 347 }, { x = 187, y = 345 }, { x = 180, y = 376 } },
        goal = 3,
    },
    carb = {
        location = "carburetor bank",
        partVerb = "Seat the carburetor bank",
        tool = "screwdriver",
        gesture = "adjust",
        operatePrompt = "Turn the screwdriver until both synchronization needles are green.",
        target = { x = 304, y = 322 },
        workPoints = { { x = 290, y = 316, startValue = 0.22 }, { x = 316, y = 316, startValue = 0.77 } },
    },
    magneto = {
        location = "magneto points",
        partVerb = "Install the magneto points",
        tool = "screwdriver",
        gesture = "rotate",
        operatePrompt = "Hold the screwdriver and circle the mouse to set the points.",
        target = { x = 289, y = 348 },
        workPoints = { { x = 280, y = 342 }, { x = 302, y = 354 } },
        goal = math.pi * 1.25,
    },
    coolant = {
        location = "radiator neck",
        partVerb = "Fit the cooling service parts",
        tool = "funnel",
        gesture = "hold",
        operatePrompt = "Hold the funnel steady, then release while the level is green.",
        target = { x = 345, y = 292 },
        workPoints = { { x = 345, y = 292 } },
        holdSeconds = 1.65,
    },
    tool = {
        location = "service point",
        partVerb = "Seat the service part",
        tool = "ratchet",
        gesture = "stroke",
        operatePrompt = "Hold the ratchet and work it left and right until it clicks.",
        target = { x = 295, y = 345 },
        workPoints = { { x = 295, y = 345 } },
        goal = 4,
    },
}

local keywords = {
    "oil", "brake", "chain", "stator", "suspension",
    "belt", "spoke", "carb", "magneto", "coolant",
}

local serviceKinds = {
    ["oil and filter service"] = "oil",
    ["front brake overhaul"] = "brake",
    ["chain and sprocket replacement"] = "chain",
    ["charging-system diagnosis"] = "stator",
    ["adventure suspension setup"] = "suspension",
    ["belt-drive and idle service"] = "belt",
    ["spoked-wheel and luggage inspection"] = "spoke",
    ["carburetor synchronization"] = "carb",
    ["vintage magneto and valve service"] = "magneto",
    ["cooling and drive-chain service"] = "coolant",
}

function RepairTasks.kindFor(job)
    if type(job) ~= "table" then return "tool" end
    if job.repairKind and definitions[job.repairKind] then return job.repairKind end
    local service = string.lower(job.service or "")
    if serviceKinds[service] then return serviceKinds[service] end
    local partText = string.lower(table.concat(job.parts or {}, " "))
    local haystack = service .. " " .. partText
    for _, keyword in ipairs(keywords) do
        if haystack:find(keyword, 1, true) then return keyword end
    end
    return "tool"
end

function RepairTasks.forJob(job)
    local kind = RepairTasks.kindFor(job)
    return kind, definitions[kind] or definitions.tool
end

function RepairTasks.get(kind) return definitions[kind] or definitions.tool end
function RepairTasks.tools() return toolOrder end
function RepairTasks.toolLabel(kind) return toolLabels[kind] or "Tool" end

function RepairTasks.toolIndex(kind)
    for index, candidate in ipairs(toolOrder) do
        if candidate == kind then return index end
    end
    return 1
end

return RepairTasks
