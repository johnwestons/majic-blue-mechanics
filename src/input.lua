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

local function serviceAction(action, context)
    local state, service = context.state, context.jobService
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
    end
    return false
end

return Input
