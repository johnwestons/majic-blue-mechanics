# Source-control boundary

Majic Blue Mechanics is its own Git repository. It shares the configured author name and email with Picture Shop, but it does not share history, remotes, objects, or a working tree.

## Tracked project material

- LÖVE entry/configuration files, launchers, and every module under `src/`.
- Project documentation under `docs/`.
- Asset validation and preparation tools under `tools/`.
- Promoted runtime art under `assets/`, including approved sister-project copies documented in `asset_provenance.md`.
- The smoke-test runner and its checked-in ignore policy under `.stabilization/`.

## Ignored local/generated material

- Smoke reports and watchdog output under `.stabilization/`.
- Asset-doctor reports and future visual previews under `output/`.
- Editor metadata, temporary files, packages, local LÖVE runtimes, and Python caches.

Ignoring a file does not authorize deleting it. Cleanup or archival of source art is a separate, reviewed task.

## Baseline validation

Before a gameplay or asset-changing commit:

1. Run `RUN_SMOKE_TEST.bat`.
2. Run `RUN_VISUAL_TESTS.bat` and inspect `output/visual-regression/`.
3. Run `powershell -ExecutionPolicy Bypass -File tools/asset_doctor.ps1`.
4. Inspect `git status --short --ignored` and the staged file list.
5. Confirm no configured runtime path is ignored.
