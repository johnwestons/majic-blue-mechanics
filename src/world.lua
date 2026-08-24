local Config = require("src.config")
local Customer = require("src.customer")
local Interaction = require("src.interaction")
local JobService = require("src.job_service")
local Jobs = require("src.jobs")
local Navigation = require("src.navigation")

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

function World.load(playerPayload)
    World.player.x = playerPayload and playerPayload.x or Config.player.spawnX
    World.player.y = playerPayload and playerPayload.y or Config.player.spawnY
    World.player.facing = playerPayload and playerPayload.facing or 1
    World.player.moving = false
    World.player.animationClock = 0
    World.selectedInteraction = nil
    World.customer:reset(Config.customer.arrivalDelay)
end

function World.snapshot()
    return { x = World.player.x, y = World.player.y, facing = World.player.facing }
end

function World.update(dt, directionX, directionY, assets, state)
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
        World.customer:reset(Config.customer.betweenCustomersDelay)
    end
    World.selectedInteraction = Interaction.nearest(player, targets(state))
    state.player = World.snapshot()
    return event
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

local function drawBackground(assets)
    local background = assets.get("workshop")
    if background then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(background, 0, 0, 0,
            Config.baseWidth / background:getWidth(),
            Config.baseHeight / background:getHeight())
    else
        love.graphics.setColor(0.22, 0.24, 0.23)
        love.graphics.rectangle("fill", 0, 0, Config.baseWidth, Config.baseHeight)
    end
end

local function drawServiceLift(job)
    local x, y = Config.serviceBay.bikeX, Config.serviceBay.bikeY
    if job then
        love.graphics.setColor(0.05, 0.07, 0.08, 0.92)
        love.graphics.rectangle("fill", x - 62, y + 42, 124, 24, 3, 3)
        love.graphics.setColor(0.91, 0.83, 0.57)
        love.graphics.printf(job.id .. "  " .. Jobs.stageLabel(job), x - 58, y + 48, 116, "center")
    end
end

local function drawMotorcycle(assets, job)
    local image = assets.get("motorcycleSide")
    if not image or not job then return end
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(image, Config.serviceBay.bikeX, Config.serviceBay.bikeY + 8, 0,
        Config.serviceBay.bikeScale, Config.serviceBay.bikeScale,
        image:getWidth() / 2, image:getHeight() * 0.80)
end

local function drawPlayer(characterAssets)
    local player = World.player
    local action = player.moving and "walk" or "idle"
    if not characterAssets.draw(Config.player.character, action, player.x, player.y,
        Config.player.maxWidth, Config.player.maxHeight, player.facing,
        player.animationClock, action == "walk" and 5.2 or 0.7)
    then
        love.graphics.setColor(0.46, 0.38, 0.31)
        love.graphics.rectangle("fill", player.x - 12, player.y - 48, 24, 48)
    end
end

function World.draw(assets, characterAssets, state)
    drawBackground(assets)
    local job = currentJob(state)
    drawServiceLift(job)

    local activeCharacters = { [Config.player.character] = true }
    if World.customer.visible then activeCharacters[World.customer.character] = true end
    characterAssets.retainCharacters(activeCharacters)

    local actors = {
        { y = Config.serviceBay.bikeY, draw = function() drawMotorcycle(assets, job) end },
        { y = World.player.y, draw = function() drawPlayer(characterAssets) end },
    }
    if World.customer.visible then
        actors[#actors + 1] = { y = World.customer.y,
            draw = function() World.customer:draw(characterAssets) end }
    end
    table.sort(actors, function(a, b) return a.y < b.y end)
    for _, actor in ipairs(actors) do actor.draw() end
end

return World
