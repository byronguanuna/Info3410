/*
    Burgers & Fries transactional database foundation
    Microsoft SQL Server / T-SQL

    This clean-build script drops and recreates only this project's
    transactional tables. Run it in a local project database.
*/

USE BurgersAndFries;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

/* Drop tables in reverse dependency order for repeatable development builds. */
DROP TABLE IF EXISTS dbo.InventoryMovement;
DROP TABLE IF EXISTS dbo.ShipmentLine;
DROP TABLE IF EXISTS dbo.Shipment;
DROP TABLE IF EXISTS dbo.InventoryRequestLine;
DROP TABLE IF EXISTS dbo.InventoryRequest;
DROP TABLE IF EXISTS dbo.UserLocationAccess;
DROP TABLE IF EXISTS dbo.Inventory;
DROP TABLE IF EXISTS dbo.Product;
DROP TABLE IF EXISTS dbo.InventoryMovementType;
DROP TABLE IF EXISTS dbo.AppUser;
DROP TABLE IF EXISTS dbo.AppRole;
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

/* Current inventory balances */
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

/* Authorized users */
CREATE TABLE dbo.AppRole
(
    RoleID INT IDENTITY(1,1) NOT NULL,
    RoleName VARCHAR(50) NOT NULL,
    Description VARCHAR(250) NULL,
    IsActive BIT NOT NULL
        CONSTRAINT DF_AppRole_IsActive DEFAULT (1),

    CONSTRAINT PK_AppRole PRIMARY KEY (RoleID),
    CONSTRAINT UQ_AppRole_RoleName UNIQUE (RoleName)
);

CREATE TABLE dbo.AppUser
(
    UserID INT IDENTITY(1,1) NOT NULL,
    Username VARCHAR(75) NOT NULL,
    DisplayName VARCHAR(100) NOT NULL,
    Email VARCHAR(254) NULL,
    IsActive BIT NOT NULL
        CONSTRAINT DF_AppUser_IsActive DEFAULT (1),
    CreatedAt DATETIME2 NOT NULL
        CONSTRAINT DF_AppUser_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_AppUser PRIMARY KEY (UserID),
    CONSTRAINT UQ_AppUser_Username UNIQUE (Username)
);

CREATE UNIQUE INDEX UX_AppUser_Email
    ON dbo.AppUser (Email)
    WHERE Email IS NOT NULL;

CREATE TABLE dbo.UserLocationAccess
(
    UserID INT NOT NULL,
    LocationID INT NOT NULL,
    RoleID INT NOT NULL,
    GrantedAt DATETIME2 NOT NULL
        CONSTRAINT DF_UserLocationAccess_GrantedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_UserLocationAccess PRIMARY KEY (UserID, LocationID, RoleID),
    CONSTRAINT FK_UserLocationAccess_AppUser FOREIGN KEY (UserID)
        REFERENCES dbo.AppUser (UserID),
    CONSTRAINT FK_UserLocationAccess_Location FOREIGN KEY (LocationID)
        REFERENCES dbo.Location (LocationID),
    CONSTRAINT FK_UserLocationAccess_AppRole FOREIGN KEY (RoleID)
        REFERENCES dbo.AppRole (RoleID)
);

/* Inventory requests */
CREATE TABLE dbo.InventoryRequest
(
    RequestID INT IDENTITY(1,1) NOT NULL,
    RequestingLocationID INT NOT NULL,
    FulfillingLocationID INT NOT NULL,
    RequestedByUserID INT NOT NULL,
    RequestDate DATETIME2 NOT NULL
        CONSTRAINT DF_InventoryRequest_RequestDate DEFAULT (SYSUTCDATETIME()),
    NeededByDate DATE NULL,
    RequestStatus VARCHAR(25) NOT NULL
        CONSTRAINT DF_InventoryRequest_RequestStatus DEFAULT ('Draft'),
    IsEmergency BIT NOT NULL
        CONSTRAINT DF_InventoryRequest_IsEmergency DEFAULT (0),
    ApprovedByUserID INT NULL,
    ApprovedDate DATETIME2 NULL,
    Notes VARCHAR(1000) NULL,

    CONSTRAINT PK_InventoryRequest PRIMARY KEY (RequestID),
    CONSTRAINT FK_InventoryRequest_RequestingLocation FOREIGN KEY (RequestingLocationID)
        REFERENCES dbo.Location (LocationID),
    CONSTRAINT FK_InventoryRequest_FulfillingLocation FOREIGN KEY (FulfillingLocationID)
        REFERENCES dbo.Location (LocationID),
    CONSTRAINT FK_InventoryRequest_RequestedByUser FOREIGN KEY (RequestedByUserID)
        REFERENCES dbo.AppUser (UserID),
    CONSTRAINT FK_InventoryRequest_ApprovedByUser FOREIGN KEY (ApprovedByUserID)
        REFERENCES dbo.AppUser (UserID),
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
    CONSTRAINT CK_InventoryRequestLine_QuantityFulfilled CHECK (QuantityFulfilled >= 0),
    CONSTRAINT CK_InventoryRequestLine_ApprovedNotOverRequested CHECK
        (QuantityApproved IS NULL OR QuantityApproved <= QuantityRequested),
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
    CreatedByUserID INT NOT NULL,
    ShipmentStatus VARCHAR(20) NOT NULL
        CONSTRAINT DF_Shipment_ShipmentStatus DEFAULT ('Preparing'),
    IsEmergency BIT NOT NULL
        CONSTRAINT DF_Shipment_IsEmergency DEFAULT (0),
    CreatedAt DATETIME2 NOT NULL
        CONSTRAINT DF_Shipment_CreatedAt DEFAULT (SYSUTCDATETIME()),
    ScheduledShipDate DATE NULL,
    ShippedAt DATETIME2 NULL,
    ExpectedDeliveryDate DATE NULL,
    ReceivedAt DATETIME2 NULL,
    ReceivedByUserID INT NULL,
    TrackingReference VARCHAR(100) NULL,
    Notes VARCHAR(1000) NULL,

    CONSTRAINT PK_Shipment PRIMARY KEY (ShipmentID),
    CONSTRAINT FK_Shipment_InventoryRequest FOREIGN KEY (RequestID)
        REFERENCES dbo.InventoryRequest (RequestID),
    CONSTRAINT FK_Shipment_FromLocation FOREIGN KEY (FromLocationID)
        REFERENCES dbo.Location (LocationID),
    CONSTRAINT FK_Shipment_ToLocation FOREIGN KEY (ToLocationID)
        REFERENCES dbo.Location (LocationID),
    CONSTRAINT FK_Shipment_CreatedByUser FOREIGN KEY (CreatedByUserID)
        REFERENCES dbo.AppUser (UserID),
    CONSTRAINT FK_Shipment_ReceivedByUser FOREIGN KEY (ReceivedByUserID)
        REFERENCES dbo.AppUser (UserID),
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
    CONSTRAINT CK_ShipmentLine_UnitCostAtShipment CHECK
        (UnitCostAtShipment IS NULL OR UnitCostAtShipment >= 0),
    CONSTRAINT CK_ShipmentLine_ReceivedNotOverShipped CHECK
        (QuantityReceived IS NULL OR QuantityReceived <= QuantityShipped)
);

/* Historical inventory activity */
CREATE TABLE dbo.InventoryMovementType
(
    MovementTypeID INT IDENTITY(1,1) NOT NULL,
    MovementTypeName VARCHAR(50) NOT NULL,
    Description VARCHAR(250) NULL,
    IsActive BIT NOT NULL
        CONSTRAINT DF_InventoryMovementType_IsActive DEFAULT (1),

    CONSTRAINT PK_InventoryMovementType PRIMARY KEY (MovementTypeID),
    CONSTRAINT UQ_InventoryMovementType_MovementTypeName UNIQUE (MovementTypeName)
);

CREATE TABLE dbo.InventoryMovement
(
    MovementID INT IDENTITY(1,1) NOT NULL,
    MovementTypeID INT NOT NULL,
    MovementDate DATETIME2 NOT NULL,
    ProductID INT NOT NULL,
    FromLocationID INT NULL,
    ToLocationID INT NULL,
    Quantity DECIMAL(12,2) NOT NULL,
    UnitCost DECIMAL(12,2) NULL,
    ShipmentLineID INT NULL,
    PerformedByUserID INT NOT NULL,
    Notes VARCHAR(1000) NULL,
    CreatedAt DATETIME2 NOT NULL
        CONSTRAINT DF_InventoryMovement_CreatedAt DEFAULT (SYSUTCDATETIME()),

    CONSTRAINT PK_InventoryMovement PRIMARY KEY (MovementID),
    CONSTRAINT FK_InventoryMovement_MovementType FOREIGN KEY (MovementTypeID)
        REFERENCES dbo.InventoryMovementType (MovementTypeID),
    CONSTRAINT FK_InventoryMovement_Product FOREIGN KEY (ProductID)
        REFERENCES dbo.Product (ProductID),
    CONSTRAINT FK_InventoryMovement_FromLocation FOREIGN KEY (FromLocationID)
        REFERENCES dbo.Location (LocationID),
    CONSTRAINT FK_InventoryMovement_ToLocation FOREIGN KEY (ToLocationID)
        REFERENCES dbo.Location (LocationID),
    CONSTRAINT FK_InventoryMovement_ShipmentLine FOREIGN KEY (ShipmentLineID)
        REFERENCES dbo.ShipmentLine (ShipmentLineID),
    CONSTRAINT FK_InventoryMovement_PerformedByUser FOREIGN KEY (PerformedByUserID)
        REFERENCES dbo.AppUser (UserID),
    CONSTRAINT CK_InventoryMovement_Quantity CHECK (Quantity > 0),
    CONSTRAINT CK_InventoryMovement_UnitCost CHECK
        (UnitCost IS NULL OR UnitCost >= 0),
    CONSTRAINT CK_InventoryMovement_HasLocation CHECK
        (FromLocationID IS NOT NULL OR ToLocationID IS NOT NULL),
    CONSTRAINT CK_InventoryMovement_DifferentLocations CHECK
        (FromLocationID IS NULL OR ToLocationID IS NULL OR FromLocationID <> ToLocationID)
);

COMMIT TRANSACTION;

