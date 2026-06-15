# Data Warehouse Handoff

Austin owns the analytical schema and all loading or automation logic. The
transactional foundation provides the following likely sources:

| Proposed warehouse object | Transactional source |
| --- | --- |
| `DimLocation` | `Location` joined to `LocationType` |
| `DimProduct` | `Product` joined to `ProductCategory` and `UnitOfMeasure` |
| `DimUser` | `AppUser` |
| `DimDate` | Generated from dates such as `InventoryMovement.MovementDate` |
| `FactInventoryMovement` | Primarily `InventoryMovement`, with related lookup data |
| Current inventory summary | `Inventory` |

`InventoryMovement` is intended to be the main auditable event source. It
identifies the movement type, product, quantity, cost when available,
performing user, optional shipment line, and both possible location roles.
`Inventory` provides the current balance rather than event history.

## Transfer Location Keys

An internal transfer has both a source location and a destination location. A
fact table with only one `LocationKey` may lose important information about
the transfer. The team should review two possible approaches:

1. Store `FromLocationKey` and `ToLocationKey` as role-playing keys to the
   location dimension.
2. Produce separate outbound and inbound fact rows for each internal transfer.

This document records the issue but does not change Austin's proposed
warehouse design.

## Ownership Boundary

Austin owns the star schema, dimensions, facts, aggregates, functions, stored
procedures, triggers, data warehouse loading, and snapshot logic. In
particular, Austin's later logic may validate parent location types, manage
request transitions, update current inventory from movements, and load the
analytical model. None of those objects are included in the transactional
foundation.

