# Asset provenance

The user explicitly authorized this sister game to reuse tools, code, and assets from Picture Shop and Mouse Frontier before generating replacements. The source projects remain unchanged; the files below are promoted copies with new stable runtime paths.

## From The Picture Shop

Source workspace: `C:\Users\johnw\OneDrive\Documents\ChatGPT\The Picture Shop`

- `assets/workshop/workshop-layout.png` ← `assets/generated/warehouse-layout-final.png` (preserved baseline)
- `assets/workshop/workshop-layout-v2.png` ← ImageGen edit of the preserved workshop layout, with the same walls, doorways, floor boundary, and camera framing but mechanic-shop equipment added
- `assets/workshop/workshop-walkmask.png` ← `assets/generated/warehouse-layout-final-walkmask.png`
- `assets/characters/business-{dragon,fox,cat}/{idle,walk,sit}.png` ← matching approved client strips under `assets/generated/characters/`
- `assets/delivery/delivery-truck-open.png` and `truck-cargo-door-strip.png` ← exact promoted copies of Picture Shop's layered 512×512 delivery truck and five-frame aligned rear cargo-door animation
- `assets/delivery/loading-bay-door-strip.png` ← exact promoted copy of Picture Shop's five-frame roll-up loading-dock door, aligned to the shared warehouse doorway coordinates
- `assets/motorcycles/gsxr-600-{side,poster,action}.png` ← matching starter images under `assets/generated/artwork/` (retained as references)
- `assets/motorcycles/gsxr-600-service.png` ← ImageGen transparent GSX-R service sprite, normalized to the project's 256×256 transparent-sprite contract by `tools/normalize_transparent_sprite.ps1`
- `assets/motorcycles/{naked-black,vintage-red-standard,black-classic,red-supersport,adventure-silver-red,red-vtwin-cruiser}-service.png` ← generated service-view motorcycle sprites based on the six user-provided motorcycle references
- `assets/motorcycles/{naked-black,vintage-red-standard,black-classic,red-supersport,adventure-silver-red,red-vtwin-cruiser}-mounted.png` ← matching rotated three-quarter mounted sprites generated against the user-provided red service-lift reference (`codex-clipboard-025fdad4-e6ce-4e32-b657-0fc33bb67c7c.png`)
- `assets/motorcycles/{adventure-blue-white,ural-tan-classic,bmw-r24-vintage,modern-gray-cruiser}-service.png` ← additional generated service-view sprites based on the next four user-provided motorcycle references
- `assets/motorcycles/{adventure-blue-white,ural-tan-classic,bmw-r24-vintage,modern-gray-cruiser}-mounted.png` ← matching rotated three-quarter mounted sprites using the same lift-angle reference
- `assets/motorcycles/{naked-black,vintage-red-standard,black-classic,red-supersport,adventure-silver-red,red-vtwin-cruiser,adventure-blue-white,ural-tan-classic,bmw-r24-vintage,modern-gray-cruiser}-rear.png` ← new ImageGen direct-rear road-test sprites, color/model matched to the corresponding service roster entry and normalized to the same 256×256 transparent-sprite contract
- Each new sprite is alpha-cleaned with `tools/remove_checkerboard_background.ps1`, then cropped and nearest-neighbor normalized to 256×256. The lift is intentionally not baked into the mounted sprite; the workshop background supplies it while the unchanged walkmask supplies navigation.
- `assets/tools/diagnostic-reader-frame-01.png` through `frame-04.png` ← ImageGen four-frame handheld motorcycle code-reader animation strip. The form follows real motorcycle scan tools with a wide screen, four-way keypad, and dedicated confirm/back controls; the raw strip is retained at `assets/tools/source/diagnostic-reader-strip-generated.png`.
- `assets/repair-parts/{oil,brake,chain,stator,suspension,belt,spoke,carb,magneto,coolant}.png` ← ImageGen motorcycle service-part sprites matched to the workshop's warm pixel-art palette. Each transparent source render is retained under `assets/repair-parts/source/` and nearest-neighbor normalized to a 128×128 runtime canvas.
- `assets/repair-tools/{ratchet,spanner,screwdriver,filter-wrench,funnel}.png` ← ImageGen motorcycle service-tool sprites matched to the repair-part set's dark steel, warm orange, and crisp pixel-art treatment. Each transparent source render is retained under `assets/repair-tools/source/` and nearest-neighbor normalized to a 128×128 runtime canvas.
- `assets/road-test/parking-lot-option-a.png` ← selected scrollable 16-bit pixel-art conversion of the motorcycle shop's rear parking-lot course, generated from the approved daylight parking-lot concept and preserved at 1024×1536 for distance-based scrolling.
- `assets/road-test/industrial-road-segment-01.png` through `industrial-road-segment-03.png` ← regenerated ImageGen endless-runner road cards based on the approved parking-lot style. Their warehouse corridor, loading district, and fenced perimeter variants share the same centered horizon, lane geometry, dash spacing, open foreground, and 1024×1536 runtime contract so they can zoom toward the camera and crossfade without changing the drivable road.
- `assets/road-test/warehouse-street-view-01.png` through `warehouse-street-view-05.png` ← production road-test sequence generated from the warehouse-corridor card. These now remain as matching location studies and fallback art; the runtime uses the derived sky layer and perspective section meshes instead of a stationary street foreground.
- `assets/road-test/runner-road-texture.png` ← ImageGen seamless asphalt tile matched to the warehouse street, then edited to remove baked lane markings so the game can project continuous road lines without distortion.
- `assets/road-test/runner-sky.png` ← ImageGen sky-only edit of the approved warehouse street view. It preserves the daylight pixel-art palette with a clean cloudless sky while removing every stationary fence, tree, building, and ground element that would clash with the moving perspective sections. Clouds are intentionally reserved for future independent moving sprites.
- `assets/road-test/runner-city-horizon.png` ← ImageGen cloudless distant-city horizon layer, drawn behind the road-section meshes so the route has a skyline without baking stationary foreground scenery into the camera layer.
- `assets/road-test/runner-fence-trees.png`, `runner-warehouse-bay.png`, and `runner-clutter.png` ← earlier ImageGen transparent billboard modules retained as source/reference art. They were replaced in the runtime because their small independently passing silhouettes clashed with the continuous street perspective.
- `assets/road-test/runner-left-section.png` and `runner-right-section.png` ← ImageGen seamless fence/tree and warehouse frontage strips, followed by a dedicated alpha-extraction pass. The runtime maps each strip onto consecutive perspective planes whose endpoints share exact projected coordinates, replacing the earlier small billboard props and static foreground scenery.
- `assets/road-test/runner-left-wall-texture-long.png` and `runner-right-wall-texture-long.png` ← purpose-built ultra-wide ImageGen side-wall textures with multiple distinct fence, concrete, warehouse, loading-bay, and service-detail modules. They are projected as the repeating side bands so the road and its surroundings share one scrolling depth system with less visible repetition.
- `assets/road-test/runner-graffiti-{raccoon,fox,owl,snake,wrench,ride,shift,majic}.png` ← transparent ImageGen animal-themed wall decals. The first four are character-only variants; the final four add readable painted words (`WRENCH`, `RIDE`, `SHIFT`, and `MAJIC`). The renderer places a deterministic randomized subset on the long wall bands, allowing future refreshes without changing the base textures.
- `assets/road-test/traffic/traffic-{hatchback-teal,sedan-orange,van-blue,pickup-olive}.png` ← transparent rear-facing ImageGen traffic sprites, normalized to 256×256. The set covers a compact hatchback, sedan, delivery van, and pickup truck for future road-test traffic spawning and lane interactions.
- `assets/road-test/rider-hit/frame-01.png` through `frame-04.png` ← four-frame transparent ImageGen rear-view collision reaction for the rider. The motorcycle remains a separate layer, so the reaction can play over every repaired bike model.
- `assets/road-test/mechanic-raccoon-rider.png` ← rear-view seated mechanic-raccoon rider sprite generated against the existing raccoon character style and normalized to 256×256; the motorcycle is drawn separately so every work order keeps its matching bike.
- `assets/road-test/road-test-cone.png` ← transparent 16-bit pixel-art traffic cone sprite normalized to 128×128; collision logic remains course-data driven while the sprite supplies the visible obstacle.

The original warehouse art remains in the repo as a fallback/reference. The v2 runtime layout is the mechanic-shop edit: it adds service lifts, tire racks, tool walls, parts shelves, oil storage, workbenches, and a reception counter while preserving the existing walkmask dimensions and alignment.

## From Mouse Frontier 8.10

Source workspace: `C:\Users\johnw\OneDrive\Documents\ChatGPT\Mouse Frontier 8.10`

- `assets/characters/mechanic-raccoon/{idle,walk,use}.png` ← matching strips under `assets/sprites/character-animations/mechanic-raccoon/`

The character loader follows Mouse Frontier's fixed-frame, nearest-neighbor, lazy-loading pattern while using Picture Shop's centralized action registration and precomputed anchoring approach.

## Reused code/tooling patterns

- Picture Shop: callback-only `main.lua`, 960×678 viewport, walkmask navigation, customer routing, screen composition, job-domain separation, versioned slots, asset gate, smoke runner, and source-control boundary.
- Mouse Frontier: character strip streaming, 512-pixel action sheets, baseline anchoring, deterministic stabilization discipline, and Sprite Doctor/asset-doctor workflow.
