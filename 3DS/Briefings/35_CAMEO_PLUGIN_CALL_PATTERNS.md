# Cameo Plugin Call Patterns

## Goal

Use this file when you know the plugin lane is correct and need the first safe call shape.

## Pattern 1: Read-only export plugin

Best first plugin for most shops:
- add one menu action
- read the active project
- walk a bounded model scope
- export a normalized JSON or CSV

Why this is the safest start:
- low UI risk
- low write risk
- easy operator validation
- easy rollback

Call pattern:

```java
Project project = Application.getInstance().getProject();
// locate scope
// walk owned elements
// resolve stereotypes/tags/connectors/ports
// write your own export schema
```

## Pattern 2: Add a browser context action

Use when the operator should trigger the logic from a selected package or element.

Core pieces:
- `DefaultBrowserAction`
- `BrowserContextAMConfigurator`
- `ActionsConfiguratorsManager`

Mental flow:
1. define the action
2. decide enable/disable logic
3. add it to a browser context category
4. register the configurator

## Pattern 3: Add a diagram context action

Use when the logic depends on selected diagram elements rather than containment-tree nodes.

Core pieces:
- `DefaultDiagramAction`
- `DiagramContextAMConfigurator`
- `ActionsConfiguratorsManager`

Good for:
- layout helpers
- selection-based analysis
- diagram-local validations

## Pattern 4: Create model elements safely

Use only when the plugin truly needs write behavior.

Write pattern:

```java
Project project = Application.getInstance().getProject();
SessionManager.getInstance().createSession(project, "Create elements");
try {
    ElementsFactory ef = project.getElementsFactory();
    Package target = project.getModel();
    Class newClass = ef.createClassInstance();
    newClass.setName("Example");
    newClass.setOwner(target);
}
finally {
    SessionManager.getInstance().closeSession(project);
}
```

Important note:
- use sessions for model writes
- keep writes narrow and explicit
- prefer read-only pilots before mutation plugins

## Pattern 5: Move or organize existing elements

Use:
- `ModelElementsManager`
- active session

Good for:
- normalization
- package cleanup
- controlled refactoring helpers

Do not use this as the first plugin unless the rollback story is clear.

## Pattern 6: Work against a TWC-backed project from the desktop

Use when the operator still wants a desktop plugin, but the project source is remote.

High-level pattern:
- use `TeamworkUtils` or related project-descriptor helpers
- load the remote project into the desktop client
- operate through the desktop Open API

Important split:
- repository inventory/admin work belongs to TWC REST
- rich model traversal or plugin UI behavior belongs to the desktop Open API

## Pattern 7: Stereotype-aware export

Use:
- `StereotypesHelper`

Pattern:
1. resolve the profile
2. resolve the stereotype from that profile
3. test whether the element carries it
4. pull tagged values into your own normalized export shape

This is the pattern that matters most for ICD, interface, and pinout extraction work.

## Pattern 8: Load a project by file or remote descriptor

Local file flow:
- build a descriptor from file URI
- load with `ProjectsManager`

Remote flow:
- resolve remote descriptor through Teamwork helpers
- load with `ProjectsManager`

Use this when building external automation that drives the client intentionally, not when a lighter TWC API call would do.

## Plugin shape to prefer first

Preferred first production shape:
- one plugin
- one menu or context action
- read-only
- one export schema
- clear operator output path
- explicit version targeting in README and descriptor

## When not to use a plugin

Do not choose a plugin first if:
- a Report Wizard export is enough
- a TWC REST inventory call is enough
- the task is really server management
- the request is only to read repository metadata

## Companion files

- `34_CAMEO_OPENAPI_CLASS_MAP.md`
- `36_CAMEO_REPORT_GROOVY_PATTERNS.md`
- `13_Teamwork_Cloud_API_Playbook.md`
- `References/PLUGIN_SKELETON.java.txt`
- `References/PLUGIN_XML_EXAMPLE.xml`
