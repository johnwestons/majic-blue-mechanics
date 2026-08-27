local AssetErrorScreen = require("src.screens.asset_error_screen")
local Assets = require("src.assets")
local Camera = require("src.camera")
local BusinessCalendar = require("src.business_calendar")
local ClientEmail = require("src.client_email")
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
local MobileControls = require("src.mobile_controls")
local Procurement = require("src.procurement")
local Save = require("src.save")
local SaveSchema = require("src.save_schema")
local ServiceScreen = require("src.screens.service_screen")
local RepairMinigameScreen = require("src.screens.repair_minigame_screen")
local RoadTestScreen = require("src.screens.road_test_screen")
local Smoke = require("src.smoke")
local SpriteMotionLab = require("src.screens.sprite_motion_lab")
local State = require("src.state")
local TitleScreen = require("src.screens.title_screen")
local Ui = require("src.screens.ui")
local Viewport = require("src.viewport")
local ViewCameras = require("src.view_cameras")
local World = require("src.world")

local App = {}
local state = State.new()
local controller = nil
local mobileControls = nil
local viewCameras = nil
local gestureCamera = nil
local cameraMousePan = nil
local activeCameraViewKey = nil
local spriteLabActive = false

local function saveCurrent()
    if not state.activeSlot then return false end
    local ok, message = Save.save(state.activeSlot, state, World.snapshot(), World.customerSnapshot())
    if not ok then state.message = "Save failed: " .. tostring(message) end
    return ok
end

local function startGame(payload, mode)
    State.applySave(state, payload)
    World.load(payload.player, payload.customer, payload.delivery,
        payload.motorcycleTransport)
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

local function currentViewKey()
    if state.screen == "asset_error" then return "asset_error" end
    if spriteLabActive then return "sprite_lab" end
    if state.screen == "road_test" and state.roadTest
        and state.roadTest.status == "review"
    then
        return "road_test_review"
    end
    return state.screen or "title"
end

local function currentCamera()
    if not viewCameras then return nil end
    local viewKey = currentViewKey()
    if activeCameraViewKey and activeCameraViewKey ~= viewKey then
        gestureCamera = nil
        cameraMousePan = nil
    end
    activeCameraViewKey = viewKey
    return viewCameras:select(viewKey)
end

local function viewportToScene(x, y)
    local camera = currentCamera()
    if camera then return camera:screenToWorld(x, y) end
    return x, y
end

local function routePointerPressed(gameX, gameY, button)
    if state.screen == "asset_error" then return false end
    if button == 1 then Ui.setPointerDown(true) end
    if spriteLabActive and button == 1 then
        return SpriteMotionLab.mousepressed(gameX, gameY, CharacterAssets)
    end
    return Input.mousepressed(gameX, gameY, button, inputContext)
end

local function routePointerMoved(gameX, gameY)
    return Input.mousemoved(gameX, gameY, inputContext)
end

local function routePointerReleased(gameX, gameY, button)
    local result = Input.mousereleased(gameX, gameY, button, inputContext)
    if button == 1 then Ui.setPointerDown(false) end
    return result
end

local function dispatchViewportPressed(x, y, button)
    local gameX, gameY = viewportToScene(x, y)
    return routePointerPressed(gameX, gameY, button)
end

local function dispatchViewportMoved(x, y)
    return routePointerMoved(viewportToScene(x, y))
end

local function dispatchViewportReleased(x, y, button)
    local gameX, gameY = viewportToScene(x, y)
    return routePointerReleased(gameX, gameY, button)
end

local function dispatchMousePressed(x, y, button)
    local gameX, gameY = Viewport.toGame(x, y, Config.baseWidth, Config.baseHeight)
    return dispatchViewportPressed(gameX, gameY, button)
end

local function dispatchMouseMoved(x, y)
    local gameX, gameY = Viewport.toGame(x, y, Config.baseWidth, Config.baseHeight)
    return dispatchViewportMoved(gameX, gameY)
end

local function dispatchMouseReleased(x, y, button)
    local gameX, gameY = Viewport.toGame(x, y, Config.baseWidth, Config.baseHeight)
    return dispatchViewportReleased(gameX, gameY, button)
end

local function mobileGameplayActive()
    if spriteLabActive then return false end
    if state.screen == "world" then return true end
    return state.screen == "road_test"
        and (not state.roadTest or state.roadTest.status ~= "review")
end

local function primaryMobileAction()
    if state.screen == "road_test" then return "w", "THROTTLE" end
    return "e", "USE"
end

local function extraMobileActions()
    if state.screen ~= "road_test" then return {} end
    return {
        { key = "s", label = "BRAKE" },
        { key = "lshift", label = "BOOST" },
    }
end

function App.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    if Smoke.requested() then love.filesystem.setIdentity("majic-blue-mechanics-smoke") end
    Assets.load()
    CharacterAssets.load()
    spriteLabActive = SpriteMotionLab.requested()
    viewCameras = ViewCameras.new({
        width = Config.baseWidth,
        height = Config.baseHeight,
        minZoom = 1,
        maxZoom = 2.25,
    })
    activeCameraViewKey = nil
    mobileControls = MobileControls.new({
        toGame = function(x, y)
            return Viewport.toGame(x, y, Config.baseWidth, Config.baseHeight)
        end,
        pressKey = function(key) return Input.keypressed(key, inputContext) end,
        releaseKey = function(key) return Input.keyreleased(key, inputContext) end,
        pressPointer = dispatchMousePressed,
        movePointer = dispatchMouseMoved,
        releasePointer = dispatchMouseReleased,
        gameplayActive = mobileGameplayActive,
        primaryAction = primaryMobileAction,
        extraActions = extraMobileActions,
        pointerDragActive = function() return state.screen == "repair_minigame" end,
        gestureActive = function() return currentCamera() ~= nil end,
        beginGesture = function(x1, y1, x2, y2)
            gestureCamera = currentCamera()
            return gestureCamera and gestureCamera:beginGesture(x1, y1, x2, y2)
        end,
        updateGesture = function(x1, y1, x2, y2)
            return gestureCamera and gestureCamera:updateGesture(x1, y1, x2, y2)
        end,
        endGesture = function()
            local camera = gestureCamera
            gestureCamera = nil
            return camera and camera:endGesture()
        end,
    })
    mobileControls:setBounds(Viewport.outerBounds(Config.baseWidth, Config.baseHeight))
    controller = Controller.new({
        pressKey = function(key)
            if spriteLabActive then
                return SpriteMotionLab.keypressed(key, CharacterAssets)
            end
            return Input.keypressed(key, inputContext)
        end,
        releaseKey = function(key) return Input.keyreleased(key, inputContext) end,
        pressPointer = function(x, y, button)
            return dispatchViewportPressed(x, y, button)
        end,
        movePointer = function(x, y)
            return dispatchViewportMoved(x, y)
        end,
        releasePointer = function(x, y, button)
            return dispatchViewportReleased(x, y, button)
        end,
        screenInfo = function()
            if spriteLabActive then return "sprite_lab" end
            return state.screen, TitleScreen.confirm
        end,
        worldMenuAction = returnToTitle,
    })
    Input.setMobileMovementProvider(function()
        if mobileControls and state.screen == "world" then
            return mobileControls:movement()
        end
        return 0, 0
    end)
    Input.setMobileRoadTestProvider(function()
        if not mobileControls or state.screen ~= "road_test" then
            return 0, false, false, false
        end
        local directionX = mobileControls:movement()
        return directionX, mobileControls:isHeld("w"), mobileControls:isHeld("s"),
            mobileControls:isHeld("lshift")
    end)
    state.assetErrors = {}
    addErrors(state.assetErrors, Assets.assertHealthy())
    addErrors(state.assetErrors, CharacterAssets.assertHealthy())

    if #state.assetErrors == 0 then
        World.load()
        TitleScreen.enter(startGame)
        if spriteLabActive then SpriteMotionLab.enter(CharacterAssets) end
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
            Camera = Camera,
            MobileControls = MobileControls,
            ViewCameras = ViewCameras,
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
            title = TitleScreen,
            world = World,
        })
    end
    print("[MAJIC BLUE MECHANICS] Startup complete")
end

function App.update(dt)
    BusinessCalendar.update(state, dt)
    ClientEmail.update(state)
    if mobileControls then mobileControls:update(dt) end
    if controller then controller:update(dt) end
    if spriteLabActive then SpriteMotionLab.update(dt, CharacterAssets); return end
    if state.screen == "world" then
        local directionX, directionY = Input.movement()
        local _, saveNeeded = World.update(dt, directionX, directionY, Assets, state)
        if saveNeeded then saveCurrent() end
    elseif state.screen == "road_test" then
        local directionX, throttle, brake, sprint = Input.roadTestMovement()
        local action = RoadTestScreen.update(state, dt, directionX, throttle, brake, sprint, Assets)
        if action then Input.completeRoadTest(action, inputContext) end
    elseif state.screen == "repair_minigame" then
        RepairMinigameScreen.update(state, dt)
    end
end

function App.draw()
    love.graphics.clear(0.025, 0.035, 0.04)
    Viewport.beginDraw(Config.baseWidth, Config.baseHeight)
    Viewport.drawBackdrop(Config.baseWidth, Config.baseHeight, Assets.get("workshop"))
    local mouseX, mouseY = love.mouse.getPosition()
    mouseX, mouseY = Viewport.toGame(mouseX, mouseY, Config.baseWidth, Config.baseHeight)
    if mobileControls and mobileControls:isEnabled() then
        local touchX, touchY = mobileControls:pointer()
        if touchX then mouseX, mouseY = touchX, touchY end
    end
    mouseX, mouseY = viewportToScene(mouseX, mouseY)
    if controller and controller:isActive() and state.screen ~= "world"
        and state.screen ~= "road_test" then
        mouseX, mouseY = controller:pointer()
        mouseX, mouseY = viewportToScene(mouseX, mouseY)
    end
    local camera = currentCamera()
    love.graphics.stencil(function()
        love.graphics.rectangle("fill", 0, 0, Config.baseWidth, Config.baseHeight)
    end, "replace", 1)
    love.graphics.setStencilTest("greater", 0)
    if camera then camera:attach() end
    if spriteLabActive and (not state.assetErrors or #state.assetErrors == 0) then
        SpriteMotionLab.draw(CharacterAssets)
    elseif state.screen == "asset_error" then
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
    if camera then camera:detach() end
    love.graphics.setStencilTest()
    if controller then controller:draw() end
    if mobileControls then mobileControls:draw() end
    Viewport.endDraw()
    Smoke.drawn()
end

function App.resize()
    if mobileControls then
        mobileControls:setBounds(Viewport.outerBounds(Config.baseWidth, Config.baseHeight))
    end
end

function App.keypressed(key)
    if key == "acback" then key = "escape" end
    if spriteLabActive then return SpriteMotionLab.keypressed(key, CharacterAssets) end
    if state.screen == "asset_error" then
        if key == "escape" or key == "q" then love.event.quit() end
        return
    end
    return Input.keypressed(key, inputContext)
end

function App.keyreleased(key)
    if key == "acback" then key = "escape" end
    return Input.keyreleased(key, inputContext)
end

function App.mousepressed(x, y, button, isTouch)
    if mobileControls and mobileControls:ignoreSyntheticMouse(isTouch) then return false end
    if button == 2 and currentCamera() then
        cameraMousePan = currentCamera()
        return true
    end
    return dispatchMousePressed(x, y, button)
end

function App.mousemoved(x, y, dx, dy, isTouch)
    if mobileControls and mobileControls:ignoreSyntheticMouse(isTouch) then return false end
    if cameraMousePan then
        local _, _, scale = Viewport.transform(Config.baseWidth, Config.baseHeight)
        cameraMousePan:panBy((dx or 0) / scale, (dy or 0) / scale)
        return true
    end
    return dispatchMouseMoved(x, y)
end

function App.mousereleased(x, y, button, isTouch)
    if mobileControls and mobileControls:ignoreSyntheticMouse(isTouch) then return false end
    if button == 2 and cameraMousePan then cameraMousePan = nil; return true end
    return dispatchMouseReleased(x, y, button)
end

function App.wheelmoved(_, y)
    local camera = currentCamera()
    if not camera or y == 0 then return false end
    local mouseX, mouseY = love.mouse.getPosition()
    mouseX, mouseY = Viewport.toGame(mouseX, mouseY,
        Config.baseWidth, Config.baseHeight)
    camera:zoomAt(math.pow(1.16, y), mouseX, mouseY)
    return true
end

function App.touchpressed(id, x, y)
    return mobileControls and mobileControls:touchpressed(id, x, y)
end

function App.touchmoved(id, x, y, dx, dy)
    return mobileControls and mobileControls:touchmoved(id, x, y, dx, dy)
end

function App.touchreleased(id, x, y)
    return mobileControls and mobileControls:touchreleased(id, x, y)
end

function App.focus(focused)
    if focused then return end
    Ui.setPointerDown(false)
    cameraMousePan = nil
    if mobileControls then mobileControls:cancelAll() end
    if controller then controller:cancelAll() end
    if not spriteLabActive then saveCurrent() end
end

function App.quit()
    if not spriteLabActive then saveCurrent() end
end

function App.gamepadpressed(joystick, button)
    return controller and controller:gamepadpressed(joystick, button)
end

function App.gamepadreleased(joystick, button)
    return controller and controller:gamepadreleased(joystick, button)
end

return App
