local Config = {
    title = "Majic Blue Mechanics",
    baseWidth = 960,
    baseHeight = 678,
    player = {
        character = "mechanic-raccoon",
        spawnX = 520,
        spawnY = 480,
        speed = 155,
        maxWidth = 154,
        maxHeight = 154,
    },
    customer = {
        characterPool = { "business-dragon", "business-fox", "business-cat" },
        maxWidth = 174,
        maxHeight = 174,
        speed = 72,
        walkAnimationRate = 4,
        arrivalDelay = 1.25,
        betweenCustomersDelay = 2.5,
        maxWaitSeconds = 300,
        interactionRadius = 58,
        route = {
            { x = 645, y = 235 },
            { x = 650, y = 245 },
            { x = 640, y = 270 },
            { x = 630, y = 295 },
            { x = 635, y = 320 },
            { x = 650, y = 340 },
            { x = 680, y = 350 },
            { x = 720, y = 355 },
            { x = 760, y = 360 },
        },
        seatSpots = {
            { name = "left-chair", x = 725, y = 320, facing = 1 },
            { name = "couch", x = 812, y = 320, facing = -1 },
            { name = "right-chair", x = 894, y = 390, facing = -1 },
        },
    },
    interactables = {
        computer = { x = 500, y = 185, radius = 62 },
        -- The regenerated shop has two service lifts. The left lift is the
        -- starter bay and is kept on the original walkmask's floor area.
        serviceBay = { x = 300, y = 336, radius = 86 },
    },
    serviceBay = {
        bikeX = 300,
        bikeY = 336,
        bikeScale = 0.72,
        collisionHalfWidth = 74,
        collisionHalfHeight = 20,
    },
    paths = {
        workshop = "assets/workshop/workshop-layout-v2.png",
        walkmask = "assets/workshop/workshop-walkmask.png",
        motorcycleSide = "assets/motorcycles/gsxr-600-service.png",
        motorcyclePoster = "assets/motorcycles/gsxr-600-poster.png",
        motorcycleAction = "assets/motorcycles/gsxr-600-action.png",
    },
    characters = {
        ["mechanic-raccoon"] = {
            idle = "assets/characters/mechanic-raccoon/idle.png",
            walk = "assets/characters/mechanic-raccoon/walk.png",
            use = "assets/characters/mechanic-raccoon/use.png",
        },
        ["business-dragon"] = {
            idle = "assets/characters/business-dragon/idle.png",
            walk = "assets/characters/business-dragon/walk.png",
            sit = "assets/characters/business-dragon/sit.png",
        },
        ["business-fox"] = {
            idle = "assets/characters/business-fox/idle.png",
            walk = "assets/characters/business-fox/walk.png",
            sit = "assets/characters/business-fox/sit.png",
        },
        ["business-cat"] = {
            idle = "assets/characters/business-cat/idle.png",
            walk = "assets/characters/business-cat/walk.png",
            sit = "assets/characters/business-cat/sit.png",
        },
    },
}

return Config
