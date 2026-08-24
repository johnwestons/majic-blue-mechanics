# Asset provenance

The user explicitly authorized this sister game to reuse tools, code, and assets from Picture Shop and Mouse Frontier before generating replacements. The source projects remain unchanged; the files below are promoted copies with new stable runtime paths.

## From The Picture Shop

Source workspace: `C:\Users\johnw\OneDrive\Documents\ChatGPT\The Picture Shop`

- `assets/workshop/workshop-layout.png` ← `assets/generated/warehouse-layout-final.png` (preserved baseline)
- `assets/workshop/workshop-layout-v2.png` ← ImageGen edit of the preserved workshop layout, with the same walls, doorways, floor boundary, and camera framing but mechanic-shop equipment added
- `assets/workshop/workshop-walkmask.png` ← `assets/generated/warehouse-layout-final-walkmask.png`
- `assets/characters/business-{dragon,fox,cat}/{idle,walk,sit}.png` ← matching approved client strips under `assets/generated/characters/`
- `assets/motorcycles/gsxr-600-{side,poster,action}.png` ← matching starter images under `assets/generated/artwork/` (retained as references)
- `assets/motorcycles/gsxr-600-service.png` ← ImageGen transparent GSX-R service sprite, normalized to the project's 256×256 transparent-sprite contract by `tools/normalize_transparent_sprite.ps1`

The original warehouse art remains in the repo as a fallback/reference. The v2 runtime layout is the mechanic-shop edit: it adds service lifts, tire racks, tool walls, parts shelves, oil storage, workbenches, and a reception counter while preserving the existing walkmask dimensions and alignment.

## From Mouse Frontier 8.10

Source workspace: `C:\Users\johnw\OneDrive\Documents\ChatGPT\Mouse Frontier 8.10`

- `assets/characters/mechanic-raccoon/{idle,walk,use}.png` ← matching strips under `assets/sprites/character-animations/mechanic-raccoon/`

The character loader follows Mouse Frontier's fixed-frame, nearest-neighbor, lazy-loading pattern while using Picture Shop's centralized action registration and precomputed anchoring approach.

## Reused code/tooling patterns

- Picture Shop: callback-only `main.lua`, 960×678 viewport, walkmask navigation, customer routing, screen composition, job-domain separation, versioned slots, asset gate, smoke runner, and source-control boundary.
- Mouse Frontier: character strip streaming, 512-pixel action sheets, baseline anchoring, deterministic stabilization discipline, and Sprite Doctor/asset-doctor workflow.
