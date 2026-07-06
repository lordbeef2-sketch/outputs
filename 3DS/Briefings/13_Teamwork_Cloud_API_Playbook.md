# Teamwork Cloud API Playbook

## Goal

Use this when the problem is better solved from the repository side than from the desktop client.

## API surfaces to remember

Officially visible in this pack:
- REST APIs
- token-based authentication support
- OSLC API
- simulation REST API
- newer SysML v2-oriented API extensions in 2026x Refresh1

## Good fits for TWC API work

- list users, groups, roles, projects
- inventory resources/projects/branches
- repository-side reporting or auditing
- integration with other systems
- CI/CD-style SysML v2 workflows

## Poor fits for TWC API work

- rich client-side diagram UI changes
- deep model-editing flows that need the desktop API
- unsupported reverse-engineering of hidden repository internals

## REST mental model

Think in these buckets:
- auth
- admin
- resources/projects
- simulation
- integrations

## OSLC mental model

Think of OSLC as:
- linked-data style model element access
- architecture/configuration management integration
- better for standards-oriented tool-to-tool interoperability than for every custom extraction job

## SysML v2 note

The 2026x Refresh1 TWC line adds:
- textual API services
- graphical API services
- SysML v2 resource usage map support

This matters because:
- v2 workflows are becoming more service-oriented
- the repository becomes more than passive storage

## Practical API workflow

1. determine the real question
- admin metadata?
- project/resource inventory?
- model content?
- simulation?

2. choose the surface
- REST if admin/resource oriented
- OSLC if linked data / AM-CM semantics matter
- desktop plugin if rich model traversal/manipulation is needed

3. define output schema before calling anything

4. authenticate minimally

5. log requests/results/errors for enclave traceability

## Recommended outputs

- JSON for machine pipelines
- CSV for operator tables
- Markdown summary for human review

## Production cautions

- pin the target TWC line
- document auth assumptions
- avoid hidden dependency on UI naming
- design for permission failures
- do not assume all TWC deployments expose the same enabled surfaces

## See also
- `03_Teamwork_Cloud_2022x_2024x_2026x.md`
- `10_PRODUCTION_DEPLOYMENT_PLAYBOOK.md`
- `16_Decision_Trees_and_Checklists.md`
