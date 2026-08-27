-- Generated from assets/characters/sprite-doctor.json by tools/sprite_doctor.py.
-- Run RUN_SPRITE_DOCTOR.bat after importing or repairing character art.
return {
    schemaVersion = 1,
    frameWidth = 512,
    frameHeight = 512,
    referenceHeight = 256,
    alphaThreshold = 16,
    characters = {
        ["business-cat"] = { nativeFacing = -1, actions = {
            idle = {
                path = "assets/characters/business-cat/idle.png", frameCount = 2,
                fps = 0, mode = "hold",
                bounds = { { 120, 73, 392, 458 }, { 120, 73, 392, 458 } },
                anchors = { { x = 255.5, y = 457 }, { x = 255.5, y = 457 } },
            },
            sit = {
                path = "assets/characters/business-cat/sit.png", frameCount = 2,
                fps = 0, mode = "hold",
                bounds = { { 131, 70, 394, 471 }, { 131, 70, 394, 471 } },
                anchors = { { x = 262.5, y = 470 }, { x = 262.5, y = 470 } },
            },
            walk = {
                path = "assets/characters/business-cat/walk.png", frameCount = 4,
                fps = 4.0, mode = "loop",
                bounds = {
                    { 135, 72, 377, 458 }, { 126, 73, 385, 458 },
                    { 126, 72, 386, 458 }, { 126, 73, 385, 458 },
                },
                anchors = {
                    { x = 255.5, y = 457 }, { x = 255.0, y = 457 },
                    { x = 255.5, y = 457 }, { x = 255.0, y = 457 },
                },
            },
        } },
        ["business-dragon"] = { nativeFacing = -1, actions = {
            idle = {
                path = "assets/characters/business-dragon/idle.png", frameCount = 2,
                fps = 0, mode = "hold",
                bounds = { { 106, 73, 405, 458 }, { 106, 73, 405, 458 } },
                anchors = { { x = 255.0, y = 457 }, { x = 255.0, y = 457 } },
            },
            sit = {
                path = "assets/characters/business-dragon/sit.png", frameCount = 2,
                fps = 0, mode = "hold",
                bounds = { { 116, 74, 396, 458 }, { 116, 74, 396, 458 } },
                anchors = { { x = 255.5, y = 457 }, { x = 255.5, y = 457 } },
            },
            walk = {
                path = "assets/characters/business-dragon/walk.png", frameCount = 4,
                fps = 4.0, mode = "loop",
                bounds = {
                    { 126, 73, 387, 458 }, { 120, 72, 393, 458 },
                    { 120, 73, 392, 458 }, { 120, 73, 393, 458 },
                },
                anchors = {
                    { x = 256.0, y = 457 }, { x = 256.0, y = 457 },
                    { x = 255.5, y = 457 }, { x = 256.0, y = 457 },
                },
            },
        } },
        ["business-fox"] = { nativeFacing = -1, actions = {
            idle = {
                path = "assets/characters/business-fox/idle.png", frameCount = 2,
                fps = 0, mode = "hold",
                bounds = { { 126, 73, 387, 458 }, { 126, 73, 387, 458 } },
                anchors = { { x = 256.0, y = 457 }, { x = 256.0, y = 457 } },
            },
            sit = {
                path = "assets/characters/business-fox/sit.png", frameCount = 2,
                fps = 0, mode = "hold",
                bounds = { { 137, 72, 375, 458 }, { 137, 72, 375, 458 } },
                anchors = { { x = 255.5, y = 457 }, { x = 255.5, y = 457 } },
            },
            walk = {
                path = "assets/characters/business-fox/walk.png", frameCount = 4,
                fps = 4.0, mode = "loop",
                bounds = {
                    { 140, 73, 371, 458 }, { 130, 73, 381, 458 },
                    { 130, 73, 382, 458 }, { 130, 73, 381, 458 },
                },
                anchors = {
                    { x = 255.0, y = 457 }, { x = 255.0, y = 457 },
                    { x = 255.5, y = 457 }, { x = 255.0, y = 457 },
                },
            },
        } },
        ["mechanic-raccoon"] = { nativeFacing = -1, actions = {
            idle = {
                path = "assets/characters/mechanic-raccoon/idle.png", frameCount = 2,
                fps = 0.7, mode = "loop",
                bounds = { { 121, 72, 390, 458 }, { 121, 72, 392, 458 } },
                anchors = { { x = 255.0, y = 457 }, { x = 256.0, y = 457 } },
            },
            use = {
                path = "assets/characters/mechanic-raccoon/use.png", frameCount = 3,
                fps = 3.0, mode = "pingpong",
                bounds = {
                    { 98, 73, 415, 458 }, { 102, 73, 409, 458 },
                    { 100, 73, 411, 458 },
                },
                anchors = {
                    { x = 256.0, y = 457 }, { x = 255.0, y = 457 },
                    { x = 255.0, y = 457 },
                },
            },
            walk = {
                path = "assets/characters/mechanic-raccoon/walk.png", frameCount = 6,
                fps = 5.2, mode = "loop",
                bounds = {
                    { 110, 73, 403, 458 }, { 106, 73, 406, 458 },
                    { 111, 73, 401, 458 }, { 108, 73, 403, 458 },
                    { 105, 73, 407, 458 }, { 110, 73, 403, 458 },
                },
                anchors = {
                    { x = 256.0, y = 457 }, { x = 255.5, y = 457 },
                    { x = 255.5, y = 457 }, { x = 255.0, y = 457 },
                    { x = 255.5, y = 457 }, { x = 256.0, y = 457 },
                },
            },
        } },
    },
}
