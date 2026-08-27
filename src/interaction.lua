local Interaction = {}

-- Pick the in-range action under/nearest the pointer first, then use player
-- distance as a gentle tie-breaker. This keeps the workshop prompt aimed at
-- the object the player is looking at instead of whichever collider happens
-- to be a few pixels closer.
function Interaction.nearest(player, targets, cursorX, cursorY)
    local best, bestScore
    for _, target in ipairs(targets or {}) do
        local dx, dy = player.x - target.x, player.y - target.y
        local playerDistance = math.sqrt(dx * dx + dy * dy)
        if playerDistance <= target.radius then
            local pointerDistance = cursorX and cursorY
                and math.sqrt((cursorX - target.x) ^ 2 + (cursorY - target.y) ^ 2) or 9999
            local hovered = pointerDistance <= (target.hoverRadius or math.min(48, target.radius * 0.72))
            local score = pointerDistance + playerDistance * 0.001 - (hovered and 10000 or 0)
            if not bestScore or score < bestScore then best, bestScore = target, score end
        end
    end
    return best
end

return Interaction
