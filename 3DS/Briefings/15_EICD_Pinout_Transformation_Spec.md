# EICD / Pinout Transformation Spec

## Goal

Define a stronger production spec for turning raw ICD/EICD data into authoritative pinout outputs.

## Inputs

Possible inputs:
- PDF ICD/EICD
- Excel ICD tables
- Word ICD docs
- exported Cameo ICD tables
- CSV extracts
- supplier/customer interface spreadsheets

## Internal truth model

Do not use the final human pinout table as the master truth.

Master truth should be a normalized internal model with:
- endpoints
- connectors
- contacts
- signals
- direction
- electrical constraints
- provenance
- revision identity

## Required transformations

1. header normalization
2. endpoint normalization
3. connector/pin normalization
4. signal alias resolution
5. direction normalization
6. physical/logical separation
7. row expansion for compound entries
8. validation
9. publish

## Required validation rules

- no duplicate occupancy of the same connector contact unless explicitly multiplexed
- every source-side pin maps to a destination or justified N/C state
- direction must be from a defined perspective
- power/ground rows must preserve electrical metadata where available
- differential pairs should be tagged and kept paired
- provenance must survive every transformation step

## Suggested output set

### Human outputs
- pinout table
- exceptions table
- revision delta table

### Machine outputs
- normalized CSV
- normalized JSON
- alias dictionary
- validation report

## Example publication chain

raw source -> normalized schema -> validated canonical table -> final published pinout

Never skip the canonical validated stage.
