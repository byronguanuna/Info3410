# Transactional Design

## Operational Scope

The transactional database tracks products and inventory inside the
Burgers & Fries distribution network. Inventory enters at a main warehouse,
moves to a sub warehouse, and then moves to a restaurant. It records current
balances, requests, shipments, external receipts, transfers, summarized
restaurant usage, waste, returns, and adjustments.

External suppliers exist in the business world but are outside this database.
The design also intentionally excludes customer orders, sales receipts,
payments, revenue accounting, and recipe-level menu depletion.

## Location Hierarchy

`Location` represents main warehouses, sub warehouses, and restaurants in one
generalized table. `LocationTypeID` identifies the type and
`ParentLocationID` creates the self-referencing supply hierarchy:

- A main warehouse normally has no internal parent.
- A sub warehouse normally has a main warehouse parent.
- A restaurant normally has a sub warehouse parent.

One table avoids duplicated address and contact structures and leaves room for
future location types without redesigning every relationship. The first
version prevents a location from parenting itself, but a check constraint
cannot inspect the type of another row. Parent-type validation is therefore
deferred to Austin's stored procedure, trigger, or approved application logic.

## Products and Current Inventory

Products are rows in `Product`, not separate columns for food, uniforms, or
cleaning supplies. Categories and units of measure are normalized into
`ProductCategory` and `UnitOfMeasure`, allowing the catalog to grow without
schema changes.

Inventory is also not stored as text. `Inventory` uses one row per location
and product, with a `DECIMAL(12,2)` quantity that supports whole and fractional
units. A quantity of zero is valid, while negative current balances are not
allowed in this first design.

`Inventory` is the current balance. `InventoryMovement` is the historical,
auditable record of activity. These responsibilities are separate so reports
can inspect past activity without treating a running balance as history.
Automatic updates from movements to current balances are deferred.

## Requests and Partial Fulfillment

`InventoryRequest` stores a request header between a requesting location and a
fulfilling location. `InventoryRequestLine` stores each requested product and
its requested, approved, and fulfilled quantities.

The approved quantity may differ from the requested quantity. Fulfillment can
occur over more than one shipment, and the header supports draft, submitted,
approved, partially fulfilled, fulfilled, and cancelled statuses. An
`IsEmergency` flag and needed-by date support off-schedule requests without a
complex scheduling system. Status-transition automation is deferred.

## Shipments

`Shipment` records an internal shipment from one location to another and may
optionally reference a request. This supports multiple shipments for one
request and also permits internal shipments that were not created from a
formal request. `ShipmentLine` stores the products and shipped or received
quantities.

The design records scheduling, shipping, and receiving dates but does not
implement routes, vehicles, or recurring schedules.

## User Authorization

`AppUser` represents people who can record or approve activity. It stores no
passwords and provides no authentication logic. `AppRole` defines the small
set of operational roles, while `UserLocationAccess` assigns one or more roles
to a user at a specific location.

This normalized access model replaces a repeated single-user field and permits
different responsibilities at different locations.

## Inventory Movements

`InventoryMovement` records historical activity using controlled values from
`InventoryMovementType`.

- An external receipt has no source location and a main warehouse destination.
- An internal transfer has both source and destination locations.
- Sold or consumed usage, waste, and adjustment out have a source but no
  destination.
- Adjustment in has a destination but no source.
- A return may move inventory from one internal location to another.

External receipts can record product, quantity, destination, timestamp, unit
cost, recording user, and notes. Outside supplier details are intentionally
not modeled.

## Known First-Version Limitations

- Parent location types are not automatically validated.
- Inventory movements do not automatically update `Inventory`.
- Request statuses and fulfillment totals are not automatically maintained.
- Movement type rules are not cross-validated against source and destination
  patterns.
- Lot numbers, expiration dates, recalls, and inventory by lot are deferred.
- Authentication, route planning, schedules, point-of-sale records, and the
  data warehouse are outside this version.

