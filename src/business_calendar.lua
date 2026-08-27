local Config = require("src.config")
local Calendar = {}
local WEEKDAYS = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" }
local MONTHS = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }

local function daysInMonth(year, month)
    if month == 2 then return (year % 400 == 0 or (year % 4 == 0 and year % 100 ~= 0)) and 29 or 28 end
    return ({ [4] = true, [6] = true, [9] = true, [11] = true })[month] and 30 or 31
end

function Calendar.defaultCalendar()
    return { year = 2026, month = 1, day = 1, weekday = 4, elapsed = 0, totalDays = 0 }
end

function Calendar.ensure(state)
    local date = type(state.calendar) == "table" and state.calendar or Calendar.defaultCalendar()
    state.calendar = date
    date.year = math.max(2026, math.floor(tonumber(date.year) or 2026))
    date.month = math.min(12, math.max(1, math.floor(tonumber(date.month) or 1)))
    date.day = math.min(daysInMonth(date.year, date.month), math.max(1, math.floor(tonumber(date.day) or 1)))
    date.weekday = math.min(7, math.max(1, math.floor(tonumber(date.weekday) or 4)))
    date.elapsed = math.max(0, tonumber(date.elapsed) or 0)
    date.totalDays = math.max(0, math.floor(tonumber(date.totalDays) or 0))
    return date
end

local function advanceDay(date)
    date.day, date.weekday, date.totalDays = date.day + 1, date.weekday % 7 + 1, date.totalDays + 1
    if date.day <= daysInMonth(date.year, date.month) then return end
    date.day, date.month = 1, date.month + 1
    if date.month > 12 then date.month, date.year = 1, date.year + 1 end
end

function Calendar.update(state, dt)
    local date = Calendar.ensure(state)
    local secondsPerDay = math.max(1, tonumber((Config.businessCalendar or {}).secondsPerDay) or 300)
    date.elapsed = date.elapsed + math.max(0, tonumber(dt) or 0)
    local days = 0
    while date.elapsed >= secondsPerDay do date.elapsed = date.elapsed - secondsPerDay; advanceDay(date); days = days + 1 end
    return days > 0, days
end

function Calendar.dateText(state)
    local d = Calendar.ensure(state)
    return string.format("%s, %s %d, %d", WEEKDAYS[d.weekday], MONTHS[d.month], d.day, d.year)
end
function Calendar.weekNumber(state) return math.floor((Calendar.ensure(state).totalDays) / 7) + 1 end
function Calendar.shiftMonth(year, month, amount)
    local absolute = year * 12 + month - 1 + amount
    return math.floor(absolute / 12), absolute % 12 + 1
end
function Calendar.monthName(month) return MONTHS[month] end
function Calendar.weekdayName(day) return WEEKDAYS[day] end
function Calendar.daysInMonth(year, month) return daysInMonth(year, month) end

function Calendar.events(state)
    local result = {}
    local function add(day, title, detail, kind)
        if day then result[#result + 1] = { day = math.max(0, math.floor(day)), title = title, detail = detail, kind = kind or "service" } end
    end
    for _, job in ipairs((state.jobs and state.jobs.active) or {}) do
        add(math.floor((job.acceptedAtHours or 0) / 24), "Service: " .. job.id, job.owner .. " • " .. job.service, "service")
        if job.delivery and job.delivery.expectedAtHours then add(math.floor(job.delivery.expectedAtHours / 24), "Parts delivery: " .. job.id, job.repairKind .. " kit", "delivery") end
        if job.stage == "ready_for_pickup" then add(state.calendar.totalDays, "Pickup: " .. job.owner, job.bike.make .. " " .. job.bike.model, "pickup") end
    end
    for _, job in ipairs((state.jobs and state.jobs.completed) or {}) do
        if job.completedAtHours then add(math.floor(job.completedAtHours / 24), "Completed: " .. job.id, job.owner, "complete") end
    end
    table.sort(result, function(a, b) return a.day < b.day end)
    return result
end

return Calendar
