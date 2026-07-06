# Python 3.11

## Snapshot

- Latest verified patch in the 3.11 line: `3.11.15`
- Release date: `2026-03-03`
- Python.org marks it as a security release for the legacy 3.11 series.

## Why 3.11 still matters

Even if newer Python feature lines exist, Python 3.11 still matters because:
- enterprise tooling often stays on established minor versions
- plugins/scripts/integration stacks may not immediately move to 3.12+
- security patch awareness matters for enclave/offline baselines

## AI mental model

Python 3.11 is often the best glue language when you need:
- ETL
- CSV/Excel/JSON shaping
- document parsing
- simple local APIs
- data validation
- reporting
- offline automation

## Where Python fits in this 3DS pack

Good Python uses here:
- digest EICDs into normalized schemas
- generate pinout tables from cleaned source data
- read exported Cameo/TWC reports and transform them
- orchestrate offline pipelines around CSV/JSON/XML/XMI inputs
- build compatibility checkers or diff tools

Less ideal Python use here:
- direct in-client Cameo UI extension
- rich native plugin logic that belongs in the Java Open API

## Recommended patterns

- Keep schemas explicit.
- Separate parsing from normalization from publishing.
- Treat vendor-exported data as source material, not final truth.
- Use Python for post-processing when Java plugin deployment is too heavy.
