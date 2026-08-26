local RepairTasks = require("src.repair_tasks")

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

local function advanceRepairPreview(screen, state, targetPhase)
    local task = state.repairMinigame
    if not task or task.action ~= "repair" or targetPhase == "part" then return end
    if task.phase == "part" then screen.pressButton(state, "ok") end
    if targetPhase == "tool" then return end
    local definition = RepairTasks.get(task.kind)
    screen.pressButton(state, "tool" .. RepairTasks.toolIndex(definition.tool))
    local guard, direction = 0, "left"
    while task.phase ~= targetPhase and task.phase ~= "inspect" and guard < 120 do
        guard = guard + 1
        if task.phase == "tool" then
            screen.pressButton(state, "ok")
            if targetPhase == "operate" then return end
        elseif task.phase == "operate" then
            if definition.gesture == "adjust" then
                task.adjustValue = 0.5
                screen.pressButton(state, "ok")
            elseif definition.gesture == "hold" then
                screen.pressButton(state, "ok")
            else
                screen.pressButton(state, direction)
                direction = direction == "left" and "right" or "left"
            end
        end
    end
end

local function runChecks(context)
    local fakeAxes = { leftx = 0.65, lefty = -0.35, rightx = 0.5, righty = 0,
        triggerright = 0.8, triggerleft = 0 }
    local fakeDown = {}
    local fakePad = {
        isGamepad = function() return true end,
        getGamepadAxis = function(_, axis) return fakeAxes[axis] or 0 end,
        isGamepadDown = function(_, button) return fakeDown[button] == true end,
    }
    local originalGetJoysticks = love.joystick.getJoysticks
    love.joystick.getJoysticks = function() return { fakePad } end
    local padMoveX, padMoveY = context.input.movement()
    check("controller_analog_shop_movement", padMoveX == fakeAxes.leftx
        and padMoveY == fakeAxes.lefty)
    local padSteer, padThrottle = context.input.roadTestMovement()
    check("controller_road_test_axes", padSteer == fakeAxes.leftx and padThrottle)
    local controllerScreen, pressedKey, pointerPressed = "world", nil, false
    local testController = context.Controller.new({
        pressKey = function(key) pressedKey = key end,
        pressPointer = function() pointerPressed = true end,
        screenInfo = function() return controllerScreen end,
        worldMenuAction = function() pressedKey = "menu" end,
    })
    check("controller_world_action", testController:gamepadpressed(fakePad, "a")
        and pressedKey == "e")
    controllerScreen, pressedKey = "service", nil
    check("controller_service_shortcut", testController:gamepadpressed(fakePad, "x")
        and pressedKey == "d")
    controllerScreen, pointerPressed = "computer", false
    check("controller_panel_click", testController:gamepadpressed(fakePad, "a")
        and pointerPressed)
    local cursorBefore = testController.pointerX
    testController:update(0.1)
    check("controller_cursor_moves", testController.pointerX > cursorBefore)
    love.joystick.getJoysticks = originalGetJoysticks

    local workshop = context.assets.get("workshop")
    local walkmask = context.assets.getData("walkmask")
    check("workshop_loaded", workshop and workshop:getWidth() == 1536 and workshop:getHeight() == 1024)
    check("walkmask_aligned", walkmask and walkmask:getWidth() == workshop:getWidth()
        and walkmask:getHeight() == workshop:getHeight())
    local roadBackground = context.assets.get("roadTestBackground")
    local roadRider = context.assets.get("roadTestRider")
    check("road_test_background_loaded", roadBackground
        and roadBackground:getWidth() == 1024 and roadBackground:getHeight() == 1536)
    local runnerHorizon = context.assets.get("roadTestRunnerHorizon")
    check("road_test_runner_horizon_loaded", runnerHorizon
        and runnerHorizon:getWidth() == 1024 and runnerHorizon:getHeight() == 1536)
    check("road_test_rider_loaded", roadRider
        and roadRider:getWidth() == 256 and roadRider:getHeight() == 256)
    local runnerRoad = context.assets.get("roadTestRunnerRoad")
    local runnerCity = context.assets.get("roadTestRunnerCity")
    local runnerLeftSection = context.assets.get("roadTestRunnerLeftSection")
    local runnerRightSection = context.assets.get("roadTestRunnerRightSection")
    check("road_test_runner_road_loaded", runnerRoad
        and runnerRoad:getWidth() == 1254 and runnerRoad:getHeight() == 1254)
    check("road_test_city_loaded", runnerCity
        and runnerCity:getWidth() == 1536 and runnerCity:getHeight() == 1024)
    check("road_test_runner_sections_loaded", runnerLeftSection and runnerRightSection
        and runnerLeftSection:getWidth() == 2172 and runnerLeftSection:getHeight() == 724
        and runnerRightSection:getWidth() == 2172 and runnerRightSection:getHeight() == 724)
    local graffitiLoaded = true
    for index = 1, 8 do
        local image = context.assets.get("roadTestGraffiti" .. string.format("%02d", index))
        graffitiLoaded = graffitiLoaded and image
            and image:getWidth() == 1254 and image:getHeight() == 1254
    end
    check("road_test_graffiti_loaded", graffitiLoaded)
    local trafficLoaded = true
    for index = 1, 4 do
        local image = context.assets.get("roadTestTraffic" .. string.format("%02d", index))
        trafficLoaded = trafficLoaded and image
            and image:getWidth() == 256 and image:getHeight() == 256
    end
    check("road_test_traffic_loaded", trafficLoaded)
    local riderHitLoaded = true
    for index = 1, 4 do
        local image = context.assets.get("roadTestRiderHit" .. string.format("%02d", index))
        riderHitLoaded = riderHitLoaded and image
            and image:getWidth() == 256 and image:getHeight() == 256
    end
    check("road_test_rider_hit_animation_loaded", riderHitLoaded)
    check("player_spawn_walkable", context.navigation.isWalkable(context.assets,
        context.config.player.spawnX, context.config.player.spawnY, {}))
    check("parts_truck_interaction_is_walkable", context.navigation.isWalkable(context.assets,
        context.config.partsDelivery.interaction.x, context.config.partsDelivery.interaction.y, {}))
    check("flatbed_interaction_is_walkable", context.navigation.isWalkable(context.assets,
        context.config.motorcycleTransport.interaction.x,
        context.config.motorcycleTransport.interaction.y, {}))

    local mechanic = context.characterAssets.get("mechanic-raccoon", "idle", 1)
    local customer = context.characterAssets.get("business-fox", "walk", 1)
    local deliveryTruck = context.assets.get("deliveryTruck")
    local truckCargoDoor = context.assets.get("truckCargoDoor")
    check("mechanic_strip_available", mechanic ~= nil)
    check("customer_strip_available", customer ~= nil)
    check("picture_shop_delivery_truck_loaded", deliveryTruck
        and deliveryTruck:getWidth() == 512 and deliveryTruck:getHeight() == 512)
    check("picture_shop_cargo_door_strip_loaded", truckCargoDoor
        and truckCargoDoor:getWidth() == 2560 and truckCargoDoor:getHeight() == 512)
    for frame = 1, context.config.partsDelivery.cargoFrameCount do
        check("picture_shop_cargo_door_frame_" .. frame,
            context.assets.getQuad("truckCargoDoor" .. frame) ~= nil)
    end
    local standingMetrics = context.characterAssets.normalizedFrameMetrics(
        "business-fox", "idle", 1)
    local seatedMetrics = context.characterAssets.normalizedFrameMetrics(
        "business-fox", "sit", 1)
    check("customer_actions_share_normalized_height", standingMetrics and seatedMetrics
        and math.abs(standingMetrics.height - seatedMetrics.height) < 0.01)
    local mechanicBounds = context.characterAssets.normalizedFrameMetrics(
        "mechanic-raccoon", "walk", 1)
    check("mechanic_visible_frame_metrics_available", mechanicBounds
        and mechanicBounds.width > 0 and mechanicBounds.height > 0)
    local cleanMechanicWalk = true
    for step = 0, 11 do
        local frame = context.characterAssets.animationFrame(
            "mechanic-raccoon", "walk", step / 5.2, 5.2)
        cleanMechanicWalk = cleanMechanicWalk and frame ~= 3 and frame ~= 4
    end
    check("mechanic_walk_skips_clipped_source_frames", cleanMechanicWalk)
    local charactersHealthy = context.characterAssets.assertHealthy()
    check("character_contracts_healthy", charactersHealthy)

    local offer = context.jobs.createOffer(1)
    offer.transportRequired = false
    check("stable_first_job_id", offer.id == "MBM-0001")
    check("stable_client_and_motorcycle_ids", offer.clientId == "CLIENT-0001"
        and offer.motorcycleId == "BIKE-0001")
    local closeState = context.State.newGame(1)
    closeState.pendingOffer = offer
    closeState.screen = "job_offer"
    local reviewCancelled = false
    check("estimate_close_uses_safe_route", context.input.closeCurrent({
        state = closeState,
        world = { cancelCustomerReview = function() reviewCancelled = true end },
        jobService = context.jobService,
    }) and reviewCancelled and closeState.screen == "world"
        and closeState.pendingOffer == offer)
    closeState.screen = "computer"
    check("computer_close_uses_shared_route", context.input.closeCurrent({ state = closeState })
        and closeState.screen == "world")
    local computerState = context.State.newGame(1)
    local computerJob = context.jobs.createOffer(1)
    context.jobs.accept(computerJob)
    computerState.jobs.active[1] = computerJob
    context.computerScreen.enter(computerState)
    check("computer_opens_on_active_tab", context.computerScreen.snapshot().tab == "active")
    check("computer_keyboard_opens_work_order",
        context.computerScreen.keypressed(computerState, "return").action == "job"
        and context.computerScreen.snapshot().selectedJobId == computerJob.id)
    check("computer_detail_returns_to_list",
        context.computerScreen.keypressed(computerState, "left").action == "detail_back"
        and context.computerScreen.snapshot().selectedJobId == nil)
    check("computer_tabs_are_keyboard_selectable",
        context.computerScreen.keypressed(computerState, "4").tab == "customers"
        and context.computerScreen.snapshot().tab == "customers")
    context.computerScreen.keypressed(computerState, "3")
    local computerPurchase = context.computerScreen.mousepressed(computerState, 390, 245, 1)
    check("computer_parts_tab_places_order", computerPurchase
        and computerPurchase.action == "part_purchased" and computerPurchase.saveNeeded
        and context.procurement.quantity(computerState, "oil") == 0
        and computerState.procurement.orders[1].status == "awaiting_delivery")
    local transportState = context.State.newGame(1)
    local transportedJob = context.jobs.createOffer(8)
    transportedJob.transportRequired = true
    context.jobs.accept(transportedJob)
    transportState.jobs.active[1] = transportedJob
    check("transported_bike_waits_for_dropoff", transportedJob.stage == "awaiting_dropoff"
        and context.jobService.currentJob(transportState) == nil)
    check("inbound_flatbed_schedules", context.motorcycleTransport.schedule(transportState,
        transportedJob, "inbound", context.config.motorcycleTransport))
    context.motorcycleTransport.update(transportState,
        context.config.motorcycleTransport.scheduleDelay, context.config.motorcycleTransport)
    context.motorcycleTransport.update(transportState,
        context.config.motorcycleTransport.travelDuration, context.config.motorcycleTransport)
    check("inbound_flatbed_arrives_loaded", transportState.motorcycleTransport.state == "parked"
        and transportState.motorcycleTransport.loaded)
    check("flatbed_dropoff_releases_service", context.jobService.receiveDropoff(transportState,
        transportedJob.id) and transportedJob.stage == "diagnosis")
    transportState.motorcycleTransport.loaded = false
    context.motorcycleTransport.depart(transportState)
    context.motorcycleTransport.update(transportState,
        context.config.motorcycleTransport.travelDuration, context.config.motorcycleTransport)
    context.jobs.diagnose(transportedJob)
    context.jobs.repair(transportedJob)
    context.jobs.completeTest(transportedJob)
    check("transported_bike_requests_return_flatbed",
        transportedJob.stage == "pickup_transport")
    check("outbound_flatbed_schedules", context.motorcycleTransport.schedule(transportState,
        transportedJob, "outbound", context.config.motorcycleTransport))
    context.motorcycleTransport.update(transportState,
        context.config.motorcycleTransport.scheduleDelay, context.config.motorcycleTransport)
    context.motorcycleTransport.update(transportState,
        context.config.motorcycleTransport.travelDuration, context.config.motorcycleTransport)
    local transportCash = transportState.money
    check("flatbed_pickup_archives_and_pays", context.jobService.completePickup(transportState,
        transportedJob.id) and #transportState.jobs.active == 0
        and #transportState.jobs.completed == 1
        and transportState.money == transportCash + transportedJob.quote)
    check("quote_covers_parts", offer.quote > offer.partsCost)
    local availableBikes = {}
    local availableProblems = {}
    for _, template in ipairs(context.jobs.templates()) do
        availableBikes[template.bikeKey] = true
        availableProblems[template.service] = true
    end
    check("random_offer_bike_is_available", availableBikes[offer.bikeKey] == true)
    check("random_offer_problem_is_available", availableProblems[offer.service] == true)
    for sequence, template in ipairs(context.jobs.templates()) do
        local rosterOffer = context.jobs.createOffer(sequence)
        local key = context.jobs.bikeKeyFor(rosterOffer)
        check("roster_bike_key_" .. sequence, availableBikes[key] == true)
        check("roster_mounted_sprite_" .. sequence,
            context.assets.get("motorcycleMounted_" .. key) ~= nil)
        check("roster_rear_sprite_" .. sequence,
            context.assets.get("motorcycleRear_" .. key) ~= nil)
    end
    for _, kind in ipairs({ "oil", "brake", "chain", "stator", "suspension",
            "belt", "spoke", "carb", "magneto", "coolant" }) do
        local part = context.assets.get("repairPart_" .. kind)
        check("repair_part_sprite_" .. kind, part and part:getWidth() == 128
            and part:getHeight() == 128)
    end
    for _, tool in ipairs(RepairTasks.tools()) do
        local sprite = context.assets.get("repairTool_" .. tool)
        check("repair_tool_sprite_" .. tool, sprite and sprite:getWidth() == 128
            and sprite:getHeight() == 128)
    end
    local legacyJob = {
        sequence = 1,
        bike = { make = "Suzuki", model = "GSX-R600" },
        artwork = "motorcycleSide",
    }
    check("legacy_job_bike_migration", context.jobs.ensureBikeSprite(legacyJob) == "redSupersport"
        and legacyJob.artwork == "motorcycleService_redSupersport")
    check("legacy_repair_kind_migration", RepairTasks.kindFor({
        service = "Cooling and drive-chain service",
        parts = { "coolant", "sealed drive chain", "chain adjuster set" },
    }) == "coolant")
    local miniState = context.State.newGame(2)
    local miniOffer = context.jobs.createOffer(1)
    miniOffer.transportRequired = false
    context.jobs.accept(miniOffer)
    miniState.jobs.active[1] = miniOffer
    miniState.selectedJobId = miniOffer.id
    check("repair_minigame_starts", context.repairMinigameScreen.begin(miniState, "diagnose"))
    local miniTask = miniState.repairMinigame
    local wrongChannel = miniTask.reader.requiredChannelIndex == 1 and 2 or 1
    miniTask.reader.channelIndex = wrongChannel
    context.repairMinigameScreen.pressButton(miniState, "ok")
    check("diagnostic_reader_rejects_wrong_channel", miniTask.reader.step == 0)
    miniTask.reader.channelIndex = miniTask.reader.requiredChannelIndex
    local diagnosticAction
    for _ = 1, 4 do
        diagnosticAction = context.repairMinigameScreen.pressButton(miniState, "ok") or diagnosticAction
    end
    check("diagnostic_reader_accepts_buttons", diagnosticAction == "diagnose"
        and miniTask.reader.step == 3)
    for index, template in ipairs(context.jobs.templates()) do
        local repairState = context.State.newGame(2)
        local repairOffer = context.jobs.createOffer(index)
        repairOffer.repairKind = template.repairKind
        repairOffer.service = template.service
        repairOffer.parts = template.parts
        repairOffer.difficulty = template.difficulty
        repairOffer.transportRequired = false
        context.jobs.accept(repairOffer)
        context.jobs.diagnose(repairOffer)
        repairState.jobs.active[1] = repairOffer
        repairState.selectedJobId = repairOffer.id
        check("repair_interaction_starts_" .. template.repairKind,
            context.repairMinigameScreen.begin(repairState, "repair"))
        local repairTask = repairState.repairMinigame
        local definition = RepairTasks.get(template.repairKind)
        check("repair_kind_is_stable_" .. template.repairKind,
            repairTask.kind == template.repairKind and repairTask.phase == "part")
        context.repairMinigameScreen.pressButton(repairState, "ok")
        check("part_drop_does_not_finish_" .. template.repairKind,
            repairTask.phase == "tool" and not repairTask.complete)
        local wrongToolIndex = RepairTasks.toolIndex(definition.tool) % #RepairTasks.tools() + 1
        context.repairMinigameScreen.pressButton(repairState, "tool" .. wrongToolIndex)
        context.repairMinigameScreen.pressButton(repairState, "ok")
        check("wrong_tool_rejected_" .. template.repairKind, repairTask.phase == "tool")
        context.repairMinigameScreen.pressButton(repairState,
            "tool" .. RepairTasks.toolIndex(definition.tool))
        local guard, direction = 0, "left"
        while repairTask.phase ~= "inspect" and guard < 120 do
            guard = guard + 1
            if repairTask.phase == "tool" then
                context.repairMinigameScreen.pressButton(repairState, "ok")
            elseif repairTask.phase == "operate" then
                if definition.gesture == "adjust" then
                    repairTask.adjustValue = 0.5
                    context.repairMinigameScreen.pressButton(repairState, "ok")
                elseif definition.gesture == "hold" then
                    context.repairMinigameScreen.pressButton(repairState, "ok")
                else
                    context.repairMinigameScreen.pressButton(repairState, direction)
                    direction = direction == "left" and "right" or "left"
                end
            end
        end
        check("tool_work_completes_" .. template.repairKind,
            repairTask.phase == "inspect" and repairTask.complete)
        check("inspection_click_confirms_" .. template.repairKind,
            context.repairMinigameScreen.mousepressed(repairState, 676, 347) == "repair")
        check("inspection_confirms_" .. template.repairKind,
            context.repairMinigameScreen.pressButton(repairState, "ok") == "repair")
    end
    local clickState = context.State.newGame(3)
    local clickOffer = context.jobs.createOffer(1)
    clickOffer.transportRequired = false
    context.jobs.accept(clickOffer)
    context.jobs.diagnose(clickOffer)
    clickState.jobs.active[1] = clickOffer
    clickState.selectedJobId = clickOffer.id
    clickState.screen = "service"
    local clickContext = {
        state = clickState,
        jobService = context.jobService,
        serviceScreen = context.serviceScreen,
        repairMinigameScreen = context.repairMinigameScreen,
        roadTestScreen = context.roadTestScreen,
        saveCurrent = function() return true end,
    }
    local unstockedClick = context.input.mousepressed(200, 550, 1, clickContext)
    check("unstocked_repair_click_returns_false", unstockedClick == false)
    check("unstocked_repair_stays_at_service",
        clickState.screen == "service" and clickOffer.stage == "repair")
    check("unstocked_repair_explains_parts_requirement",
        clickState.message and clickState.message:find("service kit", 1, true) ~= nil)
    clickState.inventory.parts[clickOffer.repairKind] = 1
    check("stocked_repair_minigame_opens",
        context.input.mousepressed(200, 550, 1, clickContext)
        and clickState.screen == "repair_minigame")
    clickState.repairMinigame.phase = "inspect"
    clickState.repairMinigame.complete = true
    check("green_check_advances_work_order_to_road_test",
        context.input.mousepressed(676, 347, 1, clickContext)
        and clickOffer.stage == "road_test" and clickOffer.checklist.repaired
        and clickState.screen == "service"
        and context.procurement.quantity(clickState, clickOffer.repairKind) == 0)
    local serviceState = context.State.newGame(1)
    serviceState.pendingOffer = offer
    check("accept_work_order", context.jobService.acceptOffer(serviceState))
    check("diagnose_work_order", context.jobService.diagnose(serviceState, offer.id))
    local cashBeforeParts = serviceState.money
    local blockedRepair = context.jobService.repair(serviceState, offer.id)
    check("repair_requires_stocked_parts", not blockedRepair and offer.stage == "repair")
    local purchased, purchaseOrder = context.procurement.orderDelivery(serviceState,
        offer.repairKind)
    check("parts_counter_purchase", purchased and purchaseOrder.id == "PO-0001"
        and purchaseOrder.status == "awaiting_delivery")
    check("ordered_parts_wait_for_van",
        context.procurement.quantity(serviceState, offer.repairKind) == 0)
    check("parts_truck_groups_waiting_order", context.deliveryVehicle.schedule(serviceState,
        serviceState.procurement, context.config.partsDelivery)
        and purchaseOrder.status == "assigned_to_van")
    context.deliveryVehicle.update(serviceState, context.config.partsDelivery.scheduleDelay,
        context.config.partsDelivery)
    context.deliveryVehicle.update(serviceState, context.config.partsDelivery.backingDuration,
        context.config.partsDelivery)
    check("parts_truck_parks", serviceState.delivery.state == "parked_closed")
    check("parts_truck_door_opens", context.deliveryVehicle.toggleDoor(serviceState))
    context.deliveryVehicle.update(serviceState, context.config.partsDelivery.cargoDuration,
        context.config.partsDelivery)
    check("parts_truck_uses_five_frame_cargo_animation",
        context.deliveryVehicle.cargoFrame(serviceState, context.config.partsDelivery)
            == context.config.partsDelivery.cargoFrameCount)
    check("parts_manifest_available", #context.procurement.manifest(serviceState) == 1)
    check("loaded_truck_cannot_close", not context.world.closePartsVan(serviceState))
    check("manifest_receives_exact_order",
        context.procurement.receiveOrder(serviceState, purchaseOrder.id)
        and context.procurement.quantity(serviceState, offer.repairKind) == 1
        and purchaseOrder.status == "received")
    check("delivery_item_cannot_be_received_twice",
        not context.procurement.receiveOrder(serviceState, purchaseOrder.id))
    check("empty_truck_can_close", context.world.closePartsVan(serviceState)
        and serviceState.delivery.state == "door_closing")
    check("parts_truck_cargo_closes_to_parked",
        context.deliveryVehicle.update(serviceState,
            context.config.partsDelivery.cargoDuration, context.config.partsDelivery)
            == "cargo_closed" and serviceState.delivery.state == "parked_closed")
    check("parts_truck_departure_starts",
        context.deliveryVehicle.depart(serviceState)
        and serviceState.delivery.state == "departing")
    check("parts_truck_departure_finishes",
        context.deliveryVehicle.update(serviceState,
            context.config.partsDelivery.backingDuration, context.config.partsDelivery)
            == "departed" and serviceState.delivery.state == "absent")
    check("repair_work_order", context.jobService.repair(serviceState, offer.id))
    check("parts_deducted", serviceState.money == cashBeforeParts - offer.partsCost)
    check("repair_consumes_inventory",
        context.procurement.quantity(serviceState, offer.repairKind) == 0)

    serviceState.selectedJobId = offer.id
    check("road_test_starts", context.roadTestScreen.begin(serviceState))
    local roadStageBeforeCancel = offer.stage
    check("road_test_close_returns_without_completion", context.input.closeCurrent({
        state = serviceState, roadTestScreen = context.roadTestScreen,
    }) and serviceState.screen == "service" and serviceState.roadTest == nil
        and offer.stage == roadStageBeforeCancel)
    check("road_test_restarts_after_safe_close", context.roadTestScreen.begin(serviceState))
    local idleRoadTask = serviceState.roadTest
    idleRoadTask.countdown = 0
    local idleLane = idleRoadTask.lane
    local idleCameraDistance = idleRoadTask.cameraDistance
    context.roadTestScreen.update(serviceState, 0.05, 0, false, false)
    check("road_test_auto_forward_without_input",
        idleRoadTask.distance > 0 and idleRoadTask.lane == idleLane)
    check("road_test_camera_always_moves_forward",
        idleRoadTask.cameraDistance > idleCameraDistance)
    check("road_test_camera_and_course_stay_synchronized",
        math.abs(idleRoadTask.cameraDistance - idleRoadTask.distance) < 0.001)
    check("road_test_traffic_spawned", idleRoadTask.traffic
        and #idleRoadTask.traffic > 0)
    local runnerSnapshot = context.roadTestScreen.debugRunner(serviceState)
    check("road_test_runner_projects_track", runnerSnapshot
        and runnerSnapshot.vertexCount == 242
        and runnerSnapshot.sectionCount > 0
        and runnerSnapshot.near.halfWidth > runnerSnapshot.far.halfWidth)
    idleRoadTask.speed = 0
    for _ = 1, 4 do
        context.roadTestScreen.update(serviceState, 0.05, 0, true, false)
    end
    check("road_test_throttle_responds_quickly", idleRoadTask.speed >= 80)
    local sprintSpeedBefore = idleRoadTask.speed
    context.roadTestScreen.update(serviceState, 0.05, 0, true, false, true)
    check("road_test_sprint_boosts_acceleration", idleRoadTask.speed > sprintSpeedBefore)
    check("road_test_course_is_extended",
        context.config.roadTest.courseLength >= context.config.roadTest.departureLength * 8)
    idleRoadTask.speed = context.config.roadTest.maxSpeed
    idleRoadTask.depth = 1
    context.roadTestScreen.update(serviceState, 0.05, 0, false, true)
    local brakingDepth = idleRoadTask.depth
    idleRoadTask.speed = 0
    for _ = 1, 8 do
        context.roadTestScreen.update(serviceState, 0.05, 0, false, false)
    end
    check("road_test_deceleration_pulls_rider_back", idleRoadTask.depth < brakingDepth)
    context.roadTestScreen.update(serviceState, 0.05, -1, true, false)
    check("road_test_lean_follows_steering", idleRoadTask.lean < -0.01)
    local trafficCar = idleRoadTask.traffic[1]
    trafficCar.worldZ = idleRoadTask.cameraDistance + 160
    trafficCar.lane = idleRoadTask.lane
    idleRoadTask.speed = context.config.roadTest.maxSpeed
    idleRoadTask.trafficHitTimer = 0
    context.roadTestScreen.update(serviceState, 0.05, 0, false, false)
    check("road_test_traffic_collision_slows_bike", trafficCar.hit
        and idleRoadTask.trafficHits > 0)
    check("road_test_traffic_hit_animation_starts", idleRoadTask.trafficHitTimer > 0
        and idleRoadTask.trafficHitElapsed == 0)
    idleRoadTask.distance = context.config.roadTest.courseLength - 1
    idleRoadTask.speed = context.config.roadTest.maxSpeed
    local roadAction = context.roadTestScreen.update(serviceState, 0.05, 0, true, false)
    check("road_test_reaches_review", roadAction == nil and serviceState.roadTest.status == "review")
    check("road_test_redo_resets_course", context.roadTestScreen.retry(serviceState)
        and serviceState.roadTest.status == "running"
        and serviceState.roadTest.distance == 0)
    local retryTask = serviceState.roadTest
    retryTask.countdown = 0
    retryTask.distance = context.config.roadTest.courseLength - 1
    retryTask.speed = 0
    context.roadTestScreen.update(serviceState, 0.05, 0, true, false)
    check("road_test_review_after_redo", retryTask.status == "review")
    context.roadTestScreen.finish(serviceState)
    check("road_test_completes", context.jobService.roadTest(serviceState, offer.id))
    check("road_test_waits_for_owner_handoff", #serviceState.jobs.active == 1
        and offer.stage == "ready_for_pickup"
        and serviceState.money == cashBeforeParts - offer.partsCost)
    check("owner_pickup_completes_handoff", context.jobService.updateOwnerPickups(serviceState,
        context.config.motorcycleTransport.ownerPickupDelay,
        context.config.motorcycleTransport.ownerPickupDelay))
    check("job_archived", #serviceState.jobs.active == 0 and #serviceState.jobs.completed == 1)
    check("payment_collected", serviceState.money == cashBeforeParts - offer.partsCost + offer.quote)

    local valid = context.save.validate({
        saveVersion = context.save.version,
        money = serviceState.money,
        revenue = serviceState.revenue,
        expenses = serviceState.expenses,
        reputation = serviceState.reputation,
        nextJobNumber = serviceState.nextJobNumber,
        jobs = serviceState.jobs,
    })
    check("save_schema_valid", valid)
    local legacy = {
        saveVersion = 1, money = 1250, revenue = 0, expenses = 0, reputation = 0,
        nextJobNumber = 2, jobs = { active = {{
            id = "MBM-0001", sequence = 1, status = "active", stage = "diagnosis",
            bike = { make = "Suzuki", model = "GSX-R600" }, checklist = {},
        }}, completed = {}, declined = {} },
    }
    local migrated = context.saveSchema.migrate(legacy)
    check("save_v1_migrates", migrated and migrated.saveVersion == context.save.version)
    check("migration_assigns_stable_identities", migrated
        and migrated.jobs.active[1].clientId == "CLIENT-0001"
        and migrated.jobs.active[1].motorcycleId == "BIKE-0001")
    local duplicate = context.saveSchema.copy(migrated)
    duplicate.jobs.completed[1] = context.saveSchema.copy(duplicate.jobs.active[1])
    check("duplicate_work_order_rejected", not context.saveSchema.validate(duplicate))
    local loungeSeats = {}
    context.world.customer:reset(nil, true)
    check("opening_customer_arrives_quickly",
        context.world.customer.timer >= context.config.customer.initialArrivalDelayMin
        and context.world.customer.timer <= context.config.customer.initialArrivalDelayMax)
    for _ = 1, 6 do
        context.world.customer:reset()
        check("recurring_arrival_uses_realistic_range_" .. _,
            context.world.customer.timer >= context.config.customer.arrivalDelayMin
            and context.world.customer.timer <= context.config.customer.arrivalDelayMax)
        loungeSeats[context.world.customer.seat.name] = true
    end
    check("lounge_rotates_all_seats", loungeSeats["left-chair"] and loungeSeats.couch
        and loungeSeats["right-chair"])
    context.save.delete(3)
    serviceState.pendingOffer = context.jobs.createOffer(serviceState.nextJobNumber)
    local savedCustomer = {
        state = "waiting", x = 812, y = 320, visible = true, timer = 0,
        waitTimer = 42, waypoint = 10, facing = -1, animationClock = 3,
        characterIndex = 2, seatIndex = 2,
    }
    local reviewingCustomer = context.saveSchema.copy(savedCustomer)
    reviewingCustomer.state = "reviewing"
    check("open_review_restores_as_waiting", context.world.customer:restore(reviewingCustomer)
        and context.world.customer.state == "waiting"
        and context.world.customer.waitTimer == reviewingCustomer.waitTimer)
    context.save.delete(2)
    local deliverySaveState = context.State.newGame(2)
    context.procurement.orderDelivery(deliverySaveState, "brake")
    context.deliveryVehicle.schedule(deliverySaveState, deliverySaveState.procurement,
        context.config.partsDelivery)
    context.deliveryVehicle.update(deliverySaveState,
        context.config.partsDelivery.scheduleDelay, context.config.partsDelivery)
    context.deliveryVehicle.update(deliverySaveState,
        context.config.partsDelivery.backingDuration / 2, context.config.partsDelivery)
    check("mid_delivery_save_write", context.save.save(2, deliverySaveState,
        { x = 520, y = 480, facing = 1 }))
    local resumedDelivery = context.save.load(2)
    check("mid_delivery_save_restores_truck", resumedDelivery
        and resumedDelivery.delivery.state == "backing"
        and resumedDelivery.delivery.progress > 0 and resumedDelivery.delivery.progress < 1
        and resumedDelivery.procurement.orders[1].status == "assigned_to_van")
    context.save.delete(2)
    local transportSaveState = context.State.newGame(2)
    local transportSaveJob = context.jobs.createOffer(2)
    transportSaveJob.transportRequired = true
    context.jobs.accept(transportSaveJob)
    transportSaveState.jobs.active[1] = transportSaveJob
    context.motorcycleTransport.schedule(transportSaveState, transportSaveJob, "inbound",
        context.config.motorcycleTransport)
    context.motorcycleTransport.update(transportSaveState,
        context.config.motorcycleTransport.scheduleDelay, context.config.motorcycleTransport)
    context.motorcycleTransport.update(transportSaveState,
        context.config.motorcycleTransport.travelDuration / 2,
        context.config.motorcycleTransport)
    check("mid_flatbed_save_write", context.save.save(2, transportSaveState,
        { x = 520, y = 480, facing = 1 }))
    local resumedTransport = context.save.load(2)
    check("mid_flatbed_save_restores_transport", resumedTransport
        and resumedTransport.motorcycleTransport.state == "arriving"
        and resumedTransport.motorcycleTransport.loaded
        and resumedTransport.motorcycleTransport.jobId == transportSaveJob.id)
    context.save.delete(2)
    check("save_round_trip_write", context.save.save(3, serviceState,
        { x = 510, y = 470, facing = 1 }, savedCustomer))
    local lobbyRoundTrip = context.save.load(3)
    check("pending_estimate_survives_save", lobbyRoundTrip
        and lobbyRoundTrip.pendingOffer
        and lobbyRoundTrip.pendingOffer.id == serviceState.pendingOffer.id)
    check("waiting_customer_survives_save", lobbyRoundTrip and lobbyRoundTrip.customer
        and lobbyRoundTrip.customer.state == "waiting" and lobbyRoundTrip.customer.waitTimer == 42)
    serviceState.money = serviceState.money + 1
    check("save_backup_write", context.save.save(3, serviceState,
        { x = 512, y = 468, facing = -1 }, savedCustomer))
    check("save_primary_can_be_damaged_for_recovery_test",
        love.filesystem.write("slot-3.lua", "return { broken ="))
    local recovered = context.save.load(3)
    check("save_recovers_last_valid_backup", recovered and recovered.recovered
        and recovered.money == serviceState.money - 1 and recovered.pendingOffer ~= nil
        and recovered.procurement and #recovered.procurement.orders == 1
        and recovered.procurement.orders[1].id == "PO-0001")
    context.save.delete(3)

    context.State.applySave(context.state, context.State.newGame(1))
    context.world.load()
    local renderOffer = context.jobs.createOffer(1)
    renderOffer.transportRequired = false
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
    elseif preview == "diagnostic" then
        context.state.selectedJobId = renderOffer.id
        context.repairMinigameScreen.begin(context.state, "diagnose")
    elseif preview == "repair" then
        context.state.selectedJobId = renderOffer.id
        context.repairMinigameScreen.begin(context.state, "repair")
        advanceRepairPreview(context.repairMinigameScreen, context.state,
            os.getenv("MAJIC_BLUE_REPAIR_PREVIEW") or "part")
    elseif preview == "road_test" then
        local roadOffer = context.jobs.createOffer(2)
        roadOffer.transportRequired = false
        context.jobs.accept(roadOffer)
        context.jobs.diagnose(roadOffer)
        context.jobs.repair(roadOffer)
        context.state.jobs.active[1] = roadOffer
        context.state.selectedJobId = roadOffer.id
        context.roadTestScreen.begin(context.state)
        local previewDistance = tonumber(os.getenv("MAJIC_BLUE_ROAD_TEST_DISTANCE"))
        if previewDistance and context.state.roadTest then
            context.state.roadTest.distance = math.max(0,
                math.min(context.config.roadTest.courseLength, previewDistance))
            context.state.roadTest.countdown = 0
            context.state.roadTest.depth = context.state.roadTest.distance > 0
                and context.config.roadTest.cameraRiderDepthBase
                    + context.config.roadTest.cameraRiderDepthRange
                or 0
            context.state.roadTest.cameraDistance = context.state.roadTest.distance
            if context.state.roadTest.distance >= context.config.roadTest.courseLength then
                context.state.roadTest.speed = 0
                context.state.roadTest.status = "review"
            end
        end
        local previewLean = tonumber(os.getenv("MAJIC_BLUE_ROAD_TEST_LEAN"))
        if previewLean and context.state.roadTest then
            context.state.roadTest.lean = previewLean
        end
    elseif preview == "computer" then
        context.computerScreen.enter(context.state)
        local previewTab = os.getenv("MAJIC_BLUE_COMPUTER_TAB")
        if previewTab then context.computerScreen.keypressed(context.state, previewTab) end
        context.state.screen = "computer"
    elseif preview == "delivery_manifest" or preview == "parts_van" then
        context.procurement.orderDelivery(context.state, "oil")
        context.deliveryVehicle.schedule(context.state, context.state.procurement,
            context.config.partsDelivery)
        context.state.delivery.progress = 1
        context.state.delivery.doorProgress = 1
        context.state.delivery.state = "cargo_open"
        context.state.screen = preview == "delivery_manifest" and "delivery_manifest" or "world"
    elseif preview == "flatbed_inbound" or preview == "flatbed_outbound" then
        context.state.jobs.active = {}
        local flatbedJob = context.jobs.createOffer(3)
        flatbedJob.transportRequired = true
        context.jobs.accept(flatbedJob)
        if preview == "flatbed_outbound" then flatbedJob.stage = "pickup_transport" end
        context.state.jobs.active[1] = flatbedJob
        context.motorcycleTransport.schedule(context.state, flatbedJob,
            preview == "flatbed_inbound" and "inbound" or "outbound",
            context.config.motorcycleTransport)
        context.state.motorcycleTransport.progress = 1
        context.state.motorcycleTransport.state = "parked"
        context.state.screen = "world"
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
