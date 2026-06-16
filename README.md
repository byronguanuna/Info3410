# Burgers & Fries Inventory Database

This INFO 3410 final project models the transactional inventory flow for a
fictional fast-food restaurant chain. Products enter the internal network at a
main warehouse, move to a regional sub warehouse, and then move to a
Burgers & Fries restaurant.

```text
External Source -> Main Warehouse -> Sub Warehouse -> Restaurant
```

The repository currently contains the first reviewable version of the
transactional database foundation. It does not contain the data warehouse,
automation logic, presentation, or large sample dataset.

## Team Scope

- **Brayden:** transactional tables, relationships, keys, basic constraints,
  and transactional ER diagram.
- **Austin:** data warehouse schema, facts, dimensions, aggregates, functions,
  stored procedures, triggers, loading, and snapshot logic.
- **Byron:** presentation, presentation screenshots, formatting support, and
  large sample-data generation.

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
- Dim_Location → Fact_Inventory_Movement
One location can have many inventory transactions
- Dim_Product → Fact_Inventory_Movement
One product can appear in many transactions
- Dim_User → Fact_Inventory_Movement
One user can record many transactions
- Dim_Date → Fact_Inventory_Movement
One date can contain many transactions
- Fact_Inventory_Movement → Aggregate_Inventory_Summary
Aggregate table is derived from fact data (summary reporting layer)

Key Structure Notes
- Fact table sits at the center of the model
- Dimension tables provide descriptive context
- Aggregate table improves reporting performance
- This follows a standard data warehouse star schema design
```

## Running the Scripts

The initial implementation assumes Microsoft SQL Server and T-SQL. Actual
`.mdf` and `.ldf` database files are local artifacts and are not shared in
Git. Backup files such as `.bak` are also local and should not be shared in
the repository.

Each teammate creates or uses a local database named `BurgersAndFries`, then
runs the scripts in this order:

1. `sql/00_create_database.sql`
2. `sql/01_create_transactional_schema.sql`
3. `sql/02_seed_required_lookups.sql`
4. `sql/Test.sql`

`sql/Test.sql` is a local validation script and is intentionally ignored by
Git.

Warning: `sql/01_create_transactional_schema.sql` is a clean-build script. It
drops the 15 transactional tables, recreates them, and deletes transactional
or sample data currently stored in those tables. It should not be rerun
casually after meaningful sample data has been added.

The seed script inserts only required lookup values and is safe to rerun.

## Intentionally Deferred

This version does not implement lot and expiration tracking, external supplier
management, automated inventory updates, hierarchy validation logic, route
planning, recurring shipping schedules, point-of-sale records, authentication,
data warehouse objects, or large sample data. See
[`docs/deferred_features.md`](docs/deferred_features.md) for the full list.

