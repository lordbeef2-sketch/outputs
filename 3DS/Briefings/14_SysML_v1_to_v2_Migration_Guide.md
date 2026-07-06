# SysML v1 to v2 Migration Guide

## Truth first

SysML v1 to v2 migration is not:
- a simple file conversion
- a guaranteed one-click vendor wizard
- only a syntax change

It is:
- a language migration
- a semantics migration
- a library/workflow/tooling migration

## What must be analyzed before migration

1. current language usage
- pure SysML v1?
- vendor-specific stereotypes/extensions?
- MagicGrid-heavy?
- report/template dependencies?

2. repository reality
- local `.mdzip` or TWC?
- branch structure?
- review workflow?

3. automation reality
- plugins
- reports
- scripts
- external integrations

4. downstream consumers
- human document outputs
- analysis tools
- simulation flows
- supplier/customer exchanges

## Migration lanes

### Lane A: Learn-only pilot
Use when:
- training team on SysML v2
- building sample models
- validating editors and libraries

### Lane B: Parallel pilot
Use when:
- SysML v1 remains production
- SysML v2 is explored for future-state workflows

### Lane C: Targeted transformation
Use when:
- a bounded subsystem/model scope is selected
- transformation and validation can be contained

### Lane D: Strategic transition
Use when:
- enterprise direction clearly commits to v2
- tooling, governance, and training are all aligned

## Migration checklist

- identify v1 constructs actually used
- identify required v2 equivalent or workaround
- identify report/export breakpoints
- identify plugin/API breakpoints
- identify review/governance breakpoints
- define success criteria before moving anything

## AI rule

If asked "should we migrate now?" do not answer from hype.
Answer from:
- scope
- dependencies
- tool maturity
- output obligations
- governance readiness

## Safe recommendation pattern

For most orgs:
- keep production truth in SysML v1 if that is the current state
- run targeted SysML v2 pilots in parallel
- build transformation and validation knowledge before broad migration
