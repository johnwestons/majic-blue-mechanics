local StatusLabels = {}

local labels = {
    offered = "Estimate pending",
    active = "In service",
    completed = "Service completed",
    declined = "Estimate declined",
    estimate = "Estimate",
    diagnosis = "Awaiting diagnosis",
    awaiting_dropoff = "Awaiting flatbed drop-off",
    repair = "Ready for repair",
    road_test = "Ready for road test",
    ready_for_pickup = "Ready for customer pickup",
    pickup_transport = "Awaiting return flatbed",
    complete = "Completed",
    closed = "Declined",
}

function StatusLabels.get(value)
    if type(value) ~= "string" then return "Unknown" end
    return labels[value] or value:gsub("_", " "):gsub("^%l", string.upper)
end

return StatusLabels
