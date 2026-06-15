/*
    Required reference data for the Burgers & Fries transactional database.
    This script is safe to rerun after 01_create_transactional_schema.sql.
*/

USE BurgersAndFries;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

INSERT INTO dbo.LocationType (LocationTypeName, Description)
SELECT Seed.LocationTypeName, Seed.Description
FROM
(
    VALUES
        ('Main Warehouse', 'Receives external inventory and supplies sub warehouses.'),
        ('Sub Warehouse', 'Regional or city warehouse that supplies restaurants.'),
        ('Restaurant', 'Burgers & Fries restaurant location.')
) AS Seed (LocationTypeName, Description)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.LocationType AS Existing
    WHERE Existing.LocationTypeName = Seed.LocationTypeName
);

INSERT INTO dbo.UnitOfMeasure (UnitName, Abbreviation)
SELECT Seed.UnitName, Seed.Abbreviation
FROM
(
    VALUES
        ('Each', 'ea'),
        ('Case', 'case'),
        ('Pallet', 'pallet'),
        ('Pound', 'lb'),
        ('Gallon', 'gal'),
        ('Bag', 'bag'),
        ('Box', 'box'),
        ('Canister', 'can')
) AS Seed (UnitName, Abbreviation)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.UnitOfMeasure AS Existing
    WHERE Existing.UnitName = Seed.UnitName
       OR Existing.Abbreviation = Seed.Abbreviation
);

INSERT INTO dbo.ProductCategory (CategoryName, CategoryGroup)
SELECT Seed.CategoryName, Seed.CategoryGroup
FROM
(
    VALUES
        ('Food Ingredients', 'Food'),
        ('Beverage Supplies', 'Beverage'),
        ('Packaging and Disposables', 'Packaging'),
        ('Cleaning Supplies', 'Cleaning'),
        ('Uniforms', 'Uniform'),
        ('Operating Supplies', 'Other')
) AS Seed (CategoryName, CategoryGroup)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.ProductCategory AS Existing
    WHERE Existing.CategoryName = Seed.CategoryName
);

INSERT INTO dbo.AppRole (RoleName, Description)
SELECT Seed.RoleName, Seed.Description
FROM
(
    VALUES
        ('Administrator', 'Manages application-level configuration and access.'),
        ('Warehouse Manager', 'Approves and oversees warehouse inventory activity.'),
        ('Inventory Clerk', 'Records receipts, shipments, and inventory activity.'),
        ('Restaurant Manager', 'Oversees restaurant requests and inventory activity.'),
        ('Restaurant Employee', 'Records permitted restaurant inventory usage.'),
        ('Auditor', 'Reviews inventory records and movement history.')
) AS Seed (RoleName, Description)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.AppRole AS Existing
    WHERE Existing.RoleName = Seed.RoleName
);

INSERT INTO dbo.InventoryMovementType (MovementTypeName, Description)
SELECT Seed.MovementTypeName, Seed.Description
FROM
(
    VALUES
        ('External Receipt', 'Inventory received by a main warehouse from outside the internal network.'),
        ('Internal Transfer', 'Inventory moved between two internal locations.'),
        ('Sold or Consumed', 'Summarized restaurant usage that reduces inventory.'),
        ('Waste', 'Inventory discarded or lost.'),
        ('Adjustment In', 'Positive inventory correction.'),
        ('Adjustment Out', 'Negative inventory correction.'),
        ('Return', 'Inventory returned from one internal location to another.')
) AS Seed (MovementTypeName, Description)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.InventoryMovementType AS Existing
    WHERE Existing.MovementTypeName = Seed.MovementTypeName
);

COMMIT TRANSACTION;

