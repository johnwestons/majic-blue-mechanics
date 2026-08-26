local Config = require("src.config")
local Customer = require("src.customer")
local Interaction = require("src.interaction")
local JobService = require("src.job_service")
local Navigation = require("src.navigation")
local DeliveryVehicle = require("src.delivery_vehicle")
local Procurement = require("src.procurement")
local MotorcycleTransport = require("src.motorcycle_transport")
local WorldRenderer = require("src.world_renderer")

local World = {
    player = {
        x = Config.player.spawnX,
        y = Config.player.spawnY,
        speed = Config.player.speed,
        moving = false,
        facing = 1,
        animationClock = 0,
    },
    customer = Customer.new(Config.customer),
    selectedInteraction = nil,
}

local function currentJob(state) return JobService.currentJob(state) end

local function movementObstacles(state)
    local obstacles = {}
    local customerObstacle = World.customer:getObstacle()
    if customerObstacle then obstacles[#obstacles + 1] = customerObstacle end
    if currentJob(state) then
        obstacles[#obstacles + 1] = {
            x = Config.serviceBay.bikeX,
            y = Config.serviceBay.bikeY,
            halfWidth = Config.serviceBay.collisionHalfWidth,
            halfHeight = Config.serviceBay.collisionHalfHeight,
        }
    end
    local vanObstacle = DeliveryVehicle.obstacle(state, Config.partsDelivery)
    if vanObstacle then obstacles[#obstacles + 1] = vanObstacle end
    local transportObstacle = MotorcycleTransport.obstacle(state, Config.motorcycleTransport)
    if transportObstacle then obstacles[#obstacles + 1] = transportObstacle end
    return obstacles
end

local function targets(state)
    local result = {
        {
            x = Config.interactables.computer.x,
            y = Config.interactables.computer.y,
            radius = Config.interactables.computer.radius,
            kind = "computer",
            prompt = "E: open work-order computer",
        },
    }
    local customer = World.customer:getInteraction()
    if customer then result[#result + 1] = customer end
    local delivery = DeliveryVehicle.interaction(state, Config.partsDelivery)
    if delivery then result[#result + 1] = delivery end
    local transport = MotorcycleTransport.interaction(state, Config.motorcycleTransport)
    if transport then result[#result + 1] = transport end
    local job = currentJob(state)
    if job then
        result[#result + 1] = {
            x = Config.interactables.serviceBay.x,
            y = Config.interactables.serviceBay.y,
            radius = Config.interactables.serviceBay.radius,
            kind = "service_bay",
            jobId = job.id,
            prompt = "E: service " .. job.id,
        }
    end
    return result
end

function World.load(playerPayload, customerPayload)
    World.player.x = playerPayload and playerPayload.x or Config.player.spawnX
    World.player.y = playerPayload and playerPayload.y or Config.player.spawnY
    World.player.facing = playerPayload and playerPayload.facing or 1
    World.player.moving = false
    World.player.animationClock = 0
    World.selectedInteraction = nil
    World.customer:reset(nil, true)
    if customerPayload then World.customer:restore(customerPayload) end
end

function World.snapshot()
    return { x = World.player.x, y = World.player.y, facing = World.player.facing }
end

function World.update(dt, directionX, directionY, assets, state)
    Procurement.ensure(state)
    DeliveryVehicle.schedule(state, state.procurement, Config.partsDelivery)
    local deliveryEvent = DeliveryVehicle.update(state, dt, Config.partsDelivery)
    if deliveryEvent == "parked" then
        state.message = "The Majic Blue parts van has arrived. Open it at the rear doors."
    elseif deliveryEvent == "departed" then
        state.message = "The parts van has left the workshop."
    end
    local transport = MotorcycleTransport.ensure(state)
    if transport.state == "absent" then
        for _, job in ipairs(state.jobs.active or {}) do
            if job.transportRequired and (job.stage == "awaiting_dropoff"
                or job.stage == "pickup_transport") then
                MotorcycleTransport.schedule(state, job,
                    job.stage == "awaiting_dropoff" and "inbound" or "outbound",
                    Config.motorcycleTransport)
                break
            end
        end
    end
    local transportEvent = MotorcycleTransport.update(state, dt, Config.motorcycleTransport)
    if transportEvent == "parked" then
        state.message = transport.mode == "inbound"
            and "The motorcycle flatbed is ready to unload."
            or "The return flatbed is ready to load the finished motorcycle."
    end
    local ownerPickupCompleted = JobService.updateOwnerPickups(state, dt,
        Config.motorcycleTransport.ownerPickupDelay)
    local player = World.player
    player.animationClock = player.animationClock + math.max(0, dt or 0)
    local length = math.sqrt(directionX * directionX + directionY * directionY)
    player.moving = length > 0
    if length > 0 then
        local normalizedX, normalizedY = directionX / length, directionY / length
        local nextX = player.x + normalizedX * player.speed * dt
        local nextY = player.y + normalizedY * player.speed * dt
        if Navigation.canMoveFrom(assets, player.x, player.y, nextX, nextY,
            movementObstacles(state))
        then
            player.x, player.y = nextX, nextY
        end
        if directionX ~= 0 then player.facing = directionX < 0 and -1 or 1 end
    end

    local event = World.customer:update(dt, player)
    if event == "arrived" then
        state.message = "A rider is waiting in the lounge with a motorcycle problem."
    elseif event == "timed_out" then
        state.pendingOffer = nil
        state.message = "The rider left after waiting too long."
    elseif event == "exited" then
        World.customer:reset()
    end
    World.selectedInteraction = Interaction.nearest(player, targets(state))
    state.player = World.snapshot()
    return event, ownerPickupCompleted == true
end

function World.interact(state)
    local selected = World.selectedInteraction
    if not selected then
        state.message = "Move closer to something you can use."
        return false
    end
    if selected.kind == "computer" then
        state.screen = "computer"
        return true
    elseif selected.kind == "customer" then
        if not World.customer:beginReview() and World.customer.state ~= "reviewing" then return false end
        JobService.prepareOffer(state)
        state.screen = "job_offer"
        return true
    elseif selected.kind == "service_bay" then
        state.selectedJobId = selected.jobId
        state.screen = "service"
        return true
    elseif selected.kind == "parts_van" then
        local delivery = DeliveryVehicle.ensure(state)
        if delivery.state == "parked_closed" then
            return DeliveryVehicle.toggleDoor(state)
        elseif delivery.state == "cargo_open" then
            state.screen = "delivery_manifest"
            return true
        end
    elseif selected.kind == "motorcycle_transport" then
        local transport = MotorcycleTransport.ensure(state)
        local ok, result
        if transport.mode == "inbound" then
            ok, result = JobService.receiveDropoff(state, transport.jobId)
        else
            ok, result = JobService.completePickup(state, transport.jobId)
        end
        if not ok then state.message = tostring(result); return false end
        transport.loaded = transport.mode == "outbound"
        MotorcycleTransport.depart(state)
        return true, true
    end
    return false
end

function World.resolveCustomer(decision)
    return World.customer:resolve(decision)
end

function World.cancelCustomerReview()
    return World.customer:cancelReview()
end

function World.prompt()
    return World.selectedInteraction and World.selectedInteraction.prompt or nil
end

function World.currentJob(state) return currentJob(state) end

function World.customerSnapshot() return World.customer:snapshot() end

function World.closePartsVan(state)
    if #Procurement.manifest(state) > 0 then return false end
    return DeliveryVehicle.toggleDoor(state)
end

function World.draw(assets, characterAssets, state)
    return WorldRenderer.draw(World, assets, characterAssets, state)
end

return World
