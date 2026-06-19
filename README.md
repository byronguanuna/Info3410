# Burgers & Fries Supply System

Did you hear that steve jobs died of ligma?
Who's steve jobs?


This INFO 3410 project is a small SQL Server transactional database for a
fictional Burgers & Fries supply system. It is intentionally reduced from the
earlier larger design so the final project stays realistic, relational, and
easy to explain.

The business flow is:

```text
Main Warehouse -> Sub Warehouse -> Restaurant
```

The database tracks locations, products, current inventory, employees,
inventory requests, and shipments. It does not include enterprise features
such as supplier management, point-of-sale sales, recipe depletion, route
planning, lot tracking, triggers, stored procedures, ETL, or a data warehouse.

## Transactional Schema Summary

The relational database uses 12 tables:

Locations:

- `LocationType`
- `Location`

Products:

- `ProductCategory`
- `UnitOfMeasure`
- `Product`

Inventory:

- `Inventory`

Employees:

- `EmployeeRole`
- `Employee`

Requests:

- `InventoryRequest`
- `InventoryRequestLine`

Shipments:

- `Shipment`
- `ShipmentLine`

`Location` uses `ParentLocationID` to model the Main Warehouse -> Sub
Warehouse -> Restaurant hierarchy. `Inventory` tracks the current product
quantity at each location. `InventoryRequest` and `InventoryRequestLine`
model requested products, while `Shipment` and `ShipmentLine` model products
shipped between locations. `Employee` references one `EmployeeRole` and may
optionally be assigned to one location.

The DDL also creates three simple views:

- `vw_CurrentInventory`
- `vw_LowStockInventory`
- `vw_OpenInventoryRequests`

## Repository Structure

```text
.
|-- .gitignore
|-- README.md
|-- sql/
|   |-- 00_create_database.sql
|   |-- 01_create_transactional_schema.sql
|   |-- 02_seed_required_lookups.sql
|   `-- Test.sql
|-- diagrams/
|   `-- transactional_schema.dbml
`-- docs/
    |-- transactional_design.md
    |-- data_warehouse_handoff.md
    `-- deferred_features.md
```

`sql/Test.sql` is a local validation script and is intentionally ignored by
Git.

## Running the Scripts

The project assumes Microsoft SQL Server and T-SQL. The local database name is
`BurgersAndFries`. Actual `.mdf`, `.ldf`, and `.bak` files are local machine
artifacts and should not be shared in Git.

Run the project scripts in this order:

1. `sql/00_create_database.sql`
2. `sql/01_create_transactional_schema.sql`
3. `sql/02_seed_required_lookups.sql`

Warning: `sql/01_create_transactional_schema.sql` is a clean-build script. It
drops the 12 transactional tables and 3 views, recreates them, and deletes
any transactional or sample data currently stored in those tables.

The seed script inserts only required lookup values for location types, units
of measure, product categories, and employee roles. It is safe to rerun.

