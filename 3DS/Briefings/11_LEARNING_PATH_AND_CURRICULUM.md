# Learning Path and Curriculum

## Who this is for

This learning path is meant for:
- an AI assistant onboarding into 3DS/Cameo/TWC work
- a new engineer coming from software or scripting
- an operator who must move from "what is this?" to "I can ship safely"

## Stage 1: Orientation

Read:
- `00_START_HERE.md`
- `01_VERSION_SNAPSHOT.md`
- `02_Cameo_2022x_2024x_2026x.md`
- `03_Teamwork_Cloud_2022x_2024x_2026x.md`
- `04_SysML_v1_and_v2.md`

Must understand:
- client vs server split
- SysML v1 vs SysML v2 split
- release line vs refresh vs hot fix
- why Java compatibility matters

Completion check:
- explain the difference between Cameo and TWC in five sentences or fewer
- identify the latest verified lines in this pack

## Stage 2: Data and modeling literacy

Read:
- `05_EICD_to_Pinout_Tables.md`
- `06_Cameo_Project_Data_Scripts_Plugins.md`

Must understand:
- ICD/EICD as interface data
- normalized schema vs display table
- `.mdzip` vs TWC project
- why official APIs are preferred

Completion check:
- define a canonical pinout row schema
- explain when not to parse `.mdzip` directly

## Stage 3: Tooling literacy

Read:
- `07_Python_3_11.md`
- `08_PowerShell.md`
- `09_Java.md`
- `12_Cameo_Plugin_Development_Guide.md`
- `13_Teamwork_Cloud_API_Playbook.md`

Must understand:
- when Python is the right glue
- when PowerShell is the right operator shell
- when Java is required
- plugin vs API integration boundary

Completion check:
- choose the right language for three sample tasks:
  - pinout CSV normalization
  - custom menu action inside Cameo
  - TWC repository inventory export

## Stage 4: Operational competence

Read:
- `10_PRODUCTION_DEPLOYMENT_PLAYBOOK.md`
- `14_SysML_v1_to_v2_Migration_Guide.md`
- `15_EICD_Pinout_Transformation_Spec.md`
- `16_Decision_Trees_and_Checklists.md`
- `18_Failure_Modes_and_Traps.md`

Must understand:
- production lanes
- migration risk
- validation before publication
- common failure patterns

Completion check:
- design a read-only extraction plan for a real Cameo/TWC environment
- design a safe pilot plugin rollout

## Stage 5: Teaching and execution

Read:
- `17_AI_Operator_Quickstart.md`

Must be able to do:
- turn a user ask into the right lane
- identify the truth rail
- explain tradeoffs clearly
- generate a phased plan without overclaiming

## Fast tracks

### Fast track: Plugin builder
Read in this order:
- 01, 02, 06, 09, 12, 16, 18

### Fast track: TWC admin/integration
Read in this order:
- 01, 03, 08, 13, 10, 16, 18

### Fast track: EICD/pinout extractor
Read in this order:
- 01, 05, 07, 15, 16, 18

### Fast track: SysML migration planner
Read in this order:
- 01, 04, 02, 03, 14, 10, 18

## Suggested exercises

1. Build a fake EICD normalization schema in CSV/JSON.
2. Sketch a Cameo plugin that exports interface rows.
3. Design a TWC inventory call chain and output schema.
4. Write a migration-risk memo for moving from SysML v1-heavy 2022x work to a 2026x/SysML v2 pilot environment.
