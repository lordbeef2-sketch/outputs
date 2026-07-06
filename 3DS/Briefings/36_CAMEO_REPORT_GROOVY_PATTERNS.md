# Cameo Report and Groovy Patterns

## Goal

Use this file when the problem is "I need data out" or "I need a document/table/export" and a full Java plugin may be unnecessary.

## First choice rule

If the task is mainly:
- reporting
- table extraction
- document generation
- light transformation inside a reporting flow

then check Report Wizard before building a plugin.

## Report Wizard mental model

Officially, Report Wizard is built on Velocity.

Think of it as:
- a template engine
- model-aware helper tools
- optional script hooks
- a lower-friction route than a Java plugin for many export jobs

## Groovy tool import

Import pattern:

```velocity
#import ('groovy', 'com.nomagic.reportwizard.tools.script.GroovyTool')
```

## Groovy tool methods

The official Groovy tool exposes:
- `eval`
- `execute`

Meaning:
- `eval` runs Groovy text inline
- `execute` runs an external Groovy file

## Best-fit use cases

Use Report Wizard plus Groovy for:
- table shaping
- conditional formatting logic
- lightweight aggregation
- export-time filtering
- document assembly from model data

Do not use it first for:
- deep UI extension
- long-lived background logic
- heavy mutation flows
- plugin-style menu integration

## Pattern 1: Inline evaluation

Use when the logic is tiny and report-local.

Example shape:

```velocity
#import ('groovy', 'com.nomagic.reportwizard.tools.script.GroovyTool')
#set($value = $groovy.eval("return 1 + 1"))
$value
```

## Pattern 2: External Groovy file

Use when the logic is large enough that it should not live inline in a template.

Pattern:
- keep the template small
- move the shaping logic to a `.groovy` file
- return a list or object structure that the template can render

## Pattern 3: Use implicit model variables

Official Groovy reporting docs note that model element collections and helper variables can be inserted into the Groovy context.

Examples include variables such as:
- `$Class`
- `$UseCase`
- `$sorter`

This matters because the Groovy file can work directly on the report context instead of rebuilding all discovery logic.

## Pattern 4: Export interface rows without a plugin

Good first answer for ICD-like work:
1. start from a report template
2. pull the relevant element collections
3. use Groovy only for shaping or filtering
4. export into document, CSV-like rows, or intermediate text

If this becomes too complex or needs UI/operator actions, then graduate to a plugin.

## Pattern 5: Hybrid strategy

Good real-world pattern:
- Report Wizard for baseline exports
- Groovy for shaping
- downstream Python or PowerShell for normalization

This is often better than forcing the whole workflow into Java too early.

## Operational cautions

- The Groovy script tool depends on the proper Report Wizard extension setup.
- External script use should be documented and version-pinned with the target Cameo line.
- Report outputs should still normalize into your own downstream schema, not a loose vendor-shaped dump.

## Decide quickly

Choose Report Wizard plus Groovy when:
- the output is a document, table, or export
- the operator does not need a new menu item
- the logic is mostly read-only

Choose a plugin when:
- the operator needs a UI action inside Cameo
- the logic must run from browser or diagram context
- the workflow needs deeper client API control

## Companion files

- `06_Cameo_Project_Data_Scripts_Plugins.md`
- `12_Cameo_Plugin_Development_Guide.md`
- `35_CAMEO_PLUGIN_CALL_PATTERNS.md`
- `References/REPORT_WIZARD_TEMPLATE_EXAMPLE.vm`
