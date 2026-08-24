local Anchors = require("src.character_anchors")
local Config = require("src.config")

local CharacterAssets = {
    metadata = {},
    images = {},
    frames = {},
    failures = {},
}

local function release(image)
    if image and image.release then pcall(image.release, image) end
end

local function frameCountFor(character, action)
    local anchors = Anchors[character] and Anchors[character][action]
    return anchors and #anchors or 0
end

function CharacterAssets.load()
    CharacterAssets.releaseAll()
    CharacterAssets.metadata, CharacterAssets.images = {}, {}
    CharacterAssets.frames, CharacterAssets.failures = {}, {}
    for character, actions in pairs(Config.characters) do
        CharacterAssets.metadata[character] = {}
        CharacterAssets.images[character] = {}
        CharacterAssets.frames[character] = {}
        for action, path in pairs(actions) do
            local count = frameCountFor(character, action)
            if not love.filesystem.getInfo(path) then
                CharacterAssets.failures[#CharacterAssets.failures + 1] = path .. ": required strip is missing"
            elseif count == 0 then
                CharacterAssets.failures[#CharacterAssets.failures + 1] = path .. ": frame anchors are missing"
            else
                CharacterAssets.metadata[character][action] = {
                    path = path,
                    frameCount = count,
                    width = count * 512,
                    height = 512,
                }
            end
        end
    end
end

local function loadAction(character, action)
    local metadata = CharacterAssets.metadata[character]
        and CharacterAssets.metadata[character][action]
    if not metadata then return nil end
    local existing = CharacterAssets.images[character][action]
    if existing then return existing, CharacterAssets.frames[character][action], metadata.frameCount end

    local ok, image = pcall(love.graphics.newImage, metadata.path)
    if not ok or not image then return nil end
    local width, height = image:getDimensions()
    if width ~= metadata.width or height ~= metadata.height then
        release(image)
        CharacterAssets.failures[#CharacterAssets.failures + 1] = string.format(
            "%s: expected %dx%d strip, got %dx%d",
            metadata.path, metadata.width, metadata.height, width, height)
        return nil
    end
    image:setFilter("nearest", "nearest")
    local frames = {}
    for frame = 1, metadata.frameCount do
        frames[frame] = love.graphics.newQuad((frame - 1) * 512, 0, 512, 512, width, height)
    end
    CharacterAssets.images[character][action] = image
    CharacterAssets.frames[character][action] = frames
    return image, frames, metadata.frameCount
end

function CharacterAssets.get(character, action, frame)
    local image, frames, count = loadAction(character, action)
    if not image or not frames or count == 0 then return nil end
    local index = ((frame or 1) - 1) % count + 1
    return image, frames[index], count, index
end

function CharacterAssets.draw(character, action, x, y, maxWidth, maxHeight, facing, clock, rate)
    local metadata = CharacterAssets.metadata[character] and CharacterAssets.metadata[character][action]
    if not metadata then return false end
    local frame = math.floor((clock or 0) * (rate or (action == "walk" and 5.2 or 0.7)))
        % metadata.frameCount + 1
    local image, quad, _, index = CharacterAssets.get(character, action, frame)
    if not image or not quad then return false end
    local anchor = Anchors[character][action][index]
    local scale = math.min((maxWidth or 82) / 512, (maxHeight or 112) / 512)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(image, quad, x, y, 0, scale * (facing or 1), scale, anchor.x, anchor.y)
    return true
end

function CharacterAssets.retainCharacters(activeCharacters)
    local active = {}
    for key, value in pairs(activeCharacters or {}) do
        if type(key) == "number" then active[value] = true elseif value then active[key] = true end
    end
    for character, actions in pairs(CharacterAssets.images) do
        if not active[character] then
            for action, image in pairs(actions) do
                release(image)
                actions[action] = nil
                CharacterAssets.frames[character][action] = nil
            end
        end
    end
end

function CharacterAssets.releaseAll()
    for _, actions in pairs(CharacterAssets.images or {}) do
        for _, image in pairs(actions) do release(image) end
    end
end

function CharacterAssets.assertHealthy()
    return #CharacterAssets.failures == 0, table.concat(CharacterAssets.failures, "\n")
end

function CharacterAssets.failureCount() return #CharacterAssets.failures end

return CharacterAssets
