local Ui = require("src.screens.ui")

local JobOfferScreen = {}

function JobOfferScreen.draw(state, assets, mouseX, mouseY)
    local job = state.pendingOffer
    Ui.panel(112, 72, 736, 534, "CUSTOMER ESTIMATE  •  " .. (job and job.id or "NO ORDER"))
    if not job then
        Ui.label("No estimate is waiting.", 150, 150, 660, { 0.92, 0.62, 0.50 }, "center")
        return
    end

    local art = assets.get(job.artwork) or assets.get("motorcyclePoster")
    if art then
        local artScale = art:getWidth() > 200 and 0.70 or 1.35
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(art, 154, 132, 0, artScale, artScale)
    end
    Ui.label(job.owner, 350, 120, 450, { 0.90, 0.84, 0.57 })
    Ui.label(job.company, 350, 144, 450, { 0.68, 0.78, 0.77 })
    Ui.label(string.format("%d %s %s  •  %s miles", job.bike.year, job.bike.make,
        job.bike.model, Ui.number(job.bike.mileage)),
        350, 180, 450, { 0.86, 0.89, 0.84 })
    Ui.label(job.service .. "  •  " .. job.difficulty, 350, 208, 450,
        { 0.58, 0.90, 0.92 })

    Ui.label("CUSTOMER COMPLAINT", 154, 274, 240, { 0.90, 0.84, 0.57 })
    Ui.label(job.complaint, 154, 302, 650, { 0.82, 0.86, 0.82 })

    Ui.label("ESTIMATE", 154, 364, 240, { 0.90, 0.84, 0.57 })
    Ui.label("Parts", 154, 394, 200)
    Ui.label(Ui.money(job.partsCost), 660, 394, 130, nil, "right")
    Ui.label(string.format("Labor (%.1f hr)", job.hours), 154, 420, 240)
    Ui.label(Ui.money(job.labor), 660, 420, 130, nil, "right")
    Ui.label("Shop supplies + tax", 154, 446, 240)
    Ui.label(Ui.money(job.shopSupplies + job.tax), 660, 446, 130, nil, "right")
    love.graphics.setColor(0.24, 0.57, 0.68)
    love.graphics.line(520, 476, 790, 476)
    Ui.label("CUSTOMER TOTAL", 520, 486, 150, { 0.90, 0.84, 0.57 })
    Ui.label(Ui.money(job.quote), 660, 486, 130, { 0.55, 0.90, 0.70 }, "right")

    Ui.button(154, 540, 226, 42, "Accept job", "A", mouseX, mouseY)
    Ui.button(584, 540, 206, 42, "Decline", "D", mouseX, mouseY)
    Ui.label("Escape: decide later", 390, 553, 184, { 0.56, 0.64, 0.62 }, "center")
end

function JobOfferScreen.hit(x, y)
    if Ui.contains(154, 540, 226, 42, x, y) then return "accept" end
    if Ui.contains(584, 540, 206, 42, x, y) then return "decline" end
end

return JobOfferScreen
