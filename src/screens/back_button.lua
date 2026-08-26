local Ui = require("src.screens.ui")

local BackButton = {}

function BackButton.contains(rect, x, y)
    return rect and Ui.contains(rect.x, rect.y, rect.width, rect.height, x, y)
end

function BackButton.draw(rect, label, mouseX, mouseY)
    local hovered = BackButton.contains(rect, mouseX, mouseY)
    local pressed = hovered and love.mouse and love.mouse.isDown and love.mouse.isDown(1)
    -- A compact blue-enamel shop switch with a steel rim and corner bolts.
    love.graphics.setColor(0.09, 0.11, 0.12, 0.98)
    love.graphics.rectangle("fill", rect.x - 2, rect.y - 2, rect.width + 4, rect.height + 4, 5, 5)
    love.graphics.setColor(0.42, 0.48, 0.49, 1)
    love.graphics.rectangle("line", rect.x - 2, rect.y - 2, rect.width + 4, rect.height + 4, 5, 5)
    love.graphics.setColor(pressed and 0.08 or (hovered and 0.16 or 0.10),
        pressed and 0.29 or (hovered and 0.48 or 0.34),
        pressed and 0.42 or (hovered and 0.63 or 0.50), 1)
    love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height, 4, 4)
    love.graphics.setColor(0.64, 0.75, 0.76, 1)
    love.graphics.rectangle("line", rect.x, rect.y, rect.width, rect.height, 4, 4)
    for _, bolt in ipairs({ { 6, 6 }, { rect.width - 6, 6 },
            { 6, rect.height - 6 }, { rect.width - 6, rect.height - 6 } }) do
        love.graphics.setColor(0.70, 0.72, 0.68, 1)
        love.graphics.circle("fill", rect.x + bolt[1], rect.y + bolt[2], 1.5)
    end
    love.graphics.setColor(0.96, 0.94, 0.82, 1)
    love.graphics.printf("ESC  " .. (label or "BACK"), rect.x + 10,
        rect.y + math.floor((rect.height - 14) / 2), rect.width - 20, "center")
    return hovered
end

return BackButton
