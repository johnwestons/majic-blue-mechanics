local Jobs = require("src.jobs")
local Ui = require("src.screens.ui")

local RepairMinigameScreen = {}

local taskNames = {
    oil = { kind = "oil", location = "oil filter", verb = "Seat the filter" },
    brake = { kind = "brake", location = "front caliper", verb = "Set the brake pad" },
    chain = { kind = "chain", location = "rear sprocket", verb = "Route the chain" },
    stator = { kind = "stator", location = "charging connector", verb = "Seat the stator lead" },
    suspension = { kind = "suspension", location = "fork adjuster", verb = "Set the preload" },
    belt = { kind = "belt", location = "drive pulley", verb = "Align the belt" },
    spoke = { kind = "spoke", location = "rear wheel", verb = "Balance the spoke" },
    carb = { kind = "carb", location = "carburetor bank", verb = "Sync the carburetors" },
    magneto = { kind = "magneto", location = "magneto points", verb = "Set the points" },
    coolant = { kind = "coolant", location = "radiator neck", verb = "Seat the coolant cap" },
}

local targetLocations = {
    oil = { x = 390, y = 330 }, brake = { x = 385, y = 250 },
    chain = { x = 260, y = 355 }, stator = { x = 360, y = 350 },
    suspension = { x = 390, y = 245 }, belt = { x = 285, y = 345 },
    spoke = { x = 265, y = 370 }, carb = { x = 365, y = 320 },
    magneto = { x = 350, y = 340 }, coolant = { x = 390, y = 270 },
}

local faultCodes = {
    oil = "P0524", brake = "C1234", chain = "P0722", stator = "P0562",
    suspension = "C1513", belt = "P0505", spoke = "C0040", carb = "P0171",
    magneto = "P0351", coolant = "P0217", tool = "P0000",
}

local readerLayout = { x = 530, y = 145, scale = 1.08 }

local function serviceKind(job)
    local service = string.lower((job and job.service) or "")
    local partText = string.lower(table.concat((job and job.parts) or {}, " "))
    local haystack = service .. " " .. partText
    for keyword, task in pairs(taskNames) do
        if haystack:find(keyword, 1, true) then return keyword, task end
    end
    return "tool", { kind = "tool", location = "service mark", verb = "Place the tool" }
end

local function taskFor(job, action)
    local keyword, task = serviceKind(job)
    local target = targetLocations[keyword] or { x = 350, y = 300 }
    local label
    if action == "diagnose" then
        label = "Press the orange OK button on the code reader to scan this bike."
    elseif action == "repair" then
        label = task.verb .. " at the " .. task.location .. "."
    else
        label = "Move the test marker through the service gate."
    end
    return {
        action = action,
        kind = action == "road_test" and "road" or task.kind,
        label = label,
        targetLabel = task.location,
        targetX = target.x,
        targetY = target.y,
        tokenX = 700,
        tokenY = 486,
        startX = 700,
        startY = 486,
        dragging = false,
        complete = false,
        reader = action == "diagnose" and {
            step = 0,
            menu = 1,
            faultCode = faultCodes[keyword] or faultCodes.tool,
            location = task.location,
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

local function distance(x1, y1, x2, y2)
    local dx, dy = x1 - x2, y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

local function tokenAt(task, x, y)
    return distance(task.tokenX, task.tokenY, x, y) <= 42
end

local function targetContains(task, x, y)
    return x >= task.targetX - 52 and x <= task.targetX + 52
        and y >= task.targetY - 42 and y <= task.targetY + 42
end

local function readerButtonAt(x, y)
    local px = (x - readerLayout.x) / readerLayout.scale
    local py = (y - readerLayout.y) / readerLayout.scale
    if px >= 146 and px <= 207 and py >= 198 and py <= 247 then return "ok" end
    if px >= 54 and px <= 116 and py >= 198 and py <= 247 then return "back" end
    if px >= 98 and px <= 159 and py >= 143 and py <= 184 then return "up" end
    if px >= 98 and px <= 159 and py >= 181 and py <= 218 then return "down" end
    if px >= 52 and px <= 99 and py >= 157 and py <= 200 then return "left" end
    if px >= 158 and px <= 207 and py >= 157 and py <= 200 then return "right" end
end

function RepairMinigameScreen.pressButton(state, button)
    local task = state.repairMinigame
    if not task or task.action ~= "diagnose" or not task.reader then return nil end
    local reader = task.reader
    if button == "up" then reader.menu = math.max(1, reader.menu - 1) return nil end
    if button == "down" then reader.menu = math.min(2, reader.menu + 1) return nil end
    if button == "back" then
        reader.step = math.max(0, reader.step - 1)
        return nil
    end
    if button == "ok" then
        if reader.step < 3 then
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
    if tokenAt(task, x, y) then
        task.dragging = true
        task.grabOffsetX, task.grabOffsetY = x - task.tokenX, y - task.tokenY
        return true
    end
    return false
end

function RepairMinigameScreen.mousemoved(state, x, y)
    local task = state.repairMinigame
    if not task or not task.dragging then return false end
    task.tokenX = x - (task.grabOffsetX or 0)
    task.tokenY = y - (task.grabOffsetY or 0)
    return true
end

function RepairMinigameScreen.mousereleased(state, x, y)
    local task = state.repairMinigame
    if task and task.action == "diagnose" then return nil end
    if not task or not task.dragging then return nil end
    task.dragging = false
    if targetContains(task, x, y) then
        task.tokenX, task.tokenY, task.complete = task.targetX, task.targetY, true
        return task.action
    end
    task.tokenX, task.tokenY = task.startX, task.startY
    state.message = "That placement missed. Drag the highlighted sprite to the target."
    return nil
end

function RepairMinigameScreen.hit(x, y)
    if Ui.contains(694, 566, 144, 38, x, y) then return "cancel" end
end

local function drawToolSprite(kind, x, y, scale, active)
    scale = scale or 1
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.scale(scale, scale)
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

local function drawTarget(task)
    love.graphics.setColor(0.28, 0.77, 0.73, 0.20)
    love.graphics.rectangle("fill", task.targetX - 52, task.targetY - 42, 104, 84, 5, 5)
    love.graphics.setColor(0.42, 0.90, 0.82, 0.95)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", task.targetX - 52, task.targetY - 42, 104, 84, 5, 5)
    drawToolSprite(task.kind, task.targetX, task.targetY, 0.62, false)
end

local function readerFrame(task)
    local step = task.reader and task.reader.step or 0
    if step <= 0 then return 1 end
    if step == 1 then return 2 end
    if step == 2 then return 2 + (math.floor(love.timer.getTime() * 5) % 2) end
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
        local positions = {
            ok = { 146, 198, 61, 49 }, back = { 54, 198, 62, 49 },
            up = { 98, 143, 61, 41 }, down = { 98, 181, 61, 37 },
            left = { 52, 157, 47, 43 }, right = { 158, 157, 49, 43 },
        }
        local box = positions[button]
        if box then
            love.graphics.setColor(0.42, 0.90, 0.82, 0.26)
            love.graphics.rectangle("fill", readerLayout.x + box[1] * readerLayout.scale,
                readerLayout.y + box[2] * readerLayout.scale,
                box[3] * readerLayout.scale, box[4] * readerLayout.scale, 4, 4)
        end
    end
    local step = task.reader.step
    if step < 3 then
        Ui.label("Mode: " .. (task.reader.menu == 1 and "READ DTC" or "LIVE DATA"),
            540, 408, 268, { 0.75, 0.82, 0.80 }, "center")
    end
    if step == 0 then
        Ui.label("Press the orange OK button to power on.", 540, 430, 268,
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

function RepairMinigameScreen.draw(state, assets, mouseX, mouseY)
    local job = selectedJob(state)
    local task = state.repairMinigame
    Ui.panel(72, 42, 816, 594, "REPAIR ACTION  •  " .. (job and job.id or "NO ACTIVE BIKE"))
    if not job or not task then
        Ui.label("No repair action is active.", 130, 170, 700, { 0.92, 0.62, 0.50 }, "center")
        Ui.button(694, 566, 144, 38, "Back", "ESC", mouseX, mouseY)
        return
    end

    local bikeKey = Jobs.ensureBikeSprite(job)
    local bike = bikeKey and assets.get("motorcycleService_" .. bikeKey)
    bike = bike or assets.get("motorcycleSide")
    if bike then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(bike, 112, 128, 0, 0.78, 0.78)
    end
    Ui.label(job.bike.make .. " " .. job.bike.model, 112, 394, 370, { 0.90, 0.84, 0.57 })
    Ui.label(task.action == "diagnose"
        and "Use the code reader buttons to inspect the ECU."
        or "Move the highlighted service sprite to the target on the bike.",
        112, 425, 370, { 0.68, 0.78, 0.77 })
    Ui.label(task.label, 112, 454, 370, { 0.58, 0.90, 0.92 })

    love.graphics.setColor(0.07, 0.12, 0.13, 0.95)
    love.graphics.rectangle("fill", 510, 112, 328, 410, 5, 5)
    if task.action == "diagnose" then
        drawCodeReader(task, assets, mouseX, mouseY, job)
        Ui.button(694, 566, 144, 38, "Cancel", "ESC", mouseX, mouseY)
        return
    end
    Ui.label("SERVICE TARGET", 540, 140, 268, { 0.90, 0.84, 0.57 }, "center")
    drawTarget(task)
    drawToolSprite(task.kind, task.tokenX, task.tokenY, 0.90, task.dragging)
    Ui.label("DRAG THIS", task.tokenX - 52, task.tokenY + 32, 104,
        { 0.82, 0.86, 0.82 }, "center")
    Ui.label("Target: " .. task.targetLabel, 540, 390, 268, { 0.75, 0.82, 0.80 }, "center")
    Ui.label("Mouse: drag sprite   •   Escape: cancel", 540, 448, 268,
        { 0.56, 0.64, 0.62 }, "center")
    Ui.button(694, 566, 144, 38, "Cancel", "ESC", mouseX, mouseY)
end

return RepairMinigameScreen
