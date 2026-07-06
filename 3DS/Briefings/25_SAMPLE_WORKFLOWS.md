# Sample Workflows

## Workflow 1: EICD spreadsheet to authoritative pinout

Inputs:
- raw spreadsheet
- revision metadata

Steps:
1. ingest to working CSV
2. normalize headers and endpoint naming
3. expand packed rows
4. map to canonical schema
5. validate duplicates/missing mates/direction
6. generate final normalized CSV and human pinout table

Reference files:
- `References/SAMPLE_EICD_RAW.csv`
- `References/SAMPLE_PINOUT_NORMALIZED.csv`
- `References/PINOUT_CANONICAL_SCHEMA.json`

## Workflow 2: Safe first Cameo export plugin

Inputs:
- target Cameo line
- target Java line
- one export goal

Steps:
1. pin versions
2. create starter project layout
3. implement one read-only action
4. export stable schema
5. test on sample model
6. document deployment/rollback

Reference files:
- `References/PLUGIN_STARTER_PROJECT_LAYOUT.txt`
- `References/PLUGIN_SKELETON.java.txt`
- `References/PLUGIN_XML_EXAMPLE.xml`

## Workflow 3: TWC repository inventory

Inputs:
- environment details
- auth method

Steps:
1. define inventory schema
2. choose REST path
3. collect projects/resources/branch counts
4. emit JSON and CSV
5. summarize caveats

Reference files:
- `References/TWC_INVENTORY_OUTPUT_SCHEMA.json`
- `References/TWC_API_WORKFLOWS.json`

## Workflow 4: SysML migration planning memo

Inputs:
- current v1 workflow facts
- tool and integration dependencies

Steps:
1. inventory current dependencies
2. identify why migration is being requested
3. separate pilot vs production target
4. define a bounded pilot
5. document risk and exit criteria

Reference files:
- `14_SysML_v1_to_v2_Migration_Guide.md`
- `04_SysML_v1_and_v2.md`
