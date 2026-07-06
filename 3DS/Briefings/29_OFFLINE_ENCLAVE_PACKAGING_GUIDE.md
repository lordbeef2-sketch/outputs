# Offline Enclave Packaging Guide

## Goal

Package knowledge, scripts, and starter artifacts so they survive disconnected use.

## Packaging principles

1. Pin versions visibly.
2. Keep source references and generated outputs separate.
3. Include README/start-here files.
4. Avoid hidden online dependencies.
5. Preserve schema examples locally.

## Recommended pack contents

- all briefings
- all references
- sample schemas and outputs
- starter scripts/templates
- deployment notes
- operator checklists

## What to add for a real enclave deployment

- approved runtime installers or hashes
- internal endpoint notes
- organization-specific naming conventions
- local security/release approval notes

## Golden pattern

Use:
- `References/MBSE_GOLDEN_DROP_LAYOUT.txt`

The core idea:
- never let generated outputs replace canonical references
- preserve logs and validation artifacts by run

## Final packaging check

- all files open offline
- no required link is internet-only for basic use
- sample artifacts are local
- start-here and master index are clear
