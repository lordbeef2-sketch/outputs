# Validation and QA Guide

## Why this matters

In this ecosystem, the most common failure is not lack of data. It is unvalidated translation.

## Validation layers

### Layer 1: Source validation
- Is the source authoritative?
- Is the revision known?
- Are headers/endpoints readable?

### Layer 2: Transformation validation
- Did packed rows expand correctly?
- Were aliases applied consistently?
- Was direction normalized correctly?

### Layer 3: Output validation
- Does the output match the canonical schema?
- Are duplicates or missing mates present?
- Are human and machine outputs aligned?

### Layer 4: Operational validation
- Was the right version line targeted?
- Was the correct surface used?
- Were permissions and rollback paths known?

## Minimum QA artifacts

- normalized output
- validation report
- source provenance note
- operator log

## Example files in this pack

- `References/PINOUT_VALIDATION_REPORT_SAMPLE.json`
- `References/TWC_INVENTORY_SAMPLE_OUTPUT.json`
- `References/COURSE_CHECKLIST_TEMPLATE.md`

## AI rule

Do not say a transformation is complete until you can point to:
- the source
- the schema
- the validation result
