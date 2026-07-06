# PowerShell

## Snapshot

Official Microsoft Learn page snapshot on 2026-07-06:
- Latest stable: `7.5.8`
- Current LTS: `7.4.17`
- Next LTS: `7.6.3`
- Current preview: `7.7.0-preview.2`

Also remember:
- Windows PowerShell `5.1` remains a separate, built-in Windows line and still matters in many enterprise/enclave environments.

## Why PowerShell matters here

PowerShell is usually the best first-choice automation shell in Windows-heavy 3DS/Cameo/TWC environments for:
- offline scripting
- server/service control
- file/layout orchestration
- deployment helpers
- packaging/export flows
- CSV/JSON/XML glue work
- wrapping Java or Python tools

## Best uses in this pack

- stage offline tool folders
- verify installed Java/runtime state
- launch/report/export helpers
- manage Teamwork Cloud service scripts on Windows hosts
- perform filesystem-safe preprocessing/postprocessing

## Caution

PowerShell is excellent orchestration glue, but:
- deep Cameo client extension belongs in Java plugins
- complicated schema transformations may become easier in Python
- keep Windows security and execution-policy realities in mind in enclaves
