local RepairTasks = require("src.repair_tasks")

local RepairMinigame = {}

local partStart = { x = 676, y = 356 }
local toolSlots = {
    { x = 538, y = 356 }, { x = 607, y = 356 }, { x = 676, y = 356 },
    { x = 745, y = 356 }, { x = 814, y = 356 },
}

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function distance(x1, y1, x2, y2)
    local dx, dy = x1 - x2, y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

local function normalizeAngle(value)
    while value > math.pi do value = value - math.pi * 2 end
    while value < -math.pi do value = value + math.pi * 2 end
    return value
end

local function slotFor(tool)
    return toolSlots[RepairTasks.toolIndex(tool)]
end

local function setFeedback(task, message, kind)
    task.feedback = message
    task.feedbackKind = kind or "info"
    task.feedbackTimer = 2.4
end

local function difficultyBand(task, gesture)
    if gesture == "hold" then
        if task.difficulty == "Advanced" then return 0.82, 1.02 end
        if task.difficulty == "Skilled" then return 0.77, 1.05 end
        return 0.70, 1.08
    end
    if task.difficulty == "Advanced" then return 0.44, 0.56 end
    if task.difficulty == "Skilled" then return 0.41, 0.59 end
    return 0.36, 0.64
end

local function motionGoal(task, definition)
    local goal = definition.goal or 4
    if task.difficulty == "Advanced" then return goal * 1.15 end
    if task.difficulty == "Routine" then return goal * 0.85 end
    return goal
end

function RepairMinigame.new(job)
    local kind, definition = RepairTasks.forJob(job)
    return {
        action = "repair",
        kind = kind,
        phase = "part",
        difficulty = (job and job.difficulty) or "Routine",
        label = definition.partVerb .. " at the " .. definition.location .. ".",
        targetLabel = definition.location,
        partX = partStart.x,
        partY = partStart.y,
        partDragging = false,
        selectedTool = nil,
        toolIndex = 1,
        toolX = nil,
        toolY = nil,
        toolDragging = false,
        toolOperating = false,
        toolAngle = 0,
        pointIndex = 1,
        completedPoints = {},
        pointProgress = 0,
        complete = false,
        feedback = "The tool tray unlocks after the part snaps into place.",
        feedbackKind = "info",
        feedbackTimer = 0,
    }
end

function RepairMinigame.definition(task)
    return RepairTasks.get(task and task.kind)
end

function RepairMinigame.toolSlots() return toolSlots end

function RepairMinigame.activePoint(task)
    local definition = RepairMinigame.definition(task)
    return definition.workPoints[task.pointIndex]
end

local function resetPoint(task)
    local definition = RepairMinigame.definition(task)
    local point = RepairMinigame.activePoint(task) or {}
    task.pointProgress = 0
    task.strokeCount = 0
    task.strokeTravel = 0
    task.strokeDirection = nil
    task.keyboardDirection = nil
    task.rotationTravel = 0
    task.adjustValue = point.startValue or 0.22
    task.fillValue = 0
    task.bandLow, task.bandHigh = difficultyBand(task, definition.gesture)
end

local function completePoint(task)
    local definition = RepairMinigame.definition(task)
    task.completedPoints[task.pointIndex] = true
    task.toolOperating = false
    task.pointProgress = 1
    if task.pointIndex >= #definition.workPoints then
        task.phase = "inspect"
        task.complete = true
        setFeedback(task, "All work points are secure. Inspect and finish the repair.", "success")
        return
    end
    task.pointIndex = task.pointIndex + 1
    task.phase = "tool"
    resetPoint(task)
    setFeedback(task, "Good click. Move the tool to the next highlighted work point.", "success")
end

local function installPart(task)
    local definition = RepairMinigame.definition(task)
    task.partX, task.partY = definition.target.x, definition.target.y
    task.partDragging = false
    task.phase = "tool"
    task.toolIndex = RepairTasks.toolIndex(definition.tool)
    resetPoint(task)
    setFeedback(task, "Part seated. Choose the correct tool and drag it to the pulse.", "success")
end

local function chooseTool(task, tool)
    task.selectedTool = tool
    task.toolIndex = RepairTasks.toolIndex(tool)
    local slot = slotFor(tool)
    task.toolX, task.toolY = slot.x, slot.y
end

local function engageSelectedTool(task)
    local definition = RepairMinigame.definition(task)
    local point = RepairMinigame.activePoint(task)
    if task.selectedTool ~= definition.tool then
        setFeedback(task, RepairTasks.toolLabel(task.selectedTool) ..
            " will not fit here. Try another tool.", "error")
        return false
    end
    task.toolX, task.toolY = point.x, point.y
    task.toolDragging = false
    task.phase = "operate"
    resetPoint(task)
    setFeedback(task, definition.operatePrompt, "info")
    return true
end

function RepairMinigame.mousepressed(task, x, y)
    if not task then return false end
    if task.phase == "part" and distance(task.partX, task.partY, x, y) <= 46 then
        task.partDragging = true
        task.grabOffsetX, task.grabOffsetY = x - task.partX, y - task.partY
        return true
    end
    if task.phase == "tool" then
        for index, slot in ipairs(toolSlots) do
            if distance(slot.x, slot.y, x, y) <= 29 then
                chooseTool(task, RepairTasks.tools()[index])
                task.toolDragging = true
                task.grabOffsetX, task.grabOffsetY = x - task.toolX, y - task.toolY
                return true
            end
        end
        if task.selectedTool and task.toolX and
            distance(task.toolX, task.toolY, x, y) <= 40 then
            task.toolDragging = true
            task.grabOffsetX, task.grabOffsetY = x - task.toolX, y - task.toolY
            return true
        end
    end
    if task.phase == "operate" then
        local point = RepairMinigame.activePoint(task)
        if point and distance(point.x, point.y, x, y) <= 54 then
            task.toolOperating = true
            task.lastMouseX, task.lastMouseY = x, y
            if distance(point.x, point.y, x, y) >= 10 then
                task.lastMouseAngle = math.atan2(y - point.y, x - point.x)
            else
                task.lastMouseAngle = nil
            end
            return true
        end
    end
    return false
end

function RepairMinigame.mousemoved(task, x, y)
    if not task then return false end
    if task.partDragging then
        task.partX = x - (task.grabOffsetX or 0)
        task.partY = y - (task.grabOffsetY or 0)
        return true
    end
    if task.toolDragging then
        task.toolX = x - (task.grabOffsetX or 0)
        task.toolY = y - (task.grabOffsetY or 0)
        return true
    end
    if not task.toolOperating then return false end

    local definition = RepairMinigame.definition(task)
    local point = RepairMinigame.activePoint(task)
    local dx = x - (task.lastMouseX or x)
    if definition.gesture == "stroke" and math.abs(dx) >= 1 then
        local direction = dx < 0 and -1 or 1
        if not task.strokeDirection then
            task.strokeDirection = direction
        elseif direction ~= task.strokeDirection then
            if (task.strokeTravel or 0) >= 12 then
                task.strokeCount = (task.strokeCount or 0) + 1
                task.strokeTravel = 0
                task.strokeDirection = direction
                task.pointProgress = clamp(task.strokeCount / motionGoal(task, definition), 0, 1)
            end
        else
            task.strokeTravel = (task.strokeTravel or 0) + math.abs(dx)
        end
        task.toolAngle = -0.72 + clamp((x - point.x) / 70, -0.34, 0.34)
    elseif definition.gesture == "rotate" then
        local radius = distance(point.x, point.y, x, y)
        if radius >= 10 then
            local angle = math.atan2(y - point.y, x - point.x)
            if task.lastMouseAngle then
                local delta = normalizeAngle(angle - task.lastMouseAngle)
                if math.abs(delta) < 0.85 then
                    task.rotationTravel = (task.rotationTravel or 0) + math.abs(delta)
                    task.pointProgress = clamp(task.rotationTravel /
                        motionGoal(task, definition), 0, 1)
                end
            end
            task.lastMouseAngle = angle
            task.toolAngle = angle + math.pi * 0.25
        end
    elseif definition.gesture == "adjust" then
        task.adjustValue = clamp((task.adjustValue or 0) + dx * 0.005, 0, 1)
        task.pointProgress = clamp(1 - math.abs(task.adjustValue - 0.5) * 2, 0, 1)
        task.toolAngle = -0.55 + (task.adjustValue - 0.5) * 0.9
    end
    task.lastMouseX, task.lastMouseY = x, y
    if (definition.gesture == "stroke" or definition.gesture == "rotate")
        and task.pointProgress >= 1 then
        completePoint(task)
    end
    return true
end

function RepairMinigame.mousereleased(task, x, y)
    if not task then return nil end
    local definition = RepairMinigame.definition(task)
    if task.partDragging then
        task.partDragging = false
        if distance(definition.target.x, definition.target.y, x, y) <= 58 then
            installPart(task)
        else
            task.partX, task.partY = partStart.x, partStart.y
            setFeedback(task, "The part missed the motorcycle. Try the glowing silhouette.", "error")
        end
        return nil
    end
    if task.toolDragging then
        task.toolDragging = false
        local point = RepairMinigame.activePoint(task)
        if point and distance(point.x, point.y, x, y) <= 58 then
            if not engageSelectedTool(task) then
                local slot = slotFor(task.selectedTool)
                task.toolX, task.toolY = slot.x, slot.y
            end
        else
            local slot = slotFor(task.selectedTool)
            task.toolX, task.toolY = slot.x, slot.y
            setFeedback(task, "Move the tool onto the pulsing work point.", "error")
        end
        return nil
    end
    if task.phase == "operate" and task.toolOperating then
        task.toolOperating = false
        if definition.gesture == "adjust" then
            if task.adjustValue >= task.bandLow and task.adjustValue <= task.bandHigh then
                completePoint(task)
            else
                setFeedback(task, "Release while the marker is inside the green band.", "error")
            end
        elseif definition.gesture == "hold" then
            if task.fillValue >= task.bandLow and task.fillValue <= task.bandHigh then
                completePoint(task)
            else
                local overfilled = task.fillValue > task.bandHigh
                task.fillValue = overfilled and 0.28 or task.fillValue
                task.pointProgress = task.fillValue
                setFeedback(task, overfilled
                    and "Too full. The level settled back; try a shorter pour."
                    or "Keep holding until the level reaches green.", "error")
            end
        end
    end
    return nil
end

function RepairMinigame.update(task, dt)
    if not task then return end
    if task.feedbackTimer and task.feedbackTimer > 0 then
        task.feedbackTimer = math.max(0, task.feedbackTimer - dt)
    end
    if task.phase ~= "operate" or not task.toolOperating then return end
    local definition = RepairMinigame.definition(task)
    if definition.gesture == "hold" then
        task.fillValue = clamp((task.fillValue or 0) + dt / (definition.holdSeconds or 1.6), 0, 1.18)
        task.pointProgress = task.fillValue
        task.toolAngle = -0.34 - math.min(task.fillValue, 1) * 0.22
    end
end

local function keyboardCompleteMotion(task, button)
    local definition = RepairMinigame.definition(task)
    if task.keyboardDirection ~= button then
        task.keyboardDirection = button
        local amount = 1 / math.max(2, math.ceil(motionGoal(task, definition)))
        task.pointProgress = clamp(task.pointProgress + amount, 0, 1)
        task.toolAngle = button == "left" and -0.88 or -0.42
        if task.pointProgress >= 1 then completePoint(task) end
    end
end

function RepairMinigame.pressButton(task, button)
    if not task then return nil end
    local definition = RepairMinigame.definition(task)
    if task.phase == "inspect" then
        if button == "ok" then return "repair" end
        return nil
    end
    if task.phase == "part" then
        if button == "ok" then installPart(task) end
        return nil
    end
    if task.phase == "tool" then
        local directIndex = tostring(button):match("^tool(%d)$")
        if directIndex then
            task.toolIndex = clamp(tonumber(directIndex), 1, #RepairTasks.tools())
            chooseTool(task, RepairTasks.tools()[task.toolIndex])
        elseif button == "left" or button == "up" then
            task.toolIndex = ((task.toolIndex - 2) % #RepairTasks.tools()) + 1
            chooseTool(task, RepairTasks.tools()[task.toolIndex])
        elseif button == "right" or button == "down" then
            task.toolIndex = (task.toolIndex % #RepairTasks.tools()) + 1
            chooseTool(task, RepairTasks.tools()[task.toolIndex])
        elseif button == "ok" then
            if not task.selectedTool then chooseTool(task, RepairTasks.tools()[task.toolIndex]) end
            engageSelectedTool(task)
        end
        return nil
    end
    if task.phase ~= "operate" then return nil end
    if definition.gesture == "stroke" or definition.gesture == "rotate" then
        if button == "left" or button == "right" then keyboardCompleteMotion(task, button) end
    elseif definition.gesture == "adjust" then
        if button == "left" then task.adjustValue = clamp(task.adjustValue - 0.08, 0, 1) end
        if button == "right" then task.adjustValue = clamp(task.adjustValue + 0.08, 0, 1) end
        task.pointProgress = clamp(1 - math.abs(task.adjustValue - 0.5) * 2, 0, 1)
        if button == "ok" then
            if task.adjustValue >= task.bandLow and task.adjustValue <= task.bandHigh then
                completePoint(task)
            else
                setFeedback(task, "Center the marker inside the green band first.", "error")
            end
        end
    elseif definition.gesture == "hold" and button == "ok" then
        task.fillValue = (task.fillValue or 0) + 0.22
        task.pointProgress = task.fillValue
        if task.fillValue >= task.bandLow and task.fillValue <= task.bandHigh then
            completePoint(task)
        elseif task.fillValue > task.bandHigh then
            task.fillValue, task.pointProgress = 0.28, 0.28
            setFeedback(task, "Too full. Try stopping in the green band.", "error")
        end
    end
    return nil
end

return RepairMinigame
