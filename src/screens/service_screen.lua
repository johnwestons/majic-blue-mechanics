local Jobs = require("src.jobs")
local BackButton = require("src.screens.back_button")
local Ui = require("src.screens.ui")

local ServiceScreen = {}
local CLOSE = { x = 674, y = 540, width = 134, height = 38 }

local stageButtons = {
    diagnosis = { action = "diagnose", hotkey = "D", label = "Run diagnosis" },
    repair = { action = "repair", hotkey = "R", label = "Install parts & repair" },
    road_test = { action = "road_test", hotkey = "T", label = "Complete road test" },
}

function ServiceScreen.draw(state, assets, mouseX, mouseY)
    local job
    for _, candidate in ipairs(state.jobs.active) do
        if candidate.id == state.selectedJobId then job = candidate break end
    end
    Ui.panel(104, 66, 752, 540, "SERVICE BAY  •  " .. (job and job.id or "NO ACTIVE BIKE"))
    if not job then
        Ui.label("This motorcycle is no longer in the service queue.", 150, 160, 660,
            { 0.92, 0.62, 0.50 }, "center")
        BackButton.draw(CLOSE, "CLOSE", mouseX, mouseY)
        return
    end

    local bikeKey = Jobs.ensureBikeSprite(job)
    local bike = bikeKey and assets.get("motorcycleService_" .. bikeKey)
    bike = bike or assets.get("motorcycleSide")
    if bike then
        love.graphics.setColor(1, 1, 1)
        local previewScale = bike:getWidth() > 200 and 0.85 or 1.55
        love.graphics.draw(bike, 152, 120, 0, previewScale, previewScale)
    end
    Ui.label(string.format("%d %s %s", job.bike.year, job.bike.make, job.bike.model),
        386, 120, 410, { 0.90, 0.84, 0.57 })
    Ui.label(job.owner .. "  •  " .. job.company, 386, 150, 410, { 0.68, 0.78, 0.77 })
    Ui.label(job.service, 386, 184, 410, { 0.58, 0.90, 0.92 })
    Ui.label(Jobs.stageLabel(job), 386, 214, 410, { 0.86, 0.89, 0.84 })

    Ui.label("TECHNICIAN NOTES", 148, 282, 250, { 0.90, 0.84, 0.57 })
    local notes = job.stage == "diagnosis" and job.complaint or job.diagnosis
    Ui.label(notes, 148, 312, 660, { 0.82, 0.86, 0.82 })

    Ui.label("PARTS", 148, 382, 160, { 0.90, 0.84, 0.57 })
    Ui.label(table.concat(job.parts, "  •  "), 148, 410, 500, { 0.75, 0.82, 0.80 })
    Ui.label(Ui.money(job.partsCost), 680, 410, 128, { 0.86, 0.89, 0.84 }, "right")

    local checks = {
        { job.checklist.diagnosed, "Diagnosis" },
        { job.checklist.repaired, "Repair" },
        { job.checklist.roadTested, "Road test" },
    }
    for index, check in ipairs(checks) do
        local x = 148 + (index - 1) * 210
        love.graphics.setColor(check[1] and 0.20 or 0.08, check[1] and 0.48 or 0.17,
            check[1] and 0.36 or 0.19)
        love.graphics.rectangle("fill", x, 468, 184, 34, 3, 3)
        Ui.label((check[1] and "OK  " or "[ ]  ") .. check[2], x + 10, 478, 164,
            check[1] and { 0.66, 0.94, 0.72 } or { 0.56, 0.64, 0.62 })
    end

    local button = stageButtons[job.stage]
    if button then
        Ui.button(148, 536, 342, 44, button.label, button.hotkey, mouseX, mouseY, true)
    end
    BackButton.draw(CLOSE, "CLOSE", mouseX, mouseY)
end

function ServiceScreen.hit(state, x, y)
    if BackButton.contains(CLOSE, x, y) then return "close" end
    if Ui.contains(148, 536, 342, 44, x, y) then
        local job
        for _, candidate in ipairs(state.jobs.active) do
            if candidate.id == state.selectedJobId then job = candidate break end
        end
        local button = job and stageButtons[job.stage]
        return button and button.action or nil
    end
end

return ServiceScreen
