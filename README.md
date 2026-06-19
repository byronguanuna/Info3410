# Burgers & Fries Supply System


This INFO 3410 project is a small SQL Server transactional database for a
fictional Burgers & Fries supply system. It is intentionally reduced from the
earlier larger design so the final project stays realistic, relational, and
easy to explain.

The business flow is:

```text
Main Warehouse -> Sub Warehouse -> Restaurant
```

The database tracks locations, products, current inventory, employees,
inventory requests, and shipments. It also includes a small data warehouse star
schema, snapshot stored procedures, functions, and triggers for loading
inventory snapshot data into that warehouse. It does not include enterprise
features such as supplier management, point-of-sale sales, recipe depletion,
route planning, or lot tracking.

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
|   |-- 03_create_warehouse_support.sql
|   `-- Test.sql
|-- Schema/
|   `-- schema.sql
|-- Functions/
|   `-- functions.sql
|-- Triggers/
|   `-- triggers.sql
|-- diagrams/
|   `-- transactional_schema.dbml
`-- docs/
    |-- transactional_design.md
    |-- data_warehouse_handoff.md
    `-- deferred_features.md
```

## ER Diagrams

The transactional ER diagram is stored in `diagrams/transactional_schema.dbml`.
The warehouse star schema is summarized below.

```text
Star Schema Relationship Summary

- Fact_Inventory_Movement (CENTER FACT TABLE)
  - FactID (PK)
  - LocationID / location_id (FK)
  - ProductID / product_id (FK)
  - UserID (FK)
  - DateID (FK)
  - Quantity
  - TransactionType
  - Cost

- Dim_Location -> Fact_Inventory_Movement
  One location can have many inventory transactions
  LocationID (PK)


- Dim_Product -> Fact_Inventory_Movement
  One product can appear in many transactions
  ProductID (PK)


- Dim_User -> Fact_Inventory_Movement
  One user can record many transactions
  UserID (PK)


- Dim_Date -> Fact_Inventory_Movement
  One date can contain many transactions
  DateID (PK)


- Fact_Inventory_Movement -> Aggregate_Inventory_Summary
  Aggregate table is derived from fact data (summary reporting layer)

  Aggregate_Inventory_Summary:
  - SummaryID (PK)
  - location_id / LocationID
  - product_id / ProductID
  - total_quantity / TotalQuantity
  - total_cost / TotalCost
  - transaction_count / TransactionCount



Key Structure Notes

- Fact table sits at the center of the model (star schema design)
- Dimension tables provide descriptive context:
  - Dim_Location (LocationName, LocationType, ContactInfo, ParentLocationID)
  - Dim_Product (ProductName, ProductCategory)
  - Dim_User (Username)
  - Dim_Date (FullDate, DayNum, MonthNum, YearNum)

- All dimension tables connect 1-to-many into Fact_Inventory_Movement
- Aggregate table is derived from fact table for reporting performance
- sql/03_create_warehouse_support.sql keeps the trigger-friendly snake_case
  columns and function-friendly PascalCase columns compatible
- This follows a standard data warehouse STAR SCHEMA design
```

`sql/Test.sql` is a validation script for checking the built database.

## Running the Scripts

The project assumes Microsoft SQL Server and T-SQL. The local database name is
`BurgersAndFries`. Actual `.mdf`, `.ldf`, and `.bak` files are local machine
artifacts and should not be shared in Git.

Run the project scripts in this order:

1. `sql/00_create_database.sql`
2. `sql/01_create_transactional_schema.sql`
3. `sql/02_seed_required_lookups.sql`
4. `Schema/schema.sql`
5. `sql/03_create_warehouse_support.sql`
6. `Functions/functions.sql`
7. `Triggers/triggers.sql`

After the scripts are created, run the warehouse snapshot:

```sql
EXEC dbo.usp_Snapshot_All @SnapshotDate = '2026-04-10';
```

Then run `sql/Test.sql` to validate the tables, views, functions, triggers,
procedures, seed data, snapshot rows, and constraints.

When running `Schema/schema.sql`, `Functions/functions.sql`, or
`Triggers/triggers.sql` manually, make sure the query window is connected to
the `BurgersAndFries` database.

Warning: `sql/01_create_transactional_schema.sql` is a clean-build script. It
drops the project views, procedures, functions, triggers, warehouse tables,
and transactional tables before recreating the transactional schema.

The seed script inserts required lookup values and sample operational data for
locations, products, employees, inventory, requests, and shipments. It is safe
to rerun after the clean-build script.

