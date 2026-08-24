local Config = require("src.config")
local Save = require("src.save")
local Ui = require("src.screens.ui")

local TitleScreen = {
    selected = 1,
    slots = {},
    confirm = nil,
    onStart = nil,
}

local headlineFont
local bodyFont

local function refresh() TitleScreen.slots = Save.listSlots() end

local function startNew(slot)
    TitleScreen.onStart(Save.newGame(slot), "new")
end

local function continueSlot(slot)
    local payload, message = Save.load(slot)
    if payload then TitleScreen.onStart(payload, payload.recovered and "recovered" or "continue") end
    return payload ~= nil, message
end

function TitleScreen.enter(onStart)
    TitleScreen.onStart = onStart
    TitleScreen.confirm = nil
    refresh()
end

function TitleScreen.keypressed(key)
    if TitleScreen.confirm then
        if key == "y" or key == "return" then
            local confirmation = TitleScreen.confirm
            TitleScreen.confirm = nil
            if confirmation.action == "overwrite" then
                Save.delete(confirmation.slot)
                startNew(confirmation.slot)
            elseif confirmation.action == "delete" then
                Save.delete(confirmation.slot)
                refresh()
            end
        elseif key == "n" or key == "escape" then
            TitleScreen.confirm = nil
        end
        return true
    end

    if key == "up" or key == "w" then
        TitleScreen.selected = (TitleScreen.selected - 2) % Save.slotCount + 1
    elseif key == "down" or key == "s" then
        TitleScreen.selected = TitleScreen.selected % Save.slotCount + 1
    elseif key == "n" then
        local info = TitleScreen.slots[TitleScreen.selected]
        if info.exists then
            TitleScreen.confirm = { action = "overwrite", slot = TitleScreen.selected }
        else
            startNew(TitleScreen.selected)
        end
    elseif key == "c" or key == "return" then
        local info = TitleScreen.slots[TitleScreen.selected]
        if info.exists and not info.damaged then continueSlot(TitleScreen.selected) end
    elseif key == "d" then
        local info = TitleScreen.slots[TitleScreen.selected]
        if info.exists then TitleScreen.confirm = { action = "delete", slot = TitleScreen.selected } end
    elseif key == "q" or key == "escape" then
        love.event.quit()
    end
    return true
end

local function slotRect(slot) return 200, 270 + (slot - 1) * 88, 560, 70 end

function TitleScreen.mousepressed(x, y, button)
    if button ~= 1 then return false end
    if TitleScreen.confirm then return false end
    for slot = 1, Save.slotCount do
        local sx, sy, sw, sh = slotRect(slot)
        if Ui.contains(sx, sy, sw, sh, x, y) then
            TitleScreen.selected = slot
            return true
        end
    end
    return false
end

function TitleScreen.draw(assets, mouseX, mouseY)
    bodyFont = bodyFont or love.graphics.getFont()
    headlineFont = headlineFont or love.graphics.newFont(32)
    love.graphics.clear(0.025, 0.04, 0.05)
    love.graphics.setColor(0.07, 0.17, 0.20)
    love.graphics.rectangle("fill", 0, 0, Config.baseWidth, Config.baseHeight)
    love.graphics.setColor(0.025, 0.05, 0.06, 0.84)
    love.graphics.polygon("fill", 0, 0, 960, 0, 960, 210, 0, 350)

    local poster = assets.get("motorcyclePoster")
    if poster then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(poster, 810, 42, 0, 1.05, 1.05, poster:getWidth() / 2, 0)
    end
    Ui.label("MAJIC BLUE", 70, 66, 690, { 0.90, 0.84, 0.57 })
    love.graphics.setFont(headlineFont)
    Ui.label("MOTORCYCLE MECHANICS", 70, 98, 740, { 0.58, 0.90, 0.92 })
    love.graphics.setFont(bodyFont)
    Ui.label("A Picture Shop and Mouse Frontier sister game", 74, 148, 650,
        { 0.70, 0.76, 0.75 })
    Ui.label("Choose a local shop save", 200, 232, 560, { 0.90, 0.84, 0.57 }, "center")

    for slot = 1, Save.slotCount do
        local info = TitleScreen.slots[slot] or { slot = slot }
        local x, y, width, height = slotRect(slot)
        local hovered = Ui.contains(x, y, width, height, mouseX, mouseY)
        local selected = slot == TitleScreen.selected
        love.graphics.setColor(selected and 0.12 or 0.06, selected and 0.30 or 0.14,
            selected and 0.33 or 0.17, hovered and 1 or 0.94)
        love.graphics.rectangle("fill", x, y, width, height, 5, 5)
        love.graphics.setColor(selected and 0.60 or 0.24, selected and 0.88 or 0.52,
            selected and 0.86 or 0.57)
        love.graphics.rectangle("line", x, y, width, height, 5, 5)
        Ui.label("SLOT " .. slot, x + 18, y + 15, 110, { 0.90, 0.84, 0.57 })
        if info.damaged then
            Ui.label("DAMAGED SAVE", x + 136, y + 15, 390, { 0.95, 0.45, 0.38 })
        elseif info.exists then
            Ui.label(string.format("%s cash   %d active   %d finished   rep %d",
                Ui.money(info.money), info.activeJobs, info.completedJobs, info.reputation),
                x + 136, y + 15, 390, { 0.78, 0.86, 0.82 })
        else
            Ui.label("EMPTY SHOP", x + 136, y + 15, 390, { 0.55, 0.62, 0.61 })
        end
        Ui.label(selected and ">" or "", x - 26, y + 26, 20, { 0.90, 0.84, 0.57 }, "right")
    end

    Ui.label("N New    C / Enter Continue    D Delete    Q Quit", 160, 558, 640,
        { 0.78, 0.84, 0.82 }, "center")
    Ui.label("W / S or arrows choose a slot", 160, 586, 640,
        { 0.53, 0.62, 0.61 }, "center")

    if TitleScreen.confirm then
        Ui.panel(260, 252, 440, 150, "CONFIRM")
        local verb = TitleScreen.confirm.action == "delete" and "delete" or "overwrite"
        Ui.label(string.format("%s Slot %d? This cannot be undone.",
            verb:gsub("^%l", string.upper), TitleScreen.confirm.slot),
            290, 316, 380, { 0.90, 0.84, 0.57 }, "center")
        Ui.label("Y / Enter confirm     N / Escape cancel", 290, 358, 380,
            { 0.76, 0.84, 0.82 }, "center")
    end
end

return TitleScreen
