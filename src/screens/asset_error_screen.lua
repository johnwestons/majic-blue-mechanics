local Ui = require("src.screens.ui")

local AssetErrorScreen = {}

function AssetErrorScreen.draw(errors)
    love.graphics.clear(0.08, 0.025, 0.025)
    Ui.panel(90, 84, 780, 510, "STARTUP ASSET CHECK FAILED")
    Ui.label("The game stopped before loading an incomplete art set.", 130, 146, 700,
        { 0.94, 0.68, 0.56 })
    for index, message in ipairs(errors or {}) do
        Ui.label("• " .. message, 130, 192 + (index - 1) * 38, 700,
            { 0.86, 0.82, 0.78 })
    end
    Ui.label("Press Escape to quit.", 130, 548, 700, { 0.62, 0.70, 0.68 }, "center")
end

return AssetErrorScreen
