# Production Deployment Playbook

## Goal

Turn the knowledge in this pack into a deployment-safe operating method for:
- Cameo client work
- Teamwork Cloud server work
- SysML v1/v2 transitions
- EICD/pinout data pipelines
- plugin/report/API automation

## Operating modes

### Mode A: Research / discovery
Use when:
- understanding an unfamiliar model
- learning a new version line
- testing a migration concept
- building a prototype extractor

Constraints:
- no production writes
- no irreversible repository changes
- capture findings as assumptions and evidence

### Mode B: Controlled engineering
Use when:
- building repeatable scripts
- creating reports/templates/plugins
- shaping normalized data pipelines

Constraints:
- version-pinned dependencies
- test data or replica projects
- explicit output schemas

### Mode C: Production execution
Use when:
- touching real repositories
- rolling out plugins
- upgrading TWC
- publishing authoritative pinout outputs

Constraints:
- change control
- backups/snapshots
- rollback plan
- compatibility evidence
- operator sign-off

## Production principles

1. Treat the model repository as a system of record.
2. Prefer official APIs and exports over unsupported file surgery.
3. Keep extraction schemas under your control.
4. Separate read-only discovery from write-capable automation.
5. Never mix migration, cleanup, and feature rollout in one blind step.
6. In offline enclaves, package dependencies and docs deliberately.

## Deployment lanes

### Lane 1: Desktop-only lane
Best for:
- local `.mdzip`
- Report Wizard templates
- client plugins
- package-ready no-install Cameo bundles
- small-team workflows

Risk profile:
- lower infrastructure risk
- higher per-user deployment friction

### Lane 2: Repository/API lane
Best for:
- Teamwork Cloud-hosted projects
- org-wide automation
- reporting/inventory/integration

Risk profile:
- higher infra risk
- better scaling and governance

### Lane 3: Hybrid lane
Best for:
- client plugins for model semantics
- TWC APIs for repository metadata and orchestration
- Python/PowerShell post-processing

Risk profile:
- most flexible
- easiest place to accidentally create hidden coupling

## What "prod ready" means by artifact

### A Cameo plugin is production-ready if:
- target versions are explicitly listed
- target package line is explicit if using no-install package distribution
- plugin folder/jar/plugin.xml layout is stable
- startup/load behavior is tested
- failures surface clearly
- read/write scopes are intentional
- model transactions/session handling is correct
- uninstall/disable path is clear

### A TWC script/integration is production-ready if:
- auth path is explicit
- permissions are minimal
- target environment/version is known
- retry/error behavior is defined
- output schema is fixed
- rate/scale assumptions are documented

### An EICD/pinout pipeline is production-ready if:
- source document provenance is preserved
- normalization rules are explicit
- alias handling is deterministic
- validation catches duplicates/missing mates/direction ambiguity
- human-readable and machine-readable outputs are both generated

## Minimal artifact set for a real project

For any serious delivery, create:
- purpose statement
- version/support matrix
- deployment steps
- rollback steps
- test plan
- sample input/output
- known limitations
- operator notes

## Recommended repo or drop layout

Suggested operational layout:
- `docs/`
  - intent, version support, operator guides
- `templates/`
  - report templates, config templates
- `plugins/`
  - jar/plugin descriptor/source references
- `scripts/`
  - orchestration scripts
- `samples/`
  - safe example projects/data
- `schemas/`
  - JSON/CSV data contracts
- `logs/`
  - execution records

## Package-ready note

If Cameo is being shipped as a no-install package set rather than a normal workstation install:
- split package lines cleanly
- split plugin folders by line
- split writable log/work/config state by line
- treat launchers as part of the packaged runtime contract

See:
- `37_CAMEO_PACKAGE_READY_NOINSTALL_PLAYBOOK.md`

## Teaching rule

If an AI or human cannot tell:
- what this touches
- what version it targets
- whether it is read-only or write-capable
- how to reverse it

then it is not production-ready yet.
