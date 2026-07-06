# Java

## Snapshot

Oracle Java downloads page snapshot on 2026-07-06:
- Latest Java SE release: `JDK 26`
- Latest LTS: `JDK 25`
- Previous LTS: `JDK 21`

## Why Java matters here

Java is the core language for:
- Cameo / MagicDraw Open API plugins
- richer in-client automation
- direct access to vendor model APIs
- higher-performance model traversals and transformations

## The key compatibility rule

In the 3DS/No Magic ecosystem:
- "latest Java" is not the decision variable.
- "vendor-supported Java for this exact release line" is the decision variable.

Example:
- No Magic compatibility docs explicitly call out supported Java lines for product families such as 2022x.

## Where Java fits best

Use Java when you need:
- plugin menus/actions/listeners
- direct model element manipulation
- custom validation or transformations inside the client
- robust long-lived integrations with the official platform API

Do not default to Java when:
- a report template can solve it
- a TWC REST integration is enough
- the job is only post-processing exported data
