local Ui = {}

function Ui.contains(x, y, width, height, mouseX, mouseY)
    return mouseX and mouseY and mouseX >= x and mouseX <= x + width
        and mouseY >= y and mouseY <= y + height
end

function Ui.panel(x, y, width, height, title)
    love.graphics.setColor(0.035, 0.055, 0.065, 0.96)
    love.graphics.rectangle("fill", x, y, width, height, 6, 6)
    love.graphics.setColor(0.24, 0.57, 0.68)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height, 6, 6)
    if title then
        love.graphics.setColor(0.09, 0.19, 0.22)
        love.graphics.rectangle("fill", x + 2, y + 2, width - 4, 42, 4, 4)
        love.graphics.setColor(0.90, 0.84, 0.57)
        love.graphics.printf(title, x + 16, y + 13, width - 32, "left")
    end
end

function Ui.button(x, y, width, height, label, hotkey, mouseX, mouseY, enabled)
    if enabled == nil then enabled = true end
    local hovered = enabled and Ui.contains(x, y, width, height, mouseX, mouseY)
    love.graphics.setColor(hovered and 0.18 or 0.10, hovered and 0.39 or 0.25,
        hovered and 0.44 or 0.29, enabled and 1 or 0.55)
    love.graphics.rectangle("fill", x, y, width, height, 4, 4)
    love.graphics.setColor(enabled and 0.48 or 0.26, enabled and 0.78 or 0.34,
        enabled and 0.80 or 0.36, enabled and 1 or 0.6)
    love.graphics.rectangle("line", x, y, width, height, 4, 4)
    love.graphics.setColor(enabled and 0.96 or 0.55, enabled and 0.94 or 0.55,
        enabled and 0.82 or 0.55)
    local text = hotkey and (hotkey .. "  " .. label) or label
    love.graphics.printf(text, x + 8, y + math.floor((height - 14) / 2), width - 16, "center")
    return hovered
end

function Ui.label(text, x, y, width, color, align)
    local selected = color or { 0.86, 0.88, 0.83, 1 }
    love.graphics.setColor(selected[1], selected[2], selected[3], selected[4] or 1)
    love.graphics.printf(tostring(text), x, y, width, align or "left")
end

function Ui.money(amount) return string.format("$%d", math.floor(amount or 0)) end

function Ui.number(amount)
    local value = tostring(math.floor(amount or 0))
    local sign, digits = value:match("^([%-]?)(%d+)$")
    local reversed = digits:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    reversed = reversed:gsub("^,", "")
    return sign .. reversed
end

return Ui
