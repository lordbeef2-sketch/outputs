# How to Read Cameo Project Data, Use Scripts, and Create Plugins

## First rule

Prefer official surfaces before reverse engineering internals.

Preferred order:
1. Report Wizard / exports
2. Open Java API plugin
3. Teamwork Cloud REST / OSLC / simulation APIs
4. official table/report/template mechanisms
5. direct `.mdzip` parsing only for narrow read-only workflows

## Local project data

Important fact from the MagicDraw developer docs:
- historically, the project content was plain XMI plus extensions for diagrams and project structure.
- `.mdzip` is a compressed local project file/package.
- older code engineering information was stored in `.mdr`.

Meaning for AI:
- a Cameo local project is not a random opaque blob.
- but it is also not safe to assume a stable, public, future-proof internal schema for unsupported automation.

## Safe ways to inspect project content

### Option A: Report Wizard
Best for:
- structured documentation
- table exports
- repeatable reports
- no plugin deployment

Key facts:
- Report Wizard is built on Velocity.
- You can use helper modules and the application Open API.
- Groovy support exists for report templates and external Groovy files.

### Option B: Open Java API plugin
Best for:
- menu actions
- custom validators
- model transformations
- bulk extraction
- custom UI in the client

Key facts from docs:
- plugins are based on the MagicDraw/Cameo Open Java API
- a plugin must include compiled Java packaged in a JAR plus a `plugin.xml`
- the plugin class derives from `com.nomagic.magicdraw.plugins.Plugin`
- actions usually derive from `com.nomagic.magicdraw.actions.MDAction`

### Option C: Teamwork Cloud REST / OSLC
Best for:
- server-side resource inventory
- user/project/admin operations
- integrations
- automation outside the desktop client

Key facts:
- TWC provides REST APIs for users, roles, projects, resources, and server management
- token-based auth samples exist
- OSLC support exposes model element data and configuration-management views

## Plugin skeleton mental model

Minimum plugin anatomy:
- folder under the plugins directory
- jar file
- `plugin.xml`
- main plugin class extending `Plugin`

Basic lifecycle:
1. Cameo/MagicDraw starts
2. plugins directory is scanned
3. plugin descriptor is read
4. plugin class is loaded
5. actions/configurators/listeners are registered

## What to automate with a plugin

Good plugin use cases:
- custom import/export
- stereotype/value normalization
- cross-model validation
- custom UI actions
- dependency analysis
- bespoke table generation
- bulk metadata updates

Bad plugin use cases:
- work that can be done more simply with Report Wizard
- brittle parsing of internal files when API access is available
- server-management tasks that belong in TWC APIs

## Reading model data programmatically

If using Open API, think in this order:
1. open project/session safely
2. locate package/model scope
3. walk owned elements
4. resolve stereotypes/tagged values
5. resolve connectors/ports/relationships
6. serialize to your own stable schema

Important principle:
- your exported schema should be yours, not a mirror of every vendor-internal object shape.

## Script paths in the ecosystem

### Groovy
Good for:
- report-time logic
- template helpers
- quick data shaping in reporting contexts

### Simulation action scripts
Good for:
- CST / simulation behaviors
- language-agnostic scripting through Java Scripting API

### Command-line/report generation
Good for:
- offline report generation
- repeatable document or table pipelines

## Recommended AI workflow for Cameo data extraction

If asked to "read a Cameo project":
1. Ask whether it is local `.mdzip` or Teamwork Cloud-hosted.
2. Ask whether the goal is:
   - report
   - analysis
   - migration
   - plugin development
   - one-time reverse inspection
3. Choose surface:
   - Report Wizard for docs/tables
   - Open API plugin for client-side logic
   - TWC REST/OSLC for repository-side integration
4. Only parse internal project packaging directly if the supported surfaces cannot solve the task.

## A practical extraction architecture

Good long-term pattern:
- Cameo/TWC as source of truth
- plugin or report/export layer as extractor
- normalized JSON/CSV/SQL schema as downstream analysis format
- separate UI/report layer from extraction logic

That architecture is usually safer than teaching downstream tools to understand raw vendor-internal project structure directly.
