local Catalog = {}

local items = {
    { kind = "oil", label = "Oil service kit", cost = 72 },
    { kind = "brake", label = "Front brake kit", cost = 164 },
    { kind = "chain", label = "Chain & sprocket kit", cost = 238 },
    { kind = "stator", label = "Charging-system kit", cost = 286 },
    { kind = "suspension", label = "Suspension service kit", cost = 214 },
    { kind = "belt", label = "Belt-drive service kit", cost = 336 },
    { kind = "spoke", label = "Spoked-wheel kit", cost = 248 },
    { kind = "carb", label = "Carburetor service kit", cost = 126 },
    { kind = "magneto", label = "Vintage ignition kit", cost = 188 },
    { kind = "coolant", label = "Cooling & chain kit", cost = 196 },
}

local byKind = {}
for _, item in ipairs(items) do byKind[item.kind] = item end

function Catalog.all() return items end
function Catalog.get(kind) return byKind[kind] end

return Catalog
