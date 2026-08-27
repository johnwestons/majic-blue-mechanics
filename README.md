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

Motorcycles with charging, vintage ignition, or major suspension problems arrive on the Majic Blue
recovery flatbed instead of appearing directly on the lift. The empty flatbed is a regenerated Picture
Shop-style truck sprite; each job's motorcycle remains a separate sprite that is loaded onto its wood
deck at runtime. The truck waits for the shared loading bay, backs through the same doorway aperture as
the parts-delivery truck, and keeps the roll-up door open until it pulls away. Unload inbound bikes at
the roll-up-door apron before
diagnosis. After a successful road test, ride-in owners return after a short handoff delay; transported
bikes wait for the return flatbed. Jobs are paid and archived only when the motorcycle leaves the shop.

The work-order rotation now covers ten bikes: modern and classic standards, cruisers, supersports, two adventure bikes, a Ural solo, and a vintage BMW. Each has a clean service-bay sprite plus a diagonal mounted sprite for the lift.

Each new client receives a random motorcycle from that fleet and a separate
random problem from the available service list; the generated offer is saved so
it stays unchanged while the client is reviewed.

Diagnosis now opens a handheld code-reader mini-game: select the channel that matches the current repair, confirm it with the orange OK button, run the ECU scan, and confirm the displayed fault before the work order advances. Repair and road-test actions retain their matching movable-part mini-games.

The final road test is a longer behind-the-bike driving course. The bike rolls
forward automatically; hold W/Up to accelerate, Shift to reach maximum speed,
S/Down to brake toward the minimum pace, and A/D or Left/Right to steer. Its
endless-runner camera keeps the rider in the lower-middle of the screen while a
perspective road and long, seamlessly joined warehouse and fence sections stream
out from the vanishing point using the same depth projection. The route starts
behind the shop and returns to
the garage for the finish. Slowing down lets the bike fall back toward the
viewer while the camera continues forward. Cone obstacles are reserved for a
later riding pass. The side walls use long detailed texture strips with
refreshable animal graffiti, including readable `WRENCH`, `RIDE`, `SHIFT`, and
`MAJIC` variants. The static sky and distant city layer are cloudless so any
future clouds can be added as independent moving sprites.

Repair actions now use a three-stage hands-on sequence. The player seats the
matching oil, brake, chain, stator, suspension, belt, spoke, carburetor,
magneto, or coolant component directly on the motorcycle, chooses a tool from
the service tray, and operates it at one or more highlighted work points.
Ratchets use alternating strokes, rotating tools follow circular mouse motion,
adjustments must be released in a green service band, and coolant is filled by
holding the funnel steady. A final inspection is required before the repair is
charged and the work order advances.

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

## Run on Android

Connect one authorized Android phone with USB debugging enabled, then run `./BUILD_ANDROID.ps1 -Install`
from PowerShell. The command packages the shared game, runs its mobile smoke check, builds and verifies
the debug APK, installs it, and confirms startup. Use `-PackageOnly` when you only need to validate the
portable `.love` package, or omit `-Install` to build the APK without changing a phone. See
`ANDROID_PORT.md` for the device checklist and output paths.

## Controls

- Move: **WASD** or arrow keys
- Interact: **E** or Enter
- Estimate: **A** accept, **D** decline, Escape decide later
- Service bay: **D** diagnose, **R** repair, **T** road test
- Repair bench: drag with the mouse; hold and move the active tool; **1–5** select tools; arrows operate; Enter confirms
- Road test: **W/Up** accelerate, hold **Shift** for maximum speed, **S/Down** brake, **A/D** or **Left/Right** steer
- View camera: mouse wheel zooms around the cursor; hold the middle mouse button and drag to pan
- Close a screen / return to title: **Escape**
- Title: **N** new, **C** continue, **D** delete, **Q** quit

Mouse buttons are available for estimate, service, and close actions. On the title screen, clicking selects a save slot.

### Controller

- Shop floor: left stick or D-pad moves; **A** uses the nearby interaction; **Start** saves and returns to the title.
- Menus and panels: either stick moves the gold cursor; **A** clicks; **B/Back** closes; D-pad retains list and tab navigation.
- Title: D-pad selects a slot; **A/Start** continues; **X** starts a new shop; **Y** deletes with confirmation.
- Service bay: **X** starts diagnosis, **Y** starts repair, and right shoulder starts the road test.
- Road test: left stick/D-pad steers, right trigger or **A** accelerates, left trigger or **X** brakes,
  right shoulder enables maximum speed, **A** approves at review, **X** retries, and **B** cancels.

### Phone

- Shop floor: use the left virtual stick to walk and the contextual **USE** button to interact.
- Menus and hands-on repair screens: tap, drag, rotate, hold, and release directly on the controls.
- Every scene and GUI supports two-finger pinch zoom and two-finger pan. Each view remembers its own
  zoom and position; virtual controls remain fixed at the phone edges.
- Road test: steer with the stick and hold the separate throttle, brake, and boost buttons together as needed.
- Android Back closes the current panel; leaving the app releases held controls and saves progress.

The office computer now separates active work orders, completed service history, customer/motorcycle
records, parts inventory, and shop finances. Click a work order for the full complaint, service, parts,
estimate, and stable record identities; number keys 1–5 change tabs and Up/Down plus Enter opens a
selected order. Parts must be stocked before a repair. Orders placed in the Parts tab are grouped onto
the Picture Shop-style box delivery truck. The shared loading dock opens through its five-frame roll-up
animation before the truck backs into the dock aperture; open the truck's animated rear cargo
door, inspect the manifest, and receive each package before
the matching repair can begin.

## Saves and safety

The game owns three versioned local slots under the LÖVE save directory. A pending file is decoded and validated before promotion; the last valid primary is retained as a backup. New games and every economy or work-order stage save automatically.
Save format 5 also retains the waiting rider, their unchanged estimate, lounge seat and wait time,
stable customer and motorcycle identities, parts inventory, purchase-order history, and an in-progress
parts-truck or motorcycle-flatbed delivery. Version-1 through version-4 shops migrate when loaded.

The first rider reaches the lounge within a few seconds. Later riders arrive at varied 60–150 second
intervals, rotate through the three lounge seats, and wait up to five minutes before leaving.

## Validation

- `RUN_SMOKE_TEST.bat` runs deterministic work-order, economy, navigation, camera/gesture, asset, customer-route, and three-frame render checks.
- `RUN_SPRITE_DOCTOR.bat -AuditOnly` audits every character strip, writes contact sheets/GIFs, and checks the generated runtime catalog. Run it without `-AuditOnly` to open the Sprite Motion Lab; `-Character mechanic-raccoon -Action use` opens a specific animation.
- `RUN_VISUAL_TESTS.bat` captures and validates a 17-scene matrix under `output/visual-regression/`, including the Sprite Motion Lab, road-test driving and finish states, and a 1170×540 phone-layout capture in addition to title, workshop, UI, repair, delivery, manifest, and flatbed scenes.
- `tools/asset_doctor.ps1` validates required dimensions, alpha-capable character sheets, workshop/mask alignment, and a strict black/white walkmask.
- `BUILD_ANDROID.ps1 -PackageOnly` builds and smoke-tests the shared mobile package; `BUILD_ANDROID.ps1 -Install` builds, installs, and verifies the debug APK on one connected phone.
- `tools/normalize_transparent_sprite.ps1` crops a generated transparent motorcycle to the project's square sprite contract without adding a floor shadow.
- The same normalizer promotes generated repair-part and repair-tool art to the 128×128 transparent UI-sprite contract.
- `tools/remove_checkerboard_background.ps1` removes generated checkerboard preview pixels before normalization.
- `tools/split_alpha_sprite_strip.ps1` splits the four-frame diagnostic-reader render into the runtime's 256×256 animation frames.

See `docs/coding_conventions.md`, `docs/source_control.md`, and `docs/asset_provenance.md` for the inherited project rules and exact sister-project sources.
See `docs/SPRITE_WORKFLOW.md` for importing and repairing animation strips, and `docs/testing.md` for the complete gameplay, visual, asset, and phone verification workflow.
On Windows, launch `RUN_GAME.vbs` to start the game without opening a command window. `RUN_GAME.bat` remains available for troubleshooting and shows any startup errors.
