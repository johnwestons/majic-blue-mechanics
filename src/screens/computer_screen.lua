local Jobs = require("src.jobs")
local Catalog = require("src.parts_catalog")
local Procurement = require("src.procurement")
local BackButton = require("src.screens.back_button")
local Ui = require("src.screens.ui")

local ComputerScreen = { tab = "active", selectedJobId = nil, cursorRow = 1 }
local CLOSE = { x = 684, y = 552, width = 134, height = 38 }
local DETAIL_BACK = { x = 128, y = 552, width = 134, height = 38 }
local LIST = { x = 128, y = 235, width = 690, rowHeight = 54, visibleRows = 5 }
local tabs = {
    { id = "active", label = "ACTIVE", x = 128, width = 126 },
    { id = "completed", label = "HISTORY", x = 264, width = 126 },
    { id = "parts", label = "PARTS", x = 400, width = 126 },
    { id = "customers", label = "CUSTOMERS", x = 536, width = 126 },
    { id = "finances", label = "SHOP", x = 672, width = 126 },
}

local function contains(rect, x, y)
    return Ui.contains(rect.x, rect.y, rect.width, rect.height, x, y)
end

local function jobById(state, id)
    for _, list in ipairs({ state.jobs.active, state.jobs.completed, state.jobs.declined }) do
        for _, job in ipairs(list or {}) do if job.id == id then return job end end
    end
end

local function jobsForTab(state)
    if ComputerScreen.tab == "active" then return state.jobs.active or {} end
    if ComputerScreen.tab == "completed" then
        local result = {}
        for index = #(state.jobs.completed or {}), 1, -1 do result[#result + 1] = state.jobs.completed[index] end
        return result
    end
    return {}
end

local function customers(state)
    local records, order = {}, {}
    for _, list in ipairs({ state.jobs.active, state.jobs.completed, state.jobs.declined }) do
        for _, job in ipairs(list or {}) do
            local key = job.clientId or job.owner
            if not records[key] then
                records[key] = { owner = job.owner, company = job.company,
                    bikes = {}, completed = 0, spent = 0 }
                order[#order + 1] = records[key]
            end
            local record = records[key]
            record.bikes[job.motorcycleId or job.id] = string.format("%d %s %s",
                job.bike.year, job.bike.make, job.bike.model)
            if job.status == "completed" then
                record.completed = record.completed + 1
                record.spent = record.spent + (job.quote or 0)
            end
        end
    end
    return order
end

local function rowRect(index)
    return { x = LIST.x, y = LIST.y + (index - 1) * LIST.rowHeight,
        width = LIST.width, height = LIST.rowHeight - 6 }
end

function ComputerScreen.enter()
    ComputerScreen.tab, ComputerScreen.selectedJobId, ComputerScreen.cursorRow = "active", nil, 1
end

local function drawTabs(mouseX, mouseY)
    for index, tab in ipairs(tabs) do
        local selected = ComputerScreen.tab == tab.id
        local hovered = Ui.contains(tab.x, 154, tab.width, 36, mouseX, mouseY)
        love.graphics.setColor(selected and 0.15 or 0.06, selected and 0.38 or 0.18,
            selected and 0.44 or 0.22, hovered and 1 or 0.94)
        love.graphics.rectangle("fill", tab.x, 154, tab.width, 36, 4, 4)
        love.graphics.setColor(selected and 0.58 or 0.24, selected and 0.88 or 0.52,
            selected and 0.86 or 0.57)
        love.graphics.rectangle("line", tab.x, 154, tab.width, 36, 4, 4)
        Ui.label(index .. "  " .. tab.label, tab.x, 165, tab.width,
            selected and { 0.96, 0.92, 0.72 } or { 0.69, 0.78, 0.75 }, "center")
    end
end

local function drawJobList(state, mouseX, mouseY)
    local jobs = jobsForTab(state)
    Ui.label(ComputerScreen.tab == "active" and "ACTIVE WORK ORDERS" or "COMPLETED SERVICE HISTORY",
        LIST.x, 205, LIST.width, { 0.90, 0.84, 0.57 })
    if #jobs == 0 then
        Ui.label(ComputerScreen.tab == "active" and "No motorcycles are waiting for service."
            or "No completed repairs yet.", LIST.x, 238, LIST.width,
            { 0.56, 0.64, 0.62 }, "center")
        return
    end
    for index = 1, math.min(#jobs, LIST.visibleRows) do
        local job, rect = jobs[index], rowRect(index)
        local hovered, selected = contains(rect, mouseX, mouseY), index == ComputerScreen.cursorRow
        love.graphics.setColor(selected and 0.09 or 0.05, selected and 0.25 or 0.13,
            selected and 0.28 or 0.16, hovered and 1 or 0.94)
        love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height, 3, 3)
        if selected then
            love.graphics.setColor(0.42, 0.76, 0.78)
            love.graphics.rectangle("line", rect.x, rect.y, rect.width, rect.height, 3, 3)
        end
        Ui.label(job.id .. "  " .. job.bike.make .. " " .. job.bike.model,
            rect.x + 14, rect.y + 7, 330, { 0.82, 0.88, 0.84 })
        Ui.label(job.owner, rect.x + 14, rect.y + 26, 300, { 0.58, 0.66, 0.64 })
        Ui.label(Jobs.stageLabel(job), rect.x + 360, rect.y + 15, 190, { 0.58, 0.90, 0.92 })
        Ui.label(Ui.money(job.quote), rect.x + 568, rect.y + 15, 100,
            { 0.55, 0.90, 0.70 }, "right")
    end
    Ui.label("Click a work order or use Up/Down + Enter", LIST.x, 526, LIST.width,
        { 0.50, 0.59, 0.58 }, "center")
end

local function drawCustomers(state)
    local records = customers(state)
    Ui.label("CUSTOMER & MOTORCYCLE RECORDS", LIST.x, 205, LIST.width, { 0.90, 0.84, 0.57 })
    if #records == 0 then
        Ui.label("Customer records appear after the first estimate.", LIST.x, 238, LIST.width,
            { 0.56, 0.64, 0.62 }, "center")
        return
    end
    for index, record in ipairs(records) do
        if index > LIST.visibleRows then break end
        local rect, bikeCount, bikeName = rowRect(index), 0, ""
        for _, name in pairs(record.bikes) do bikeCount, bikeName = bikeCount + 1, name end
        love.graphics.setColor(0.05, 0.13, 0.16, 0.94)
        love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height, 3, 3)
        Ui.label(record.owner .. "  •  " .. record.company, rect.x + 14, rect.y + 7, 400,
            { 0.82, 0.88, 0.84 })
        Ui.label(bikeName .. (bikeCount > 1 and "  +" .. (bikeCount - 1) or ""),
            rect.x + 14, rect.y + 26, 400, { 0.58, 0.72, 0.72 })
        Ui.label(string.format("%d finished  •  %s", record.completed, Ui.money(record.spent)),
            rect.x + 458, rect.y + 16, 210, { 0.55, 0.90, 0.70 }, "right")
    end
end

local function metric(x, label, value, color)
    Ui.label(label, x, 232, 145, { 0.62, 0.72, 0.70 }, "center")
    Ui.label(value, x, 262, 145, color or { 0.86, 0.89, 0.84 }, "center")
end

local function drawFinances(state)
    Ui.label("SHOP SUMMARY", LIST.x, 205, LIST.width, { 0.90, 0.84, 0.57 })
    metric(142, "CASH", Ui.money(state.money), { 0.55, 0.90, 0.70 })
    metric(305, "REVENUE", Ui.money(state.revenue))
    metric(468, "PARTS SPENT", Ui.money(state.expenses), { 0.92, 0.70, 0.52 })
    metric(631, "REPUTATION", tostring(state.reputation), { 0.90, 0.84, 0.57 })
    local profit = (state.revenue or 0) - (state.expenses or 0)
    Ui.label("RECORDED SERVICE PROFIT", 230, 344, 300, { 0.62, 0.72, 0.70 })
    Ui.label(Ui.money(profit), 550, 344, 150,
        profit >= 0 and { 0.55, 0.90, 0.70 } or { 0.95, 0.52, 0.44 }, "right")
    Ui.label(string.format("%d active  •  %d completed  •  %d declined",
        #state.jobs.active, #state.jobs.completed, #state.jobs.declined),
        230, 390, 470, { 0.75, 0.82, 0.80 }, "center")
    Ui.label("Parts inventory and delivery accounting will appear when those shop systems are installed.",
        190, 460, 580, { 0.50, 0.59, 0.58 }, "center")
end

local function partRect(index)
    local column = (index - 1) % 2
    local row = math.floor((index - 1) / 2)
    return { x = 128 + column * 350, y = 230 + row * 58, width = 340, height = 50 }
end

local function partBuyRect(index)
    local rect = partRect(index)
    return { x = rect.x + 252, y = rect.y + 9, width = 76, height = 32 }
end

local function drawParts(state, mouseX, mouseY)
    Procurement.ensure(state)
    Ui.label("MOTORCYCLE PARTS INVENTORY  •  TRUCK DELIVERY", LIST.x, 205,
        LIST.width, { 0.90, 0.84, 0.57 })
    for index, item in ipairs(Catalog.all()) do
        local rect, buy = partRect(index), partBuyRect(index)
        love.graphics.setColor(0.05, 0.13, 0.16, 0.94)
        love.graphics.rectangle("fill", rect.x, rect.y, rect.width, rect.height, 3, 3)
        Ui.label(item.label, rect.x + 10, rect.y + 7, 226, { 0.82, 0.88, 0.84 })
        Ui.label(string.format("IN STOCK %d  •  %s", Procurement.quantity(state, item.kind),
            Ui.money(item.cost)), rect.x + 10, rect.y + 27, 226, { 0.58, 0.72, 0.72 })
        Ui.button(buy.x, buy.y, buy.width, buy.height, "ORDER", nil, mouseX, mouseY,
            state.money >= item.cost)
    end
    Ui.label("HOW: Order the kit named by the service bay. Wait for the delivery truck, open its rear cargo door, then RECEIVE the package.",
        LIST.x, 526, LIST.width, { 0.90, 0.76, 0.36 }, "center")
end

local function drawDetail(state, mouseX, mouseY)
    local job = jobById(state, ComputerScreen.selectedJobId)
    if not job then ComputerScreen.selectedJobId = nil; return end
    Ui.label(job.id .. "  •  " .. Jobs.stageLabel(job), 128, 160, 650, { 0.90, 0.84, 0.57 })
    Ui.label(string.format("%d %s %s  •  %s miles", job.bike.year, job.bike.make,
        job.bike.model, Ui.number(job.bike.mileage)), 128, 202, 650, { 0.58, 0.90, 0.92 })
    Ui.label(job.owner .. "  •  " .. job.company, 128, 230, 650, { 0.75, 0.82, 0.80 })
    Ui.label("CUSTOMER COMPLAINT", 128, 278, 220, { 0.90, 0.84, 0.57 })
    Ui.label(job.complaint, 128, 306, 690, { 0.82, 0.86, 0.82 })
    Ui.label("SERVICE", 128, 362, 120, { 0.90, 0.84, 0.57 })
    Ui.label(job.service, 250, 362, 568, { 0.58, 0.90, 0.92 })
    Ui.label("PARTS", 128, 400, 120, { 0.90, 0.84, 0.57 })
    Ui.label(table.concat(job.parts or {}, "  •  "), 250, 400, 568, { 0.75, 0.82, 0.80 })
    Ui.label("IDENTITIES", 128, 458, 120, { 0.90, 0.84, 0.57 })
    Ui.label((job.clientId or "Unknown client") .. "  •  " ..
        (job.motorcycleId or "Unknown motorcycle"), 250, 458, 568, { 0.58, 0.72, 0.72 })
    Ui.label("ESTIMATE", 128, 500, 120, { 0.90, 0.84, 0.57 })
    Ui.label(Ui.money(job.quote), 250, 500, 150, { 0.55, 0.90, 0.70 })
    BackButton.draw(DETAIL_BACK, "WORK ORDERS", mouseX, mouseY)
end

function ComputerScreen.draw(state, mouseX, mouseY)
    Ui.panel(90, 62, 780, 548, "MAJIC BLUE  •  SERVICE MANAGEMENT")
    if ComputerScreen.selectedJobId then drawDetail(state, mouseX, mouseY) else
        drawTabs(mouseX, mouseY)
        if ComputerScreen.tab == "active" or ComputerScreen.tab == "completed" then
            drawJobList(state, mouseX, mouseY)
        elseif ComputerScreen.tab == "parts" then drawParts(state, mouseX, mouseY)
        elseif ComputerScreen.tab == "customers" then drawCustomers(state) else drawFinances(state) end
    end
    BackButton.draw(CLOSE, "CLOSE", mouseX, mouseY)
end

local function selectTab(id)
    ComputerScreen.tab, ComputerScreen.selectedJobId, ComputerScreen.cursorRow = id, nil, 1
    return { action = "tab", tab = id }
end

function ComputerScreen.mousepressed(state, x, y, button)
    if button ~= 1 then return nil end
    if BackButton.contains(CLOSE, x, y) then return { action = "close" } end
    if ComputerScreen.selectedJobId then
        if BackButton.contains(DETAIL_BACK, x, y) then
            ComputerScreen.selectedJobId = nil
            return { action = "detail_back" }
        end
        return nil
    end
    for _, tab in ipairs(tabs) do
        if Ui.contains(tab.x, 154, tab.width, 36, x, y) then return selectTab(tab.id) end
    end
    if ComputerScreen.tab == "parts" then
        for index, item in ipairs(Catalog.all()) do
            if contains(partBuyRect(index), x, y) then
                local ok, result = Procurement.orderDelivery(state, item.kind)
                return { action = ok and "part_purchased" or "blocked", result = result,
                    saveNeeded = ok }
            end
        end
    end
    if ComputerScreen.tab == "active" or ComputerScreen.tab == "completed" then
        local jobs = jobsForTab(state)
        for index = 1, math.min(#jobs, LIST.visibleRows) do
            if contains(rowRect(index), x, y) then
                ComputerScreen.cursorRow, ComputerScreen.selectedJobId = index, jobs[index].id
                return { action = "job", job = jobs[index] }
            end
        end
    end
end


function ComputerScreen.keypressed(state, key)
    if ComputerScreen.selectedJobId then
        if key == "backspace" or key == "left" then
            ComputerScreen.selectedJobId = nil
            return { action = "detail_back" }
        end
        return nil
    end
    local number = tonumber(key)
    if number and tabs[number] then return selectTab(tabs[number].id) end
    local current = 1
    for index, tab in ipairs(tabs) do if tab.id == ComputerScreen.tab then current = index end end
    if key == "left" then return selectTab(tabs[(current - 2) % #tabs + 1].id) end
    if key == "right" then return selectTab(tabs[current % #tabs + 1].id) end
    if ComputerScreen.tab == "active" or ComputerScreen.tab == "completed" then
        local jobs = jobsForTab(state)
        if key == "up" then
            ComputerScreen.cursorRow = math.max(1, ComputerScreen.cursorRow - 1)
            return { action = "cursor" }
        elseif key == "down" then
            ComputerScreen.cursorRow = math.min(math.max(1, math.min(#jobs, LIST.visibleRows)),
                ComputerScreen.cursorRow + 1)
            return { action = "cursor" }
        elseif key == "return" and jobs[ComputerScreen.cursorRow] then
            ComputerScreen.selectedJobId = jobs[ComputerScreen.cursorRow].id
            return { action = "job", job = jobs[ComputerScreen.cursorRow] }
        end
    end
end

function ComputerScreen.hit(x, y)
    return BackButton.contains(CLOSE, x, y) and "close" or nil
end

function ComputerScreen.snapshot()
    return { tab = ComputerScreen.tab, selectedJobId = ComputerScreen.selectedJobId,
        cursorRow = ComputerScreen.cursorRow }
end

return ComputerScreen
