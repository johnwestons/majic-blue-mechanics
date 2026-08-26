local DeliveryVehicle = {}

local function lerp(a, b, amount) return a + (b - a) * amount end
local function smoothstep(amount)
    amount = math.max(0, math.min(1, amount or 0))
    return amount * amount * (3 - 2 * amount)
end

function DeliveryVehicle.ensure(state)
    state.delivery = type(state.delivery) == "table" and state.delivery or {}
    local delivery = state.delivery
    delivery.state = delivery.state or "absent"
    delivery.timer = math.max(0, tonumber(delivery.timer) or 0)
    delivery.progress = math.max(0, math.min(1, tonumber(delivery.progress) or 0))
    delivery.doorProgress = math.max(0, math.min(1, tonumber(delivery.doorProgress) or 0))
    delivery.orderIds = type(delivery.orderIds) == "table" and delivery.orderIds or {}
    return delivery
end

function DeliveryVehicle.schedule(state, procurement, config)
    local delivery = DeliveryVehicle.ensure(state)
    if delivery.state ~= "absent" then return false end
    local ids = {}
    for _, order in ipairs(procurement.orders or {}) do
        if order.status == "awaiting_delivery" and #ids < (config.maximumOrders or 5) then
            ids[#ids + 1] = order.id
            order.status = "assigned_to_van"
        end
    end
    if #ids == 0 then return false end
    delivery.orderIds, delivery.timer = ids, config.scheduleDelay or 2
    delivery.progress, delivery.doorProgress, delivery.state = 0, 0, "scheduled"
    return true
end

function DeliveryVehicle.update(state, dt, config)
    local delivery = DeliveryVehicle.ensure(state)
    dt = math.max(0, dt or 0)
    if delivery.state == "scheduled" then
        delivery.timer = math.max(0, delivery.timer - dt)
        if delivery.timer == 0 then delivery.state = "arriving"; return "arrival_started" end
    elseif delivery.state == "arriving" then
        delivery.progress = math.min(1, delivery.progress + dt / (config.travelDuration or 2.2))
        if delivery.progress == 1 then delivery.state = "parked_closed"; return "parked" end
    elseif delivery.state == "door_opening" then
        delivery.doorProgress = math.min(1, delivery.doorProgress + dt / (config.doorDuration or 0.6))
        if delivery.doorProgress == 1 then delivery.state = "cargo_open"; return "cargo_opened" end
    elseif delivery.state == "door_closing" then
        delivery.doorProgress = math.max(0, delivery.doorProgress - dt / (config.doorDuration or 0.6))
        if delivery.doorProgress == 0 then delivery.state = "departing"; return "departing" end
    elseif delivery.state == "departing" then
        delivery.progress = math.max(0, delivery.progress - dt / (config.travelDuration or 2.2))
        if delivery.progress == 0 then
            delivery.state, delivery.orderIds = "absent", {}
            return "departed"
        end
    end
end

function DeliveryVehicle.toggleDoor(state)
    local delivery = DeliveryVehicle.ensure(state)
    if delivery.state == "parked_closed" then delivery.state = "door_opening"; return true end
    if delivery.state == "cargo_open" then delivery.state = "door_closing"; return true end
    return false
end

function DeliveryVehicle.transform(state, config)
    local delivery = DeliveryVehicle.ensure(state)
    local amount = smoothstep(delivery.progress)
    return { x = lerp(config.start.x, config.parked.x, amount),
        y = lerp(config.start.y, config.parked.y, amount),
        scale = lerp(config.start.scale, config.parked.scale, amount) }
end

function DeliveryVehicle.visible(state)
    local value = DeliveryVehicle.ensure(state).state
    return value ~= "absent" and value ~= "scheduled"
end

function DeliveryVehicle.interaction(state, config)
    local delivery = DeliveryVehicle.ensure(state)
    if delivery.state ~= "parked_closed" and delivery.state ~= "cargo_open" then return nil end
    return { x = config.interaction.x, y = config.interaction.y,
        radius = config.interaction.radius, kind = "parts_van",
        prompt = delivery.state == "parked_closed" and "E: open parts van"
            or "E: review parts delivery manifest" }
end

function DeliveryVehicle.obstacle(state, config)
    if not DeliveryVehicle.visible(state) then return nil end
    local transform = DeliveryVehicle.transform(state, config)
    return { x = transform.x, y = transform.y, halfWidth = config.obstacle.halfWidth,
        halfHeight = config.obstacle.halfHeight }
end

return DeliveryVehicle
