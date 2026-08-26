local BayDoor = {}
local Instance = {}
Instance.__index = Instance

function BayDoor.new(config)
    assert(type(config) == "table", "loading-bay configuration is required")
    local instance = setmetatable({
        duration = config.duration or 0.9,
        frameCount = config.frameCount or 5,
        interaction = config.interaction,
        obstacle = config.obstacle,
    }, Instance)
    instance:reset()
    return instance
end

function Instance:reset()
    self.state, self.progress = "closed", 0
end

function Instance:open()
    if self.state ~= "closed" then return false end
    self.state = "opening"
    return true
end

function Instance:close()
    if self.state ~= "open" then return false end
    self.state = "closing"
    return true
end

function Instance:toggle()
    if self.state == "closed" then return self:open() end
    if self.state == "open" then return self:close() end
    return false
end

function Instance:update(dt)
    if self.state ~= "opening" and self.state ~= "closing" then return nil end
    local direction = self.state == "opening" and 1 or -1
    self.progress = math.min(1, math.max(0,
        self.progress + direction * math.max(0, dt or 0) / self.duration))
    if self.progress >= 1 then self.state = "open" return "opened" end
    if self.progress <= 0 then self.state = "closed" return "closed" end
end

function Instance:frame()
    return math.floor(self.progress * (self.frameCount - 1) + 0.5) + 1
end

function Instance:getInteraction()
    local prompt = self.state == "closed" and "E: open loading dock door"
        or self.state == "open" and "E: close loading dock door"
        or "Loading dock door is " .. self.state
    return { x = self.interaction.x, y = self.interaction.y,
        radius = self.interaction.radius, kind = "loading_bay_door", prompt = prompt }
end

function Instance:getObstacle()
    if self.state == "open" then return nil end
    return { x = self.obstacle.x, y = self.obstacle.y, radius = self.obstacle.radius }
end

function Instance:holdOpen()
    self.state, self.progress = "open", 1
end

function Instance:snapshot()
    return { state = self.state, progress = self.progress, frame = self:frame() }
end

BayDoor.Instance = Instance
return BayDoor
