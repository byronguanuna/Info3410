/*
    Required lookup and sample data for the Burgers & Fries Supply System.
    This script is safe to rerun after 01_create_transactional_schema.sql.
*/

USE BurgersAndFries;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
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

/* Locations: Main Warehouse -> Sub Warehouse -> Restaurant. */
INSERT INTO dbo.Location
(
    LocationTypeID,
    ParentLocationID,
    LocationCode,
    LocationName,
    AddressLine1,
    AddressLine2,
    City,
    StateCode,
    PostalCode,
    Phone,
    Email
)
SELECT
    LT.LocationTypeID,
    NULL,
    Seed.LocationCode,
    Seed.LocationName,
    Seed.AddressLine1,
    Seed.AddressLine2,
    Seed.City,
    Seed.StateCode,
    Seed.PostalCode,
    Seed.Phone,
    Seed.Email
FROM
(
    VALUES
        ('BAF-DEN-MAIN', 'Main Warehouse', 'Denver Main Distribution Warehouse', '2500 Blake St', NULL, 'Denver', 'CO', '80205', '303-555-0100', 'denver-main@burgersandfries.test')
) AS Seed (LocationCode, LocationTypeName, LocationName, AddressLine1, AddressLine2, City, StateCode, PostalCode, Phone, Email)
INNER JOIN dbo.LocationType AS LT
    ON LT.LocationTypeName = Seed.LocationTypeName
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Location AS Existing
    WHERE Existing.LocationCode = Seed.LocationCode
);

INSERT INTO dbo.Location
(
    LocationTypeID,
    ParentLocationID,
    LocationCode,
    LocationName,
    AddressLine1,
    AddressLine2,
    City,
    StateCode,
    PostalCode,
    Phone,
    Email
)
SELECT
    LT.LocationTypeID,
    Parent.LocationID,
    Seed.LocationCode,
    Seed.LocationName,
    Seed.AddressLine1,
    Seed.AddressLine2,
    Seed.City,
    Seed.StateCode,
    Seed.PostalCode,
    Seed.Phone,
    Seed.Email
FROM
(
    VALUES
        ('BAF-BOU-SUB', 'Sub Warehouse', 'BAF-DEN-MAIN', 'Boulder Sub Warehouse', '4800 Pearl Pkwy', NULL, 'Boulder', 'CO', '80301', '720-555-0110', 'boulder-sub@burgersandfries.test'),
        ('BAF-DEN-SUB', 'Sub Warehouse', 'BAF-DEN-MAIN', 'Denver South Sub Warehouse', '780 S Jason St', NULL, 'Denver', 'CO', '80223', '303-555-0120', 'denver-south-sub@burgersandfries.test'),
        ('BAF-COS-SUB', 'Sub Warehouse', 'BAF-DEN-MAIN', 'Colorado Springs Sub Warehouse', '1180 Aviation Way', NULL, 'Colorado Springs', 'CO', '80916', '719-555-0130', 'cos-sub@burgersandfries.test')
) AS Seed (LocationCode, LocationTypeName, ParentLocationCode, LocationName, AddressLine1, AddressLine2, City, StateCode, PostalCode, Phone, Email)
INNER JOIN dbo.LocationType AS LT
    ON LT.LocationTypeName = Seed.LocationTypeName
INNER JOIN dbo.Location AS Parent
    ON Parent.LocationCode = Seed.ParentLocationCode
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Location AS Existing
    WHERE Existing.LocationCode = Seed.LocationCode
);

INSERT INTO dbo.Location
(
    LocationTypeID,
    ParentLocationID,
    LocationCode,
    LocationName,
    AddressLine1,
    AddressLine2,
    City,
    StateCode,
    PostalCode,
    Phone,
    Email
)
SELECT
    LT.LocationTypeID,
    Parent.LocationID,
    Seed.LocationCode,
    Seed.LocationName,
    Seed.AddressLine1,
    Seed.AddressLine2,
    Seed.City,
    Seed.StateCode,
    Seed.PostalCode,
    Seed.Phone,
    Seed.Email
FROM
(
    VALUES
        ('BAF-BOU-001', 'Restaurant', 'BAF-BOU-SUB', 'Boulder Pearl Restaurant', '1600 Pearl St', NULL, 'Boulder', 'CO', '80302', '720-555-0140', 'boulder-pearl@burgersandfries.test'),
        ('BAF-DEN-001', 'Restaurant', 'BAF-DEN-SUB', 'Denver LoDo Restaurant', '1899 Wynkoop St', NULL, 'Denver', 'CO', '80202', '303-555-0150', 'denver-lodo@burgersandfries.test'),
        ('BAF-COS-001', 'Restaurant', 'BAF-COS-SUB', 'Colorado Springs North Restaurant', '742 Garden of the Gods Rd', NULL, 'Colorado Springs', 'CO', '80907', '719-555-0160', 'cos-north@burgersandfries.test')
) AS Seed (LocationCode, LocationTypeName, ParentLocationCode, LocationName, AddressLine1, AddressLine2, City, StateCode, PostalCode, Phone, Email)
INNER JOIN dbo.LocationType AS LT
    ON LT.LocationTypeName = Seed.LocationTypeName
INNER JOIN dbo.Location AS Parent
    ON Parent.LocationCode = Seed.ParentLocationCode
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Location AS Existing
    WHERE Existing.LocationCode = Seed.LocationCode
);

INSERT INTO dbo.Product
(
    ProductSKU,
    ProductName,
    ProductCategoryID,
    UnitOfMeasureID,
    Description,
    StorageType,
    IsPerishable,
    StandardUnitCost
)
SELECT
    Seed.ProductSKU,
    Seed.ProductName,
    PC.ProductCategoryID,
    U.UnitOfMeasureID,
    Seed.Description,
    Seed.StorageType,
    Seed.IsPerishable,
    Seed.StandardUnitCost
FROM
(
    VALUES
        ('BEEF-PATTY-4OZ', 'Quarter Pound Beef Patties', 'Food Ingredients', 'Case', 'Frozen four-ounce burger patties.', 'Frozen', 1, 54.00),
        ('FRIES-SHOESTRING', 'Shoestring French Fries', 'Food Ingredients', 'Bag', 'Frozen par-fried potatoes.', 'Frozen', 1, 18.50),
        ('BURGER-BUN', 'Sesame Burger Buns', 'Food Ingredients', 'Box', 'Restaurant burger buns.', 'Ambient', 1, 14.25),
        ('CHEDDAR-SLICES', 'Cheddar Cheese Slices', 'Food Ingredients', 'Case', 'Pre-sliced cheddar cheese.', 'Refrigerated', 1, 31.75),
        ('PICKLE-CHIPS', 'Dill Pickle Chips', 'Food Ingredients', 'Gallon', 'Crinkle-cut dill pickle chips.', 'Refrigerated', 1, 8.95),
        ('LETTUCE-SHRED', 'Shredded Iceberg Lettuce', 'Food Ingredients', 'Bag', 'Washed shredded lettuce.', 'Refrigerated', 1, 7.80),
        ('FRY-OIL-BLEND', 'High Heat Fry Oil Blend', 'Food Ingredients', 'Gallon', 'Fryer oil for restaurant operations.', 'Ambient', 0, 12.40),
        ('KETCHUP-PACKET', 'Ketchup Packets', 'Food Ingredients', 'Case', 'Single-serve ketchup packets.', 'Ambient', 0, 16.90),
        ('CUP-FOUNTAIN-20', '20 oz Fountain Cups', 'Packaging and Disposables', 'Case', 'Disposable fountain drink cups.', 'Ambient', 0, 22.10),
        ('CARTON-FRY-SM', 'Small Paper Fry Cartons', 'Packaging and Disposables', 'Box', 'Small branded fry cartons.', 'Ambient', 0, 19.40),
        ('SANITIZER-CONC', 'Sanitizer Concentrate', 'Cleaning Supplies', 'Canister', 'Food-safe sanitizer concentrate.', 'Ambient', 0, 27.35),
        ('GRILL-GLOVES', 'Heat Resistant Grill Gloves', 'Operating Supplies', 'Each', 'Reusable grill gloves.', 'Ambient', 0, 11.60)
) AS Seed (ProductSKU, ProductName, CategoryName, UnitName, Description, StorageType, IsPerishable, StandardUnitCost)
INNER JOIN dbo.ProductCategory AS PC
    ON PC.CategoryName = Seed.CategoryName
INNER JOIN dbo.UnitOfMeasure AS U
    ON U.UnitName = Seed.UnitName
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Product AS Existing
    WHERE Existing.ProductSKU = Seed.ProductSKU
);

INSERT INTO dbo.Employee
(
    EmployeeRoleID,
    LocationID,
    FirstName,
    LastName,
    Email,
    Phone
)
SELECT
    ER.EmployeeRoleID,
    L.LocationID,
    Seed.FirstName,
    Seed.LastName,
    Seed.Email,
    Seed.Phone
FROM
(
    VALUES
        ('Warehouse Manager', 'BAF-DEN-MAIN', 'Alex', 'Porter', 'alex.porter@burgersandfries.test', '303-555-1100'),
        ('Inventory Clerk', 'BAF-DEN-MAIN', 'Morgan', 'Lee', 'morgan.lee@burgersandfries.test', '303-555-1101'),
        ('Warehouse Manager', 'BAF-BOU-SUB', 'Jamie', 'Chen', 'jamie.chen@burgersandfries.test', '720-555-1110'),
        ('Inventory Clerk', 'BAF-DEN-SUB', 'Taylor', 'Smith', 'taylor.smith@burgersandfries.test', '303-555-1120'),
        ('Restaurant Manager', 'BAF-BOU-001', 'Riley', 'Gomez', 'riley.gomez@burgersandfries.test', '720-555-1140'),
        ('Restaurant Manager', 'BAF-DEN-001', 'Casey', 'Patel', 'casey.patel@burgersandfries.test', '303-555-1150'),
        ('Restaurant Employee', 'BAF-COS-001', 'Drew', 'Nguyen', 'drew.nguyen@burgersandfries.test', '719-555-1160'),
        ('Auditor', NULL, 'Priya', 'Shah', 'priya.shah@burgersandfries.test', '303-555-1199')
) AS Seed (RoleName, LocationCode, FirstName, LastName, Email, Phone)
INNER JOIN dbo.EmployeeRole AS ER
    ON ER.RoleName = Seed.RoleName
LEFT JOIN dbo.Location AS L
    ON L.LocationCode = Seed.LocationCode
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Employee AS Existing
    WHERE Existing.Email = Seed.Email
);

INSERT INTO dbo.Inventory
(
    LocationID,
    ProductID,
    QuantityOnHand,
    ReorderPoint,
    TargetStockLevel,
    LastUpdated
)
SELECT
    L.LocationID,
    P.ProductID,
    Seed.QuantityOnHand,
    Seed.ReorderPoint,
    Seed.TargetStockLevel,
    CONVERT(DATETIME2, Seed.LastUpdatedText)
FROM
(
    VALUES
        ('BAF-DEN-MAIN', 'BEEF-PATTY-4OZ', 520.00, 150.00, 600.00, '2026-04-10T07:30:00'),
        ('BAF-DEN-MAIN', 'FRIES-SHOESTRING', 780.00, 200.00, 900.00, '2026-04-10T07:30:00'),
        ('BAF-DEN-MAIN', 'BURGER-BUN', 430.00, 120.00, 520.00, '2026-04-10T07:30:00'),
        ('BAF-DEN-MAIN', 'FRY-OIL-BLEND', 260.00, 75.00, 320.00, '2026-04-10T07:30:00'),
        ('BAF-BOU-SUB', 'BEEF-PATTY-4OZ', 118.00, 40.00, 160.00, '2026-04-10T08:00:00'),
        ('BAF-BOU-SUB', 'FRIES-SHOESTRING', 170.00, 50.00, 220.00, '2026-04-10T08:00:00'),
        ('BAF-BOU-SUB', 'BURGER-BUN', 96.00, 30.00, 140.00, '2026-04-10T08:00:00'),
        ('BAF-DEN-SUB', 'BEEF-PATTY-4OZ', 92.00, 45.00, 170.00, '2026-04-10T08:15:00'),
        ('BAF-DEN-SUB', 'FRY-OIL-BLEND', 34.00, 24.00, 80.00, '2026-04-10T08:15:00'),
        ('BAF-DEN-SUB', 'CHEDDAR-SLICES', 44.00, 18.00, 65.00, '2026-04-10T08:15:00'),
        ('BAF-COS-SUB', 'LETTUCE-SHRED', 38.00, 14.00, 50.00, '2026-04-10T08:30:00'),
        ('BAF-COS-SUB', 'CARTON-FRY-SM', 76.00, 20.00, 90.00, '2026-04-10T08:30:00'),
        ('BAF-BOU-001', 'BEEF-PATTY-4OZ', 28.00, 20.00, 50.00, '2026-04-10T09:00:00'),
        ('BAF-BOU-001', 'BURGER-BUN', 18.00, 16.00, 45.00, '2026-04-10T09:00:00'),
        ('BAF-BOU-001', 'CUP-FOUNTAIN-20', 14.00, 10.00, 25.00, '2026-04-10T09:00:00'),
        ('BAF-DEN-001', 'FRIES-SHOESTRING', 24.00, 28.00, 55.00, '2026-04-10T09:15:00'),
        ('BAF-DEN-001', 'CHEDDAR-SLICES', 9.00, 10.00, 24.00, '2026-04-10T09:15:00'),
        ('BAF-DEN-001', 'KETCHUP-PACKET', 11.00, 8.00, 20.00, '2026-04-10T09:15:00'),
        ('BAF-COS-001', 'LETTUCE-SHRED', 7.00, 8.00, 18.00, '2026-04-10T09:30:00'),
        ('BAF-COS-001', 'CARTON-FRY-SM', 16.00, 10.00, 28.00, '2026-04-10T09:30:00')
) AS Seed (LocationCode, ProductSKU, QuantityOnHand, ReorderPoint, TargetStockLevel, LastUpdatedText)
INNER JOIN dbo.Location AS L
    ON L.LocationCode = Seed.LocationCode
INNER JOIN dbo.Product AS P
    ON P.ProductSKU = Seed.ProductSKU
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Inventory AS Existing
    WHERE Existing.LocationID = L.LocationID
      AND Existing.ProductID = P.ProductID
);

INSERT INTO dbo.InventoryRequest
(
    RequestingLocationID,
    FulfillingLocationID,
    RequestedByEmployeeID,
    RequestDate,
    NeededByDate,
    RequestStatus,
    IsEmergency,
    ApprovedByEmployeeID,
    ApprovedDate,
    Notes
)
SELECT
    Requesting.LocationID,
    Fulfilling.LocationID,
    RequestedBy.EmployeeID,
    CONVERT(DATETIME2, Seed.RequestDateText),
    CONVERT(DATE, Seed.NeededByDateText),
    Seed.RequestStatus,
    Seed.IsEmergency,
    ApprovedBy.EmployeeID,
    CASE
        WHEN Seed.ApprovedDateText IS NULL THEN NULL
        ELSE CONVERT(DATETIME2, Seed.ApprovedDateText)
    END,
    CONCAT('Sample request ', Seed.RequestCode)
FROM
(
    VALUES
        ('REQ-2026-001', 'BAF-BOU-001', 'BAF-BOU-SUB', 'riley.gomez@burgersandfries.test', '2026-04-02T09:00:00', '2026-04-04', 'Fulfilled', 0, 'jamie.chen@burgersandfries.test', '2026-04-02T10:15:00'),
        ('REQ-2026-002', 'BAF-DEN-001', 'BAF-DEN-SUB', 'casey.patel@burgersandfries.test', '2026-04-05T16:20:00', '2026-04-06', 'Submitted', 1, NULL, NULL),
        ('REQ-2026-003', 'BAF-DEN-SUB', 'BAF-DEN-MAIN', 'taylor.smith@burgersandfries.test', '2026-04-06T08:10:00', '2026-04-09', 'Approved', 0, 'alex.porter@burgersandfries.test', '2026-04-06T09:00:00'),
        ('REQ-2026-004', 'BAF-COS-001', 'BAF-COS-SUB', 'drew.nguyen@burgersandfries.test', '2026-04-07T12:30:00', '2026-04-08', 'Partially Fulfilled', 0, 'morgan.lee@burgersandfries.test', '2026-04-07T13:05:00')
) AS Seed (RequestCode, RequestingLocationCode, FulfillingLocationCode, RequestedByEmail, RequestDateText, NeededByDateText, RequestStatus, IsEmergency, ApprovedByEmail, ApprovedDateText)
INNER JOIN dbo.Location AS Requesting
    ON Requesting.LocationCode = Seed.RequestingLocationCode
INNER JOIN dbo.Location AS Fulfilling
    ON Fulfilling.LocationCode = Seed.FulfillingLocationCode
INNER JOIN dbo.Employee AS RequestedBy
    ON RequestedBy.Email = Seed.RequestedByEmail
LEFT JOIN dbo.Employee AS ApprovedBy
    ON ApprovedBy.Email = Seed.ApprovedByEmail
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.InventoryRequest AS Existing
    WHERE Existing.Notes = CONCAT('Sample request ', Seed.RequestCode)
);

INSERT INTO dbo.InventoryRequestLine
(
    RequestID,
    ProductID,
    QuantityRequested,
    QuantityApproved,
    QuantityFulfilled
)
SELECT
    R.RequestID,
    P.ProductID,
    Seed.QuantityRequested,
    Seed.QuantityApproved,
    Seed.QuantityFulfilled
FROM
(
    VALUES
        ('REQ-2026-001', 'BEEF-PATTY-4OZ', 20.00, 20.00, 20.00),
        ('REQ-2026-001', 'BURGER-BUN', 12.00, 12.00, 12.00),
        ('REQ-2026-001', 'CUP-FOUNTAIN-20', 10.00, 10.00, 10.00),
        ('REQ-2026-002', 'FRIES-SHOESTRING', 30.00, NULL, 0.00),
        ('REQ-2026-002', 'CHEDDAR-SLICES', 8.00, NULL, 0.00),
        ('REQ-2026-003', 'BEEF-PATTY-4OZ', 80.00, 75.00, 0.00),
        ('REQ-2026-003', 'FRY-OIL-BLEND', 24.00, 24.00, 0.00),
        ('REQ-2026-004', 'LETTUCE-SHRED', 10.00, 10.00, 6.00),
        ('REQ-2026-004', 'CARTON-FRY-SM', 12.00, 12.00, 12.00)
) AS Seed (RequestCode, ProductSKU, QuantityRequested, QuantityApproved, QuantityFulfilled)
INNER JOIN dbo.InventoryRequest AS R
    ON R.Notes = CONCAT('Sample request ', Seed.RequestCode)
INNER JOIN dbo.Product AS P
    ON P.ProductSKU = Seed.ProductSKU
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.InventoryRequestLine AS Existing
    WHERE Existing.RequestID = R.RequestID
      AND Existing.ProductID = P.ProductID
);

INSERT INTO dbo.Shipment
(
    RequestID,
    FromLocationID,
    ToLocationID,
    CreatedByEmployeeID,
    ShipmentStatus,
    CreatedAt,
    ScheduledShipDate,
    ShippedAt,
    ExpectedDeliveryDate,
    ReceivedAt,
    ReceivedByEmployeeID,
    TrackingReference,
    Notes
)
SELECT
    R.RequestID,
    FromLocation.LocationID,
    ToLocation.LocationID,
    CreatedBy.EmployeeID,
    Seed.ShipmentStatus,
    CONVERT(DATETIME2, Seed.CreatedAtText),
    CONVERT(DATE, Seed.ScheduledShipDateText),
    CASE
        WHEN Seed.ShippedAtText IS NULL THEN NULL
        ELSE CONVERT(DATETIME2, Seed.ShippedAtText)
    END,
    CONVERT(DATE, Seed.ExpectedDeliveryDateText),
    CASE
        WHEN Seed.ReceivedAtText IS NULL THEN NULL
        ELSE CONVERT(DATETIME2, Seed.ReceivedAtText)
    END,
    ReceivedBy.EmployeeID,
    Seed.TrackingReference,
    CONCAT('Sample shipment ', Seed.ShipmentCode)
FROM
(
    VALUES
        ('SHIP-2026-001', 'REQ-2026-001', 'BAF-BOU-SUB', 'BAF-BOU-001', 'jamie.chen@burgersandfries.test', 'Delivered', '2026-04-03T08:00:00', '2026-04-03', '2026-04-03T09:15:00', '2026-04-03', '2026-04-03T12:20:00', 'riley.gomez@burgersandfries.test', 'BFR-TRK-1001'),
        ('SHIP-2026-002', 'REQ-2026-003', 'BAF-DEN-MAIN', 'BAF-DEN-SUB', 'morgan.lee@burgersandfries.test', 'In Transit', '2026-04-07T07:45:00', '2026-04-08', '2026-04-08T06:30:00', '2026-04-09', NULL, NULL, 'BFR-TRK-1002'),
        ('SHIP-2026-003', 'REQ-2026-004', 'BAF-COS-SUB', 'BAF-COS-001', 'morgan.lee@burgersandfries.test', 'Delivered', '2026-04-07T14:00:00', '2026-04-07', '2026-04-07T15:00:00', '2026-04-08', '2026-04-08T09:30:00', 'drew.nguyen@burgersandfries.test', 'BFR-TRK-1003')
) AS Seed (ShipmentCode, RequestCode, FromLocationCode, ToLocationCode, CreatedByEmail, ShipmentStatus, CreatedAtText, ScheduledShipDateText, ShippedAtText, ExpectedDeliveryDateText, ReceivedAtText, ReceivedByEmail, TrackingReference)
LEFT JOIN dbo.InventoryRequest AS R
    ON R.Notes = CONCAT('Sample request ', Seed.RequestCode)
INNER JOIN dbo.Location AS FromLocation
    ON FromLocation.LocationCode = Seed.FromLocationCode
INNER JOIN dbo.Location AS ToLocation
    ON ToLocation.LocationCode = Seed.ToLocationCode
INNER JOIN dbo.Employee AS CreatedBy
    ON CreatedBy.Email = Seed.CreatedByEmail
LEFT JOIN dbo.Employee AS ReceivedBy
    ON ReceivedBy.Email = Seed.ReceivedByEmail
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Shipment AS Existing
    WHERE Existing.TrackingReference = Seed.TrackingReference
);

INSERT INTO dbo.ShipmentLine
(
    ShipmentID,
    ProductID,
    QuantityShipped,
    QuantityReceived,
    UnitCostAtShipment
)
SELECT
    S.ShipmentID,
    P.ProductID,
    Seed.QuantityShipped,
    Seed.QuantityReceived,
    Seed.UnitCostAtShipment
FROM
(
    VALUES
        ('BFR-TRK-1001', 'BEEF-PATTY-4OZ', 20.00, 20.00, 54.00),
        ('BFR-TRK-1001', 'BURGER-BUN', 12.00, 12.00, 14.25),
        ('BFR-TRK-1001', 'CUP-FOUNTAIN-20', 10.00, 10.00, 22.10),
        ('BFR-TRK-1002', 'BEEF-PATTY-4OZ', 75.00, NULL, 54.00),
        ('BFR-TRK-1002', 'FRY-OIL-BLEND', 24.00, NULL, 12.40),
        ('BFR-TRK-1003', 'LETTUCE-SHRED', 6.00, 6.00, 7.80),
        ('BFR-TRK-1003', 'CARTON-FRY-SM', 12.00, 12.00, 19.40)
) AS Seed (TrackingReference, ProductSKU, QuantityShipped, QuantityReceived, UnitCostAtShipment)
INNER JOIN dbo.Shipment AS S
    ON S.TrackingReference = Seed.TrackingReference
INNER JOIN dbo.Product AS P
    ON P.ProductSKU = Seed.ProductSKU
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.ShipmentLine AS Existing
    WHERE Existing.ShipmentID = S.ShipmentID
      AND Existing.ProductID = P.ProductID
);

COMMIT TRANSACTION;
GO
