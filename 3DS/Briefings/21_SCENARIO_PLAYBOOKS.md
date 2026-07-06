# Scenario Playbooks

These are realistic task shapes and how to think through them.

## Scenario 1: "Read this Cameo project and give me interface rows"

Questions to localize:
- Local `.mdzip` or TWC?
- Read-only enough?
- One-time extraction or repeatable pipeline?
- Human report or machine data?

Recommended path:
- local report/export if simple
- read-only plugin if richer traversal is needed
- normalize to CSV/JSON before downstream use

Do not:
- start by reverse-patching internal files

## Scenario 2: "We need all TWC projects and branch activity"

Questions to localize:
- Admin metadata only or element content too?
- Single environment or multi-environment?
- Human dashboard or export artifact?

Recommended path:
- TWC REST first
- branch/repository metadata schema
- PowerShell or Python wrapper depending environment and output needs

Do not:
- solve this from the client if the repository is the real source of truth

## Scenario 3: "Turn this EICD into a pinout table"

Questions to localize:
- What is the source format?
- Is the source authoritative or partial?
- Is physical pin mapping present or only logical interface text?
- Are we publishing human tables, machine tables, or both?

Recommended path:
- canonical normalization first
- validation second
- final table third

Do not:
- publish the first table shape that looks readable

## Scenario 4: "Build a plugin to automate exports"

Questions to localize:
- Could Report Wizard solve enough of this?
- Is there a supported API need?
- What version line is the target?
- Is read-only sufficient?

Recommended path:
- first plugin = exporter
- explicit Java/runtime target
- small scope and stable output

## Scenario 5: "Should we migrate to SysML v2?"

Questions to localize:
- Why now?
- What pain exists in SysML v1?
- What outputs/integrations/reviews depend on v1 today?
- Are you asking for production migration or pilot capability?

Recommended path:
- start with pilot framing
- map dependencies before answering yes/no

Do not:
- answer from enthusiasm alone

## Scenario 6: "The user wants a prod-ready tool today"

Questions to localize:
- Is it really production or a prototype with urgency language?
- What environment is real?
- What rollback path exists?
- Who owns deployment?

Recommended path:
- choose the smallest production-safe lane
- document constraints
- state what was and was not validated
