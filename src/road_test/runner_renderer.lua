local Config = require("src.config")

local RunnerRenderer = {}
local settings = Config.roadTest.runner
local roadMesh
local sideMeshes = {}

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function projectionAt(relativeZ)
    local z = clamp(relativeZ, settings.nearClip, settings.farClip)
    local nearInverse = 1 / settings.nearClip
    local farInverse = 1 / settings.farClip
    local amount = (1 / z - farInverse) / (nearInverse - farInverse)
    amount = clamp(amount, 0, 1)
    return {
        amount = amount,
        y = settings.horizonY + (settings.bottomY - settings.horizonY) * amount,
        halfWidth = settings.farHalfWidth
            + (settings.nearHalfWidth - settings.farHalfWidth) * amount,
    }
end

local function roadVertices(cameraDistance)
    local vertices = {}
    local nearInverse = 1 / settings.nearClip
    local farInverse = 1 / settings.farClip
    for index = 0, settings.roadSlices do
        local amount = index / settings.roadSlices
        local inverseZ = farInverse + (nearInverse - farInverse) * amount
        local relativeZ = 1 / inverseZ
        local y = settings.horizonY + (settings.bottomY - settings.horizonY) * amount
        local halfWidth = settings.farHalfWidth
            + (settings.nearHalfWidth - settings.farHalfWidth) * amount
        local textureV = (cameraDistance + relativeZ) / settings.roadTextureWorldLength
        vertices[#vertices + 1] = {
            settings.centerX - halfWidth, y, 0, textureV, 1, 1, 1, 1,
        }
        vertices[#vertices + 1] = {
            settings.centerX + halfWidth, y, 1, textureV, 1, 1, 1, 1,
        }
    end
    return vertices
end

local function drawHorizon(assets)
    local image = assets.get("roadTestRunnerHorizon")
    if not image then
        love.graphics.setColor(0.32, 0.67, 0.86)
        love.graphics.rectangle("fill", 0, 0, Config.baseWidth, settings.horizonY + 8)
        return
    end
    local scale = Config.baseWidth / image:getWidth()
    local x = Config.baseWidth * 0.5 - image:getWidth() * 0.5 * scale
    local y = settings.horizonY - settings.horizonSourceY * scale
    -- Keep only the sky and the tiny distant vanishing-point scenery from the
    -- original street card. The projected side sections own everything below.
    love.graphics.setScissor(0, 0, Config.baseWidth, settings.horizonY + 2)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(image, x, y, 0, scale, scale)
    love.graphics.setScissor()
end

local function drawCityHorizon(assets)
    local city = assets.get("roadTestRunnerCity")
    if not city then return end
    local scale = Config.baseWidth / city:getWidth()
    local x = Config.baseWidth * 0.5 - city:getWidth() * 0.5 * scale
    local y = settings.cityScreenGroundY - settings.citySourceGroundY * scale
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(city, x, y, 0, scale, scale)
end

local function drawRoadLine(farProjection, nearProjection, farCenterX, nearCenterX,
        farHalfWidth, nearHalfWidth)
    love.graphics.polygon("fill",
        farCenterX - farHalfWidth, farProjection.y,
        farCenterX + farHalfWidth, farProjection.y,
        nearCenterX + nearHalfWidth, nearProjection.y,
        nearCenterX - nearHalfWidth, nearProjection.y)
end

local function drawLaneMarkings(task)
    love.graphics.setColor(0.84, 0.82, 0.73, 0.96)
    local farProjection = projectionAt(settings.farClip)
    local nearProjection = projectionAt(settings.nearClip)
    for _, side in ipairs({ -1, 1 }) do
        local farCenter = settings.centerX + side * farProjection.halfWidth
            * settings.edgeLinePositionRatio
        local nearCenter = settings.centerX + side * nearProjection.halfWidth
            * settings.edgeLinePositionRatio
        drawRoadLine(farProjection, nearProjection, farCenter, nearCenter,
            math.max(0.5, farProjection.halfWidth * settings.edgeLineHalfWidthRatio),
            nearProjection.halfWidth * settings.edgeLineHalfWidthRatio)
    end

    local cameraDistance = task.cameraDistance or 0
    local firstDash = math.floor((cameraDistance + settings.nearClip)
        / settings.centerDashPeriod) - 1
    local lastDash = math.ceil((cameraDistance + settings.farClip)
        / settings.centerDashPeriod) + 1
    for slot = firstDash, lastDash do
        local worldNear = slot * settings.centerDashPeriod
        local worldFar = worldNear + settings.centerDashLength
        local relativeNear = clamp(worldNear - cameraDistance,
            settings.nearClip, settings.farClip)
        local relativeFar = clamp(worldFar - cameraDistance,
            settings.nearClip, settings.farClip)
        if worldFar - cameraDistance >= settings.nearClip
                and worldNear - cameraDistance <= settings.farClip then
            local projectedNear = projectionAt(relativeNear)
            local projectedFar = projectionAt(relativeFar)
            drawRoadLine(projectedFar, projectedNear, settings.centerX, settings.centerX,
                math.max(0.45, projectedFar.halfWidth
                    * settings.centerLineHalfWidthRatio),
                projectedNear.halfWidth * settings.centerLineHalfWidthRatio)
        end
    end
end

local function drawRoad(task, assets)
    local texture = assets.get("roadTestRunnerRoad")
    if not texture then
        love.graphics.setColor(0.20, 0.20, 0.19)
        love.graphics.polygon("fill",
            settings.centerX - settings.farHalfWidth, settings.horizonY,
            settings.centerX + settings.farHalfWidth, settings.horizonY,
            settings.centerX + settings.nearHalfWidth, settings.bottomY,
            settings.centerX - settings.nearHalfWidth, settings.bottomY)
        return
    end

    local vertices = roadVertices(task.cameraDistance or 0)
    if not roadMesh then
        roadMesh = love.graphics.newMesh(vertices, "strip", "dynamic")
        roadMesh:setTexture(texture)
    else
        roadMesh:setVertices(vertices)
        roadMesh:setTexture(texture)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(roadMesh)
end

local function sectionPoint(relativeZ, side, nearHeight)
    local projection = projectionAt(relativeZ)
    local perspectiveScale = projection.halfWidth / settings.nearHalfWidth
    return {
        x = settings.centerX + side * projection.halfWidth
            * settings.sectionRoadEdgeRatio,
        bottomY = projection.y,
        topY = projection.y - nearHeight * perspectiveScale,
    }
end

local function sectionVertices(side, segmentNearZ, visibleNearZ, visibleFarZ,
        nearHeight, vTop, vBottom)
    local vertices = {}
    -- Render narrow vertical depth columns. Each column keeps the artwork's
    -- vertical proportions intact while its ground position and scale follow
    -- the same inverse-depth curve as the road. This avoids bending doors,
    -- fence posts, and roof panels across one oversized trapezoid.
    for index = settings.sectionSlices - 1, 0, -1 do
        local farAmount = (index + 1) / settings.sectionSlices
        local nearAmount = index / settings.sectionSlices
        local farZ = visibleFarZ
            + (visibleNearZ - visibleFarZ) * farAmount
        local nearZ = visibleFarZ
            + (visibleNearZ - visibleFarZ) * nearAmount
        local farPoint = sectionPoint(farZ, side, nearHeight)
        local nearPoint = sectionPoint(nearZ, side, nearHeight)
        local centerPoint = sectionPoint((farZ + nearZ) * 0.5, side, nearHeight)
        local uFar = clamp((farZ - segmentNearZ) / settings.sectionLength, 0, 1)
        local uNear = clamp((nearZ - segmentNearZ) / settings.sectionLength, 0, 1)
        vertices[#vertices + 1] = {
            farPoint.x, centerPoint.topY, uFar, vTop, 1, 1, 1, 1,
        }
        vertices[#vertices + 1] = {
            farPoint.x, farPoint.bottomY, uFar, vBottom, 1, 1, 1, 1,
        }
        vertices[#vertices + 1] = {
            nearPoint.x, centerPoint.topY, uNear, vTop, 1, 1, 1, 1,
        }
        vertices[#vertices + 1] = {
            nearPoint.x, centerPoint.topY, uNear, vTop, 1, 1, 1, 1,
        }
        vertices[#vertices + 1] = {
            farPoint.x, farPoint.bottomY, uFar, vBottom, 1, 1, 1, 1,
        }
        vertices[#vertices + 1] = {
            nearPoint.x, nearPoint.bottomY, uNear, vBottom, 1, 1, 1, 1,
        }
    end
    return vertices
end

local function drawSection(meshIndex, image, vertices)
    local mesh = sideMeshes[meshIndex]
    if not mesh then
        mesh = love.graphics.newMesh(vertices, "triangles", "dynamic")
        sideMeshes[meshIndex] = mesh
    else
        mesh:setVertices(vertices)
    end
    mesh:setTexture(image)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(mesh)
end

local function visibleSectionRange(cameraDistance)
    local firstSlot = math.floor((cameraDistance + settings.nearClip)
        / settings.sectionLength)
    local lastSlot = math.floor((cameraDistance + settings.farClip)
        / settings.sectionLength)
    return firstSlot, lastSlot
end

local function drawSideSections(task, assets)
    local leftImage = assets.get("roadTestRunnerLeftSection")
    local rightImage = assets.get("roadTestRunnerRightSection")
    if not leftImage or not rightImage then return end

    local cameraDistance = task.cameraDistance or 0
    local firstSlot, lastSlot = visibleSectionRange(cameraDistance)
    local meshIndex = 0
    -- Draw far-to-near. Every neighboring section uses the same projected
    -- world boundary, so its ground line and vertical seam meet exactly.
    for slot = lastSlot, firstSlot, -1 do
        local segmentNearZ = slot * settings.sectionLength - cameraDistance
        local segmentFarZ = segmentNearZ + settings.sectionLength
        local visibleNearZ = math.max(segmentNearZ, settings.nearClip)
        local visibleFarZ = math.min(segmentFarZ, settings.farClip)
        if visibleNearZ < visibleFarZ then
            meshIndex = meshIndex + 1
            drawSection(meshIndex, leftImage,
                sectionVertices(-1, segmentNearZ, visibleNearZ, visibleFarZ,
                    settings.leftSectionNearHeight, settings.leftSectionVTop,
                    settings.leftSectionVBottom))
            meshIndex = meshIndex + 1
            drawSection(meshIndex, rightImage,
                sectionVertices(1, segmentNearZ, visibleNearZ, visibleFarZ,
                    settings.rightSectionNearHeight, settings.rightSectionVTop,
                    settings.rightSectionVBottom))
        end
    end
end

local function drawGraffiti(task, assets)
    local cameraDistance = task.cameraDistance or 0
    local firstSlot, lastSlot = visibleSectionRange(cameraDistance)
    local count = #(Config.paths.roadTest.runnerGraffiti or {})
    if count == 0 then return end

    for slot = firstSlot, lastSlot do
        if slot % 2 == 0 then
            local segmentNearZ = slot * settings.sectionLength - cameraDistance
            for sideIndex, placementSide in ipairs({ -1, 1 }) do
                local relativeZ = segmentNearZ + settings.sectionLength
                    * (placementSide < 0 and 0.50 or 0.68)
                if relativeZ >= settings.nearClip and relativeZ <= settings.farClip then
                    local projection = projectionAt(relativeZ)
                    if projection.amount >= settings.graffitiMinimumAmount then
                        local graffitiIndex = (math.abs(slot * 5 + sideIndex) % count) + 1
                        local image = assets.get("roadTestGraffiti"
                            .. string.format("%02d", graffitiIndex))
                        if image then
                            local perspectiveScale = projection.halfWidth
                                / settings.nearHalfWidth
                            local width = settings.graffitiFarWidth
                                + (settings.graffitiNearWidth - settings.graffitiFarWidth)
                                    * projection.amount ^ 0.86
                            local scale = width / image:getWidth()
                            local roadEdge = settings.centerX + placementSide
                                * projection.halfWidth * settings.sectionRoadEdgeRatio
                            local x = roadEdge + placementSide
                                * settings.graffitiWallInset * perspectiveScale
                            local y = projection.y - 22 * perspectiveScale
                            love.graphics.setColor(1, 1, 1, 0.94)
                            love.graphics.draw(image, x, y, 0, scale, scale,
                                image:getWidth() * 0.5, image:getHeight())
                        end
                    end
                end
            end
        end
    end
end

local function drawTraffic(task, assets)
    local cars = task.traffic or {}
    if #cars == 0 then return end

    local cameraDistance = task.cameraDistance or 0
    local drawOrder = {}
    for index, car in ipairs(cars) do
        drawOrder[#drawOrder + 1] = { index = index, relativeZ = car.worldZ - cameraDistance }
    end
    table.sort(drawOrder, function(left, right)
        return left.relativeZ > right.relativeZ
    end)

    for _, entry in ipairs(drawOrder) do
        local car = cars[entry.index]
        local relativeZ = entry.relativeZ
        if relativeZ >= settings.nearClip and relativeZ <= settings.farClip then
            local image = assets.get("roadTestTraffic"
                .. string.format("%02d", car.spriteIndex))
            if image then
                local projection = projectionAt(relativeZ)
                local perspectiveScale = projection.halfWidth / settings.nearHalfWidth
                local width = Config.roadTest.traffic.farWidth
                    + (Config.roadTest.traffic.nearWidth - Config.roadTest.traffic.farWidth)
                    * projection.amount ^ 0.88
                local scale = width / image:getWidth()
                    * (Config.roadTest.traffic.spriteScale or 1)
                local x = settings.centerX + car.lane
                    * Config.roadTest.traffic.laneHalfWidth * perspectiveScale
                local y = projection.y + 3 * perspectiveScale
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(image, x, y, 0, scale, scale,
                    image:getWidth() * 0.5, image:getHeight())
            end
        end
    end
end

function RunnerRenderer.draw(task, assets)
    drawHorizon(assets)
    drawCityHorizon(assets)
    drawSideSections(task, assets)
    drawGraffiti(task, assets)
    drawRoad(task, assets)
    drawLaneMarkings(task)
    drawTraffic(task, assets)
end

function RunnerRenderer.debugSnapshot(task)
    local cameraDistance = task.cameraDistance or 0
    local firstSlot, lastSlot = visibleSectionRange(cameraDistance)
    return {
        cameraDistance = cameraDistance,
        sectionCount = math.max(0, lastSlot - firstSlot + 1) * 2,
        near = projectionAt(settings.nearClip),
        far = projectionAt(settings.farClip),
        vertexCount = (settings.roadSlices + 1) * 2,
    }
end

function RunnerRenderer.release()
    if roadMesh and roadMesh.release then roadMesh:release() end
    roadMesh = nil
    for _, mesh in ipairs(sideMeshes) do
        if mesh and mesh.release then mesh:release() end
    end
    sideMeshes = {}
end

return RunnerRenderer
