local Email = {}

function Email.ensure(state)
    state.clientEmails = type(state.clientEmails) == "table" and state.clientEmails or { inbox = {}, archive = {}, nextId = 1 }
    local box = state.clientEmails
    box.inbox = type(box.inbox) == "table" and box.inbox or {}
    box.archive = type(box.archive) == "table" and box.archive or {}
    box.nextId = math.max(1, math.floor(tonumber(box.nextId) or 1))
    return box
end

local function exists(box, jobId, subject)
    for _, mail in ipairs(box.inbox) do if mail.jobId == jobId and mail.subject == subject then return true end end
    for _, mail in ipairs(box.archive) do if mail.jobId == jobId and mail.subject == subject then return true end end
    return false
end

function Email.update(state)
    local box = Email.ensure(state)
    for _, job in ipairs((state.jobs and state.jobs.active) or {}) do
        local subject = "Motorcycle service update: " .. job.id
        if not exists(box, job.id, subject) then
            box.inbox[#box.inbox + 1] = { id = string.format("MAIL-%04d", box.nextId), jobId = job.id,
                sender = job.owner, subject = subject,
                body = string.format("Hi Majic Blue, I left my %d %s %s with you. Please keep me posted on the repair.", job.bike.year, job.bike.make, job.bike.model),
                receivedDay = (state.calendar and state.calendar.totalDays) or 0 }
            box.nextId = box.nextId + 1
        end
    end
end

function Email.inbox(state) return Email.ensure(state).inbox end
function Email.archive(state) return Email.ensure(state).archive end
function Email.markRead(state, id)
    local box = Email.ensure(state)
    for index, mail in ipairs(box.inbox) do
        if mail.id == id then table.remove(box.inbox, index); box.archive[#box.archive + 1] = mail; return true end
    end
    return false
end

return Email
