# Cameo Package-Ready No-Install Playbook

## Goal

Use this file when Cameo 2022x, 2024x, and 2026x are being staged as controlled package drops rather than traditional installed desktop software.

This matches enclave-style operations better than normal end-user install thinking.

## Truth rail

If the package is no-install, then the runtime contract matters more than the installer story.

That means the real questions are:
- what exact version line is this package
- what Java/runtime expectation comes with it
- where do writable files go
- where do logs go
- where do plugins go
- how is licensing/configuration handled
- how is launch isolated from other package lines

## Operating model

Treat each Cameo line as its own sealed runtime bundle:

- `Cameo-2022xR2`
- `Cameo-2024xR3`
- `Cameo-2026xR1`

Each bundle should have:
- fixed binaries
- fixed plugin set
- fixed companion config
- fixed launcher
- fixed log/output path

Do not let them silently share mutable state unless that sharing is intentional and documented.

## Recommended package layout

Suggested shape:

- `Packages/`
  - `Cameo-2022xR2/`
  - `Cameo-2024xR3/`
  - `Cameo-2026xR1/`
- `Plugins/`
  - `2022xR2/`
  - `2024xR3/`
  - `2026xR1/`
- `Config/`
  - `2022xR2/`
  - `2024xR3/`
  - `2026xR1/`
- `Logs/`
  - `2022xR2/`
  - `2024xR3/`
  - `2026xR1/`
- `Work/`
  - temporary or export staging per line
- `Launchers/`
  - version-pinned `.cmd` or `.ps1` entrypoints

## Package rules

### Rule 1: pin by line

Never label a package only as `Cameo`.

Use the full target line:
- `2022x Refresh2`
- `2024x Refresh3`
- `2026x Refresh1`

### Rule 2: isolate plugins by line

Do not assume a plugin built for one line is safe on another line without rebuild or validation.

Keep plugin folders version-split.

### Rule 3: isolate writable state

If the package is read-only but the app needs writable state:
- redirect logs
- redirect temp/output
- document cache/config behavior

### Rule 4: document runtime assumptions

For each package, capture:
- product line
- refresh level
- required Java support line
- required companion plugins
- local vs TWC target workflows
- read-only vs write-capable usage intent

## Launcher expectations

Each package should have a launcher that makes the runtime explicit.

The launcher should:
- identify the target package line
- set package-local or controlled external paths
- point to the correct plugin folder
- point to the correct config/log/work locations
- avoid accidental cross-line sharing

## Plugin deployment rule

Because you are not depending on normal installs:
- plugin placement becomes part of package composition
- plugin enable/disable becomes a package-build concern
- rollback becomes a package-version concern

This is usually cleaner than post-install drift on user machines.

## Good pairing with the KB/DB

For each package line, store a record containing:
- package name
- package path
- exact Cameo line
- Java/runtime note
- plugin set hash or version list
- supported workflows
- TWC compatibility note
- operator warnings

This lets the local MCP or tool layer reason about what is available before calling anything.

## What the AI should infer from this

If a user says:
- `2022x package`
- `2024x package`
- `2026x package`
- `no install`

then the system should assume:
- package-managed runtime
- version-specific plugin boundaries
- explicit launch paths
- more controlled environment assumptions than a generic installed desktop

## Best companion files

- `02_Cameo_2022x_2024x_2026x.md`
- `10_PRODUCTION_DEPLOYMENT_PLAYBOOK.md`
- `34_CAMEO_OPENAPI_CLASS_MAP.md`
- `35_CAMEO_PLUGIN_CALL_PATTERNS.md`
- `References/CAMEO_OPENAPI_OPERATION_RECIPES.json`
