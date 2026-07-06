# Cameo Plugin Development Guide

## What this guide is for

Use this when the goal is:
- create a Cameo/MagicDraw plugin
- inspect project data from inside the client
- add actions, menus, validators, or custom automation

## Official base

The vendor docs say:
- the platform exposes an Open Java API
- plugins use a `plugin.xml` descriptor
- the main plugin class derives from `com.nomagic.magicdraw.plugins.Plugin`
- actions commonly derive from `com.nomagic.magicdraw.actions.MDAction`

## Plugin anatomy

Minimum structure:
- plugin directory
- jar file(s)
- `plugin.xml`
- main plugin class

Common additions:
- icons/resources
- config files
- helper libraries
- logging config

## Build mental model

The plugin is not just "Java code that runs."
It is:
- loaded by the modeling platform
- tied to exact platform versions
- sensitive to API compatibility
- operating inside a stateful modeling session

## Safe first plugin

Best first target:
- a read-only exporter

Why:
- lower blast radius
- easier to test
- easier to validate against model truth
- teaches traversal without mutation mistakes

Good first plugin tasks:
- export blocks/ports/connectors to CSV
- generate interface inventory
- validate stereotype completeness
- open a small custom report action

## Recommended workflow

1. Pin target version(s)
- for example: 2024x Refresh3 only

2. Pin Java line
- use the vendor-supported Java for that release line

3. Build the smallest useful feature
- single action
- single output
- single package scope if possible

4. Test on:
- a tiny sample model
- a medium realistic model
- a TWC-backed model if relevant

5. Capture:
- load behavior
- runtime errors
- output correctness
- performance notes

## Design rules

### Rule 1: Read-only first
Until proven otherwise, design exporters/inspectors before model writers.

### Rule 2: Normalize outputs
Do not dump raw object internals if the downstream user needs stable data.

### Rule 3: Make version support explicit
Every plugin should state:
- supported Cameo/MagicDraw lines
- supported Java line
- required companion plugins if any

### Rule 4: Fail loudly but locally
If the plugin cannot run, surface the reason clearly without corrupting the session.

## Data extraction pattern

Typical flow:
1. identify project scope
2. walk packages/elements
3. identify target types
4. resolve relationships/stereotypes/tagged values
5. map to your export schema
6. write CSV/JSON/report output

## When not to use a plugin

Do not jump to plugin work if:
- Report Wizard already solves the report
- TWC REST/OSLC gives the needed data
- Python can transform an existing export with less operational cost

## Suggested plugin roadmap

Level 1:
- add one menu action
- export one stable table

Level 2:
- validate stereotypes or interfaces
- provide settings/config

Level 3:
- TWC-aware behavior
- model transformations
- richer UI

## See also
- `06_Cameo_Project_Data_Scripts_Plugins.md`
- `09_Java.md`
- `16_Decision_Trees_and_Checklists.md`
