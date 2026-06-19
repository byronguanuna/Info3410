/*
    Required lookup data for the reduced Burgers & Fries Supply System.
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
        ('Main Warehouse', 'Main distribution warehouse.'),
        ('Sub Warehouse', 'Regional or city warehouse.'),
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

INSERT INTO dbo.EmployeeRole (RoleName, Description)
SELECT Seed.RoleName, Seed.Description
FROM
(
    VALUES
        ('Warehouse Manager', 'Manages warehouse inventory activity.'),
        ('Inventory Clerk', 'Records requests, shipments, and inventory counts.'),
        ('Restaurant Manager', 'Manages restaurant inventory requests.'),
        ('Restaurant Employee', 'Assists with restaurant inventory activity.'),
        ('Auditor', 'Reviews inventory and shipment records.')
) AS Seed (RoleName, Description)
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.EmployeeRole AS Existing
    WHERE Existing.RoleName = Seed.RoleName
);

COMMIT TRANSACTION;

