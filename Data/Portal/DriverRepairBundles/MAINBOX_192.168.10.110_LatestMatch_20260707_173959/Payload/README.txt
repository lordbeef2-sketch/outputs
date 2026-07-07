ERDS Full Repo Driver Repair Bundle
ComputerName: MAINBOX
IPAddress: 192.168.10.110
SelectionMode: LatestMatch
GeneratedLocal: 2026-07-07 17:39:59
RepoCandidateCount: 4
SelectedPackageCount: 2

This bundle was curated from the entire host server driver repository.
One candidate package was selected per problem device when a hardware ID or compatible ID match was found.

Selection lanes:
- LatestMatch: prefers the newest matching package by date/version.
- BestKnownWorking: prefers the most repeated matching package in the repo, then date/version.

Use this bundle on the affected Windows device itself.
Open an elevated PowerShell window and run Apply-FullRepo-Drivers.ps1 from this bundle.
The script installs all INF-backed drivers included in this curated Drivers folder.

Files:
- Apply-FullRepo-Drivers.ps1 : local curated repo install helper
- FullRepoSelection.json     : selection manifest with matched IDs and source metadata
- Drivers\                   : selected package folders copied from the server repo