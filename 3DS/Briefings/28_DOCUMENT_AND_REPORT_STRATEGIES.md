# Document and Report Strategies

## Goal

Choose the right document/report path without overengineering.

## Strategy A: Report Wizard first

Best when:
- Cameo is the active source
- output is document/table centric
- low-friction delivery matters

Use:
- `References/REPORT_WIZARD_TEMPLATE_EXAMPLE.vm`

## Strategy B: Export then transform

Best when:
- machine pipeline matters
- you need canonical schemas
- downstream analytics or QA matters

Use:
- CSV/JSON outputs
- Python transformation

## Strategy C: Plugin-generated output

Best when:
- no existing export exposes the needed data
- client semantics matter
- repeatability matters

Use:
- `12_Cameo_Plugin_Development_Guide.md`

## Strategy D: Repository report

Best when:
- TWC is the real source of truth
- admin or metadata reporting is needed

Use:
- `13_Teamwork_Cloud_API_Playbook.md`

## Rule of thumb

Choose the smallest reporting surface that preserves the truth of the data.
