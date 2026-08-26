local AssetErrorScreen = require("src.screens.asset_error_screen")
local Assets = require("src.assets")
local CharacterAssets = require("src.character_assets")
local ComputerScreen = require("src.screens.computer_screen")
local Controller = require("src.controller")
local DeliveryManifestScreen = require("src.screens.delivery_manifest_screen")
local DeliveryVehicle = require("src.delivery_vehicle")
local Config = require("src.config")
local Hud = require("src.screens.hud")
local Input = require("src.input")
local JobOfferScreen = require("src.screens.job_offer_screen")
local JobService = require("src.job_service")
local Jobs = require("src.jobs")
local Navigation = require("src.navigation")
local MotorcycleTransport = require("src.motorcycle_transport")
local Procurement = require("src.procurement")
local Save = require("src.save")
local SaveSchema = require("src.save_schema")
local ServiceScreen = require("src.screens.service_screen")
local RepairMinigameScreen = require("src.screens.repair_minigame_screen")
local RoadTestScreen = require("src.screens.road_test_screen")
local Smoke = require("src.smoke")
local State = require("src.state")
local TitleScreen = require("src.screens.title_screen")
local Viewport = require("src.viewport")
local World = require("src.world")

local App = {}
local state = State.new()
local controller = nil

local function saveCurrent()
    if not state.activeSlot then return false end
    local ok, message = Save.save(state.activeSlot, state, World.snapshot(), World.customerSnapshot())
    if not ok then state.message = "Save failed: " .. tostring(message) end
    return ok
end

local function startGame(payload, mode)
    State.applySave(state, payload)
    World.load(payload.player, payload.customer)
    if mode == "new" then saveCurrent() end
    if payload.recovered then
        state.message = "Recovered this shop from its last valid backup."
    end
end

local function returnToTitle()
    saveCurrent()
    state.screen = "title"
    TitleScreen.enter(startGame)
end

local inputContext = {
    state = state,
    title = TitleScreen,
    world = World,
    jobService = JobService,
    jobOfferScreen = JobOfferScreen,
    computerScreen = ComputerScreen,
    deliveryManifestScreen = DeliveryManifestScreen,
    serviceScreen = ServiceScreen,
    repairMinigameScreen = RepairMinigameScreen,
    roadTestScreen = RoadTestScreen,
    saveCurrent = saveCurrent,
    returnToTitle = returnToTitle,
}

local function addErrors(target, healthy, message)
    if healthy then return end
    for line in tostring(message):gmatch("[^\n]+") do target[#target + 1] = line end
end

function App.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    if Smoke.requested() then love.filesystem.setIdentity("majic-blue-mechanics-smoke") end
    Assets.load()
    CharacterAssets.load()
    controller = Controller.new({
        pressKey = function(key) return Input.keypressed(key, inputContext) end,
        pressPointer = function(x, y, button)
            return Input.mousepressed(x, y, button, inputContext)
        end,
        screenInfo = function() return state.screen, TitleScreen.confirm end,
        worldMenuAction = returnToTitle,
    })
    state.assetErrors = {}
    addErrors(state.assetErrors, Assets.assertHealthy())
    addErrors(state.assetErrors, CharacterAssets.assertHealthy())

    if #state.assetErrors == 0 then
        World.load()
        TitleScreen.enter(startGame)
    else
        state.screen = "asset_error"
        state.message = string.format("Startup stopped: %d required asset error(s).", #state.assetErrors)
    end

    if Smoke.requested() then
        if #state.assetErrors == 0 then startGame(Save.newGame(1), "smoke") end
        Smoke.start({
            assets = Assets,
            characterAssets = CharacterAssets,
            config = Config,
            computerScreen = ComputerScreen,
            Controller = Controller,
            deliveryManifestScreen = DeliveryManifestScreen,
            deliveryVehicle = DeliveryVehicle,
            jobs = Jobs,
            jobService = JobService,
            input = Input,
            repairMinigameScreen = RepairMinigameScreen,
            roadTestScreen = RoadTestScreen,
            serviceScreen = ServiceScreen,
            navigation = Navigation,
            motorcycleTransport = MotorcycleTransport,
            procurement = Procurement,
            save = Save,
            saveSchema = SaveSchema,
            state = state,
            State = State,
            world = World,
        })
    end
end

function App.update(dt)
    if controller then controller:update(dt) end
    if state.screen == "world" then
        local directionX, directionY = Input.movement()
        local _, saveNeeded = World.update(dt, directionX, directionY, Assets, state)
        if saveNeeded then saveCurrent() end
    elseif state.screen == "road_test" then
        local directionX, throttle, brake, sprint = Input.roadTestMovement()
        local action = RoadTestScreen.update(state, dt, directionX, throttle, brake, sprint)
        if action then Input.completeRoadTest(action, inputContext) end
    elseif state.screen == "repair_minigame" then
        RepairMinigameScreen.update(state, dt)
    end
end

function App.draw()
    love.graphics.clear(0.025, 0.035, 0.04)
    Viewport.beginDraw(Config.baseWidth, Config.baseHeight)
    local mouseX, mouseY = love.mouse.getPosition()
    mouseX, mouseY = Viewport.toGame(mouseX, mouseY, Config.baseWidth, Config.baseHeight)
    if controller and controller:isActive() and state.screen ~= "world"
        and state.screen ~= "road_test" then
        mouseX, mouseY = controller:pointer()
    end
    if state.screen == "asset_error" then
        CharacterAssets.retainCharacters({})
        AssetErrorScreen.draw(state.assetErrors)
    elseif state.screen == "title" then
        CharacterAssets.retainCharacters({})
        TitleScreen.draw(Assets, mouseX, mouseY)
    else
        World.draw(Assets, CharacterAssets, state)
        if state.screen == "world" then
            Hud.draw(state, World.prompt())
        elseif state.screen == "job_offer" then
            JobOfferScreen.draw(state, Assets, mouseX, mouseY)
        elseif state.screen == "computer" then
            ComputerScreen.draw(state, mouseX, mouseY)
        elseif state.screen == "delivery_manifest" then
            DeliveryManifestScreen.draw(state, mouseX, mouseY)
        elseif state.screen == "service" then
            ServiceScreen.draw(state, Assets, mouseX, mouseY)
        elseif state.screen == "repair_minigame" then
            RepairMinigameScreen.draw(state, Assets, mouseX, mouseY)
        elseif state.screen == "road_test" then
            RoadTestScreen.draw(state, Assets, mouseX, mouseY)
        end
    end
    if controller then controller:draw() end
    Viewport.endDraw()
    Smoke.drawn()
end

function App.keypressed(key)
    if state.screen == "asset_error" then
        if key == "escape" or key == "q" then love.event.quit() end
        return
    end
    Input.keypressed(key, inputContext)
end

function App.mousepressed(x, y, button)
    if state.screen == "asset_error" then return end
    local gameX, gameY = Viewport.toGame(x, y, Config.baseWidth, Config.baseHeight)
    Input.mousepressed(gameX, gameY, button, inputContext)
end

function App.mousemoved(x, y)
    local gameX, gameY = Viewport.toGame(x, y, Config.baseWidth, Config.baseHeight)
    Input.mousemoved(gameX, gameY, inputContext)
end

function App.mousereleased(x, y, button)
    local gameX, gameY = Viewport.toGame(x, y, Config.baseWidth, Config.baseHeight)
    Input.mousereleased(gameX, gameY, button, inputContext)
end

function App.quit() saveCurrent() end

function App.gamepadpressed(joystick, button)
    return controller and controller:gamepadpressed(joystick, button)
end

function App.gamepadreleased(joystick, button)
    return controller and controller:gamepadreleased(joystick, button)
end

return App
