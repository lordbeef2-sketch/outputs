# Teamwork Cloud Auth Patterns

## Goal

Use this file when the question is not just "what endpoint exists?" but "how do I get an authenticated call through cleanly?"

## Truth rail

There is no single universal auth story for every TWC deployment.

What is consistent from the official documentation:
- TWC REST is exposed under the `/osmc` surface.
- A local Swagger document is bundled with the installation.
- Token-based authentication is a supported pattern.
- SAML/SSO may sit in front of the REST flow.

What still varies by deployment:
- whether token flow is enabled
- whether SSO is required
- certificate/trust behavior
- which surfaces are exposed to the caller

## Primary discovery points

- Local Swagger UI: `https://<twc-host>:8111/osmc/swagger`
- Public reference snapshot used in this pack:
  - `References/TWC_REST_SWAGGER_2026xR1.json`
  - `References/TWC_SIMULATION_SWAGGER_2026xR1.json`
- Endpoint grouping and call summaries:
  - `References/TWC_ENDPOINT_CATALOG.json`
  - `References/TWC_REQUEST_RESPONSE_EXAMPLES.json`

## Token-based auth pattern

Official docs describe this as a REST-supported flow.

High-level sequence:
1. Configure the auth server and TWC so the REST client ID is allowed.
2. Open the REST login endpoint in a browser.
3. Complete the identity-provider login if redirected.
4. Copy the returned token.
5. Send the token in the `Authorization` header using token type `Token`.

Official path pattern from the docs:
- browser login entry: `https://<ip>:8111/osmc/authen/login`
- REST login check example: `https://<ip>:8111/osmc/login`

Header pattern:

```http
Authorization: Token <token-value>
```

## Practical operator flow

For enclave-safe automation, use this order:

1. Check reachability:
   - `GET /osmc/admin/health`
2. Resolve auth shape:
   - browser redirect, token, or deployment-specific front door
3. Confirm identity:
   - `GET /osmc/admin/currentUser`
4. Run the smallest read-only query first:
   - `GET /osmc/resources`
5. Only then move into inventory or model extraction calls

## Good default call sequence

For a new environment:

1. `GET /osmc/admin/health`
2. `GET /osmc/login`
3. `GET /osmc/admin/currentUser`
4. `GET /osmc/resources`
5. `GET /osmc/resources/{resourceId}/branches`

This gives:
- health
- auth confirmation
- user identity
- repository listing
- branch listing

## What to store in the local KB/DB

For each TWC environment, keep:
- base URL
- TWC version line
- auth mode
- whether token flow is enabled
- whether simulation REST is enabled
- whether SysML v2 services are enabled
- trusted certificate expectations
- read-only service account details if allowed

## What not to assume

- Do not assume every TWC server exposes the same enabled endpoints.
- Do not assume a public Swagger snapshot exactly matches a private deployment.
- Do not assume SSO-backed environments will behave like simple local auth.
- Do not assume write access even if the endpoint exists.

## Best companion files

- `13_Teamwork_Cloud_API_Playbook.md`
- `References/TWC_ENDPOINT_CATALOG.json`
- `References/TWC_REQUEST_RESPONSE_EXAMPLES.json`
- `References/TWC_REST_SWAGGER_2026xR1.json`
- `References/TWC_SIMULATION_SWAGGER_2026xR1.json`
