local Config = require("src.config")
local Jobs = require("src.jobs")
local RunnerRenderer = require("src.road_test.runner_renderer")
local Ui = require("src.screens.ui")
local BackButton = require("src.screens.back_button")

local RoadTestScreen = {}
local CLOSE = { x = 790, y = 104, width = 140, height = 38 }
local settings = Config.roadTest
local trafficSettings = settings.traffic

local trafficLanes = { -1, 0, 1, 0, 1, -1, 0, 1, -1, 0 }

local function buildTraffic()
    local traffic = {}
    local paths = Config.paths.roadTest.traffic or {}
    if #paths == 0 then return traffic end

    local distance = trafficSettings.startDistance
    local index = 1
    while distance < settings.courseLength - settings.arrivalLength do
        local jitter = ((index * 97) % 11 - 5) / 5
        traffic[#traffic + 1] = {
            worldZ = distance + jitter * trafficSettings.spacingJitter,
            lane = trafficLanes[((index - 1) % #trafficLanes) + 1],
            spriteIndex = ((index - 1) % #paths) + 1,
            hit = false,
        }
        distance = distance + trafficSettings.spacing
        index = index + 1
    end
    return traffic
end

local function selectedJob(state)
    for _, job in ipairs(state.jobs.active or {}) do
        if job.id == state.selectedJobId then return job end
    end
end

local function newTask(job)
    return {
        jobId = job.id,
        bikeKey = Jobs.ensureBikeSprite(job),
        distance = 0,
        speed = 0,
        lane = 0,
        lean = 0,
        depth = 0,
        cameraDistance = 0,
        cameraSpeed = 0,
        elapsed = 0,
        countdown = 1.35,
        status = "running",
        traffic = buildTraffic(),
        trafficHits = 0,
        trafficHitTimer = 0,
        trafficHitElapsed = 0,
    }
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function playerY(task)
    local amount = clamp(task.depth or 0, 0, 1) ^ 0.72
    return settings.bikeY - 230 * amount
end

local function depthScale(task)
    -- The previous endpoint was 58% scale; the new endpoint is 20% smaller
    -- than that, making the approach to the garage more visually pronounced.
    return 1.0 - 0.536 * clamp(task.depth or 0, 0, 1)
end

local function bikeX(task)
    return 480 + task.lane * (settings.roadWidth * 0.5 - 38)
end

local function updateTraffic(task, dt)
    if not task.traffic then return end
    local delta = dt or 0
    task.trafficHitTimer = math.max(0, (task.trafficHitTimer or 0) - delta)
    if task.trafficHitTimer > 0 then
        task.trafficHitElapsed = (task.trafficHitElapsed or 0) + delta
    else
        task.trafficHitElapsed = 0
    end
    for _, car in ipairs(task.traffic) do
        if not car.hit then
            local relativeZ = car.worldZ - task.cameraDistance
            if relativeZ >= settings.runner.nearClip
                    and relativeZ <= trafficSettings.collisionDistance
                    and math.abs(task.lane - car.lane) <= trafficSettings.collisionLaneWidth
                    and task.trafficHitTimer <= 0 then
                task.speed = math.max(settings.cameraMinimumSpeed,
                    task.speed * trafficSettings.collisionSlowdown)
                task.cameraSpeed = math.min(task.cameraSpeed, task.speed
                    * (settings.scrollSpeedScale or 1))
                car.hit = true
                task.trafficHits = (task.trafficHits or 0) + 1
                task.trafficHitTimer = trafficSettings.hitCooldown
                task.trafficHitElapsed = 0
            end
        end
    end
end

local function drawBackground(image, zoom, alpha, sourceHorizonY, screenHorizonY)
    if not image then return false end
    zoom = zoom or 1
    local scale = Config.baseWidth / image:getWidth() * zoom
    local drawX = Config.baseWidth * 0.5 - image:getWidth() * 0.5 * scale
    local drawY = screenHorizonY - sourceHorizonY * scale
    love.graphics.setColor(1, 1, 1, alpha or 1)
    love.graphics.draw(image, drawX, drawY, 0, scale, scale)
    return true
end

local function drawCourseBackground(task, assets)
    local garage = assets.get("roadTestBackground")
    if not garage then
        love.graphics.setColor(0.07, 0.11, 0.12)
        love.graphics.rectangle("fill", 0, 0, Config.baseWidth, Config.baseHeight)
        return
    end

    local arrivalStart = settings.courseLength - settings.arrivalLength
    RunnerRenderer.draw(task, assets)
    if task.distance < settings.departureLength then
        local blendStart = settings.departureLength - settings.garageBlendDistance
        local blend = clamp((task.distance - blendStart) / settings.garageBlendDistance, 0, 1)
        drawBackground(garage, 1, 1 - blend,
            settings.garageSourceHorizonY, settings.garageScreenHorizonY)
        return
    end

    if task.distance > arrivalStart then
        local blend = clamp((task.distance - arrivalStart) / settings.garageBlendDistance, 0, 1)
        drawBackground(garage, 1, blend,
            settings.garageSourceHorizonY, settings.garageScreenHorizonY)
    end
end

local function drawRider(task, assets, x, y, scale, rotation)
    local rider = assets.get("roadTestRider")
    if task.trafficHitTimer and task.trafficHitTimer > 0 then
        local frame = math.min(4, math.floor((task.trafficHitElapsed or 0) / 0.11) + 1)
        rider = assets.get("roadTestRiderHit" .. string.format("%02d", frame)) or rider
    end
    if not rider then return end
    local riderScale = (150 / rider:getWidth()) * scale
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(rider, x, y + 5, rotation, riderScale, riderScale,
        rider:getWidth() * 0.5, rider:getHeight() * 0.84)
end

local function drawBike(task, assets)
    local image = assets.get("motorcycleRear_" .. task.bikeKey)
    image = image or assets.get("motorcycleService_" .. task.bikeKey)
    local x, y = bikeX(task), playerY(task)
    local scale = depthScale(task)
    local rotation = task.lean or 0
    if image then
        local imageScale = (190 / image:getWidth()) * scale
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(image, x, y, rotation, imageScale, imageScale,
            image:getWidth() * 0.5, image:getHeight() * 0.82)
    else
        love.graphics.setColor(0.12, 0.13, 0.14)
        love.graphics.rectangle("fill", x - 55 * scale, y - 100 * scale,
            110 * scale, 120 * scale, 16, 16)
        love.graphics.setColor(0.95, 0.18, 0.18)
        love.graphics.rectangle("fill", x - 24 * scale, y - 84 * scale,
            48 * scale, 12 * scale, 4, 4)
    end
    -- Lift the rider into the seat/handlebar pocket so the head and hands sit
    -- over the bike instead of dropping behind the rear bodywork.
    drawRider(task, assets, x, y - 54 * scale, scale, rotation)
end

function RoadTestScreen.begin(state)
    local job = selectedJob(state)
    if not job then
        state.message = "There is no active motorcycle in this service bay."
        return false
    end
    state.roadTest = newTask(job)
    state.screen = "road_test"
    return true
end

function RoadTestScreen.cancel(state)
    RunnerRenderer.release()
    state.roadTest = nil
    state.screen = "service"
end

function RoadTestScreen.retry(state)
    local job = selectedJob(state)
    if not job or not state.roadTest then return false end
    RunnerRenderer.release()
    state.roadTest = newTask(job)
    return true
end

function RoadTestScreen.finish(state)
    RunnerRenderer.release()
    state.roadTest = nil
end

function RoadTestScreen.update(state, dt, directionX, throttle, brake, sprint)
    local task = state.roadTest
    if not task or task.status ~= "running" then return nil end
    dt = math.min(math.max(dt or 0, 0), 0.05)
    if task.countdown > 0 then
        task.countdown = math.max(0, task.countdown - dt)
        return nil
    end

    task.elapsed = task.elapsed + dt
    local speedLimit = settings.maxSpeed * (sprint and settings.sprintMultiplier or 1)
    local acceleration = settings.acceleration * (sprint and settings.sprintMultiplier or 1)
    if throttle then
        task.speed = task.speed + acceleration * dt
    else
        task.speed = task.speed - settings.coasting * dt
    end
    if brake then task.speed = task.speed - settings.braking * dt end
    task.speed = clamp(task.speed, settings.cameraMinimumSpeed, speedLimit)

    -- Keep the bike's throttle response and displayed speed independent from
    -- the perceived scenery speed. The road test should feel brisk without
    -- making the walls and lane markings race past the rider.
    local scrollSpeedScale = settings.scrollSpeedScale or 1
    local worldTargetSpeed = task.speed * scrollSpeedScale
    local cameraBlend = math.min(1, dt * settings.cameraResponse)
    task.cameraSpeed = task.cameraSpeed + (worldTargetSpeed - task.cameraSpeed) * cameraBlend
    task.cameraDistance = task.cameraDistance + task.cameraSpeed * dt

    -- Endless-runner framing: the camera catches the rider and keeps the bike
    -- in the lower-middle of the screen while the road streams toward it.
    -- Slowing still lets the bike fall back toward the viewer.
    local speedRatio = clamp(math.max(task.speed, 0) / settings.maxSpeed, 0, 1)
    local targetDepth = settings.cameraRiderDepthBase
        + settings.cameraRiderDepthRange * speedRatio
    local depthBlend = math.min(1, dt * settings.depthResponse)
    task.depth = task.depth + (targetDepth - task.depth) * depthBlend

    local steeringAmount = settings.steering * (0.45 + math.min(math.abs(task.speed) / settings.maxSpeed, 1))
    task.lane = clamp(task.lane + directionX * steeringAmount * dt, -0.94, 0.94)
    local speedFactor = 0.35 + 0.65 * math.min(math.abs(task.speed) / settings.maxSpeed, 1)
    local targetLean = directionX * settings.maxLean * speedFactor
    local leanBlend = math.min(1, dt * settings.leanResponse)
    task.lean = task.lean + (targetLean - task.lean) * leanBlend
    task.distance = clamp(task.distance + task.cameraSpeed * dt, 0, settings.courseLength)
    updateTraffic(task, dt)
    if task.distance >= settings.courseLength then
        task.distance = settings.courseLength
        task.speed = 0
        task.cameraSpeed = 0
        task.status = "review"
    end
    return nil
end

function RoadTestScreen.draw(state, assets, mouseX, mouseY)
    local job = selectedJob(state)
    local task = state.roadTest
    love.graphics.setColor(1, 1, 1)
    if not task or not job then
        Ui.panel(72, 42, 816, 594, "ROAD TEST")
        Ui.label("No road test is active.", 150, 260, 660, { 0.92, 0.62, 0.50 }, "center")
        BackButton.draw(CLOSE, "BACK", mouseX, mouseY)
        return
    end

    drawCourseBackground(task, assets)
    drawBike(task, assets)

    love.graphics.setColor(0.025, 0.035, 0.04, 0.92)
    love.graphics.rectangle("fill", 18, 16, 924, 70, 6, 6)
    love.graphics.setColor(0.25, 0.58, 0.66)
    love.graphics.rectangle("line", 18, 16, 924, 70, 6, 6)
    Ui.label("ROAD TEST  •  " .. job.id, 34, 28, 270, { 0.90, 0.84, 0.57 })
    Ui.label(job.bike.make .. " " .. job.bike.model, 34, 52, 300, { 0.68, 0.78, 0.77 })
    Ui.label(string.format("%03d km/h", math.max(0,
            math.floor(task.speed * settings.speedDisplayScale))),
        360, 28, 120, { 0.58, 0.90, 0.92 }, "center")
    Ui.label(string.format("MAX SPEED  %03d km/h",
            math.floor(settings.maxSpeed * settings.sprintMultiplier * settings.speedDisplayScale)),
        690, 28, 210, { 0.75, 0.82, 0.80 }, "right")

    love.graphics.setColor(0.06, 0.10, 0.11, 0.92)
    love.graphics.rectangle("fill", 34, 94, 220, 12, 3, 3)
    love.graphics.setColor(0.36, 0.84, 0.72)
    love.graphics.rectangle("fill", 34, 94, 220 * task.distance / settings.courseLength, 12, 3, 3)
    Ui.label(string.format("COURSE  %d%%", math.floor(task.distance / settings.courseLength * 100)),
        34, 112, 220, { 0.75, 0.82, 0.80 }, "center")
    BackButton.draw(CLOSE, "CANCEL TEST", mouseX, mouseY)

    if task.trafficHitTimer and task.trafficHitTimer > 0 then
        Ui.label("TRAFFIC CONTACT", 330, 112, 300, { 1.0, 0.54, 0.40 }, "center")
    end

    if task.countdown > 0 then
        love.graphics.setColor(0.025, 0.035, 0.04, 0.82)
        love.graphics.rectangle("fill", 185, 208, 590, 78, 6, 6)
        Ui.label("GET READY", 320, 222, 320, { 1.0, 0.84, 0.48 }, "center")
        Ui.label("AUTO FORWARD  •  W / UP accelerate  •  SHIFT max speed  •  A D / LEFT RIGHT steer",
            180, 252, 600,
            { 0.82, 0.86, 0.82 }, "center")
    end

    if task.status == "review" then
        love.graphics.setColor(0.025, 0.035, 0.04, 0.96)
        love.graphics.rectangle("fill", 220, 220, 520, 190, 8, 8)
        love.graphics.setColor(0.25, 0.58, 0.66)
        love.graphics.rectangle("line", 220, 220, 520, 190, 8, 8)
        Ui.label("ROAD TEST COMPLETE", 260, 246, 440, { 0.58, 0.92, 0.74 }, "center")
        Ui.label("Approve this result or re-do the test?", 260, 280, 440,
            { 0.78, 0.84, 0.80 }, "center")
        Ui.button(295, 330, 165, 42, "Approve", "A", mouseX, mouseY, true)
        Ui.button(500, 330, 165, 42, "Re-do", "R", mouseX, mouseY, true)
    end

    love.graphics.setColor(0.025, 0.035, 0.04, 0.94)
    love.graphics.rectangle("fill", 150, 630, 660, 34, 5, 5)
    Ui.label("W/UP accelerate  •  SHIFT max speed  •  S/DOWN brake  •  A/D steer  •  ESC cancel",
        166, 640, 628, { 0.90, 0.84, 0.57 }, "center")
end

function RoadTestScreen.hit(x, y)
    if BackButton.contains(CLOSE, x, y) then return "cancel" end
    if Ui.contains(295, 330, 165, 42, x, y) then return "approve" end
    if Ui.contains(500, 330, 165, 42, x, y) then return "redo" end
end

function RoadTestScreen.debugRunner(state)
    if not state.roadTest then return nil end
    return RunnerRenderer.debugSnapshot(state.roadTest)
end

return RoadTestScreen
