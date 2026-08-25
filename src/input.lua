local Input = {}

function Input.movement()
    local x, y = 0, 0
    if love.keyboard.isDown("a", "left") then x = x - 1 end
    if love.keyboard.isDown("d", "right") then x = x + 1 end
    if love.keyboard.isDown("w", "up") then y = y - 1 end
    if love.keyboard.isDown("s", "down") then y = y + 1 end
    return x, y
end

local function saveAfter(context, ok, message)
    if ok then context.saveCurrent() elseif message then context.state.message = tostring(message) end
    return ok
end

local function serviceAction(action, context, fromMiniGame)
    local state, service = context.state, context.jobService
    if not fromMiniGame then
        return context.repairMinigameScreen.begin(state, action)
    end
    local ok, message
    if action == "diagnose" then
        ok, message = service.diagnose(state, state.selectedJobId)
    elseif action == "repair" then
        ok, message = service.repair(state, state.selectedJobId)
    elseif action == "road_test" then
        ok, message = service.roadTest(state, state.selectedJobId)
        if ok then state.screen = "world" end
    end
    return saveAfter(context, ok, message)
end

local function completeMiniGame(action, context)
    if not action then return false end
    local state = context.state
    context.repairMinigameScreen.finish(state)
    local ok = serviceAction(action, context, true)
    if ok and action ~= "road_test" then state.screen = "service" end
    if not ok then state.screen = "service" end
    return ok
end

local function accept(context)
    local ok, message = context.jobService.acceptOffer(context.state)
    if ok then context.world.resolveCustomer("accepted") end
    return saveAfter(context, ok, message)
end

local function decline(context)
    local ok, message = context.jobService.declineOffer(context.state)
    if ok then context.world.resolveCustomer("declined") end
    return saveAfter(context, ok, message)
end

function Input.keypressed(key, context)
    local state = context.state
    if state.screen == "title" then
        return context.title.keypressed(key)
    elseif state.screen == "world" then
        if key == "e" or key == "return" then return context.world.interact(state) end
        if key == "escape" then context.returnToTitle() return true end
    elseif state.screen == "job_offer" then
        if key == "a" then return accept(context) end
        if key == "d" then return decline(context) end
        if key == "escape" then
            context.world.cancelCustomerReview()
            context.jobService.cancelReview(state)
            return true
        end
    elseif state.screen == "computer" then
        if key == "escape" or key == "e" then state.screen = "world" return true end
    elseif state.screen == "service" then
        if key == "escape" or key == "e" then state.screen = "world" return true end
        if key == "d" then return serviceAction("diagnose", context) end
        if key == "r" then return serviceAction("repair", context) end
        if key == "t" then return serviceAction("road_test", context) end
    elseif state.screen == "repair_minigame" then
        if key == "escape" or key == "e" then
            context.repairMinigameScreen.cancel(state)
            return true
        end
        if key == "return" or key == "space" then
            return completeMiniGame(context.repairMinigameScreen.pressButton(state, "ok"), context)
        end
        if key == "up" or key == "w" then
            context.repairMinigameScreen.pressButton(state, "up")
            return true
        end
        if key == "down" or key == "s" then
            context.repairMinigameScreen.pressButton(state, "down")
            return true
        end
    end
    return false
end

function Input.mousepressed(x, y, button, context)
    if button ~= 1 then return false end
    local state = context.state
    if state.screen == "title" then
        return context.title.mousepressed(x, y, button)
    elseif state.screen == "job_offer" then
        local action = context.jobOfferScreen.hit(x, y)
        if action == "accept" then return accept(context) end
        if action == "decline" then return decline(context) end
    elseif state.screen == "computer" then
        if context.computerScreen.hit(x, y) == "close" then state.screen = "world" return true end
    elseif state.screen == "service" then
        local action = context.serviceScreen.hit(state, x, y)
        if action == "close" then state.screen = "world" return true end
        if action then return serviceAction(action, context) end
    elseif state.screen == "repair_minigame" then
        if context.repairMinigameScreen.hit(x, y) == "cancel" then
            context.repairMinigameScreen.cancel(state)
            return true
        end
        local result = context.repairMinigameScreen.mousepressed(state, x, y)
        if type(result) == "string" then return completeMiniGame(result, context) end
        return result
    end
    return false
end

function Input.mousemoved(x, y, context)
    if context.state.screen == "repair_minigame" then
        return context.repairMinigameScreen.mousemoved(context.state, x, y)
    end
    return false
end

function Input.mousereleased(x, y, button, context)
    if button ~= 1 or context.state.screen ~= "repair_minigame" then return false end
    local action = context.repairMinigameScreen.mousereleased(context.state, x, y)
    return completeMiniGame(action, context)
end

return Input
