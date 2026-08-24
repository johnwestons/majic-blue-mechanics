local Jobs = require("src.jobs")
local Ui = require("src.screens.ui")

local ComputerScreen = {}

function ComputerScreen.draw(state, mouseX, mouseY)
    Ui.panel(90, 62, 780, 548, "MAJIC BLUE  •  WORK-ORDER COMPUTER")
    Ui.label("Cash", 128, 120, 100, { 0.62, 0.72, 0.70 })
    Ui.label(Ui.money(state.money), 128, 144, 130, { 0.55, 0.90, 0.70 })
    Ui.label("Revenue", 292, 120, 100, { 0.62, 0.72, 0.70 })
    Ui.label(Ui.money(state.revenue), 292, 144, 130, { 0.86, 0.89, 0.84 })
    Ui.label("Parts spent", 456, 120, 120, { 0.62, 0.72, 0.70 })
    Ui.label(Ui.money(state.expenses), 456, 144, 130, { 0.86, 0.89, 0.84 })
    Ui.label("Reputation", 646, 120, 100, { 0.62, 0.72, 0.70 })
    Ui.label(tostring(state.reputation), 646, 144, 100, { 0.90, 0.84, 0.57 })

    Ui.label("ACTIVE SERVICE QUEUE", 128, 196, 330, { 0.90, 0.84, 0.57 })
    if #state.jobs.active == 0 then
        Ui.label("No motorcycles are waiting for service.", 128, 230, 690,
            { 0.56, 0.64, 0.62 })
    else
        for index, job in ipairs(state.jobs.active) do
            local y = 224 + (index - 1) * 58
            love.graphics.setColor(index == 1 and 0.08 or 0.05, index == 1 and 0.20 or 0.12,
                index == 1 and 0.22 or 0.14, 0.94)
            love.graphics.rectangle("fill", 128, y, 690, 46, 3, 3)
            Ui.label(job.id .. "  " .. job.bike.make .. " " .. job.bike.model,
                142, y + 8, 360, { 0.82, 0.88, 0.84 })
            Ui.label(Jobs.stageLabel(job), 500, y + 8, 190, { 0.58, 0.90, 0.92 })
            Ui.label(Ui.money(job.quote), 704, y + 8, 96, { 0.55, 0.90, 0.70 }, "right")
        end
    end

    local completedY = math.min(464, 252 + #state.jobs.active * 58)
    Ui.label("RECENTLY COMPLETED", 128, completedY, 330, { 0.90, 0.84, 0.57 })
    local shown = 0
    for index = #state.jobs.completed, 1, -1 do
        local job = state.jobs.completed[index]
        local y = completedY + 28 + shown * 28
        if y > 548 then break end
        Ui.label(job.id .. "  " .. job.service, 142, y, 520, { 0.69, 0.78, 0.75 })
        Ui.label(Ui.money(job.quote), 704, y, 96, { 0.55, 0.90, 0.70 }, "right")
        shown = shown + 1
    end

    Ui.button(684, 556, 134, 34, "Close", "ESC", mouseX, mouseY)
end

function ComputerScreen.hit(x, y)
    return Ui.contains(684, 556, 134, 34, x, y) and "close" or nil
end

return ComputerScreen
