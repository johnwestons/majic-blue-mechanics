-- Stable floor-contact anchors inherited from Picture Shop's approved client
-- strips. Mouse Frontier's mechanic raccoon strips use their canonical
-- 512-pixel bottom baseline.
return {
    ["mechanic-raccoon"] = {
        idle = { { x = 256, y = 512 }, { x = 256, y = 512 } },
        walk = {
            { x = 256, y = 512 }, { x = 256, y = 512 }, { x = 256, y = 512 },
            { x = 256, y = 512 }, { x = 256, y = 512 }, { x = 256, y = 512 },
        },
        use = { { x = 256, y = 512 }, { x = 256, y = 512 }, { x = 256, y = 512 } },
    },
    ["business-dragon"] = {
        idle = { { x = 255.5, y = 477 }, { x = 255.5, y = 477 } },
        walk = {
            { x = 255.0, y = 477 }, { x = 255.0, y = 477 },
            { x = 255.0, y = 477 }, { x = 255.5, y = 477 },
        },
        sit = { { x = 256.0, y = 477 }, { x = 256.0, y = 478 } },
    },
    ["business-fox"] = {
        idle = { { x = 255.5, y = 477 }, { x = 255.5, y = 477 } },
        walk = {
            { x = 255.5, y = 477 }, { x = 255.5, y = 477 },
            { x = 255.0, y = 477 }, { x = 255.5, y = 477 },
        },
        sit = { { x = 256.0, y = 477 }, { x = 256.0, y = 478 } },
    },
    ["business-cat"] = {
        idle = { { x = 255.5, y = 477 }, { x = 255.5, y = 477 } },
        walk = {
            { x = 255.0, y = 477 }, { x = 255.0, y = 477 },
            { x = 255.0, y = 477 }, { x = 255.5, y = 477 },
        },
        sit = { { x = 255.5, y = 477 }, { x = 255.5, y = 478 } },
    },
}
