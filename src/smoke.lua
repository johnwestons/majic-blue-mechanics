local Smoke = {
    active = false,
    completed = false,
    failed = false,
    drawCount = 0,
    report = nil,
}

local function requested() return os.getenv("MAJIC_BLUE_SMOKE") == "1" end

local function writeLine(message)
    if Smoke.report then Smoke.report:write(message .. "\n") Smoke.report:flush() end
end

local function check(name, condition)
    if not condition then error("check failed: " .. name, 2) end
    writeLine("PASS " .. name)
end

local function runChecks(context)
    local workshop = context.assets.get("workshop")
    local walkmask = context.assets.getData("walkmask")
    check("workshop_loaded", workshop and workshop:getWidth() == 1536 and workshop:getHeight() == 1024)
    check("walkmask_aligned", walkmask and walkmask:getWidth() == workshop:getWidth()
        and walkmask:getHeight() == workshop:getHeight())
    check("player_spawn_walkable", context.navigation.isWalkable(context.assets,
        context.config.player.spawnX, context.config.player.spawnY, {}))

    local mechanic = context.characterAssets.get("mechanic-raccoon", "idle", 1)
    local customer = context.characterAssets.get("business-fox", "walk", 1)
    check("mechanic_strip_available", mechanic ~= nil)
    check("customer_strip_available", customer ~= nil)
    local charactersHealthy = context.characterAssets.assertHealthy()
    check("character_contracts_healthy", charactersHealthy)

    local offer = context.jobs.createOffer(1)
    check("stable_first_job_id", offer.id == "MBM-0001")
    check("quote_covers_parts", offer.quote > offer.partsCost)
    for sequence, template in ipairs(context.jobs.templates()) do
        local rosterOffer = context.jobs.createOffer(sequence)
        local key = context.jobs.bikeKeyFor(rosterOffer)
        check("roster_bike_key_" .. sequence, key == template.bikeKey)
        check("roster_mounted_sprite_" .. sequence,
            context.assets.get("motorcycleMounted_" .. key) ~= nil)
    end
    local legacyJob = {
        sequence = 1,
        bike = { make = "Suzuki", model = "GSX-R600" },
        artwork = "motorcycleSide",
    }
    check("legacy_job_bike_migration", context.jobs.ensureBikeSprite(legacyJob) == "redSupersport"
        and legacyJob.artwork == "motorcycleService_redSupersport")
    local miniState = context.State.newGame(2)
    local miniOffer = context.jobs.createOffer(1)
    context.jobs.accept(miniOffer)
    miniState.jobs.active[1] = miniOffer
    miniState.selectedJobId = miniOffer.id
    check("repair_minigame_starts", context.repairMinigameScreen.begin(miniState, "diagnose"))
    local miniTask = miniState.repairMinigame
    context.repairMinigameScreen.mousepressed(miniState, miniTask.tokenX, miniTask.tokenY)
    context.repairMinigameScreen.mousemoved(miniState, miniTask.targetX, miniTask.targetY)
    check("repair_minigame_accepts_drop",
        context.repairMinigameScreen.mousereleased(miniState, miniTask.targetX, miniTask.targetY) == "diagnose")
    local serviceState = context.State.newGame(1)
    serviceState.pendingOffer = offer
    check("accept_work_order", context.jobService.acceptOffer(serviceState))
    check("diagnose_work_order", context.jobService.diagnose(serviceState, offer.id))
    local cashBeforeParts = serviceState.money
    check("repair_work_order", context.jobService.repair(serviceState, offer.id))
    check("parts_deducted", serviceState.money == cashBeforeParts - offer.partsCost)
    check("road_test_completes", context.jobService.roadTest(serviceState, offer.id))
    check("job_archived", #serviceState.jobs.active == 0 and #serviceState.jobs.completed == 1)
    check("payment_collected", serviceState.money == cashBeforeParts - offer.partsCost + offer.quote)

    local valid = context.save.validate({
        saveVersion = 1,
        money = serviceState.money,
        nextJobNumber = serviceState.nextJobNumber,
        jobs = serviceState.jobs,
    })
    check("save_schema_valid", valid)
    context.save.delete(3)
    check("save_round_trip_write", context.save.save(3, serviceState,
        { x = 510, y = 470, facing = 1 }))
    serviceState.money = serviceState.money + 1
    check("save_backup_write", context.save.save(3, serviceState,
        { x = 512, y = 468, facing = -1 }))
    check("save_primary_can_be_damaged_for_recovery_test",
        love.filesystem.write("slot-3.lua", "return { broken ="))
    local recovered = context.save.load(3)
    check("save_recovers_last_valid_backup", recovered and recovered.recovered
        and recovered.money == serviceState.money - 1)
    context.save.delete(3)

    context.State.applySave(context.state, context.State.newGame(1))
    context.world.load()
    local renderOffer = context.jobs.createOffer(1)
    context.jobs.accept(renderOffer)
    context.state.jobs.active[1] = renderOffer
    context.world.update(10, 0, 0, context.assets, context.state)
    check("customer_reaches_lounge", context.world.customer.state == "waiting")
    local preview = os.getenv("MAJIC_BLUE_PREVIEW")
    if preview == "title" then
        context.state.screen = "title"
    elseif preview == "job_offer" then
        context.state.pendingOffer = context.jobs.createOffer(2)
        context.state.screen = "job_offer"
    elseif preview == "service" then
        context.state.selectedJobId = renderOffer.id
        context.state.screen = "service"
    elseif preview == "computer" then
        context.state.screen = "computer"
    else
        context.state.screen = "world"
    end
end

function Smoke.requested() return requested() end

function Smoke.start(context)
    if not requested() then return end
    Smoke.active = true
    local reportPath = os.getenv("MAJIC_BLUE_SMOKE_REPORT") or "smoke-report.rpt"
    local report, errorMessage = io.open(reportPath, "w")
    if not report then
        io.stderr:write("SMOKE_REPORT_ERROR: " .. tostring(errorMessage) .. "\n")
        love.event.quit(1)
        return
    end
    Smoke.report = report
    writeLine("MAJIC_BLUE_MECHANICS_SMOKE version=1")

    local ok, message = xpcall(function() runChecks(context) end, debug.traceback)
    if not ok then
        Smoke.failed = true
        writeLine("FAIL " .. tostring(message))
        io.stderr:write("SMOKE_ERROR: " .. tostring(message) .. "\n")
        io.stderr:flush()
    else
        Smoke.completed = true
        writeLine("CHECKS_COMPLETE")
    end
end

function Smoke.drawn()
    if not Smoke.active then return end
    Smoke.drawCount = Smoke.drawCount + 1
    if Smoke.drawCount == 1 and os.getenv("MAJIC_BLUE_SMOKE_SCREENSHOT") == "1" then
        love.graphics.captureScreenshot("smoke-preview.png")
    end
    if Smoke.failed then
        if Smoke.report then Smoke.report:close() end
        love.event.quit(1)
    elseif Smoke.completed and Smoke.drawCount >= 3 then
        writeLine("PASS render_three_frames")
        writeLine("SMOKE_OK")
        Smoke.report:close()
        print("SMOKE_OK: mechanics loop checks and three draw frames completed")
        io.flush()
        love.event.quit(0)
    end
end

return Smoke
