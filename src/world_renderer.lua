local Config = require("src.config")
local Jobs = require("src.jobs")
local DeliveryVehicle = require("src.delivery_vehicle")
local MotorcycleTransport = require("src.motorcycle_transport")

local Renderer = {}

local function drawBackground(assets)
    local background = assets.get("workshop")
    if background then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(background, 0, 0, 0,
            Config.baseWidth / background:getWidth(), Config.baseHeight / background:getHeight())
    else
        love.graphics.setColor(0.22, 0.24, 0.23)
        love.graphics.rectangle("fill", 0, 0, Config.baseWidth, Config.baseHeight)
    end
end

local function drawBayDoor(world, assets)
    local image = assets.get("loadingBayDoor")
    local quad = assets.getQuad("loadingBayDoor" .. world.bayDoor:frame())
    local workshop = assets.get("workshop")
    if not image or not quad or not workshop then return end
    local scaleX = Config.baseWidth / workshop:getWidth()
    local scaleY = Config.baseHeight / workshop:getHeight()
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(image, quad,
        Config.loadingBay.sourceX * scaleX,
        Config.loadingBay.sourceY * scaleY, 0, scaleX, scaleY)
end

local function drawServiceLift(job)
    local x, y = Config.serviceBay.bikeX, Config.serviceBay.bikeY
    if not job then return end
    love.graphics.setColor(0.05, 0.07, 0.08, 0.92)
    love.graphics.rectangle("fill", x - 62, y + 42, 124, 24, 3, 3)
    love.graphics.setColor(0.91, 0.83, 0.57)
    love.graphics.printf(job.id .. "  " .. Jobs.stageLabel(job), x - 58, y + 48, 116, "center")
end

local function drawMotorcycle(assets, job)
    if not job then return end
    local bikeKey = Jobs.ensureBikeSprite(job)
    local image = bikeKey and assets.get("motorcycleMounted_" .. bikeKey)
    image = image or assets.get("motorcycleSide")
    if not image then return end
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(image, Config.serviceBay.bikeX, Config.serviceBay.bikeY + 8, 0,
        Config.serviceBay.bikeScale, Config.serviceBay.bikeScale,
        image:getWidth() / 2, image:getHeight() * 0.80)
end

local function drawPlayer(world, characterAssets)
    local player = world.player
    local action = player.moving and "walk" or "idle"
    if not characterAssets.draw(Config.player.character, action, player.x, player.y,
        Config.player.maxWidth, Config.player.maxHeight, player.facing,
        player.animationClock, action == "walk" and 5.2 or 0.7)
    then
        love.graphics.setColor(0.46, 0.38, 0.31)
        love.graphics.rectangle("fill", player.x - 12, player.y - 48, 24, 48)
    end
end

local function drawPartsTruck(state, assets)
    if not DeliveryVehicle.visible(state) then return end
    local transform = DeliveryVehicle.transform(state, Config.partsDelivery)
    local truck = assets.get("deliveryTruck")
    local cargo = assets.get("truckCargoDoor")
    local cargoQuad = assets.getQuad("truckCargoDoor"
        .. DeliveryVehicle.cargoFrame(state, Config.partsDelivery))
    if not truck or not cargo or not cargoQuad then return end
    local origin = Config.partsDelivery.frameSize
    local aperture = {}
    for _, point in ipairs(Config.partsDelivery.aperture) do
        aperture[#aperture + 1] = point.x
        aperture[#aperture + 1] = point.y
    end
    love.graphics.stencil(function()
        love.graphics.polygon("fill", unpack(aperture))
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(truck, transform.x, transform.y, 0,
        transform.scale, transform.scale, origin / 2, origin * 0.84)
    love.graphics.draw(cargo, cargoQuad, transform.x, transform.y, 0,
        transform.scale, transform.scale, origin / 2, origin * 0.84)
    love.graphics.setStencilTest()
end

local function drawMotorcycleTransport(state, assets)
    if not MotorcycleTransport.visible(state) then return end
    local transport = MotorcycleTransport.ensure(state)
    local transform = MotorcycleTransport.transform(state, Config.motorcycleTransport)
    love.graphics.push()
    love.graphics.translate(transform.x, transform.y)
    love.graphics.scale(transform.scale, transform.scale)
    love.graphics.setColor(0.05, 0.08, 0.09, 1)
    love.graphics.rectangle("fill", -128, -18, 205, 34, 5, 5)
    love.graphics.setColor(0.16, 0.42, 0.54, 1)
    love.graphics.rectangle("fill", 48, -48, 78, 62, 8, 8)
    love.graphics.setColor(0.58, 0.90, 0.92, 1)
    love.graphics.polygon("fill", 68, -40, 112, -40, 112, -18, 78, -18)
    love.graphics.setColor(0.90, 0.84, 0.57, 1)
    love.graphics.printf("MBM\nRECOVERY", 53, -12, 68, "center")
    love.graphics.setColor(0.04, 0.04, 0.04, 1)
    for _, x in ipairs({ -82, 80 }) do love.graphics.circle("fill", x, 17, 16) end
    love.graphics.setColor(0.62, 0.65, 0.62, 1)
    for _, x in ipairs({ -82, 80 }) do love.graphics.circle("fill", x, 17, 6) end
    if transport.loaded and transport.bikeKey then
        local bike = assets.get("motorcycleMounted_" .. transport.bikeKey)
        if bike then
            love.graphics.setColor(1, 1, 1)
            local scale = math.min(105 / bike:getWidth(), 72 / bike:getHeight())
            love.graphics.draw(bike, -30, -13, 0, scale, scale,
                bike:getWidth() / 2, bike:getHeight() * 0.82)
        end
    end
    love.graphics.pop()
end

function Renderer.draw(world, assets, characterAssets, state)
    drawBackground(assets)
    drawBayDoor(world, assets)
    drawPartsTruck(state, assets)
    local job = world.currentJob(state)
    drawServiceLift(job)
    local activeCharacters = { [Config.player.character] = true }
    if world.customer.visible then activeCharacters[world.customer.character] = true end
    characterAssets.retainCharacters(activeCharacters)
    local actors = {
        { y = Config.serviceBay.bikeY, draw = function() drawMotorcycle(assets, job) end },
        { y = MotorcycleTransport.transform(state, Config.motorcycleTransport).y,
            draw = function() drawMotorcycleTransport(state, assets) end },
        { y = world.player.y, draw = function() drawPlayer(world, characterAssets) end },
    }
    if world.customer.visible then
        actors[#actors + 1] = { y = world.customer.y,
            draw = function() world.customer:draw(characterAssets) end }
    end
    table.sort(actors, function(a, b) return a.y < b.y end)
    for _, actor in ipairs(actors) do actor.draw() end
end

return Renderer
