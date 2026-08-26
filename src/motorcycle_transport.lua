local Transport = {}

local function lerp(a, b, amount) return a + (b - a) * amount end
local function smoothstep(value)
    value = math.max(0, math.min(1, value or 0))
    return value * value * (3 - 2 * value)
end

function Transport.ensure(state)
    state.motorcycleTransport = type(state.motorcycleTransport) == "table"
        and state.motorcycleTransport or {}
    local transport = state.motorcycleTransport
    transport.state = transport.state or "absent"
    transport.mode = transport.mode
    transport.jobId = transport.jobId
    transport.bikeKey = transport.bikeKey
    transport.loaded = transport.loaded == true
    transport.timer = math.max(0, tonumber(transport.timer) or 0)
    transport.progress = math.max(0, math.min(1, tonumber(transport.progress) or 0))
    return transport
end

function Transport.schedule(state, job, mode, config)
    local transport = Transport.ensure(state)
    if transport.state ~= "absent" or not job then return false end
    transport.state, transport.jobId, transport.mode = "scheduled", job.id, mode
    transport.bikeKey, transport.loaded = job.bikeKey, mode == "inbound"
    transport.timer, transport.progress = config.scheduleDelay or 2, 0
    return true
end

function Transport.update(state, dt, config)
    local transport = Transport.ensure(state)
    dt = math.max(0, dt or 0)
    if transport.state == "scheduled" then
        transport.timer = math.max(0, transport.timer - dt)
        if transport.timer == 0 then transport.state = "arriving"; return "arrival_started" end
    elseif transport.state == "arriving" then
        transport.progress = math.min(1, transport.progress + dt / (config.travelDuration or 2.4))
        if transport.progress == 1 then transport.state = "parked"; return "parked" end
    elseif transport.state == "departing" then
        transport.progress = math.max(0, transport.progress - dt / (config.travelDuration or 2.4))
        if transport.progress == 0 then
            transport.state, transport.jobId, transport.mode = "absent", nil, nil
            transport.bikeKey, transport.loaded = nil, false
            return "departed"
        end
    end
end

function Transport.depart(state)
    local transport = Transport.ensure(state)
    if transport.state ~= "parked" then return false end
    transport.state = "departing"
    return true
end

function Transport.transform(state, config)
    local amount = smoothstep(Transport.ensure(state).progress)
    return { x = lerp(config.start.x, config.parked.x, amount),
        y = lerp(config.start.y, config.parked.y, amount),
        scale = lerp(config.start.scale, config.parked.scale, amount) }
end

function Transport.visible(state)
    local value = Transport.ensure(state).state
    return value == "arriving" or value == "parked" or value == "departing"
end

function Transport.interaction(state, config)
    local transport = Transport.ensure(state)
    if transport.state ~= "parked" then return nil end
    return { x = config.interaction.x, y = config.interaction.y,
        radius = config.interaction.radius, kind = "motorcycle_transport",
        prompt = transport.mode == "inbound" and "E: unload motorcycle from flatbed"
            or "E: load finished motorcycle for return" }
end

function Transport.obstacle(state, config)
    if not Transport.visible(state) then return nil end
    local transform = Transport.transform(state, config)
    return { x = transform.x, y = transform.y,
        halfWidth = config.obstacle.halfWidth, halfHeight = config.obstacle.halfHeight }
end

return Transport
