local Config = require("src.config")

local Assets = {
    images = {},
    data = {},
    quads = {},
    failures = {},
}

local function failure(path, message)
    Assets.failures[#Assets.failures + 1] = path .. ": " .. message
end

local function loadImage(key, path)
    if not love.filesystem.getInfo(path) then
        failure(path, "required image is missing")
        return
    end
    local ok, image = pcall(love.graphics.newImage, path)
    if not ok or not image then
        failure(path, tostring(image or "could not decode image"))
        return
    end
    image:setFilter("nearest", "nearest")
    Assets.images[key] = image
end

local function loadData(key, path)
    if not love.filesystem.getInfo(path) then
        failure(path, "required image data is missing")
        return
    end
    local ok, imageData = pcall(love.image.newImageData, path)
    if not ok or not imageData then
        failure(path, tostring(imageData or "could not decode image data"))
        return
    end
    Assets.data[key] = imageData
end

function Assets.load()
    Assets.releaseAll()
    Assets.images, Assets.data, Assets.quads, Assets.failures = {}, {}, {}, {}
    loadImage("workshop", Config.paths.workshop)
    loadData("walkmask", Config.paths.walkmask)
    loadImage("deliveryTruck", Config.paths.deliveryTruck)
    loadImage("truckCargoDoor", Config.paths.truckCargoDoor)
    loadImage("loadingBayDoor", Config.paths.loadingBayDoor)
    loadImage("motorcycleSide", Config.paths.motorcycleSide)
    loadImage("motorcyclePoster", Config.paths.motorcyclePoster)
    loadImage("motorcycleAction", Config.paths.motorcycleAction)
    for key, path in pairs(Config.paths.repairParts or {}) do
        loadImage("repairPart_" .. key, path)
    end
    for key, path in pairs(Config.paths.repairTools or {}) do
        loadImage("repairTool_" .. key, path)
    end
    for index, path in ipairs(Config.paths.diagnosticReader or {}) do
        loadImage("diagnosticReader" .. string.format("%02d", index), path)
    end
    if Config.paths.roadTest then
        loadImage("roadTestBackground", Config.paths.roadTest.background)
        loadImage("roadTestRunnerHorizon", Config.paths.roadTest.runnerHorizon)
        loadImage("roadTestRunnerRoad", Config.paths.roadTest.runnerRoad)
        loadImage("roadTestRunnerCity", Config.paths.roadTest.runnerCity)
        loadImage("roadTestRunnerLeftSection", Config.paths.roadTest.runnerLeftSection)
        loadImage("roadTestRunnerRightSection", Config.paths.roadTest.runnerRightSection)
        for index, path in ipairs(Config.paths.roadTest.runnerGraffiti or {}) do
            loadImage("roadTestGraffiti" .. string.format("%02d", index), path)
        end
        for index, path in ipairs(Config.paths.roadTest.traffic or {}) do
            loadImage("roadTestTraffic" .. string.format("%02d", index), path)
        end
        for index, path in ipairs(Config.paths.roadTest.riderHit or {}) do
            loadImage("roadTestRiderHit" .. string.format("%02d", index), path)
        end
        loadImage("roadTestRider", Config.paths.roadTest.rider)
        if Assets.images.roadTestRunnerRoad then
            Assets.images.roadTestRunnerRoad:setWrap("clamp", "repeat")
            Assets.images.roadTestRunnerRoad:setFilter("linear", "linear", 4)
        end
    end
    for key, paths in pairs(Config.paths.motorcycles or {}) do
        loadImage("motorcycleService_" .. key, paths.service)
        loadImage("motorcycleMounted_" .. key, paths.mounted)
        loadImage("motorcycleRear_" .. key, paths.rear)
    end

    local truck, cargo = Assets.images.deliveryTruck, Assets.images.truckCargoDoor
    local frameSize = Config.partsDelivery.frameSize
    local frameCount = Config.partsDelivery.cargoFrameCount
    if truck and (truck:getWidth() ~= frameSize or truck:getHeight() ~= frameSize) then
        failure(Config.paths.deliveryTruck, string.format(
            "expected %dx%d delivery-truck sprite", frameSize, frameSize))
    end
    if cargo then
        if cargo:getWidth() ~= frameSize * frameCount or cargo:getHeight() ~= frameSize then
            failure(Config.paths.truckCargoDoor, string.format(
                "expected %dx%d cargo-door strip", frameSize * frameCount, frameSize))
        else
            for frame = 1, frameCount do
                Assets.quads["truckCargoDoor" .. frame] = love.graphics.newQuad(
                    (frame - 1) * frameSize, 0, frameSize, frameSize,
                    cargo:getWidth(), cargo:getHeight())
            end
        end
    end
    local bayDoor = Assets.images.loadingBayDoor
    if bayDoor then
        local width = Config.loadingBay.frameWidth * Config.loadingBay.frameCount
        local height = Config.loadingBay.frameHeight
        if bayDoor:getWidth() ~= width or bayDoor:getHeight() ~= height then
            failure(Config.paths.loadingBayDoor, string.format(
                "expected %dx%d loading-bay door strip", width, height))
        else
            for frame = 1, Config.loadingBay.frameCount do
                Assets.quads["loadingBayDoor" .. frame] = love.graphics.newQuad(
                    (frame - 1) * Config.loadingBay.frameWidth, 0,
                    Config.loadingBay.frameWidth, Config.loadingBay.frameHeight,
                    width, height)
            end
        end
    end

    local workshop, walkmask = Assets.images.workshop, Assets.data.walkmask
    if workshop and walkmask then
        local workshopWidth, workshopHeight = workshop:getDimensions()
        local maskWidth, maskHeight = walkmask:getDimensions()
        if workshopWidth ~= maskWidth or workshopHeight ~= maskHeight then
            failure(Config.paths.walkmask, "must match the workshop image dimensions")
        end
    end
end

function Assets.get(key) return Assets.images[key] end
function Assets.getData(key) return Assets.data[key] end
function Assets.getQuad(key) return Assets.quads[key] end

function Assets.assertHealthy()
    return #Assets.failures == 0, table.concat(Assets.failures, "\n")
end

function Assets.textureBytes()
    local bytes = 0
    for _, image in pairs(Assets.images) do
        local width, height = image:getDimensions()
        bytes = bytes + width * height * 4
    end
    return bytes
end

function Assets.releaseAll()
    for _, image in pairs(Assets.images or {}) do
        if image.release then pcall(image.release, image) end
    end
    for _, imageData in pairs(Assets.data or {}) do
        if imageData.release then pcall(imageData.release, imageData) end
    end
end

return Assets
