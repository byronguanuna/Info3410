/*
    Warehouse support for the canonical star schema.

    Full build order:
      1. database/00_create_database.sql
      2. database/01_create_transactional_schema.sql
      3. database/02_seed_required_lookups.sql
      4. Schema/schema.sql
      5. database/03_create_warehouse_support.sql
      6. Functions/functions.sql
      7. Triggers/triggers.sql

    Execute dbo.usp_Snapshot_All after the full build order is complete.

    Schema/schema.sql owns the star table definitions. This script only adds
    the aliases needed by Triggers/triggers.sql, rebuilds the aggregate table
    so Functions/functions.sql can still read PascalCase names, and creates the
    snapshot stored procedures that load the star schema from the transactional
    database.
*/

USE BurgersAndFries;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dbo.Dim_Location', N'U') IS NULL
    RAISERROR('Run Schema/schema.sql before database/03_create_warehouse_support.sql. Missing dbo.Dim_Location.', 16, 1);

IF OBJECT_ID(N'dbo.Dim_Product', N'U') IS NULL
    RAISERROR('Run Schema/schema.sql before database/03_create_warehouse_support.sql. Missing dbo.Dim_Product.', 16, 1);

IF OBJECT_ID(N'dbo.Dim_User', N'U') IS NULL
    RAISERROR('Run Schema/schema.sql before database/03_create_warehouse_support.sql. Missing dbo.Dim_User.', 16, 1);

IF OBJECT_ID(N'dbo.Dim_Date', N'U') IS NULL
    RAISERROR('Run Schema/schema.sql before database/03_create_warehouse_support.sql. Missing dbo.Dim_Date.', 16, 1);

IF OBJECT_ID(N'dbo.Fact_Inventory_Movement', N'U') IS NULL
    RAISERROR('Run Schema/schema.sql before database/03_create_warehouse_support.sql. Missing dbo.Fact_Inventory_Movement.', 16, 1);
GO

DROP TRIGGER IF EXISTS dbo.trg_FactInventory_Update;
DROP TRIGGER IF EXISTS dbo.trg_FactInventory_Delete;
DROP TRIGGER IF EXISTS dbo.trg_FactInventory_Insert;
GO

IF COL_LENGTH(N'dbo.Fact_Inventory_Movement', N'location_id') IS NULL
BEGIN
    ALTER TABLE dbo.Fact_Inventory_Movement
        ADD location_id AS LocationID PERSISTED;
END;
GO

IF COL_LENGTH(N'dbo.Fact_Inventory_Movement', N'product_id') IS NULL
BEGIN
    ALTER TABLE dbo.Fact_Inventory_Movement
        ADD product_id AS ProductID PERSISTED;
END;
GO

BEGIN TRANSACTION;

DROP TABLE IF EXISTS dbo.Aggregate_Inventory_Summary;

CREATE TABLE dbo.Aggregate_Inventory_Summary
(
    SummaryID INT IDENTITY(1,1) NOT NULL,
    location_id INT NOT NULL,
    product_id INT NOT NULL,
    total_quantity INT NULL,
    total_cost DECIMAL(12,2) NULL,
    transaction_count INT NULL,
    LocationID INT NULL,
    ProductID INT NULL,
    TotalQuantity INT NULL,
    TotalCost DECIMAL(12,2) NULL,
    TransactionCount INT NULL,

    CONSTRAINT PK_Aggregate_Inventory_Summary PRIMARY KEY (SummaryID),
    CONSTRAINT FK_Aggregate_Location FOREIGN KEY (location_id)
        REFERENCES dbo.Dim_Location (LocationID),
    CONSTRAINT FK_Aggregate_Product FOREIGN KEY (product_id)
        REFERENCES dbo.Dim_Product (ProductID)
);

CREATE INDEX IX_Aggregate_InventorySummary_LocationProduct
    ON dbo.Aggregate_Inventory_Summary (location_id, product_id);

COMMIT TRANSACTION;
GO

CREATE OR ALTER TRIGGER dbo.trg_AggregateInventory_SyncPascalCase
ON dbo.Aggregate_Inventory_Summary
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE A
    SET
        A.LocationID = A.location_id,
        A.ProductID = A.product_id,
        A.TotalQuantity = A.total_quantity,
        A.TotalCost = A.total_cost,
        A.TransactionCount = A.transaction_count
    FROM dbo.Aggregate_Inventory_Summary AS A
    INNER JOIN inserted AS I
        ON I.SummaryID = A.SummaryID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Snapshot_Dimensions
    @SnapshotDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @SnapshotDate IS NULL
    BEGIN
        SET @SnapshotDate = CONVERT(DATE, SYSUTCDATETIME());
    END;

    DECLARE @DateID INT = CONVERT(INT, CONVERT(CHAR(8), @SnapshotDate, 112));

    UPDATE DL
    SET
        DL.LocationName = LEFT(L.LocationName, 50),
        DL.LocationType = LEFT(LT.LocationTypeName, 20),
        DL.ContactInfo = LEFT(L.Phone, 15),
        DL.ParentLocationID = L.ParentLocationID
    FROM dbo.Dim_Location AS DL
    INNER JOIN dbo.Location AS L
        ON L.LocationID = DL.LocationID
    INNER JOIN dbo.LocationType AS LT
        ON LT.LocationTypeID = L.LocationTypeID;

    INSERT INTO dbo.Dim_Location
    (
        LocationID,
        LocationName,
        LocationType,
        ContactInfo,
        ParentLocationID
    )
    SELECT
        L.LocationID,
        LEFT(L.LocationName, 50),
        LEFT(LT.LocationTypeName, 20),
        LEFT(L.Phone, 15),
        L.ParentLocationID
    FROM dbo.Location AS L
    INNER JOIN dbo.LocationType AS LT
        ON LT.LocationTypeID = L.LocationTypeID
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.Dim_Location AS Existing
        WHERE Existing.LocationID = L.LocationID
    );

    UPDATE DP
    SET
        DP.ProductName = LEFT(P.ProductName, 50),
        DP.ProductCategory = LEFT(PC.CategoryName, 30)
    FROM dbo.Dim_Product AS DP
    INNER JOIN dbo.Product AS P
        ON P.ProductID = DP.ProductID
    INNER JOIN dbo.ProductCategory AS PC
        ON PC.ProductCategoryID = P.ProductCategoryID;

    INSERT INTO dbo.Dim_Product
    (
        ProductID,
        ProductName,
        ProductCategory
    )
    SELECT
        P.ProductID,
        LEFT(P.ProductName, 50),
        LEFT(PC.CategoryName, 30)
    FROM dbo.Product AS P
    INNER JOIN dbo.ProductCategory AS PC
        ON PC.ProductCategoryID = P.ProductCategoryID
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.Dim_Product AS Existing
        WHERE Existing.ProductID = P.ProductID
    );

    UPDATE DU
    SET DU.Username = LEFT(LOWER(CONCAT(E.FirstName, '.', E.LastName)), 50)
    FROM dbo.Dim_User AS DU
    INNER JOIN dbo.Employee AS E
        ON E.EmployeeID = DU.UserID;

    INSERT INTO dbo.Dim_User
    (
        UserID,
        Username
    )
    SELECT
        E.EmployeeID,
        LEFT(LOWER(CONCAT(E.FirstName, '.', E.LastName)), 50)
    FROM dbo.Employee AS E
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.Dim_User AS Existing
        WHERE Existing.UserID = E.EmployeeID
    );

    UPDATE dbo.Dim_Date
    SET
        FullDate = @SnapshotDate,
        DayNum = DAY(@SnapshotDate),
        MonthNum = MONTH(@SnapshotDate),
        YearNum = YEAR(@SnapshotDate)
    WHERE DateID = @DateID;

    INSERT INTO dbo.Dim_Date
    (
        DateID,
        FullDate,
        DayNum,
        MonthNum,
        YearNum
    )
    SELECT
        @DateID,
        @SnapshotDate,
        DAY(@SnapshotDate),
        MONTH(@SnapshotDate),
        YEAR(@SnapshotDate)
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.Dim_Date AS Existing
        WHERE Existing.DateID = @DateID
    );
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Snapshot_InventoryFact
    @SnapshotDate DATE = NULL,
    @SnapshotUserEmail VARCHAR(254) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @SnapshotDate IS NULL
    BEGIN
        SET @SnapshotDate = CONVERT(DATE, SYSUTCDATETIME());
    END;

    IF OBJECT_ID(N'dbo.ufn_GetLocationName', N'FN') IS NULL
    BEGIN
        RAISERROR('Run Functions/functions.sql before executing dbo.usp_Snapshot_InventoryFact.', 16, 1);
    END;

    IF OBJECT_ID(N'dbo.trg_FactInventory_Insert', N'TR') IS NULL
    BEGIN
        RAISERROR('Run Triggers/triggers.sql before executing dbo.usp_Snapshot_InventoryFact.', 16, 1);
    END;

    EXEC dbo.usp_Snapshot_Dimensions @SnapshotDate = @SnapshotDate;

    DECLARE @DateID INT = CONVERT(INT, CONVERT(CHAR(8), @SnapshotDate, 112));
    DECLARE @SnapshotUserID INT;

    SELECT @SnapshotUserID = E.EmployeeID
    FROM dbo.Employee AS E
    WHERE E.Email = @SnapshotUserEmail;

    IF @SnapshotUserID IS NULL
    BEGIN
        SELECT TOP (1) @SnapshotUserID = E.EmployeeID
        FROM dbo.Employee AS E
        INNER JOIN dbo.EmployeeRole AS ER
            ON ER.EmployeeRoleID = E.EmployeeRoleID
        WHERE ER.RoleName = 'Auditor'
        ORDER BY E.EmployeeID;
    END;

    IF @SnapshotUserID IS NULL
    BEGIN
        SELECT TOP (1) @SnapshotUserID = E.EmployeeID
        FROM dbo.Employee AS E
        ORDER BY E.EmployeeID;
    END;

    IF @SnapshotUserID IS NULL
    BEGIN
        RAISERROR('No employee exists to record the inventory snapshot.', 16, 1);
    END;

    DECLARE @FactLoadSql NVARCHAR(MAX) = N'
        SET ANSI_NULLS ON;
        SET QUOTED_IDENTIFIER ON;

        INSERT INTO dbo.Fact_Inventory_Movement
        (
            LocationID,
            ProductID,
            UserID,
            DateID,
            Quantity,
            TransactionType,
            Cost
        )
        SELECT
            I.LocationID,
            I.ProductID,
            @SnapshotUserID,
            @DateID,
            CASE
                WHEN I.QuantityOnHand > 0 AND I.QuantityOnHand < 1 THEN 1
                ELSE CAST(ROUND(I.QuantityOnHand, 0) AS INT)
            END,
            ''Snapshot'',
            CAST(ROUND(I.QuantityOnHand * COALESCE(P.StandardUnitCost, 0), 2) AS DECIMAL(10,2))
        FROM dbo.Inventory AS I
        INNER JOIN dbo.Product AS P
            ON P.ProductID = I.ProductID
        WHERE I.QuantityOnHand <> 0
          AND dbo.ufn_GetLocationName(I.LocationID) IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1
              FROM dbo.Fact_Inventory_Movement AS Existing
              WHERE Existing.LocationID = I.LocationID
                AND Existing.ProductID = I.ProductID
                AND Existing.UserID = @SnapshotUserID
                AND Existing.DateID = @DateID
                AND Existing.TransactionType = ''Snapshot''
          );';

    EXEC sys.sp_executesql
        @FactLoadSql,
        N'@SnapshotUserID INT, @DateID INT',
        @SnapshotUserID = @SnapshotUserID,
        @DateID = @DateID;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Snapshot_All
    @SnapshotDate DATE = NULL,
    @SnapshotUserEmail VARCHAR(254) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    EXEC dbo.usp_Snapshot_InventoryFact
        @SnapshotDate = @SnapshotDate,
        @SnapshotUserEmail = @SnapshotUserEmail;
END;
GO
