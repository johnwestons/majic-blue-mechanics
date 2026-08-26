local Jobs = require("src.jobs")
local RepairMinigame = require("src.repair_minigame")
local RepairTasks = require("src.repair_tasks")
local Ui = require("src.screens.ui")
local BackButton = require("src.screens.back_button")

local RepairMinigameScreen = {}
local REPAIR_BACK = { x = 100, y = 566, width = 144, height = 38 }
local DIAGNOSIS_BACK = { x = 694, y = 566, width = 144, height = 38 }

local faultCodes = {
    oil = "P0524", brake = "C1234", chain = "P0722", stator = "P0562",
    suspension = "C1513", belt = "P0505", spoke = "C0040", carb = "P0171",
    magneto = "P0351", coolant = "P0217", tool = "P0000",
}

local channelOrder = {
    "ENGINE", "BRAKES", "DRIVETRAIN", "CHARGING",
    "SUSPENSION", "FUEL", "IGNITION", "COOLING",
}

local channelForKind = {
    oil = "ENGINE", brake = "BRAKES", chain = "DRIVETRAIN",
    stator = "CHARGING", suspension = "SUSPENSION", belt = "DRIVETRAIN",
    spoke = "DRIVETRAIN", carb = "FUEL", magneto = "IGNITION",
    coolant = "COOLING", tool = "ENGINE",
}

local readerLayout = { x = 530, y = 145, scale = 1.08 }

-- Coordinates are in the 256x256 source-reader image. Keep these tight to the
-- visible controls: they are reused for both hit testing and hover feedback.
local readerButtons = {
    back = { x = 101, y = 201, width = 26, height = 25 },
    ok = { x = 132, y = 201, width = 28, height = 25 },
    up = { x = 116, y = 147, width = 24, height = 24 },
    left = { x = 94, y = 169, width = 24, height = 24 },
    right = { x = 140, y = 169, width = 24, height = 24 },
}

local function taskFor(job, action)
    if action == "repair" then return RepairMinigame.new(job) end
    local keyword, definition = RepairTasks.forJob(job)
    return {
        action = action,
        kind = keyword,
        label = "Select the repair channel, then press the orange OK button.",
        targetLabel = definition.location,
        complete = false,
        reader = action == "diagnose" and {
            step = 0,
            channelIndex = 1,
            requiredChannel = channelForKind[keyword] or channelForKind.tool,
            requiredChannelIndex = 1,
            faultCode = faultCodes[keyword] or faultCodes.tool,
            location = definition.location,
        } or nil,
    }
end

local function selectedJob(state)
    for _, job in ipairs(state.jobs.active or {}) do
        if job.id == state.selectedJobId then return job end
    end
end

function RepairMinigameScreen.begin(state, action)
    local job = selectedJob(state)
    if not job then
        state.message = "There is no active motorcycle in this service bay."
        return false
    end
    Jobs.ensureBikeSprite(job)
    state.repairMinigame = taskFor(job, action)
    local task = state.repairMinigame
    if task.reader then
        for index, channel in ipairs(channelOrder) do
            if channel == task.reader.requiredChannel then
                task.reader.requiredChannelIndex = index
                break
            end
        end
    end
    state.screen = "repair_minigame"
    return true
end

function RepairMinigameScreen.cancel(state)
    state.repairMinigame = nil
    state.screen = "service"
end

function RepairMinigameScreen.finish(state)
    state.repairMinigame = nil
end

local function readerButtonAt(x, y)
    local px = (x - readerLayout.x) / readerLayout.scale
    local py = (y - readerLayout.y) / readerLayout.scale
    for name, button in pairs(readerButtons) do
        if px >= button.x and px <= button.x + button.width
            and py >= button.y and py <= button.y + button.height then
            return name
        end
    end
end

function RepairMinigameScreen.pressButton(state, button)
    local task = state.repairMinigame
    if task and task.action == "repair" then
        return RepairMinigame.pressButton(task, button)
    end
    if not task or task.action ~= "diagnose" or not task.reader then return nil end
    local reader = task.reader
    if button == "up" or button == "left" or button == "down" or button == "right" then
        if reader.step == 0 then
            local delta = (button == "up" or button == "left") and -1 or 1
            reader.channelIndex = ((reader.channelIndex - 1 + delta) % #channelOrder) + 1
        end
        return nil
    end
    if button == "back" then
        reader.step = math.max(0, reader.step - 1)
        return nil
    end
    if button == "ok" then
        if reader.step == 0 then
            if reader.channelIndex ~= reader.requiredChannelIndex then
                state.message = "Wrong channel. Select the channel for this repair before pressing OK."
                return nil
            end
            reader.step = 1
            return nil
        elseif reader.step < 3 then
            reader.step = reader.step + 1
            if reader.step == 3 then task.complete = true end
            return nil
        end
        return task.action
    end
end

function RepairMinigameScreen.mousepressed(state, x, y)
    local task = state.repairMinigame
    if not task then return false end
    if task.action == "diagnose" then
        return RepairMinigameScreen.pressButton(state, readerButtonAt(x, y))
    end
    return RepairMinigame.mousepressed(task, x, y)
end

function RepairMinigameScreen.mousemoved(state, x, y)
    local task = state.repairMinigame
    if not task or task.action ~= "repair" then return false end
    return RepairMinigame.mousemoved(task, x, y)
end

function RepairMinigameScreen.mousereleased(state, x, y)
    local task = state.repairMinigame
    if task and task.action == "diagnose" then return nil end
    if not task or task.action ~= "repair" then return nil end
    return RepairMinigame.mousereleased(task, x, y)
end

function RepairMinigameScreen.update(state, dt)
    local task = state.repairMinigame
    if task and task.action == "repair" then RepairMinigame.update(task, dt) end
end

function RepairMinigameScreen.hit(state, x, y)
    local task = state and state.repairMinigame
    if task and task.action == "repair" then
        if task.phase == "inspect" and Ui.contains(610, 566, 228, 38, x, y) then
            return "finish"
        end
        if BackButton.contains(REPAIR_BACK, x, y) then return "cancel" end
        return nil
    end
    if BackButton.contains(DIAGNOSIS_BACK, x, y) then return "cancel" end
end

local function drawPartSprite(assets, kind, x, y, scale, active, opacity)
    scale = scale or 1
    opacity = opacity or (active and 1 or 0.90)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(scale, scale)

    local sprite = assets and assets.get("repairPart_" .. kind)
    if sprite then
        if active then
            love.graphics.setColor(0.95, 0.73, 0.28, 0.22)
            love.graphics.rectangle("fill", -38, -38, 76, 76, 8, 8)
        end
        local width, height = sprite:getDimensions()
        love.graphics.setColor(1, 1, 1, opacity)
        love.graphics.draw(sprite, -32, -32, 0, 64 / width, 64 / height)
        love.graphics.pop()
        return
    end

    love.graphics.setColor(active and 0.95 or 0.74, active and 0.83 or 0.70,
        active and 0.42 or 0.55, 1)
    love.graphics.rectangle("fill", -24, -24, 48, 48, 4, 4)
    love.graphics.setColor(0.05, 0.09, 0.10)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", -24, -24, 48, 48, 4, 4)
    love.graphics.setColor(0.84, 0.91, 0.88)
    if kind == "oil" or kind == "coolant" then
        love.graphics.rectangle("fill", -9, -14, 18, 28, 3, 3)
        love.graphics.rectangle("fill", -5, -20, 10, 7)
    elseif kind == "brake" or kind == "spoke" then
        love.graphics.circle("line", 0, 0, 16)
        love.graphics.line(-14, 0, 14, 0)
        love.graphics.line(0, -14, 0, 14)
    elseif kind == "chain" or kind == "belt" then
        love.graphics.arc("line", "open", -10, -10, 16, 0, math.pi * 2)
        love.graphics.arc("line", "open", 10, 10, 16, 0, math.pi * 2)
        love.graphics.line(-4, -4, 4, 4)
    elseif kind == "suspension" then
        for index = -2, 2 do love.graphics.line(-13, index * 7 - 4, 13, index * 7 + 4) end
    elseif kind == "stator" or kind == "magneto" then
        love.graphics.circle("fill", 0, 0, 14)
        love.graphics.setColor(0.12, 0.19, 0.20)
        love.graphics.circle("fill", 0, 0, 6)
    elseif kind == "carb" then
        love.graphics.rectangle("fill", -15, -10, 30, 20, 3, 3)
        love.graphics.circle("fill", -9, 0, 5)
        love.graphics.circle("fill", 9, 0, 5)
    elseif kind == "road" then
        love.graphics.polygon("fill", -16, 12, 16, 0, -16, -12)
    else
        love.graphics.line(-15, 12, 15, -12)
        love.graphics.circle("fill", -15, 12, 5)
    end
    love.graphics.pop()
end

local function drawRepairTool(assets, kind, x, y, scale, angle, active)
    if not x or not y then return end
    scale = scale or 1
    angle = angle or 0
    local sprite = assets and assets.get("repairTool_" .. tostring(kind))
    if active then
        love.graphics.setColor(0.95, 0.73, 0.28, 0.20)
        love.graphics.circle("fill", x, y, 34 * scale)
    end
    if sprite then
        local width, height = sprite:getDimensions()
        love.graphics.setColor(1, 1, 1, active and 1 or 0.92)
        love.graphics.draw(sprite, x, y, angle, 64 * scale / width,
            64 * scale / height, width / 2, height / 2)
        return
    end
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(angle)
    love.graphics.setColor(0.84, 0.91, 0.88)
    love.graphics.rectangle("fill", -25 * scale, -5 * scale, 50 * scale, 10 * scale, 3, 3)
    love.graphics.setColor(0.95, 0.64, 0.18)
    love.graphics.circle("fill", 24 * scale, 0, 8 * scale)
    love.graphics.pop()
end

local function readerFrame(task)
    local step = task.reader and task.reader.step or 0
    if step <= 0 then return 1 end
    if step == 1 then return 2 end
    -- Keep the settling state on the blue scan/progress frame. Alternating
    -- between the progress screen and the live-data graph made the reader
    -- flicker between two unrelated visual states.
    if step == 2 then return 2 end
    return 4
end

local function drawCodeReader(task, assets, mouseX, mouseY, job)
    local frame = assets.get("diagnosticReader" .. string.format("%02d", readerFrame(task)))
    Ui.label("MOTO CODE READER", 540, 140, 268, { 0.90, 0.84, 0.57 }, "center")
    if frame then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(frame, readerLayout.x, readerLayout.y, 0,
            readerLayout.scale, readerLayout.scale)
    end
    local button = readerButtonAt(mouseX or -1, mouseY or -1)
    if button then
        local box = readerButtons[button]
        if box then
            love.graphics.setColor(0.42, 0.90, 0.82, 0.26)
            love.graphics.rectangle("fill", readerLayout.x + box.x * readerLayout.scale,
                readerLayout.y + box.y * readerLayout.scale,
                box.width * readerLayout.scale, box.height * readerLayout.scale, 4, 4)
        end
    end
    local step = task.reader.step
    if step < 3 then
        if step == 0 then
            Ui.label("CHANNEL: " .. channelOrder[task.reader.channelIndex],
                540, 408, 268, { 0.75, 0.82, 0.80 }, "center")
            Ui.label("REQUIRED: " .. task.reader.requiredChannel,
                540, 430, 268, { 1.0, 0.73, 0.32 }, "center")
        else
            Ui.label("Mode: READ DTC", 540, 408, 268,
                { 0.75, 0.82, 0.80 }, "center")
        end
    end
    if step == 0 then
        Ui.label("Select the repair channel, then press OK.", 540, 452, 268,
            { 0.75, 0.82, 0.80 }, "center")
    elseif step == 1 then
        Ui.label("ECU link ready. Press OK to scan.", 540, 430, 268,
            { 0.58, 0.90, 0.92 }, "center")
    elseif step == 2 then
        Ui.label("Reading live data... press OK when the scan settles.", 540, 430, 268,
            { 0.58, 0.90, 0.92 }, "center")
    else
        Ui.label("DTC " .. task.reader.faultCode .. " FOUND", 540, 420, 268,
            { 1.0, 0.73, 0.32 }, "center")
        Ui.label(job.diagnosis, 540, 448, 268, { 0.82, 0.86, 0.82 }, "center")
        Ui.label("Press OK to send the result to the work order.", 540, 500, 268,
            { 0.75, 0.82, 0.80 }, "center")
    end
    Ui.label("Use the reader buttons: arrows navigate • orange check confirms",
        520, 530, 308, { 0.56, 0.64, 0.62 }, "center")
end

local function drawPhaseHeader(task)
    local active = task.phase == "part" and 1
        or task.phase == "inspect" and 3 or 2
    local labels = { "1  PART", "2  TOOL", "3  INSPECT" }
    for index, label in ipairs(labels) do
        local x = 518 + (index - 1) * 104
        local done = index < active or task.phase == "inspect" and index < 3
        local selected = index == active
        love.graphics.setColor(done and 0.12 or selected and 0.12 or 0.07,
            done and 0.42 or selected and 0.30 or 0.14,
            done and 0.31 or selected and 0.35 or 0.16, 1)
        love.graphics.rectangle("fill", x, 120, 94, 30, 4, 4)
        Ui.label((done and "OK  " or "") .. label, x + 4, 129, 86,
            selected and { 0.96, 0.82, 0.42 }
                or done and { 0.66, 0.94, 0.72 }
                or { 0.48, 0.57, 0.56 }, "center")
    end
end

local function drawWorkPoints(task)
    if task.phase == "part" then return end
    local definition = RepairMinigame.definition(task)
    local pulse = 2 + math.sin(love.timer.getTime() * 6) * 2
    for index, point in ipairs(definition.workPoints) do
        local completed = task.completedPoints[index]
        local current = index == task.pointIndex and task.phase ~= "inspect"
        love.graphics.setLineWidth(current and 3 or 2)
        if completed then
            love.graphics.setColor(0.30, 0.92, 0.52, 0.92)
            love.graphics.circle("fill", point.x, point.y, 9)
            love.graphics.setColor(0.05, 0.18, 0.13)
            love.graphics.line(point.x - 4, point.y, point.x - 1, point.y + 4,
                point.x + 5, point.y - 5)
        elseif current then
            love.graphics.setColor(0.38, 0.94, 0.88, 0.22)
            love.graphics.circle("fill", point.x, point.y, 18 + pulse)
            love.graphics.setColor(0.48, 0.96, 0.91, 0.96)
            love.graphics.circle("line", point.x, point.y, 14 + pulse)
            love.graphics.circle("fill", point.x, point.y, 5)
        else
            love.graphics.setColor(0.34, 0.48, 0.47, 0.65)
            love.graphics.circle("line", point.x, point.y, 10)
        end
    end
end

local function drawToolTray(task, assets, mouseX, mouseY)
    local definition = RepairMinigame.definition(task)
    local slots = RepairMinigame.toolSlots()
    Ui.label("TOOL TRAY", 526, 302, 300, { 0.90, 0.84, 0.57 }, "center")
    for index, tool in ipairs(RepairTasks.tools()) do
        local slot = slots[index]
        local hovered = mouseX and mouseY
            and mouseX >= slot.x - 29 and mouseX <= slot.x + 29
            and mouseY >= slot.y - 31 and mouseY <= slot.y + 31
        local selected = task.selectedTool == tool
        local routineHint = task.difficulty == "Routine" and definition.tool == tool
        love.graphics.setColor(selected and 0.18 or hovered and 0.13 or 0.075,
            selected and 0.39 or hovered and 0.29 or 0.15,
            selected and 0.44 or hovered and 0.34 or 0.17, 1)
        love.graphics.rectangle("fill", slot.x - 29, slot.y - 31, 58, 62, 5, 5)
        love.graphics.setColor(routineHint and 0.95 or selected and 0.48 or 0.24,
            routineHint and 0.65 or selected and 0.82 or 0.43,
            routineHint and 0.22 or selected and 0.82 or 0.45, 0.95)
        love.graphics.rectangle("line", slot.x - 29, slot.y - 31, 58, 62, 5, 5)
        if not selected then drawRepairTool(assets, tool, slot.x, slot.y - 2, 0.72, 0, false) end
        Ui.label(tostring(index), slot.x - 25, slot.y - 27, 18,
            { 0.72, 0.78, 0.75 })
        Ui.label(RepairTasks.toolLabel(tool), slot.x - 31, 393, 62,
            { 0.62, 0.70, 0.68 }, "center")
    end
end

local function drawProgressMeter(task)
    local definition = RepairMinigame.definition(task)
    local x, y, width, height = 536, 430, 278, 22
    Ui.label(string.format("WORK POINT %d / %d", task.pointIndex,
        #definition.workPoints), x, 410, width, { 0.75, 0.82, 0.80 }, "center")
    love.graphics.setColor(0.035, 0.075, 0.08, 1)
    love.graphics.rectangle("fill", x, y, width, height, 4, 4)
    if definition.gesture == "adjust" or definition.gesture == "hold" then
        local low, high = task.bandLow or 0.4, task.bandHigh or 0.6
        love.graphics.setColor(0.20, 0.67, 0.38, 0.78)
        love.graphics.rectangle("fill", x + low * width, y + 2,
            (high - low) * width, height - 4, 3, 3)
        local value = definition.gesture == "adjust"
            and (task.adjustValue or 0) or (task.fillValue or 0)
        local markerX = x + math.min(value, 1) * width
        love.graphics.setColor(value > high and 0.95 or 0.96,
            value > high and 0.35 or 0.78, value > high and 0.24 or 0.28, 1)
        love.graphics.rectangle("fill", markerX - 3, y - 4, 6, height + 8, 2, 2)
    else
        love.graphics.setColor(0.28, 0.77, 0.73, 0.92)
        love.graphics.rectangle("fill", x + 2, y + 2,
            math.max(0, (width - 4) * math.min(task.pointProgress or 0, 1)),
            height - 4, 3, 3)
    end
    love.graphics.setColor(0.31, 0.62, 0.65, 0.9)
    love.graphics.rectangle("line", x, y, width, height, 4, 4)
end

local function drawRepair(task, job, bike, assets, mouseX, mouseY)
    local definition = RepairMinigame.definition(task)
    if bike then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(bike, 92, 98, 0, 1.36, 1.36)
    end

    local targetPulse = 0.72 + math.sin(love.timer.getTime() * 5) * 0.08
    if task.phase == "part" then
        love.graphics.setColor(0.36, 0.92, 0.86, 0.18)
        love.graphics.circle("fill", definition.target.x, definition.target.y, 50)
        drawPartSprite(assets, task.kind, definition.target.x, definition.target.y,
            targetPulse, false, 0.28)
    else
        drawPartSprite(assets, task.kind, definition.target.x, definition.target.y,
            0.72, false, task.phase == "inspect" and 0.94 or 0.78)
        drawWorkPoints(task)
    end

    Ui.label(job.bike.make .. " " .. job.bike.model, 104, 449, 374,
        { 0.90, 0.84, 0.57 })
    Ui.label(definition.partVerb .. " • " .. definition.location, 104, 475, 374,
        { 0.58, 0.90, 0.92 })
    Ui.label(job.difficulty .. " repair", 104, 501, 374,
        { 0.62, 0.70, 0.68 })

    love.graphics.setColor(0.055, 0.095, 0.105, 0.97)
    love.graphics.rectangle("fill", 500, 100, 352, 442, 5, 5)
    drawPhaseHeader(task)

    local instruction
    if task.phase == "part" then
        instruction = "Drag the replacement part onto the glowing silhouette on the motorcycle."
        Ui.label("REPLACEMENT PART", 526, 302, 300, { 0.90, 0.84, 0.57 }, "center")
        Ui.label("DRAG TO BIKE", 626, 402, 100, { 0.75, 0.82, 0.80 }, "center")
    elseif task.phase == "tool" then
        instruction = task.selectedTool
            and "Drag the selected tool onto the pulsing work point."
            or "Choose the tool that fits this service, then drag it to the pulse."
        drawToolTray(task, assets, mouseX, mouseY)
    elseif task.phase == "operate" then
        instruction = definition.operatePrompt
        drawToolTray(task, assets, mouseX, mouseY)
        drawProgressMeter(task)
    else
        instruction = "Every work point is secure. The installation is ready for final inspection."
        love.graphics.setColor(0.16, 0.55, 0.34, 0.28)
        love.graphics.circle("fill", 676, 347, 62)
        love.graphics.setColor(0.48, 0.96, 0.64)
        love.graphics.setLineWidth(8)
        love.graphics.line(648, 348, 668, 369, 706, 324)
        Ui.label("REPAIR VERIFIED", 536, 425, 280, { 0.66, 0.94, 0.72 }, "center")
    end

    Ui.label(task.phase == "inspect" and "QUALITY CHECK" or string.upper(task.targetLabel),
        526, 168, 300, { 0.90, 0.84, 0.57 }, "center")
    Ui.label(instruction, 526, 198, 300, { 0.78, 0.84, 0.81 }, "center")

    if task.phase == "part" then
        drawPartSprite(assets, task.kind, task.partX, task.partY, 1.05,
            task.partDragging, 1)
    end

    if task.selectedTool and task.toolX and task.phase ~= "inspect" then
        drawRepairTool(assets, task.selectedTool, task.toolX, task.toolY,
            task.toolOperating and 0.94 or 0.84, task.toolAngle,
            task.toolDragging or task.toolOperating)
    end

    local feedbackColor = task.feedbackKind == "error" and { 0.96, 0.48, 0.36 }
        or task.feedbackKind == "success" and { 0.58, 0.94, 0.68 }
        or { 0.58, 0.78, 0.80 }
    Ui.label(task.feedback or "", 526, 476, 300, feedbackColor, "center")
    BackButton.draw(REPAIR_BACK, "CANCEL", mouseX, mouseY)
    if task.phase == "inspect" then
        Ui.button(610, 566, 228, 38, "Finish repair", "ENTER", mouseX, mouseY, true)
    else
        Ui.label("Mouse: drag + work tool   •   Keyboard: arrows + Enter",
            326, 579, 266, { 0.50, 0.59, 0.58 }, "center")
    end
end

function RepairMinigameScreen.draw(state, assets, mouseX, mouseY)
    local job = selectedJob(state)
    local task = state.repairMinigame
    Ui.panel(72, 42, 816, 594, "REPAIR ACTION  •  " .. (job and job.id or "NO ACTIVE BIKE"))
    if not job or not task then
        Ui.label("No repair action is active.", 130, 170, 700, { 0.92, 0.62, 0.50 }, "center")
        BackButton.draw(DIAGNOSIS_BACK, "BACK", mouseX, mouseY)
        return
    end

    local bikeKey = Jobs.ensureBikeSprite(job)
    local bike = bikeKey and assets.get("motorcycleService_" .. bikeKey)
    bike = bike or assets.get("motorcycleSide")
    if task.action == "repair" then
        drawRepair(task, job, bike, assets, mouseX, mouseY)
        return
    end

    if bike then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(bike, 112, 128, 0, 0.78, 0.78)
    end
    Ui.label(job.bike.make .. " " .. job.bike.model, 112, 394, 370, { 0.90, 0.84, 0.57 })
    Ui.label("Use the code reader buttons to inspect the ECU.",
        112, 425, 370, { 0.68, 0.78, 0.77 })
    Ui.label(task.label, 112, 454, 370, { 0.58, 0.90, 0.92 })

    love.graphics.setColor(0.07, 0.12, 0.13, 0.95)
    love.graphics.rectangle("fill", 510, 112, 328, 410, 5, 5)
    drawCodeReader(task, assets, mouseX, mouseY, job)
    BackButton.draw(DIAGNOSIS_BACK, "CANCEL", mouseX, mouseY)
end

return RepairMinigameScreen
