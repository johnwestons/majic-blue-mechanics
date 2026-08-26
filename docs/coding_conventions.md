# Majic Blue Mechanics coding conventions

These boundaries deliberately carry forward the proven Picture Shop and Mouse Frontier practices.

- `main.lua` is only a LÖVE callback adapter. Game state and behavior belong in modules.
- One module owns each concern: app routing, state, save files, assets, viewport, input, navigation, interactions, world simulation, work-order rules, work-order services, and each screen renderer.
- Modules return a local table and avoid globals. Shared state is passed explicitly or owned by `src/app.lua`.
- Simulation changes happen in update or input handlers. Drawing does not change game state.
- The game renders to a fixed 960×678 logical canvas. `src/viewport.lua` applies uniform scaling and letterboxing.
- Raster art uses nearest-neighbor filtering. Runtime paths are centralized in `src/config.lua`.
- Core assets are validated during load, by the deterministic engine smoke test, and by `tools/asset_doctor.ps1`.
- Save payloads are versioned and validated before promotion. Every money, job-stage, and completion result triggers a save.
- `src/interaction.lua` selects interactions. `src/navigation.lua` owns walkability and samples the character's feet against the mask.
- `src/jobs.lua` remains a pure domain module. It must not read game state or draw.
- New gameplay requires a deterministic smoke-test checkpoint before it is considered stable.
- Reference/source assets are never overwritten during preparation. Promoted runtime assets receive stable filenames and provenance notes.
- Generated transparent motorcycle, repair-part, and repair-tool art is normalized through `tools/normalize_transparent_sprite.ps1` before runtime use; source-resolution renders remain beside the promoted sprite.
- Do not draw artificial circular or elliptical shadows beneath sprites. Collision footprints follow visible floor contact, not the full PNG canvas.

## Module map

- `src/app.lua`: composition root and screen routing
- `src/state.lua`: new-game defaults and save application
- `src/save.lua` and `src/save_schema.lua`: migrated, reconciled, validated local slots with backups
- `src/assets.lua`: core image loading and validation
- `src/character_assets.lua`: lazy character-strip loading and nearest-neighbor quads
- `src/input.lua` and `src/controller.lua`: keyboard, mouse, and gamepad routing
- `src/navigation.lua`: walkmask and obstacle checks
- `src/interaction.lua`: proximity selection
- `src/world.lua` and `src/world_renderer.lua`: workshop simulation and depth-sorted presentation
- `src/jobs.lua`: motorcycle estimate and legal stage transitions
- `src/repair_tasks.lua`: data-only mappings from work orders to parts, tools, gestures, and work points
- `src/repair_minigame.lua`: repair interaction state, gesture recognition, and completion rules
- `src/job_service.lua`: economy and work-order orchestration
- `src/procurement.lua`, `src/delivery_vehicle.lua`, and `src/motorcycle_transport.lua`: parts and vehicle lifecycles
- `src/screens/`: title, HUD, estimate, computer, manifests, service, road-test, and startup-error presentation
- `src/smoke.lua`: deterministic in-engine checks
