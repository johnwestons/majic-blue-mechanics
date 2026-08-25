local AssetErrorScreen = require("src.screens.asset_error_screen")
local Assets = require("src.assets")
local CharacterAssets = require("src.character_assets")
local ComputerScreen = require("src.screens.computer_screen")
local Config = require("src.config")
local Hud = require("src.screens.hud")
local Input = require("src.input")
local JobOfferScreen = require("src.screens.job_offer_screen")
local JobService = require("src.job_service")
local Jobs = require("src.jobs")
local Navigation = require("src.navigation")
local Save = require("src.save")
local ServiceScreen = require("src.screens.service_screen")
local RepairMinigameScreen = require("src.screens.repair_minigame_screen")
local Smoke = require("src.smoke")
local State = require("src.state")
local TitleScreen = require("src.screens.title_screen")
local Viewport = require("src.viewport")
local World = require("src.world")

local App = {}
local state = State.new()

local function saveCurrent()
    if not state.activeSlot then return false end
    local ok, message = Save.save(state.activeSlot, state, World.snapshot())
    if not ok then state.message = "Save failed: " .. tostring(message) end
    return ok
end

local function startGame(payload, mode)
    State.applySave(state, payload)
    World.load(payload.player)
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
    serviceScreen = ServiceScreen,
    repairMinigameScreen = RepairMinigameScreen,
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
            jobs = Jobs,
            jobService = JobService,
            repairMinigameScreen = RepairMinigameScreen,
            navigation = Navigation,
            save = Save,
            state = state,
            State = State,
            world = World,
        })
    end
end

function App.update(dt)
    if state.screen == "world" then
        local directionX, directionY = Input.movement()
        World.update(dt, directionX, directionY, Assets, state)
    end
end

function App.draw()
    love.graphics.clear(0.025, 0.035, 0.04)
    Viewport.beginDraw(Config.baseWidth, Config.baseHeight)
    local mouseX, mouseY = love.mouse.getPosition()
    mouseX, mouseY = Viewport.toGame(mouseX, mouseY, Config.baseWidth, Config.baseHeight)
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
        elseif state.screen == "service" then
            ServiceScreen.draw(state, Assets, mouseX, mouseY)
        elseif state.screen == "repair_minigame" then
            RepairMinigameScreen.draw(state, Assets, mouseX, mouseY)
        end
    end
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

return App
