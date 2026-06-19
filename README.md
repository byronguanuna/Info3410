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

## ER Diagram

```text
Relationship Summary

- Fact_Inventory_Movement (CENTER FACT TABLE)
  - fact_id (PK)
  - location_id (FK)
  - product_id (FK)
  - user_id (FK)
  - date_id (FK)
  - quantity
  - transaction_type
  - cost

- Dim_Location → Fact_Inventory_Movement
  One location can have many inventory transactions
  location_id (PK)


- Dim_Product → Fact_Inventory_Movement
  One product can appear in many transactions
  product_id (PK)


- Dim_User → Fact_Inventory_Movement
  One user can record many transactions
  user_id (PK)


- Dim_Date → Fact_Inventory_Movement
  One date can contain many transactions
  date_id (PK)


- Fact_Inventory_Movement → Aggregate_Inventory_Summary
  Aggregate table is derived from fact data (summary reporting layer)

  Aggregate_Inventory_Summary:
  - summary_id (PK)
  - location_id
  - product_id
  - total_quantity
  - total_cost
  - transaction_count



Key Structure Notes

- Fact table sits at the center of the model (star schema design)
- Dimension tables provide descriptive context:
  - Dim_Location (location_name, location_type, contact_info, parent_location_id)
  - Dim_Product (product_name, product_category)
  - Dim_User (username)
  - Dim_Date (full_date, day, month, year)

- All dimension tables connect 1-to-many into Fact_Inventory_Movement
- Aggregate table is derived from fact table for reporting performance
- This follows a standard data warehouse STAR SCHEMA design
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

