# Majic Blue Mechanics

A playable LÖVE 2D vertical slice for an isometric motorcycle-mechanic shop game starring a raccoon technician. It is a sister project to The Picture Shop and Mouse Frontier, with its own Git history and save identity.

## Current playable loop

1. Start or continue one of three local shop saves.
2. Walk the mechanic raccoon through the workshop.
3. Meet a client in the lounge and review the motorcycle estimate.
4. Accept or decline the work order.
5. Visit the motorcycle at the service bay.
6. Diagnose it, buy/install the required parts, and complete the road test.
7. Collect payment, build reputation, and take the next customer.

The work-order rotation now covers six bikes: a modern naked bike, an old-school V-twin standard, a classic cruiser, a red supersport, an adventure bike, and a V-twin cruiser. Each has a clean service-bay sprite plus a diagonal mounted sprite for the lift.

The runtime workshop is the regenerated mechanic-shop layout in
`assets/workshop/workshop-layout-v2.png`; it keeps the original Picture Shop
walkmask unchanged. The original GSX-R remains as a fallback/reference in
`assets/motorcycles/gsxr-600-service.png`. The new production set lives in
`assets/motorcycles/*-service.png` and `assets/motorcycles/*-mounted.png`, with
high-resolution generated and alpha-cleaned sources retained under
`assets/motorcycles/source/`.

## Run on Windows

1. Install LÖVE 11.x from <https://love2d.org/>.
2. Double-click `RUN_GAME.bat`.

The launcher finds LÖVE on `PATH`, in a local `runtime` folder, or in the normal Program Files locations. Launch the whole project folder, not `main.lua` by itself.

## Controls

- Move: **WASD** or arrow keys
- Interact: **E** or Enter
- Estimate: **A** accept, **D** decline, Escape decide later
- Service bay: **D** diagnose, **R** repair, **T** road test
- Close a screen / return to title: **Escape**
- Title: **N** new, **C** continue, **D** delete, **Q** quit

Mouse buttons are available for estimate, service, and close actions. On the title screen, clicking selects a save slot.

## Saves and safety

The game owns three versioned local slots under the LÖVE save directory. A pending file is decoded and validated before promotion; the last valid primary is retained as a backup. New games and every economy or work-order stage save automatically.

## Validation

- `RUN_SMOKE_TEST.bat` runs deterministic work-order, economy, navigation, asset, customer-route, and three-frame render checks.
- `tools/asset_doctor.ps1` validates required dimensions, alpha-capable character sheets, workshop/mask alignment, and a strict black/white walkmask.
- `tools/normalize_transparent_sprite.ps1` crops a generated transparent motorcycle to the project's square sprite contract without adding a floor shadow.
- `tools/remove_checkerboard_background.ps1` removes generated checkerboard preview pixels before normalization.

See `docs/coding_conventions.md`, `docs/source_control.md`, and `docs/asset_provenance.md` for the inherited project rules and exact sister-project sources.
