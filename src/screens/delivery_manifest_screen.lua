local BackButton = require("src.screens.back_button")
local Procurement = require("src.procurement")
local Ui = require("src.screens.ui")

local Screen = {}
local BACK = { x = 126, y = 552, width = 142, height = 38 }
local CLOSE_VAN = { x = 620, y = 552, width = 196, height = 38 }

local function rowRect(index)
    return { x = 126, y = 190 + (index - 1) * 66, width = 690, height = 54 }
end

local function receiveRect(index)
    local row = rowRect(index)
    return { x = row.x + row.width - 118, y = row.y + 9, width = 104, height = 36 }
end

function Screen.draw(state, mouseX, mouseY)
    Ui.panel(88, 62, 784, 548, "MAJIC BLUE PARTS VAN  •  DELIVERY MANIFEST")
    local manifest = Procurement.manifest(state)
    Ui.label(string.format("%d package%s remaining", #manifest, #manifest == 1 and "" or "s"),
        126, 132, 690, { 0.90, 0.84, 0.57 })
    Ui.label("HOW: Click RECEIVE on every package. When none remain, close the cargo doors.",
        126, 158, 690, { 0.90, 0.76, 0.36 })
    if #manifest == 0 then
        Ui.label("All ordered parts are checked into shop inventory.", 126, 224, 690,
            { 0.58, 0.92, 0.74 }, "center")
        Ui.label("Close the cargo doors to release the van.", 126, 258, 690,
            { 0.75, 0.82, 0.80 }, "center")
    else
        for index, order in ipairs(manifest) do
            local row, receive = rowRect(index), receiveRect(index)
            love.graphics.setColor(0.05, 0.13, 0.16, 0.96)
            love.graphics.rectangle("fill", row.x, row.y, row.width, row.height, 4, 4)
            Ui.label(order.id .. "  •  " .. order.productName, row.x + 14, row.y + 8, 430,
                { 0.82, 0.88, 0.84 })
            Ui.label(string.format("Qty %d  •  Paid %s", order.quantity, Ui.money(order.total)),
                row.x + 14, row.y + 29, 430, { 0.58, 0.72, 0.72 })
            Ui.button(receive.x, receive.y, receive.width, receive.height, "RECEIVE", nil,
                mouseX, mouseY, true)
        end
    end
    BackButton.draw(BACK, "BACK", mouseX, mouseY)
    Ui.button(CLOSE_VAN.x, CLOSE_VAN.y, CLOSE_VAN.width, CLOSE_VAN.height,
        "Close cargo doors", nil, mouseX, mouseY, #manifest == 0)
end

function Screen.mousepressed(state, x, y, button)
    if button ~= 1 then return nil end
    if BackButton.contains(BACK, x, y) then return { action = "back" } end
    local manifest = Procurement.manifest(state)
    if #manifest == 0 and Ui.contains(CLOSE_VAN.x, CLOSE_VAN.y, CLOSE_VAN.width,
        CLOSE_VAN.height, x, y) then return { action = "close_van" } end
    for index, order in ipairs(manifest) do
        local rect = receiveRect(index)
        if Ui.contains(rect.x, rect.y, rect.width, rect.height, x, y) then
            local ok, result = Procurement.receiveOrder(state, order.id)
            return { action = ok and "received" or "blocked", result = result, saveNeeded = ok }
        end
    end
end

return Screen
