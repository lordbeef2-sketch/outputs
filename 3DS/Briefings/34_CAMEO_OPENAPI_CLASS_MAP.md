# Cameo Open API Class Map

## Goal

Use this file as the "what class family do I reach for?" map for common Cameo or MagicDraw plugin work.

This is not a full Javadoc mirror.
It is the high-value class map for the first layers of real work.

## Core application and project access

### `com.nomagic.magicdraw.core.Application`

Use for:
- getting the active application instance
- getting the active project
- getting `ProjectsManager`
- reaching GUI-level services such as the browser

Common mental pattern:

```java
Application.getInstance()
```

### `com.nomagic.magicdraw.core.project.ProjectsManager`

Use for:
- listing open projects
- getting the active project
- loading, saving, closing, importing, and activating projects

Typical entry:

```java
ProjectsManager projectsManager = Application.getInstance().getProjectsManager();
```

### `com.nomagic.magicdraw.core.Project`

Use for:
- project-scoped element access
- project model root access
- project element factory access
- project diagram access

Common pattern:

```java
Project project = Application.getInstance().getProject();
```

## Model creation and editing

### `com.nomagic.magicdraw.openapi.uml.SessionManager`

Use for:
- wrapping write operations in a model session
- committing or cancelling edits safely

Rule:
- if you are modifying the model, open a session first

### `com.nomagic.uml2.impl.ElementsFactory`

Use for:
- creating UML/SysML model element instances

Typical pattern:

```java
ElementsFactory ef = project.getElementsFactory();
Class newClass = ef.createClassInstance();
```

### `com.nomagic.magicdraw.openapi.uml.ModelElementsManager`

Use for:
- adding, moving, deleting model elements
- creating diagrams in supported flows

Typical pattern:

```java
ModelElementsManager.getInstance().moveElement(classA, targetPackage);
```

## Stereotypes and tagged values

### `com.nomagic.uml2.ext.jmi.helpers.StereotypesHelper`

Use for:
- finding profiles
- resolving stereotypes
- assigning and unassigning stereotypes
- reading and writing tagged values

Best-practice pattern from the docs:
- find profile by URI
- find stereotype inside the target profile
- pass stereotype objects, not loose stereotype names, whenever possible

## Plugin shell and lifecycle

### `com.nomagic.magicdraw.plugins.Plugin`

Use for:
- main plugin class base type
- startup and shutdown lifecycle

Your plugin class is referenced from `plugin.xml`.

### `plugin.xml`

This is not a Java class, but it is part of the class map because it controls loading.

Key elements from the docs:
- `plugin`
- `requires`
- `api`
- `required-plugin`
- `runtime`
- `library`

Key attributes worth remembering:
- plugin `id`
- plugin `name`
- plugin `version`
- plugin `class`
- `ownClassloader`
- `class-lookup`

## Actions, menus, and UI hooks

### `com.nomagic.magicdraw.actions.MDAction`

Use for:
- defining actions that appear in menus, toolbars, or context menus

The docs state that actions used in the modeling tool must subclass `MDAction`.

### `com.nomagic.magicdraw.ui.browser.actions.DefaultBrowserAction`

Use for:
- browser-tree driven actions
- actions that depend on selected nodes in containment or other browser trees

### `com.nomagic.magicdraw.ui.actions.DefaultDiagramAction`

Use for:
- diagram-context actions
- actions driven by selected diagram elements

### `com.nomagic.actions.ActionsManager`

Use for:
- representing a menu bar, toolbar, or shortcut menu container

### `com.nomagic.actions.ActionsCategory`

Use for:
- grouping actions in menus and toolbars

### `com.nomagic.actions.AMConfigurator`

Use for:
- adding or arranging actions in a defined GUI surface

### `com.nomagic.magicdraw.actions.BrowserContextAMConfigurator`

Use for:
- browser shortcut menu configuration

### `com.nomagic.magicdraw.actions.DiagramContextAMConfigurator`

Use for:
- diagram shortcut menu configuration

### `com.nomagic.magicdraw.actions.ActionsConfiguratorsManager`

Use for:
- registering configurators into known menu and shortcut extension points

## Teamwork-aware desktop access

### `magicdraw.teamwork.application.TeamworkUtils`

Use for:
- locating remote server project descriptors by qualified name

This matters when the project source is TWC-backed rather than a local `.mdzip`.

### `com.nomagic.magicdraw.core.ProjectUtilities`

Use for:
- helper access around project and used-project behaviors
- version and shared-package related operations in official examples

## Report and script side

### `com.nomagic.reportwizard.tools.script.GroovyTool`

Use for:
- Report Wizard Groovy execution from templates
- `eval(...)`
- `execute(...)`

Import pattern:

```velocity
#import ('groovy', 'com.nomagic.reportwizard.tools.script.GroovyTool')
```

## Fast routing table

If the task is:

- open/load/save project -> `Application`, `ProjectsManager`, `Project`
- create or move model elements -> `SessionManager`, `ElementsFactory`, `ModelElementsManager`
- work with stereotypes/tags -> `StereotypesHelper`
- add menu or context action -> `MDAction`, configurator classes, `ActionsConfiguratorsManager`
- load a TWC-backed project in desktop context -> `TeamworkUtils`, `ProjectsManager`
- run report-time Groovy -> `GroovyTool`

## Companion files

- `12_Cameo_Plugin_Development_Guide.md`
- `35_CAMEO_PLUGIN_CALL_PATTERNS.md`
- `36_CAMEO_REPORT_GROOVY_PATTERNS.md`
- `References/PLUGIN_SKELETON.java.txt`
- `References/PLUGIN_XML_EXAMPLE.xml`
