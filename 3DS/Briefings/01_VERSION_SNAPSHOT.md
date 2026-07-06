# Version Snapshot

Snapshot date: 2026-07-06

This file answers the user's "latest versions" request in the narrowest possible way first.

## Dassault / No Magic product tracks

### 1) Cameo 2024x
- Product family: Magic Cyber Systems Engineer / Cameo Systems Modeler
- Latest public release line verified: `2024x Refresh3`
- Release date: `2025-07-11`
- Notes:
  - Official version news says 2024x Refresh3 adds simulation improvements, FMU support improvements, and collaborative-modeling improvements including Teamwork Cloud partial project usages as a technology preview.
  - 2024x base released on `2023-11-10`.

### 2) Cameo 2022x
- Product family: Cameo Systems Modeler
- Latest public release line verified: `2022x Refresh2`
- Release date: `2023-07-07`
- Notes:
  - Official version news also shows `2022x Refresh2 Hot Fix 1` and `Hot Fix 2` availability on the page.
  - 2022x base released on `2022-07-01`.

### 3) Cameo 2026x
- Product family: Magic Cyber Systems Engineer / Cameo Systems Modeler
- Latest public release line verified: `2026x Refresh1`
- Release date: `2026-06-26`
- Notes:
  - Official version news says 2026x Refresh1 improves SysML v1 modeling, simulation, and client-side collaborative modeling.
  - The broader 2026x portfolio page also lists 2026x hot fixes, but the clearest current product release for Cameo itself is 2026x Refresh1.

### 4) TWC 2022x
- Product family: Teamwork Cloud / Teamwork Cloud and Services
- Latest public release line verified: `2022x Refresh2`
- Release date: `2023-07-07`
- Notes:
  - 2022x base released on `2022-07-01`.

### 5) TWC 2024x
- Product family: Teamwork Cloud and Services / Magic Collaboration Studio
- Latest public release line verified: `2024x Refresh3`
- Release date: `2025-07-11`
- Notes:
  - 2024x base released on `2023-11-10`.
  - 2024x base page also shows Hot Fix 2 and Hot Fix 3 availability.

### 6) TWC 2026x
- Product family: Magic Collaboration Studio / Teamwork Cloud and Services
- Latest public release line verified: `2026x Refresh1`
- Release date: `2026-06-26`
- Notes:
  - Official version news highlights MagicLab Collaborator, a Resource Usage Map for SysML v2 resources, and SysML v2 REST API extensions.

## Standards

### 7) SysML v1
- Latest minor revision verified: `OMG SysML 1.7`
- Date shown by SysML.org spec index: `June 2024`
- Notes:
  - Treat SysML 1.7 as the latest SysML 1.x line.
  - SysML v1 remains the main production language for many Cameo deployments.

### 8) SysML v2
- Current standards state verified:
  - `OMG Systems Modeling Language (SysML), version 2.0`
  - OMG SysML v2 release repository says the formal specifications were adopted by OMG `as of 2025-06-30`
  - Editorial updates for ISO submission occurred in `March 2026`
- Notes:
  - SysML v2 is paired conceptually with KerML and the Systems Modeling API and Services spec.
  - Vendor support and project workflows are still evolving rapidly.

## Languages / runtimes

### 11) Python 3.11
- Latest Python 3.11 patch release verified: `3.11.15`
- Release date: `2026-03-03`
- Notes:
  - Python.org marks it as a security release for the legacy 3.11 series.

### 12) PowerShell
- Official Microsoft Learn install page snapshot:
  - Latest stable: `7.5.8`
  - Current LTS: `7.4.17`
  - Next LTS: `7.6.3`
  - Current preview: `7.7.0-preview.2`
- Notes:
  - Windows PowerShell 5.1 still exists separately as the built-in Windows line.
  - In enterprise/offline enclaves, both 5.1 and 7.x often matter.

### 13) Java
- Oracle Java download page snapshot:
  - Latest Java SE release: `JDK 26`
  - Latest LTS: `JDK 25`
  - Previous LTS still commonly relevant: `JDK 21`
- Notes:
  - For Cameo/TWC compatibility, the vendor-tested Java version matters more than simply "latest Java."

## Important compatibility caution

For Cameo/TWC:
- Do not assume newest Java = supported Java.
- Do not assume SysML v2 support exists in every Cameo edition.
- Do not assume a refresh line is backward-compatible with every plugin without rebuild/testing.

Read next:
- `02_Cameo_2022x_2024x_2026x.md`
- `03_Teamwork_Cloud_2022x_2024x_2026x.md`
- `04_SysML_v1_and_v2.md`
