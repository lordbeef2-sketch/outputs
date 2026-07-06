# Cookbook Task Guides

This file gives short "if asked X, do Y" patterns.

## Task: "What is the latest version of Cameo/TWC?"

Use:
- `01_VERSION_SNAPSHOT.md`
- `References/VERSION_MATRIX.csv`

Answer pattern:
1. give latest verified line
2. include date
3. mention if hot-fix ambiguity exists
4. mention compatibility caution if the task implies deployment

## Task: "Can you read this Cameo project?"

Localize:
- local `.mdzip` vs TWC
- read-only vs write
- report vs data extraction

Choose:
- Report Wizard for docs/tables
- plugin for rich client traversal
- TWC API for repository-side work

## Task: "How do I create a Cameo plugin?"

Use:
- `12_Cameo_Plugin_Development_Guide.md`
- `References/PLUGIN_SKELETON.java.txt`
- `References/PLUGIN_XML_EXAMPLE.xml`

Bias:
- read-only first
- one action
- one stable output

## Task: "How do I extract ICD data into a pinout table?"

Use:
- `05_EICD_to_Pinout_Tables.md`
- `15_EICD_Pinout_Transformation_Spec.md`

Bias:
- canonical schema first
- alias/validation pipeline second
- human table last

## Task: "Should I use Python, PowerShell, or Java?"

Quick rule:
- Java for Cameo plugin/Open API work
- Python for normalization/transformation/post-processing
- PowerShell for Windows orchestration/deployment/glue

## Task: "Should we move to SysML v2?"

Use:
- `04_SysML_v1_and_v2.md`
- `14_SysML_v1_to_v2_Migration_Guide.md`

Bias:
- ask whether this is a pilot or a production migration
- do not overclaim maturity or ease

## Task: "How do I get data out of TWC?"

Use:
- `13_Teamwork_Cloud_API_Playbook.md`
- `References/TWC_API_WORKFLOWS.json`

Bias:
- REST first for admin/resource inventory
- OSLC when linked-data semantics matter

## Task: "Make it production ready"

Use:
- `10_PRODUCTION_DEPLOYMENT_PLAYBOOK.md`
- `16_Decision_Trees_and_Checklists.md`
- `18_Failure_Modes_and_Traps.md`

Bias:
- define target environment
- define version compatibility
- define rollback
- define test proof
