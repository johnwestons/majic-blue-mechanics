# Majic Blue Mechanics testing

## Gameplay smoke suite

Run `RUN_SMOKE_TEST.bat` after gameplay, economy, save, input, navigation, or rendering changes.
The in-engine suite completes ride-in and flatbed work-order lifecycles, parts procurement and van
receiving, repair actions, road testing, owner/transport pickup and payment, migrations, backup
recovery, controller routing, asset contracts, navigation checks, and three rendered frames.

## Visual regression matrix

Run `RUN_VISUAL_TESTS.bat` after screen, world-layout, sprite, vehicle, or UI changes. It runs the full
smoke suite for every capture and writes 14 validated 960x678 PNGs plus `manifest.json` under
`output/visual-regression/`. Review the contact set for clipping, overlap, fallback art, incorrect
depth order, illegible controls, and theme regressions. The output is intentionally ignored local
evidence rather than source art.

The matrix covers title, workshop, estimate, active computer, parts computer, service, diagnostic,
repair part/tool stages, road test, parts van, delivery manifest, and inbound/outbound flatbeds.

## Asset validation

Run `tools/asset_doctor.ps1` to validate the workshop/walkmask pairing and all required runtime sprite
contracts. A change is ready only when gameplay smoke, visual captures, and asset validation pass.
