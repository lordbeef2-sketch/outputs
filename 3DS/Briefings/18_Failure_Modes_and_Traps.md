# Failure Modes and Traps

## Common trap: Treating Cameo as only a file

Why it fails:
- ignores repository semantics
- ignores official APIs
- creates brittle automation

## Common trap: Treating TWC as only storage

Why it fails:
- misses admin/API/branch/resource semantics
- leads to weak integration design

## Common trap: Using the wrong language for the job

- Python for client plugin internals when Java is required
- Java plugin for work that a report/export already solves
- PowerShell for heavy schema logic that belongs in Python

## Common trap: Starting from output instead of schema

Typical symptom:
- a pinout table is hand-shaped before the canonical normalized model exists

## Common trap: Version blindness

Typical symptom:
- plugin or integration built against "Cameo" generically
- no release/refresh line pinned
- Java support ignored

## Common trap: Migration by aspiration

Typical symptom:
- "we should move to SysML v2" without a dependency map

## Common trap: Unsupported certainty

Typical symptom:
- claiming exact internal project behavior from limited docs
- claiming feature compatibility without product-matrix proof

## Recovery rule

When in doubt:
- localize the real task
- pick the smallest supported surface
- preserve provenance
- keep the schema stable
- widen only after success
