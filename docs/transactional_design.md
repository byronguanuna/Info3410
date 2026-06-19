# Reduced Transactional Design

The current Burgers & Fries Supply System is a reduced 12-table transactional
database for the INFO 3410 class project. It is designed to demonstrate a
highly relational third-normal-form model without enterprise-scale features.

## Business Scope

The system tracks inventory through this hierarchy:

```text
Main Warehouse -> Sub Warehouse -> Restaurant
```

Restaurants can request inventory from a sub warehouse. Sub warehouses can
request inventory from a main warehouse. Shipments move requested products
between locations. Current inventory is stored by location and product.

## Main Design Choices

- `Location` is generalized for main warehouses, sub warehouses, and
  restaurants.
- `ParentLocationID` represents the hierarchy between locations.
- `Product`, `ProductCategory`, and `UnitOfMeasure` keep product data
  normalized.
- `Inventory` is a bridge table between `Location` and `Product`.
- `Employee` has one `EmployeeRole` and may optionally be assigned to one
  location.
- `InventoryRequest` and `InventoryRequestLine` separate request headers from
  requested products.
- `Shipment` and `ShipmentLine` separate shipment headers from shipped
  products.

## Views

The DDL creates three views for simple reporting:

- `vw_CurrentInventory`
- `vw_LowStockInventory`
- `vw_OpenInventoryRequests`

These views are intentionally basic and only use the transactional tables.

## Removed From Current Scope

The reduced version does not include separate app-user authorization tables,
inventory movement history, suppliers, distributors, point-of-sale sales,
customer orders, recipes, payments, route planning, or lot tracking.

The project now includes a small data warehouse star schema, snapshot stored
procedures, functions, and triggers. Those pieces support the assignment's
warehouse-loading requirements without expanding the transactional model into
an enterprise-scale system.

