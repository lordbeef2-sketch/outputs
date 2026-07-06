# SysML v1 and SysML v2

## SysML v1

Current line in this pack:
- `SysML 1.7`

What it is:
- The long-standing MBSE language used broadly across Cameo deployments.

What it is good for:
- requirements
- structure
- behavior
- analysis and verification modeling
- table/diagram-heavy enterprise MBSE workflows

How to think about it in Cameo:
- SysML v1 is still the default reality for many production organizations.
- A lot of ICD, port/interface, parametric, and requirement-driven workflows are still SysML v1-centered.

## SysML v2

Current line in this pack:
- `OMG SysML 2.0`
- Formal adoption referenced by the OMG SysML v2 release repository on `2025-06-30`
- Editorial updates for ISO submission in `March 2026`

What it is:
- Next-generation SysML with stronger precision, better textual foundations, and a larger surrounding standards story.

Key companions:
- KerML
- Systems Modeling API and Services

What makes SysML v2 different in practice:
- stronger textual notation story
- clearer formalization
- better machine-oriented interchange possibilities
- cleaner basis for model services, APIs, and automation

## Practical comparison

### SysML v1 mindset
- diagram-first in many organizations
- tool-implementation-heavy workflows
- lots of mature enterprise habits

### SysML v2 mindset
- model-as-language + model-as-service
- textual + graphical coexistence
- better future fit for CI/CD-like MBSE workflows

## Migration truth

Do not treat SysML v2 as a drop-in file-format upgrade from v1.

Migration concerns:
- language differences
- semantic mapping
- library differences
- tool support maturity
- transformation limitations
- workflow retraining

The official SysML v2 release repository explicitly includes:
- spec documents
- example models
- model libraries
- install material for editors
- notes on transformation from SysML v1 to v2

## AI guidance

If the user says:
- "production Cameo model today"
  - default assumption should still be SysML v1 unless told otherwise.
- "pilot, future-state, text-first, API-first, transformation"
  - SysML v2 may be the actual target.

## What to preserve mentally

- SysML v1 is the operational present for many organizations.
- SysML v2 is the strategic future path and an active standards/tooling shift.
- The hard problem is not only syntax conversion. It is semantic migration plus workflow migration.

## Read next
- `05_EICD_to_Pinout_Tables.md`
- `06_Cameo_Project_Data_Scripts_Plugins.md`
