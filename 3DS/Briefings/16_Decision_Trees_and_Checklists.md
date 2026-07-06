# Decision Trees and Checklists

## Decision tree: How should I access the data?

Question 1:
Is the data in Teamwork Cloud?

- Yes -> consider TWC REST/OSLC first
- No -> continue

Question 2:
Is the goal a document/table/report?

- Yes -> consider Report Wizard first
- No -> continue

Question 3:
Is the goal rich model logic or client UI integration?

- Yes -> Java plugin
- No -> continue

Question 4:
Is there already an export that Python or PowerShell can transform?

- Yes -> transform the export instead of building a plugin first
- No -> consider plugin/API path

## Checklist: Before touching a Cameo project

- version line known
- local vs TWC known
- SysML v1 vs v2 known
- read-only vs write-capable intent known
- output schema known

## Checklist: Before touching TWC

- auth method known
- permissions known
- target environment known
- backup/rollback path known if making changes
- Cassandra/upgrade implications known if doing infra work

## Checklist: Before building a plugin

- exact version target known
- exact Java support line known
- first release is read-only if possible
- plugin.xml structure understood
- deployment path understood

## Checklist: Before publishing a pinout table

- source provenance captured
- normalization complete
- duplicates checked
- directions validated
- unmapped rows reviewed
- human and machine outputs aligned
