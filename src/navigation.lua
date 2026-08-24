local Config = require("src.config")

local Navigation = {}

local function whiteAt(mask, x, y)
    local width, height = mask:getDimensions()
    local pixelX = math.floor(x / Config.baseWidth * width)
    local pixelY = math.floor(y / Config.baseHeight * height)
    if pixelX < 0 or pixelY < 0 or pixelX >= width or pixelY >= height then return false end
    local red, green, blue = mask:getPixel(pixelX, pixelY)
    return red > 0.9 and green > 0.9 and blue > 0.9
end

local function feetAreOnMask(mask, x, y)
    if not mask then
        return x > 55 and x < Config.baseWidth - 55 and y > 90 and y < Config.baseHeight - 45
    end
    return whiteAt(mask, x - 6, y)
        and whiteAt(mask, x, y + 2)
        and whiteAt(mask, x + 6, y)
end

local function outsideObstacle(x, y, obstacle)
    local dx, dy = x - obstacle.x, y - obstacle.y
    if obstacle.halfWidth and obstacle.halfHeight then
        return math.abs(dx) >= obstacle.halfWidth or math.abs(dy) >= obstacle.halfHeight
    end
    return dx * dx + dy * dy >= obstacle.radius * obstacle.radius
end

function Navigation.isWalkable(assets, x, y, obstacles)
    local mask = assets.getData("walkmask")
    if not feetAreOnMask(mask, x, y) then return false end
    for _, obstacle in ipairs(obstacles or {}) do
        if not outsideObstacle(x, y, obstacle) then return false end
    end
    return true
end

function Navigation.canMoveFrom(assets, currentX, currentY, nextX, nextY, obstacles)
    local mask = assets.getData("walkmask")
    if not feetAreOnMask(mask, nextX, nextY) then return false end
    for _, obstacle in ipairs(obstacles or {}) do
        if not outsideObstacle(nextX, nextY, obstacle) then
            local currentDx, currentDy = currentX - obstacle.x, currentY - obstacle.y
            local nextDx, nextDy = nextX - obstacle.x, nextY - obstacle.y
            if obstacle.halfWidth and obstacle.halfHeight then
                local currentDepth = math.min(
                    obstacle.halfWidth - math.abs(currentDx),
                    obstacle.halfHeight - math.abs(currentDy))
                local nextDepth = math.min(
                    obstacle.halfWidth - math.abs(nextDx),
                    obstacle.halfHeight - math.abs(nextDy))
                if currentDepth <= 0 or nextDepth >= currentDepth then return false end
            else
                local currentDistance = currentDx * currentDx + currentDy * currentDy
                local nextDistance = nextDx * nextDx + nextDy * nextDy
                if currentDistance >= obstacle.radius * obstacle.radius
                    or nextDistance <= currentDistance
                then
                    return false
                end
            end
        end
    end
    return true
end

return Navigation
