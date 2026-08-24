local Ui = require("src.screens.ui")

local Hud = {}

function Hud.draw(state, prompt)
    love.graphics.setColor(0.025, 0.035, 0.04, 0.90)
    love.graphics.rectangle("fill", 16, 14, 360, 64, 5, 5)
    love.graphics.setColor(0.25, 0.58, 0.66)
    love.graphics.rectangle("line", 16, 14, 360, 64, 5, 5)
    Ui.label("MAJIC BLUE MECHANICS", 30, 24, 210, { 0.90, 0.84, 0.57 })
    Ui.label(Ui.money(state.money), 250, 24, 108, { 0.55, 0.90, 0.70 }, "right")
    Ui.label(string.format("Active %d   Finished %d   Rep %d",
        #state.jobs.active, #state.jobs.completed, state.reputation),
        30, 48, 328, { 0.75, 0.82, 0.80 })

    local footer = prompt or state.message
    if footer and footer ~= "" then
        love.graphics.setColor(0.025, 0.035, 0.04, 0.92)
        love.graphics.rectangle("fill", 150, 630, 660, 34, 5, 5)
        love.graphics.setColor(0.90, 0.84, 0.57)
        love.graphics.printf(footer, 166, 640, 628, "center")
    end
end

return Hud
