-- Stable visible floor-contact anchors. The mechanic used to anchor against
-- the empty bottom of its 512px cells, which offset every animation pose.
return {
    ["mechanic-raccoon"] = {
        idle = { { x = 256, y = 457 }, { x = 255.5, y = 457 } },
        walk = {
            { x = 256, y = 457 }, { x = 255.5, y = 457 }, { x = 255.5, y = 457 },
            { x = 256, y = 457 }, { x = 255.5, y = 457 }, { x = 256, y = 457 },
        },
        use = { { x = 255.5, y = 457 }, { x = 255.5, y = 457 }, { x = 255.5, y = 457 } },
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
