local Input = {}

local function closeCurrent(context)
    local state = context.state
    if state.screen == "job_offer" then
        context.world.cancelCustomerReview()
        context.jobService.cancelReview(state)
    elseif state.screen == "repair_minigame" then
        context.repairMinigameScreen.cancel(state)
    elseif state.screen == "road_test" then
        context.roadTestScreen.cancel(state)
    elseif state.screen == "computer" or state.screen == "service"
        or state.screen == "delivery_manifest" then
        state.screen = "world"
    else
        return false
    end
    return true
end

function Input.closeCurrent(context) return closeCurrent(context) end

function Input.movement()
    local x, y = 0, 0
    if love.keyboard.isDown("a", "left") then x = x - 1 end
    if love.keyboard.isDown("d", "right") then x = x + 1 end
    if love.keyboard.isDown("w", "up") then y = y - 1 end
    if love.keyboard.isDown("s", "down") then y = y + 1 end
    if love.joystick and love.joystick.getJoysticks then
        for _, joystick in ipairs(love.joystick.getJoysticks()) do
            if joystick:isGamepad() then
                local axisX = joystick:getGamepadAxis("leftx") or 0
                local axisY = joystick:getGamepadAxis("lefty") or 0
                if math.abs(axisX) < 0.20 then axisX = 0 end
                if math.abs(axisY) < 0.20 then axisY = 0 end
                if joystick:isGamepadDown("dpleft") then axisX = -1 end
                if joystick:isGamepadDown("dpright") then axisX = 1 end
                if joystick:isGamepadDown("dpup") then axisY = -1 end
                if joystick:isGamepadDown("dpdown") then axisY = 1 end
                if axisX ~= 0 or axisY ~= 0 then x, y = axisX, axisY end
                break
            end
        end
    end
    return x, y
end

function Input.roadTestMovement()
    local directionX = 0
    if love.keyboard.isDown("a", "left") then directionX = directionX - 1 end
    if love.keyboard.isDown("d", "right") then directionX = directionX + 1 end
    local throttle = love.keyboard.isDown("w", "up")
    local brake = love.keyboard.isDown("s", "down")
    local sprint = love.keyboard.isDown("lshift", "rshift")
    if love.joystick and love.joystick.getJoysticks then
        for _, joystick in ipairs(love.joystick.getJoysticks()) do
            if joystick:isGamepad() then
                local axis = joystick:getGamepadAxis("leftx") or 0
                if math.abs(axis) < 0.20 then axis = 0 end
                if joystick:isGamepadDown("dpleft") then axis = -1 end
                if joystick:isGamepadDown("dpright") then axis = 1 end
                if axis ~= 0 then directionX = axis end
                throttle = throttle or (joystick:getGamepadAxis("triggerright") or 0) > 0.18
                    or joystick:isGamepadDown("a")
                brake = brake or (joystick:getGamepadAxis("triggerleft") or 0) > 0.18
                    or joystick:isGamepadDown("x")
                sprint = sprint or joystick:isGamepadDown("rightshoulder")
                break
            end
        end
    end
    return directionX, throttle, brake, sprint
end

local function saveAfter(context, ok, message)
    if ok then context.saveCurrent() elseif message then context.state.message = tostring(message) end
    return ok
end

local function serviceAction(action, context, fromMiniGame)
    local state, service = context.state, context.jobService
    if not fromMiniGame then
        if action == "road_test" then
            return context.roadTestScreen.begin(state)
        end
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
    if action == "road_test" then
        context.roadTestScreen.finish(state)
    else
        context.repairMinigameScreen.finish(state)
    end
    local ok = serviceAction(action, context, true)
    if ok and action ~= "road_test" then state.screen = "service" end
    if not ok then state.screen = "service" end
    return ok
end

function Input.completeRoadTest(action, context)
    return completeMiniGame(action, context)
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
        if key == "e" or key == "return" then
            local handled, saveNeeded = context.world.interact(state)
            if handled and state.screen == "computer" and context.computerScreen.enter then
                context.computerScreen.enter(state)
            end
            if saveNeeded then context.saveCurrent() end
            return handled
        end
        if key == "escape" then context.returnToTitle() return true end
    elseif state.screen == "job_offer" then
        if key == "a" then return accept(context) end
        if key == "d" then return decline(context) end
        if key == "escape" then return closeCurrent(context) end
    elseif state.screen == "computer" then
        if key == "escape" or key == "e" then return closeCurrent(context) end
        return context.computerScreen.keypressed(state, key) ~= nil
    elseif state.screen == "delivery_manifest" then
        if key == "escape" or key == "e" then return closeCurrent(context) end
    elseif state.screen == "service" then
        if key == "escape" or key == "e" then return closeCurrent(context) end
        if key == "d" then return serviceAction("diagnose", context) end
        if key == "r" then return serviceAction("repair", context) end
        if key == "t" then return serviceAction("road_test", context) end
    elseif state.screen == "repair_minigame" then
        if key == "escape" or key == "e" then return closeCurrent(context) end
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
        if key == "left" or key == "a" then
            context.repairMinigameScreen.pressButton(state, "left")
            return true
        end
        if key == "right" or key == "d" then
            context.repairMinigameScreen.pressButton(state, "right")
            return true
        end
        local toolNumber = key:match("^kp([1-5])$") or key:match("^([1-5])$")
        if toolNumber then
            context.repairMinigameScreen.pressButton(state, "tool" .. toolNumber)
            return true
        end
    elseif state.screen == "road_test" then
        local task = state.roadTest
        if key == "escape" or key == "e" then return closeCurrent(context) end
        if task and task.status == "review" then
            if key == "return" or key == "space" or key == "a" then
                return completeMiniGame("road_test", context)
            end
            if key == "r" then
                return context.roadTestScreen.retry(state)
            end
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
        if action == "close" then return closeCurrent(context) end
    elseif state.screen == "computer" then
        local result = context.computerScreen.mousepressed(state, x, y, button)
        if result and result.action == "close" then return closeCurrent(context) end
        if result and result.saveNeeded then context.saveCurrent() end
        if result and result.action == "blocked" and result.result then
            state.message = tostring(result.result)
        end
        return result ~= nil
    elseif state.screen == "delivery_manifest" then
        local result = context.deliveryManifestScreen.mousepressed(state, x, y, button)
        if not result then return false end
        if result.action == "back" then state.screen = "world" return true end
        if result.action == "close_van" then
            if context.world.closePartsVan(state) then state.screen = "world"; context.saveCurrent(); return true end
            return false
        end
        if result.saveNeeded then context.saveCurrent() end
        if result.action == "blocked" and result.result then state.message = tostring(result.result) end
        return true
    elseif state.screen == "service" then
        local action = context.serviceScreen.hit(state, x, y)
        if action == "close" then return closeCurrent(context) end
        if action then return serviceAction(action, context) end
    elseif state.screen == "repair_minigame" then
        local repairAction = context.repairMinigameScreen.hit(state, x, y)
        if repairAction == "cancel" then return closeCurrent(context) end
        if repairAction == "finish" then return completeMiniGame("repair", context) end
        local result = context.repairMinigameScreen.mousepressed(state, x, y)
        if type(result) == "string" then return completeMiniGame(result, context) end
        return result
    elseif state.screen == "road_test" then
        local action = context.roadTestScreen.hit(x, y)
        if action == "cancel" then return closeCurrent(context) end
        if action == "approve" then return completeMiniGame("road_test", context) end
        if action == "redo" then return context.roadTestScreen.retry(state) end
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
    if action then return completeMiniGame(action, context) end
    return true
end

return Input
