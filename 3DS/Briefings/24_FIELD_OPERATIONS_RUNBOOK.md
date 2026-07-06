# Field Operations Runbook

Use this file when the environment is real, constrained, and time-sensitive.

## Before starting any task

Write down:
- target version line
- local file vs TWC
- read-only vs write-capable intent
- expected output type
- rollback or abort condition

## Fast triage categories

### Category A: Version / compatibility
Use:
- `01_VERSION_SNAPSHOT.md`
- `References/COMPATIBILITY_NOTES.md`

### Category B: Model extraction
Use:
- `06_Cameo_Project_Data_Scripts_Plugins.md`
- `12_Cameo_Plugin_Development_Guide.md`

### Category C: Repository inventory / admin
Use:
- `13_Teamwork_Cloud_API_Playbook.md`
- `References/TWC_INVENTORY_OUTPUT_SCHEMA.json`

### Category D: Interface/pinout transformation
Use:
- `15_EICD_Pinout_Transformation_Spec.md`
- sample raw/normalized files in `References`

## Minimal operator log

For any real operation, record:
- date/time
- environment
- version line
- objective
- chosen method
- outputs generated
- failures or caveats

## Abort conditions

Stop and re-localize if:
- version line is unclear
- permissions are unclear
- you are about to mutate production without rollback
- source data cannot be proven authoritative
- the output schema is still fuzzy

## Good operator rhythm

1. localize
2. choose the smallest correct surface
3. generate a controlled output
4. validate
5. publish only what is actually supported
