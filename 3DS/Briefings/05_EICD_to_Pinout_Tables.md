# Ways to Map and Digest EICDs into Pinout Tables

## Scope

This section is partly source-backed and partly engineering synthesis.

Ground truths from sources:
- An ICD table describes interfaces between systems/subsystems.
- It can describe interfaces from physical connection details up through logical/application layers.
- Cameo SysML tooling already has ICD table concepts.

Engineering synthesis added here:
- a practical normalization pipeline for turning mixed EICD input into machine-usable pinout tables.

## What an EICD usually contains

An EICD or ICD may contain:
- system or subsystem names
- interface names
- connectors / plugs / shells / backshells
- pin or contact IDs
- signals
- directionality
- voltage/current/termination/shielding details
- protocol/logical usage
- source/consumer endpoint mapping
- revision and ownership data
- notes/exceptions

## What a pinout table needs

At minimum, a pinout table row should answer:
- which connector?
- which pin/contact?
- what signal/net/function?
- direction?
- source side?
- destination side?
- electrical constraints?
- notes/revision?

## Recommended canonical intermediate schema

Before generating any final pinout table, normalize to this schema:

| Field | Meaning |
|---|---|
| `interface_id` | stable interface key |
| `interface_name` | human-readable interface name |
| `source_system` | originating system/subsystem |
| `source_element` | block/assembly/LRU/module |
| `source_connector` | connector name/part |
| `source_pin` | pin/contact/cavity |
| `dest_system` | receiving system/subsystem |
| `dest_element` | destination block/assembly/LRU/module |
| `dest_connector` | destination connector |
| `dest_pin` | destination pin/contact/cavity |
| `signal_name` | normalized signal or circuit name |
| `signal_type` | power, ground, discrete, analog, serial, ethernet, etc. |
| `direction` | source-to-dest, bidirectional, N/A |
| `protocol_layer` | optional logical layer |
| `electrical_limits` | voltage/current/impedance/termination |
| `wire_color_or_id` | optional harness-specific field |
| `shield_drain` | optional shield/drain mapping |
| `revision` | source revision |
| `source_doc_ref` | where the row came from |
| `notes` | free-text residue |

## Recommended ingestion pipeline

1. Collect raw EICD sources
- PDF
- Excel
- Word
- CSV
- exported Cameo tables
- scanned/customer ICDs

2. Normalize the structure
- Split merged cells
- propagate inherited headers
- standardize connector names
- standardize pin naming
- standardize direction vocabulary

3. Separate logical and physical layers
- logical signal definitions
- physical connector/pin mappings
- endpoint ownership

4. Expand one-to-many rows
- one signal to multiple pins
- one connector shell to multiple contacts
- differential pairs
- shield/drain and return-path rows

5. Resolve naming conflicts
- alias dictionary for signal names
- connector alias dictionary
- subsystem name alias dictionary

6. Validate
- duplicate pin occupancy
- impossible direction pairs
- missing mate pin
- power/ground rows missing constraints
- differential-pair incompleteness
- connector shell mismatch

7. Emit outputs
- master normalized table
- source-specific exception table
- final human pinout table
- change report by revision

## Good AI parsing strategy

If an AI has to ingest a messy EICD:
- do not jump straight to final pinout rows
- first identify:
  - endpoints
  - connectors
  - contacts
  - signal names
  - directions
  - constraints
- only then generate the row set

## Mapping Cameo / SysML data to pinout rows

Useful model elements:
- blocks / parts / subsystems
- ports / flow ports / interface blocks
- connectors
- item flows
- value properties / tagged values
- requirement references
- ICD tables

Practical crosswalk:
- `source_system` / `dest_system` <- owning blocks or parts
- `signal_name` <- item flow, conveyed item, or interface signal definition
- `connector` <- modeled connector / physical interface
- `direction` <- flow properties / interface semantics
- `electrical_limits` <- value properties, stereotypes, or ICD table columns

## Common failure modes

- pin numbers are present but mating connector names are ambiguous
- direction uses "IN/OUT" from inconsistent perspective
- one row mixes logical function and physical wiring in uncontrolled text
- shields/grounds/returns are embedded in notes instead of rows
- connector revisions drift while signal names stay stable

## Best final outputs

For human use:
- one clean pinout table
- one exception table
- one revision delta table

For AI use:
- one canonical normalized CSV/JSON
- one alias dictionary
- one validation report

## Bottom line

The best way to digest EICDs into pinout tables is:
- normalize first
- separate layers
- validate hard
- only then publish the human-facing table

Do not let the display format become the master data model.
