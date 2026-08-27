local Interaction = {}

local function distance(ax, ay, bx, by)
    local dx, dy = ax - bx, ay - by
    return math.sqrt(dx * dx + dy * dy)
end

local function identityOf(target)
    return target and (target.id or target.key or target.kind) or nil
end

local function sameTarget(a, b)
    if not a or not b then
        return false
    end
    if a == b then
        return true
    end
    local aId, bId = identityOf(a), identityOf(b)
    return aId ~= nil and bId ~= nil and aId == bId
        and a.x == b.x and a.y == b.y
end

local function facingVector(player)
    local x = player.intentX or player.moveX or 0
    local y = player.intentY or player.moveY or 0
    if x ~= 0 or y ~= 0 then
        local length = math.sqrt(x * x + y * y)
        return x / length, y / length
    end
    if type(player.facing) == "number" then
        return player.facing < 0 and -1 or 1, 0
    end
    local vectors = {
        left = { -1, 0 }, west = { -1, 0 },
        right = { 1, 0 }, east = { 1, 0 },
        up = { 0, -1 }, north = { 0, -1 },
        down = { 0, 1 }, south = { 0, 1 },
    }
    local vector = vectors[player.facing]
    return vector and vector[1] or 0, vector and vector[2] or 0
end

function Interaction.nearest(player, targets, cursorX, cursorY, previous, options)
    options = options or {}
    local best, bestScore, bestIndex
    local pointerActive = options.pointerActive
    if pointerActive == nil then
        pointerActive = type(cursorX) == "number" and type(cursorY) == "number"
    end
    local facingX, facingY = facingVector(player)

    for index, target in ipairs(targets or {}) do
        if type(target.x) == "number" and type(target.y) == "number"
            and target.available ~= false and target.disabled ~= true and target.hidden ~= true then
            local acquireRadius = target.interactionRadius or target.radius or 60
            local releaseRadius = target.releaseRadius or acquireRadius * (options.releaseScale or 1.18)
            local retained = sameTarget(target, previous)
            local playerDistance = distance(player.x, player.y, target.x, target.y)
            local allowedRadius = retained and releaseRadius or acquireRadius

            if playerDistance <= allowedRadius then
                local cursorDistance = pointerActive and distance(cursorX, cursorY, target.x, target.y) or math.huge
                local hoverRadius = target.hoverRadius or math.min(acquireRadius, 20)
                local hovered = pointerActive and cursorDistance <= hoverRadius
                local score = playerDistance

                if hovered then
                    score = cursorDistance * 0.70 + playerDistance * 0.30
                    score = score - 1000
                end

                if playerDistance > 0 and (facingX ~= 0 or facingY ~= 0) then
                    local dot = ((target.x - player.x) * facingX + (target.y - player.y) * facingY) / playerDistance
                    score = score - math.max(0, dot) * (options.facingWeight or 9)
                end
                score = score - (target.interactionPriority or 0) * 100
                if retained then
                    score = score - (options.stickiness or 14)
                end

                target.playerDistance = playerDistance
                target.cursorDistance = cursorDistance
                target.hovered = hovered
                target.score = score
                target.radius = acquireRadius
                target.releaseRadius = releaseRadius

                if not bestScore or score < bestScore or (score == bestScore and index < bestIndex) then
                    best, bestScore, bestIndex = target, score, index
                end
            end
        end
    end

    return best
end

return Interaction
