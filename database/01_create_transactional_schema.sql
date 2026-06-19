/*
    Burgers & Fries Supply System
    Transactional database foundation for INFO 3410
    Microsoft SQL Server / T-SQL

    Clean-build warning:
    This script drops this project's views, procedures, functions, triggers,
    warehouse tables, and transactional tables. It recreates only the
    transactional schema. Run Schema/schema.sql afterward to create the
    canonical star schema.
*/

USE BurgersAndFries;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DROP VIEW IF EXISTS dbo.vw_OpenInventoryRequests;
DROP VIEW IF EXISTS dbo.vw_LowStockInventory;
DROP VIEW IF EXISTS dbo.vw_CurrentInventory;

DROP PROCEDURE IF EXISTS dbo.usp_Snapshot_All;
DROP PROCEDURE IF EXISTS dbo.usp_Snapshot_InventoryFact;
DROP PROCEDURE IF EXISTS dbo.usp_Snapshot_Dimensions;

DROP FUNCTION IF EXISTS dbo.ufn_GetLocationInventoryCost;
DROP FUNCTION IF EXISTS dbo.ufn_GetTotalProductQuantity;
DROP FUNCTION IF EXISTS dbo.ufn_GetFullDate;
DROP FUNCTION IF EXISTS dbo.ufn_GetUsername;
DROP FUNCTION IF EXISTS dbo.ufn_GetProductName;
DROP FUNCTION IF EXISTS dbo.ufn_GetLocationName;

DROP TRIGGER IF EXISTS dbo.trg_FactInventory_Update;
DROP TRIGGER IF EXISTS dbo.trg_FactInventory_Delete;
DROP TRIGGER IF EXISTS dbo.trg_FactInventory_Insert;

BEGIN TRANSACTION;

/* Drop warehouse tables created by Schema/schema.sql in reverse dependency order. */
DROP TABLE IF EXISTS dbo.Aggregate_Inventory_Summary;
DROP TABLE IF EXISTS dbo.Fact_Inventory_Movement;
DROP TABLE IF EXISTS dbo.Dim_Date;
DROP TABLE IF EXISTS dbo.Dim_User;
DROP TABLE IF EXISTS dbo.Dim_Product;
DROP TABLE IF EXISTS dbo.Dim_Location;

/* Drop transactional tables in reverse dependency order. */
DROP TABLE IF EXISTS dbo.ShipmentLine;
DROP TABLE IF EXISTS dbo.Shipment;
DROP TABLE IF EXISTS dbo.InventoryRequestLine;
DROP TABLE IF EXISTS dbo.InventoryRequest;
DROP TABLE IF EXISTS dbo.Employee;
DROP TABLE IF EXISTS dbo.EmployeeRole;
DROP TABLE IF EXISTS dbo.Inventory;
DROP TABLE IF EXISTS dbo.Product;
DROP TABLE IF EXISTS dbo.UnitOfMeasure;
DROP TABLE IF EXISTS dbo.ProductCategory;
DROP TABLE IF EXISTS dbo.Location;
DROP TABLE IF EXISTS dbo.LocationType;

/* Locations */
CREATE TABLE dbo.LocationType
(
    LocationTypeID INT IDENTITY(1,1) NOT NULL,
    LocationTypeName VARCHAR(50) NOT NULL,
    Description VARCHAR(250) NULL,
    IsActive BIT NOT NULL
        CONSTRAINT DF_LocationType_IsActive DEFAULT (1),

    CONSTRAINT PK_LocationType PRIMARY KEY (LocationTypeID),
    CONSTRAINT UQ_LocationType_LocationTypeName UNIQUE (LocationTypeName)
);

CREATE TABLE dbo.Location
(
    LocationID INT IDENTITY(1,1) NOT NULL,
    LocationTypeID INT NOT NULL,
    ParentLocationID INT NULL,
    LocationCode VARCHAR(30) NOT NULL,
    LocationName VARCHAR(100) NOT NULL,
    AddressLine1 VARCHAR(150) NOT NULL,
    AddressLine2 VARCHAR(150) NULL,
    City VARCHAR(100) NOT NULL,
    StateCode CHAR(2) NOT NULL,
    PostalCode VARCHAR(10) NOT NULL,
    Phone VARCHAR(25) NULL,
    Email VARCHAR(254) NULL,
    IsActive BIT NOT NULL
        CONSTRAINT DF_Location_IsActive DEFAULT (1),
    CreatedAt DATETIME2 NOT NULL
        CONSTRAINT DF_Location_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_Location PRIMARY KEY (LocationID),
    CONSTRAINT UQ_Location_LocationCode UNIQUE (LocationCode),
    CONSTRAINT FK_Location_LocationType FOREIGN KEY (LocationTypeID)
        REFERENCES dbo.LocationType (LocationTypeID),
    CONSTRAINT FK_Location_ParentLocation FOREIGN KEY (ParentLocationID)
        REFERENCES dbo.Location (LocationID),
    CONSTRAINT CK_Location_ParentNotSelf CHECK
        (ParentLocationID IS NULL OR ParentLocationID <> LocationID)
);

/* Products */
CREATE TABLE dbo.ProductCategory
(
    ProductCategoryID INT IDENTITY(1,1) NOT NULL,
    CategoryName VARCHAR(75) NOT NULL,
    CategoryGroup VARCHAR(25) NOT NULL,
    IsActive BIT NOT NULL
        CONSTRAINT DF_ProductCategory_IsActive DEFAULT (1),

    CONSTRAINT PK_ProductCategory PRIMARY KEY (ProductCategoryID),
    CONSTRAINT UQ_ProductCategory_CategoryName UNIQUE (CategoryName),
    CONSTRAINT CK_ProductCategory_CategoryGroup CHECK
        (CategoryGroup IN ('Food', 'Beverage', 'Packaging', 'Cleaning', 'Uniform', 'Other'))
);

CREATE TABLE dbo.UnitOfMeasure
(
    UnitOfMeasureID INT IDENTITY(1,1) NOT NULL,
    UnitName VARCHAR(50) NOT NULL,
    Abbreviation VARCHAR(15) NOT NULL,

    CONSTRAINT PK_UnitOfMeasure PRIMARY KEY (UnitOfMeasureID),
    CONSTRAINT UQ_UnitOfMeasure_UnitName UNIQUE (UnitName),
    CONSTRAINT UQ_UnitOfMeasure_Abbreviation UNIQUE (Abbreviation)
);

CREATE TABLE dbo.Product
(
    ProductID INT IDENTITY(1,1) NOT NULL,
    ProductSKU VARCHAR(40) NOT NULL,
    ProductName VARCHAR(100) NOT NULL,
    ProductCategoryID INT NOT NULL,
    UnitOfMeasureID INT NOT NULL,
    Description VARCHAR(500) NULL,
    StorageType VARCHAR(20) NOT NULL
        CONSTRAINT DF_Product_StorageType DEFAULT ('Ambient'),
    IsPerishable BIT NOT NULL
        CONSTRAINT DF_Product_IsPerishable DEFAULT (0),
    StandardUnitCost DECIMAL(12,2) NULL,
    IsActive BIT NOT NULL
        CONSTRAINT DF_Product_IsActive DEFAULT (1),
    CreatedAt DATETIME2 NOT NULL
        CONSTRAINT DF_Product_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_Product PRIMARY KEY (ProductID),
    CONSTRAINT UQ_Product_ProductSKU UNIQUE (ProductSKU),
    CONSTRAINT FK_Product_ProductCategory FOREIGN KEY (ProductCategoryID)
        REFERENCES dbo.ProductCategory (ProductCategoryID),
    CONSTRAINT FK_Product_UnitOfMeasure FOREIGN KEY (UnitOfMeasureID)
        REFERENCES dbo.UnitOfMeasure (UnitOfMeasureID),
    CONSTRAINT CK_Product_StorageType CHECK
        (StorageType IN ('Ambient', 'Refrigerated', 'Frozen')),
    CONSTRAINT CK_Product_StandardUnitCost CHECK
        (StandardUnitCost IS NULL OR StandardUnitCost >= 0)
);

/* Current inventory */
CREATE TABLE dbo.Inventory
(
    LocationID INT NOT NULL,
    ProductID INT NOT NULL,
    QuantityOnHand DECIMAL(12,2) NOT NULL
        CONSTRAINT DF_Inventory_QuantityOnHand DEFAULT (0),
    ReorderPoint DECIMAL(12,2) NOT NULL
        CONSTRAINT DF_Inventory_ReorderPoint DEFAULT (0),
    TargetStockLevel DECIMAL(12,2) NOT NULL
        CONSTRAINT DF_Inventory_TargetStockLevel DEFAULT (0),
    LastUpdated DATETIME2 NOT NULL
        CONSTRAINT DF_Inventory_LastUpdated DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_Inventory PRIMARY KEY (LocationID, ProductID),
    CONSTRAINT FK_Inventory_Location FOREIGN KEY (LocationID)
        REFERENCES dbo.Location (LocationID),
    CONSTRAINT FK_Inventory_Product FOREIGN KEY (ProductID)
        REFERENCES dbo.Product (ProductID),
    CONSTRAINT CK_Inventory_QuantityOnHand CHECK (QuantityOnHand >= 0),
    CONSTRAINT CK_Inventory_ReorderPoint CHECK (ReorderPoint >= 0),
    CONSTRAINT CK_Inventory_TargetStockLevel CHECK (TargetStockLevel >= 0),
    CONSTRAINT CK_Inventory_TargetAtLeastReorder CHECK (TargetStockLevel >= ReorderPoint)
);

/* Employees */
CREATE TABLE dbo.EmployeeRole
(
    EmployeeRoleID INT IDENTITY(1,1) NOT NULL,
    RoleName VARCHAR(50) NOT NULL,
    Description VARCHAR(250) NULL,
    IsActive BIT NOT NULL
        CONSTRAINT DF_EmployeeRole_IsActive DEFAULT (1),

    CONSTRAINT PK_EmployeeRole PRIMARY KEY (EmployeeRoleID),
    CONSTRAINT UQ_EmployeeRole_RoleName UNIQUE (RoleName)
);

CREATE TABLE dbo.Employee
(
    EmployeeID INT IDENTITY(1,1) NOT NULL,
    EmployeeRoleID INT NOT NULL,
    LocationID INT NULL,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(254) NULL,
    Phone VARCHAR(25) NULL,
    IsActive BIT NOT NULL
        CONSTRAINT DF_Employee_IsActive DEFAULT (1),
    CreatedAt DATETIME2 NOT NULL
        CONSTRAINT DF_Employee_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_Employee PRIMARY KEY (EmployeeID),
    CONSTRAINT FK_Employee_EmployeeRole FOREIGN KEY (EmployeeRoleID)
        REFERENCES dbo.EmployeeRole (EmployeeRoleID),
    CONSTRAINT FK_Employee_Location FOREIGN KEY (LocationID)
        REFERENCES dbo.Location (LocationID)
);

CREATE UNIQUE INDEX UX_Employee_Email
    ON dbo.Employee (Email)
    WHERE Email IS NOT NULL;

/* Inventory requests */
CREATE TABLE dbo.InventoryRequest
(
    RequestID INT IDENTITY(1,1) NOT NULL,
    RequestingLocationID INT NOT NULL,
    FulfillingLocationID INT NOT NULL,
    RequestedByEmployeeID INT NOT NULL,
    RequestDate DATETIME2 NOT NULL
        CONSTRAINT DF_InventoryRequest_RequestDate DEFAULT (SYSUTCDATETIME()),
    NeededByDate DATE NULL,
    RequestStatus VARCHAR(25) NOT NULL
        CONSTRAINT DF_InventoryRequest_RequestStatus DEFAULT ('Draft'),
    IsEmergency BIT NOT NULL
        CONSTRAINT DF_InventoryRequest_IsEmergency DEFAULT (0),
    ApprovedByEmployeeID INT NULL,
    ApprovedDate DATETIME2 NULL,
    Notes VARCHAR(1000) NULL,

    CONSTRAINT PK_InventoryRequest PRIMARY KEY (RequestID),
    CONSTRAINT FK_InventoryRequest_RequestingLocation FOREIGN KEY (RequestingLocationID)
        REFERENCES dbo.Location (LocationID),
    CONSTRAINT FK_InventoryRequest_FulfillingLocation FOREIGN KEY (FulfillingLocationID)
        REFERENCES dbo.Location (LocationID),
    CONSTRAINT FK_InventoryRequest_RequestedByEmployee FOREIGN KEY (RequestedByEmployeeID)
        REFERENCES dbo.Employee (EmployeeID),
    CONSTRAINT FK_InventoryRequest_ApprovedByEmployee FOREIGN KEY (ApprovedByEmployeeID)
        REFERENCES dbo.Employee (EmployeeID),
    CONSTRAINT CK_InventoryRequest_DifferentLocations CHECK
        (RequestingLocationID <> FulfillingLocationID),
    CONSTRAINT CK_InventoryRequest_NeededByDate CHECK
        (NeededByDate IS NULL OR NeededByDate >= CAST(RequestDate AS DATE)),
    CONSTRAINT CK_InventoryRequest_RequestStatus CHECK
        (RequestStatus IN ('Draft', 'Submitted', 'Approved', 'Partially Fulfilled', 'Fulfilled', 'Cancelled'))
);

CREATE TABLE dbo.InventoryRequestLine
(
    RequestLineID INT IDENTITY(1,1) NOT NULL,
    RequestID INT NOT NULL,
    ProductID INT NOT NULL,
    QuantityRequested DECIMAL(12,2) NOT NULL,
    QuantityApproved DECIMAL(12,2) NULL,
    QuantityFulfilled DECIMAL(12,2) NOT NULL
        CONSTRAINT DF_InventoryRequestLine_QuantityFulfilled DEFAULT (0),

    CONSTRAINT PK_InventoryRequestLine PRIMARY KEY (RequestLineID),
    CONSTRAINT UQ_InventoryRequestLine_Request_Product UNIQUE (RequestID, ProductID),
    CONSTRAINT FK_InventoryRequestLine_InventoryRequest FOREIGN KEY (RequestID)
        REFERENCES dbo.InventoryRequest (RequestID),
    CONSTRAINT FK_InventoryRequestLine_Product FOREIGN KEY (ProductID)
        REFERENCES dbo.Product (ProductID),
    CONSTRAINT CK_InventoryRequestLine_QuantityRequested CHECK (QuantityRequested > 0),
    CONSTRAINT CK_InventoryRequestLine_QuantityApproved CHECK
        (QuantityApproved IS NULL OR QuantityApproved >= 0),
    CONSTRAINT CK_InventoryRequestLine_ApprovedNotOverRequested CHECK
        (QuantityApproved IS NULL OR QuantityApproved <= QuantityRequested),
    CONSTRAINT CK_InventoryRequestLine_QuantityFulfilled CHECK (QuantityFulfilled >= 0),
    CONSTRAINT CK_InventoryRequestLine_FulfilledNotOverRequested CHECK
        (QuantityFulfilled <= QuantityRequested),
    CONSTRAINT CK_InventoryRequestLine_FulfilledNotOverApproved CHECK
        (QuantityApproved IS NULL OR QuantityFulfilled <= QuantityApproved)
);

/* Shipments */
CREATE TABLE dbo.Shipment
(
    ShipmentID INT IDENTITY(1,1) NOT NULL,
    RequestID INT NULL,
    FromLocationID INT NOT NULL,
    ToLocationID INT NOT NULL,
    CreatedByEmployeeID INT NOT NULL,
    ShipmentStatus VARCHAR(20) NOT NULL
        CONSTRAINT DF_Shipment_ShipmentStatus DEFAULT ('Preparing'),
    CreatedAt DATETIME2 NOT NULL
        CONSTRAINT DF_Shipment_CreatedAt DEFAULT (SYSUTCDATETIME()),
    ScheduledShipDate DATE NULL,
    ShippedAt DATETIME2 NULL,
    ExpectedDeliveryDate DATE NULL,
    ReceivedAt DATETIME2 NULL,
    ReceivedByEmployeeID INT NULL,
    TrackingReference VARCHAR(100) NULL,
    Notes VARCHAR(1000) NULL,

    CONSTRAINT PK_Shipment PRIMARY KEY (ShipmentID),
    CONSTRAINT FK_Shipment_InventoryRequest FOREIGN KEY (RequestID)
        REFERENCES dbo.InventoryRequest (RequestID),
    CONSTRAINT FK_Shipment_FromLocation FOREIGN KEY (FromLocationID)
        REFERENCES dbo.Location (LocationID),
    CONSTRAINT FK_Shipment_ToLocation FOREIGN KEY (ToLocationID)
        REFERENCES dbo.Location (LocationID),
    CONSTRAINT FK_Shipment_CreatedByEmployee FOREIGN KEY (CreatedByEmployeeID)
        REFERENCES dbo.Employee (EmployeeID),
    CONSTRAINT FK_Shipment_ReceivedByEmployee FOREIGN KEY (ReceivedByEmployeeID)
        REFERENCES dbo.Employee (EmployeeID),
    CONSTRAINT CK_Shipment_DifferentLocations CHECK
        (FromLocationID <> ToLocationID),
    CONSTRAINT CK_Shipment_ShipmentStatus CHECK
        (ShipmentStatus IN ('Preparing', 'In Transit', 'Delivered', 'Cancelled')),
    CONSTRAINT CK_Shipment_ExpectedDeliveryDate CHECK
        (ExpectedDeliveryDate IS NULL OR ScheduledShipDate IS NULL
         OR ExpectedDeliveryDate >= ScheduledShipDate),
    CONSTRAINT CK_Shipment_ReceivedAt CHECK
        (ReceivedAt IS NULL OR ShippedAt IS NULL OR ReceivedAt >= ShippedAt)
);

CREATE TABLE dbo.ShipmentLine
(
    ShipmentLineID INT IDENTITY(1,1) NOT NULL,
    ShipmentID INT NOT NULL,
    ProductID INT NOT NULL,
    QuantityShipped DECIMAL(12,2) NOT NULL,
    QuantityReceived DECIMAL(12,2) NULL,
    UnitCostAtShipment DECIMAL(12,2) NULL,

    CONSTRAINT PK_ShipmentLine PRIMARY KEY (ShipmentLineID),
    CONSTRAINT UQ_ShipmentLine_Shipment_Product UNIQUE (ShipmentID, ProductID),
    CONSTRAINT FK_ShipmentLine_Shipment FOREIGN KEY (ShipmentID)
        REFERENCES dbo.Shipment (ShipmentID),
    CONSTRAINT FK_ShipmentLine_Product FOREIGN KEY (ProductID)
        REFERENCES dbo.Product (ProductID),
    CONSTRAINT CK_ShipmentLine_QuantityShipped CHECK (QuantityShipped > 0),
    CONSTRAINT CK_ShipmentLine_QuantityReceived CHECK
        (QuantityReceived IS NULL OR QuantityReceived >= 0),
    CONSTRAINT CK_ShipmentLine_ReceivedNotOverShipped CHECK
        (QuantityReceived IS NULL OR QuantityReceived <= QuantityShipped),
    CONSTRAINT CK_ShipmentLine_UnitCostAtShipment CHECK
        (UnitCostAtShipment IS NULL OR UnitCostAtShipment >= 0)
);

CREATE INDEX IX_Inventory_ProductID
    ON dbo.Inventory (ProductID);

CREATE INDEX IX_InventoryRequest_RequestStatus
    ON dbo.InventoryRequest (RequestStatus);

CREATE INDEX IX_Shipment_ShipmentStatus
    ON dbo.Shipment (ShipmentStatus);

COMMIT TRANSACTION;
GO

CREATE VIEW dbo.vw_CurrentInventory
AS
SELECT
    L.LocationCode,
    L.LocationName,
    LT.LocationTypeName,
    P.ProductSKU,
    P.ProductName,
    PC.CategoryName,
    I.QuantityOnHand,
    U.UnitName,
    I.ReorderPoint,
    I.TargetStockLevel,
    I.LastUpdated
FROM dbo.Inventory AS I
INNER JOIN dbo.Location AS L
    ON L.LocationID = I.LocationID
INNER JOIN dbo.LocationType AS LT
    ON LT.LocationTypeID = L.LocationTypeID
INNER JOIN dbo.Product AS P
    ON P.ProductID = I.ProductID
INNER JOIN dbo.ProductCategory AS PC
    ON PC.ProductCategoryID = P.ProductCategoryID
INNER JOIN dbo.UnitOfMeasure AS U
    ON U.UnitOfMeasureID = P.UnitOfMeasureID;
GO

CREATE VIEW dbo.vw_LowStockInventory
AS
SELECT
    L.LocationCode,
    L.LocationName,
    LT.LocationTypeName,
    P.ProductSKU,
    P.ProductName,
    PC.CategoryName,
    I.QuantityOnHand,
    U.UnitName,
    I.ReorderPoint,
    I.TargetStockLevel,
    I.LastUpdated
FROM dbo.Inventory AS I
INNER JOIN dbo.Location AS L
    ON L.LocationID = I.LocationID
INNER JOIN dbo.LocationType AS LT
    ON LT.LocationTypeID = L.LocationTypeID
INNER JOIN dbo.Product AS P
    ON P.ProductID = I.ProductID
INNER JOIN dbo.ProductCategory AS PC
    ON PC.ProductCategoryID = P.ProductCategoryID
INNER JOIN dbo.UnitOfMeasure AS U
    ON U.UnitOfMeasureID = P.UnitOfMeasureID
WHERE I.QuantityOnHand <= I.ReorderPoint;
GO

CREATE VIEW dbo.vw_OpenInventoryRequests
AS
SELECT
    R.RequestID,
    Requesting.LocationName AS RequestingLocation,
    Fulfilling.LocationName AS FulfillingLocation,
    CONCAT(E.FirstName, ' ', E.LastName) AS RequestedByEmployee,
    R.RequestDate,
    R.NeededByDate,
    R.RequestStatus,
    R.IsEmergency,
    COUNT(RL.RequestLineID) AS NumberOfLines,
    COALESCE(SUM(RL.QuantityRequested), 0) AS TotalQuantityRequested,
    COALESCE(SUM(RL.QuantityApproved), 0) AS TotalQuantityApproved,
    COALESCE(SUM(RL.QuantityFulfilled), 0) AS TotalQuantityFulfilled
FROM dbo.InventoryRequest AS R
INNER JOIN dbo.Location AS Requesting
    ON Requesting.LocationID = R.RequestingLocationID
INNER JOIN dbo.Location AS Fulfilling
    ON Fulfilling.LocationID = R.FulfillingLocationID
INNER JOIN dbo.Employee AS E
    ON E.EmployeeID = R.RequestedByEmployeeID
LEFT JOIN dbo.InventoryRequestLine AS RL
    ON RL.RequestID = R.RequestID
WHERE R.RequestStatus NOT IN ('Fulfilled', 'Cancelled')
GROUP BY
    R.RequestID,
    Requesting.LocationName,
    Fulfilling.LocationName,
    E.FirstName,
    E.LastName,
    R.RequestDate,
    R.NeededByDate,
    R.RequestStatus,
    R.IsEmergency;
GO
