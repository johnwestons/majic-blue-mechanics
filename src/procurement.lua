local Catalog = require("src.parts_catalog")

local Procurement = {}

function Procurement.ensure(state)
    state.inventory = type(state.inventory) == "table" and state.inventory or {}
    state.inventory.parts = type(state.inventory.parts) == "table" and state.inventory.parts or {}
    for _, item in ipairs(Catalog.all()) do
        state.inventory.parts[item.kind] = math.max(0,
            math.floor(tonumber(state.inventory.parts[item.kind]) or 0))
    end
    state.procurement = type(state.procurement) == "table" and state.procurement or {}
    state.procurement.orders = type(state.procurement.orders) == "table"
        and state.procurement.orders or {}
    state.procurement.nextOrderId = math.max(1,
        math.floor(tonumber(state.procurement.nextOrderId) or 1))
end

function Procurement.quantity(state, kind)
    Procurement.ensure(state)
    return state.inventory.parts[kind] or 0
end

function Procurement.orderDelivery(state, kind)
    Procurement.ensure(state)
    local item = Catalog.get(kind)
    if not item then return false, "That motorcycle part is not in the supplier catalog." end
    if state.money < item.cost then
        return false, string.format("Need $%d; the shop has $%d.", item.cost, state.money)
    end
    local order = {
        id = string.format("PO-%04d", state.procurement.nextOrderId),
        kind = item.kind, productName = item.label, quantity = 1,
        unitCost = item.cost, total = item.cost, status = "awaiting_delivery",
        fulfillment = "parts_van",
    }
    state.procurement.nextOrderId = state.procurement.nextOrderId + 1
    state.procurement.orders[#state.procurement.orders + 1] = order
    state.money = state.money - item.cost
    state.expenses = state.expenses + item.cost
    state.message = string.format("%s ordered for parts-van delivery.", item.label)
    return true, order
end


function Procurement.purchaseCounterPickup(state, kind)
    return Procurement.orderDelivery(state, kind)
end

function Procurement.findOrder(state, id)
    Procurement.ensure(state)
    for _, order in ipairs(state.procurement.orders) do if order.id == id then return order end end
end

function Procurement.manifest(state)
    Procurement.ensure(state)
    local result, ids = {}, {}
    for _, id in ipairs((state.delivery and state.delivery.orderIds) or {}) do ids[id] = true end
    for _, order in ipairs(state.procurement.orders) do
        if ids[order.id] and order.status ~= "received" then result[#result + 1] = order end
    end
    return result
end

function Procurement.receiveOrder(state, id)
    local order = Procurement.findOrder(state, id)
    if not order or order.status ~= "assigned_to_van" then
        return false, "That delivery item is no longer available to receive."
    end
    state.inventory.parts[order.kind] = state.inventory.parts[order.kind] + order.quantity
    order.status = "received"
    state.message = order.productName .. " received into parts inventory."
    return true, order
end

function Procurement.consume(state, kind)
    Procurement.ensure(state)
    if Procurement.quantity(state, kind) < 1 then return false end
    state.inventory.parts[kind] = state.inventory.parts[kind] - 1
    return true
end

return Procurement
