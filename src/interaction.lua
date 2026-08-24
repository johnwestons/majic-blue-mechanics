local Interaction = {}

function Interaction.nearest(player, targets)
    local best, bestDistance
    for _, target in ipairs(targets or {}) do
        local dx, dy = player.x - target.x, player.y - target.y
        local distance = dx * dx + dy * dy
        if distance <= target.radius * target.radius and (not bestDistance or distance < bestDistance) then
            best, bestDistance = target, distance
        end
    end
    return best
end

return Interaction
