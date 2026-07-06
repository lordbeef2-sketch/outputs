# Teamwork Cloud / Magic Collaboration Studio (TWC)

## What TWC is

TWC is the repository/server/collaboration side of the stack.

Think of it as:
- storage
- model versioning
- branching/merging
- access control
- admin services
- web-based collaboration surfaces
- API surface for automation and integration

Modern naming can show up as:
- Teamwork Cloud and Services
- Magic Collaboration Studio / Teamwork Cloud and Services
- Cameo Collaborator for Teamwork Cloud

## Release line view

### 2022x
What stands out:
- data markings
- reporting support
- easier installation
- access-control improvements

### 2022x Refresh2
What stands out:
- element-level webhooks
- stronger password lifecycle options
- more flexible resource synchronization

### 2024x
What stands out:
- visual branch activity
- new user-group membership manager role
- branch-specific webhook selection
- DSLS licensing option in addition to FlexNet
- Collaborator enhancements including export/template features

### 2024x Refresh3
What stands out:
- admin-side license management options
- simplified SAML setup and testing
- broader UX and efficiency improvements

### 2026x Refresh1
What stands out:
- MagicLab Collaborator for SysML v2 collaboration
- Resource Usage Map for SysML v2 resources
- modernized Web Application Platform home page
- automatic SAML login redirection
- configurable parallel synchronization jobs
- SysML v2 REST API extensions for textual and graphical workflows

## The server-side mental model

Core concerns:
- projects/resources
- branches/commits/history
- users/groups/roles
- authentication/SSO
- deployment/runtime
- API access
- collaboration UX

## API surface

Officially visible surfaces include:
- REST APIs for user accounts, roles, projects, resources, and server management
- token-based authentication endpoints
- OSLC support for model element data
- simulation REST endpoints
- newer SysML v2-specific API extensions in 2026x Refresh1

Practical rule:
- If the data lives in TWC, prefer TWC APIs/export/reporting before screen scraping or raw file surgery.

## Upgrade thinking

Never treat TWC upgrades as "just install the new bits."

Track at least:
- TWC software version
- Cassandra version / migration needs
- auth/SSO configuration impacts
- plugin/service compatibility
- client/Cameo compatibility
- licensing changes

The official upgrade tables matter because:
- some jumps require Cassandra upgrades
- some jumps require database migration
- non-consecutive upgrades may still be supported, but not without infrastructure checks

## Offline enclave relevance

TWC is especially important in enclaves because it can become:
- the authoritative model repository
- the audit/review backbone
- the collaboration control point
- the integration hub for scripted automation

That also means:
- upgrades must be staged carefully
- authentication choices have operational consequences
- API-based extraction can be cleaner than ad-hoc file handling

## AI "do not confuse these" list

- TWC is not just a file server.
- TWC branches/history are richer than exchanging `.mdzip` files.
- TWC REST and OSLC are not the same thing.
- Collaborator, MagicLab, Admin, and core TWC services are related but distinct layers.

## Read next
- `02_Cameo_2022x_2024x_2026x.md`
- `06_Cameo_Project_Data_Scripts_Plugins.md`
