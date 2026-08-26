local Controller = {}
Controller.__index = Controller

local dpadKeys = { dpleft = "left", dpright = "right", dpup = "up", dpdown = "down" }

function Controller.new(options)
    local self = setmetatable({}, Controller)
    self.pressKey = assert(options.pressKey)
    self.pressPointer = assert(options.pressPointer)
    self.screenInfo = assert(options.screenInfo)
    self.worldMenuAction = assert(options.worldMenuAction)
    self.pointerX, self.pointerY = 480, 339
    self.active, self.pointerHeld = nil, false
    return self
end

function Controller:findGamepad()
    if not love.joystick or not love.joystick.getJoysticks then return nil end
    for _, joystick in ipairs(love.joystick.getJoysticks()) do
        if joystick:isGamepad() then return joystick end
    end
end

function Controller:isActive() return self.active ~= nil end
function Controller:pointer() return self.pointerX, self.pointerY end

function Controller:update(dt)
    self.active = self:findGamepad()
    if not self.active then return end
    local screen = self.screenInfo()
    if screen == "world" or screen == "road_test" or screen == "asset_error" then return end
    local x = self.active:getGamepadAxis("rightx") or 0
    local y = self.active:getGamepadAxis("righty") or 0
    if math.abs(x) < 0.18 and math.abs(y) < 0.18 then
        x = self.active:getGamepadAxis("leftx") or 0
        y = self.active:getGamepadAxis("lefty") or 0
    end
    if math.abs(x) < 0.18 then x = 0 end
    if math.abs(y) < 0.18 then y = 0 end
    self.pointerX = math.max(0, math.min(960, self.pointerX + x * 520 * dt))
    self.pointerY = math.max(0, math.min(678, self.pointerY + y * 520 * dt))
end

function Controller:gamepadpressed(joystick, button)
    if not joystick or not joystick:isGamepad() then return false end
    self.active = joystick
    local screen, detail = self.screenInfo()
    if screen == "title" then
        if button == "a" or button == "start" then self.pressKey("return"); return true end
        if button == "x" then self.pressKey("n"); return true end
        if button == "y" then self.pressKey("d"); return true end
        if (button == "b" or button == "back") and detail then
            self.pressKey("escape"); return true
        end
    end
    if dpadKeys[button] then self.pressKey(dpadKeys[button]); return true end
    if screen == "world" then
        if button == "a" then self.pressKey("e"); return true end
        if button == "start" then self.worldMenuAction(); return true end
        return false
    end
    if screen == "service" then
        if button == "x" then self.pressKey("d"); return true end
        if button == "y" then self.pressKey("r"); return true end
        if button == "rightshoulder" then self.pressKey("t"); return true end
    elseif screen == "road_test" then
        if button == "a" then self.pressKey("return"); return true end
        if button == "x" then self.pressKey("r"); return true end
    end
    if button == "b" or button == "back" or button == "start" then
        self.pressKey("escape")
        return true
    end
    if button == "a" then
        self.pointerHeld = true
        self.pressPointer(self.pointerX, self.pointerY, 1)
        return true
    end
    return false
end

function Controller:gamepadreleased(joystick, button)
    if joystick ~= self.active then return false end
    if button == "a" and self.pointerHeld then self.pointerHeld = false; return true end
    return false
end

function Controller:draw()
    if not self.active then return end
    local screen = self.screenInfo()
    if screen == "world" or screen == "road_test" or screen == "asset_error" then return end
    love.graphics.setColor(0.02, 0.05, 0.07, 0.92)
    love.graphics.circle("fill", self.pointerX, self.pointerY, 13)
    love.graphics.setColor(0.98, 0.82, 0.25, 1)
    love.graphics.setLineWidth(3)
    love.graphics.circle("line", self.pointerX, self.pointerY, 13)
    love.graphics.line(self.pointerX - 18, self.pointerY, self.pointerX + 18, self.pointerY)
    love.graphics.line(self.pointerX, self.pointerY - 18, self.pointerX, self.pointerY + 18)
    love.graphics.setLineWidth(1)
end

return Controller
