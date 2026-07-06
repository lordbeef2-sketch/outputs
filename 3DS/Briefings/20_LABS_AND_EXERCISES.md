# Labs and Exercises

These labs are designed for either a human trainee or an AI agent being evaluated.

## Lab 1: Version orientation

Goal:
- prove you can read the release landscape correctly

Tasks:
1. Identify the latest verified line for:
   - Cameo 2022x
   - Cameo 2024x
   - Cameo 2026x
   - TWC 2022x
   - TWC 2024x
   - TWC 2026x
2. Explain the difference between:
   - base release
   - refresh release
   - hot fix
3. Explain why Java 26 is not automatically the right answer for Cameo/TWC work.

Expected output:
- short markdown memo
- one compatibility warning section

## Lab 2: Pick the right automation surface

Goal:
- choose the correct execution lane

Tasks:
Given each scenario, choose one primary path and justify it:
1. Generate a requirements verification document from a local model.
2. Add a custom menu action inside Cameo that exports interfaces.
3. Inventory all repositories and user roles from TWC.
4. Clean a messy EICD spreadsheet into a normalized pin map.

Expected output:
- table with:
  - scenario
  - chosen surface
  - rejected alternatives
  - reason

## Lab 3: EICD normalization

Goal:
- turn messy interface data into a controlled schema

Tasks:
1. Create a canonical field list for a pinout row.
2. Define three validation rules.
3. Define three common ambiguity classes and how to resolve them.

Expected output:
- JSON schema sketch or CSV header row
- validation checklist

## Lab 4: Plugin planning

Goal:
- design a safe first plugin

Tasks:
1. Define a read-only plugin use case.
2. Specify:
   - target Cameo line
   - target Java line
   - plugin scope
   - output schema
3. Identify three failure points and how to surface them.

Expected output:
- 1-page design note

## Lab 5: TWC API planning

Goal:
- plan a repository-side integration

Tasks:
1. Define a TWC inventory use case.
2. Choose REST vs OSLC and explain why.
3. Define the output schema.
4. List permissions assumptions.

Expected output:
- JSON or markdown integration spec

## Lab 6: Migration reality check

Goal:
- separate strategy from hype

Tasks:
1. Describe a shop that should stay on SysML v1 for now.
2. Describe a shop that can justify a SysML v2 pilot.
3. Define one safe migration pilot boundary.

Expected output:
- comparison memo

## Scoring rubric

Strong answer characteristics:
- localizes the actual problem
- chooses a supported surface
- keeps truth/boundary notes explicit
- distinguishes fact from inference
- keeps schema and output intent separate
