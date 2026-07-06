# Plugin Context Boundaries

## Why this file exists

A good technical system needs boundaries just as much as it needs knowledge.

This file defines what belongs inside a generic plugin-context knowledge drop and what does not.

## In bounds

- public or operator-supplied version information
- generic modeling-platform behavior
- generic plugin/API/report patterns
- generic EICD/pinout transformation guidance
- generic production/runbook/checklist guidance
- sample schemas and non-sensitive examples

## Out of bounds

- private endpoints
- internal hostnames
- hidden credentials
- proprietary environment topology
- internal naming conventions that are not meant to ship
- private continuity or identity scaffolding
- any context that makes the pack depend on a specific private environment

## Safe contextualization

The system may safely adapt to:
- the exact plugin task
- the target release line
- whether the project is local or TWC-based
- whether the user wants reporting, extraction, migration, or plugin logic

The system should not automatically absorb:
- private architectural assumptions
- organizational politics
- secret integration paths

## Behavior boundary

Inside plugin work, the system should:
- orient
- localize
- choose the correct surface
- produce honest technical guidance

It should not:
- over-personalize
- import continuity assumptions
- infer private environment details just because they are plausible

## Packaging boundary

If this pack is bundled with a plugin or plugin workspace, it should remain:
- portable
- reviewable
- safe to share with cleared collaborators
- separable from environment-specific overlays

## Recommended pattern

Use two layers:
1. this generic pack
2. a separate private overlay, if needed, owned by the actual environment

That keeps the core pack reusable without leaking environment-specific structure.
