USE BurgersAndFries;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @SnapshotDate DATE = '2026-04-10';
DECLARE @SnapshotDateID INT = CONVERT(INT, CONVERT(CHAR(8), @SnapshotDate, 112));
DECLARE @FailureCount INT;

IF OBJECT_ID(N'tempdb..#ValidationResults', N'U') IS NOT NULL
BEGIN
    DROP TABLE #ValidationResults;
END;

CREATE TABLE #ValidationResults
(
    ResultID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    CheckGroup VARCHAR(80) NOT NULL,
    CheckName VARCHAR(160) NOT NULL,
    ExpectedValue VARCHAR(120) NOT NULL,
    ActualValue VARCHAR(120) NOT NULL,
    Result VARCHAR(10) NOT NULL,
    Details VARCHAR(1000) NULL
);

PRINT '============================================================';
PRINT 'BURGERS AND FRIES DATABASE VALIDATION';
PRINT '============================================================';

SELECT
    DB_NAME() AS CurrentDatabase,
    @@SERVERNAME AS SqlServerInstance,
    SUSER_SNAME() AS CurrentLogin,
    SYSDATETIME() AS TestRunTime;

/* Expected project objects. */
WITH ExpectedObjects AS
(
    SELECT ObjectName, ObjectType, ObjectTypeDescription
    FROM (VALUES
        (N'LocationType', N'U', N'Table'),
        (N'Location', N'U', N'Table'),
        (N'ProductCategory', N'U', N'Table'),
        (N'UnitOfMeasure', N'U', N'Table'),
        (N'Product', N'U', N'Table'),
        (N'Inventory', N'U', N'Table'),
        (N'EmployeeRole', N'U', N'Table'),
        (N'Employee', N'U', N'Table'),
        (N'InventoryRequest', N'U', N'Table'),
        (N'InventoryRequestLine', N'U', N'Table'),
        (N'Shipment', N'U', N'Table'),
        (N'ShipmentLine', N'U', N'Table'),
        (N'Dim_Location', N'U', N'Table'),
        (N'Dim_Product', N'U', N'Table'),
        (N'Dim_User', N'U', N'Table'),
        (N'Dim_Date', N'U', N'Table'),
        (N'Fact_Inventory_Movement', N'U', N'Table'),
        (N'Aggregate_Inventory_Summary', N'U', N'Table'),
        (N'vw_CurrentInventory', N'V', N'View'),
        (N'vw_LowStockInventory', N'V', N'View'),
        (N'vw_OpenInventoryRequests', N'V', N'View'),
        (N'ufn_GetLocationName', N'FN', N'Function'),
        (N'ufn_GetProductName', N'FN', N'Function'),
        (N'ufn_GetUsername', N'FN', N'Function'),
        (N'ufn_GetFullDate', N'FN', N'Function'),
        (N'ufn_GetTotalProductQuantity', N'FN', N'Function'),
        (N'ufn_GetLocationInventoryCost', N'FN', N'Function'),
        (N'trg_FactInventory_Insert', N'TR', N'Trigger'),
        (N'trg_FactInventory_Delete', N'TR', N'Trigger'),
        (N'trg_FactInventory_Update', N'TR', N'Trigger'),
        (N'trg_AggregateInventory_SyncPascalCase', N'TR', N'Trigger'),
        (N'usp_Snapshot_Dimensions', N'P', N'Procedure'),
        (N'usp_Snapshot_InventoryFact', N'P', N'Procedure'),
        (N'usp_Snapshot_All', N'P', N'Procedure')
    ) AS V(ObjectName, ObjectType, ObjectTypeDescription)
)
INSERT INTO #ValidationResults
(
    CheckGroup,
    CheckName,
    ExpectedValue,
    ActualValue,
    Result,
    Details
)
SELECT
    'Object existence',
    CONVERT(VARCHAR(160), E.ObjectTypeDescription + ': ' + E.ObjectName),
    'Exists',
    CASE WHEN O.object_id IS NULL THEN 'Missing' ELSE 'Exists' END,
    CASE WHEN O.object_id IS NULL THEN 'Fail' ELSE 'Pass' END,
    NULL
FROM ExpectedObjects AS E
LEFT JOIN sys.objects AS O
    ON O.name = E.ObjectName
   AND O.type = E.ObjectType
   AND SCHEMA_NAME(O.schema_id) = N'dbo';

/* Expected columns used by the schema, functions, triggers, and snapshot procedures. */
WITH ExpectedColumns AS
(
    SELECT TableName, ColumnName, IsComputed
    FROM (VALUES
        (N'LocationType', N'LocationTypeID', 0),
        (N'LocationType', N'LocationTypeName', 0),
        (N'Location', N'LocationID', 0),
        (N'Location', N'LocationTypeID', 0),
        (N'Location', N'ParentLocationID', 0),
        (N'Location', N'LocationName', 0),
        (N'Location', N'LocationCode', 0),
        (N'Location', N'Phone', 0),
        (N'ProductCategory', N'ProductCategoryID', 0),
        (N'ProductCategory', N'CategoryName', 0),
        (N'Product', N'ProductID', 0),
        (N'Product', N'ProductSKU', 0),
        (N'Product', N'ProductName', 0),
        (N'Product', N'ProductCategoryID', 0),
        (N'Product', N'StandardUnitCost', 0),
        (N'Inventory', N'LocationID', 0),
        (N'Inventory', N'ProductID', 0),
        (N'Inventory', N'QuantityOnHand', 0),
        (N'EmployeeRole', N'EmployeeRoleID', 0),
        (N'EmployeeRole', N'RoleName', 0),
        (N'Employee', N'EmployeeID', 0),
        (N'Employee', N'EmployeeRoleID', 0),
        (N'Employee', N'FirstName', 0),
        (N'Employee', N'LastName', 0),
        (N'Employee', N'Email', 0),
        (N'Dim_Location', N'LocationID', 0),
        (N'Dim_Location', N'LocationName', 0),
        (N'Dim_Location', N'LocationType', 0),
        (N'Dim_Location', N'ContactInfo', 0),
        (N'Dim_Location', N'ParentLocationID', 0),
        (N'Dim_Product', N'ProductID', 0),
        (N'Dim_Product', N'ProductName', 0),
        (N'Dim_Product', N'ProductCategory', 0),
        (N'Dim_User', N'UserID', 0),
        (N'Dim_User', N'Username', 0),
        (N'Dim_Date', N'DateID', 0),
        (N'Dim_Date', N'FullDate', 0),
        (N'Dim_Date', N'DayNum', 0),
        (N'Dim_Date', N'MonthNum', 0),
        (N'Dim_Date', N'YearNum', 0),
        (N'Fact_Inventory_Movement', N'FactID', 0),
        (N'Fact_Inventory_Movement', N'LocationID', 0),
        (N'Fact_Inventory_Movement', N'ProductID', 0),
        (N'Fact_Inventory_Movement', N'UserID', 0),
        (N'Fact_Inventory_Movement', N'DateID', 0),
        (N'Fact_Inventory_Movement', N'Quantity', 0),
        (N'Fact_Inventory_Movement', N'TransactionType', 0),
        (N'Fact_Inventory_Movement', N'Cost', 0),
        (N'Fact_Inventory_Movement', N'location_id', 1),
        (N'Fact_Inventory_Movement', N'product_id', 1),
        (N'Aggregate_Inventory_Summary', N'SummaryID', 0),
        (N'Aggregate_Inventory_Summary', N'location_id', 0),
        (N'Aggregate_Inventory_Summary', N'product_id', 0),
        (N'Aggregate_Inventory_Summary', N'total_quantity', 0),
        (N'Aggregate_Inventory_Summary', N'total_cost', 0),
        (N'Aggregate_Inventory_Summary', N'transaction_count', 0),
        (N'Aggregate_Inventory_Summary', N'LocationID', 0),
        (N'Aggregate_Inventory_Summary', N'ProductID', 0),
        (N'Aggregate_Inventory_Summary', N'TotalQuantity', 0),
        (N'Aggregate_Inventory_Summary', N'TotalCost', 0),
        (N'Aggregate_Inventory_Summary', N'TransactionCount', 0)
    ) AS V(TableName, ColumnName, IsComputed)
)
INSERT INTO #ValidationResults
(
    CheckGroup,
    CheckName,
    ExpectedValue,
    ActualValue,
    Result,
    Details
)
SELECT
    'Column compatibility',
    CONVERT(VARCHAR(160), E.TableName + '.' + E.ColumnName),
    CASE WHEN E.IsComputed = 1 THEN 'Exists as computed column' ELSE 'Exists' END,
    CASE
        WHEN C.column_id IS NULL THEN 'Missing'
        WHEN E.IsComputed = 1 AND C.is_computed = 0 THEN 'Exists but not computed'
        ELSE 'Exists'
    END,
    CASE
        WHEN C.column_id IS NULL THEN 'Fail'
        WHEN E.IsComputed = 1 AND C.is_computed = 0 THEN 'Fail'
        ELSE 'Pass'
    END,
    NULL
FROM ExpectedColumns AS E
LEFT JOIN sys.tables AS T
    ON T.name = E.TableName
   AND SCHEMA_NAME(T.schema_id) = N'dbo'
LEFT JOIN sys.columns AS C
    ON C.object_id = T.object_id
   AND C.name = E.ColumnName;

/* Seed data row counts. */
WITH ExpectedCounts AS
(
    SELECT TableName, ExpectedCount
    FROM (VALUES
        (N'LocationType', 3),
        (N'UnitOfMeasure', 8),
        (N'ProductCategory', 6),
        (N'EmployeeRole', 5),
        (N'Location', 7),
        (N'Product', 12),
        (N'Employee', 8),
        (N'Inventory', 20),
        (N'InventoryRequest', 4),
        (N'InventoryRequestLine', 9),
        (N'Shipment', 3),
        (N'ShipmentLine', 7)
    ) AS V(TableName, ExpectedCount)
),
ActualCounts AS
(
    SELECT N'LocationType' AS TableName, COUNT(*) AS ActualCount FROM dbo.LocationType
    UNION ALL SELECT N'UnitOfMeasure', COUNT(*) FROM dbo.UnitOfMeasure
    UNION ALL SELECT N'ProductCategory', COUNT(*) FROM dbo.ProductCategory
    UNION ALL SELECT N'EmployeeRole', COUNT(*) FROM dbo.EmployeeRole
    UNION ALL SELECT N'Location', COUNT(*) FROM dbo.Location
    UNION ALL SELECT N'Product', COUNT(*) FROM dbo.Product
    UNION ALL SELECT N'Employee', COUNT(*) FROM dbo.Employee
    UNION ALL SELECT N'Inventory', COUNT(*) FROM dbo.Inventory
    UNION ALL SELECT N'InventoryRequest', COUNT(*) FROM dbo.InventoryRequest
    UNION ALL SELECT N'InventoryRequestLine', COUNT(*) FROM dbo.InventoryRequestLine
    UNION ALL SELECT N'Shipment', COUNT(*) FROM dbo.Shipment
    UNION ALL SELECT N'ShipmentLine', COUNT(*) FROM dbo.ShipmentLine
)
INSERT INTO #ValidationResults
(
    CheckGroup,
    CheckName,
    ExpectedValue,
    ActualValue,
    Result,
    Details
)
SELECT
    'Seed data',
    CONVERT(VARCHAR(160), E.TableName + ' row count'),
    CONVERT(VARCHAR(120), E.ExpectedCount),
    CONVERT(VARCHAR(120), A.ActualCount),
    CASE WHEN A.ActualCount = E.ExpectedCount THEN 'Pass' ELSE 'Fail' END,
    'Expected exact count after running database/01 and database/02 once.'
FROM ExpectedCounts AS E
INNER JOIN ActualCounts AS A
    ON A.TableName = E.TableName;

/* Execute the snapshot so the test is valid whether or not the user ran it manually first. */
BEGIN TRY
    EXEC sys.sp_executesql
        N'EXEC dbo.usp_Snapshot_All @SnapshotDate = @RunDate;',
        N'@RunDate DATE',
        @RunDate = @SnapshotDate;

    INSERT INTO #ValidationResults
    (
        CheckGroup,
        CheckName,
        ExpectedValue,
        ActualValue,
        Result,
        Details
    )
    VALUES
    (
        'Snapshot execution',
        'dbo.usp_Snapshot_All runs for sample date',
        'Completes without error',
        'Completed',
        'Pass',
        NULL
    );
END TRY
BEGIN CATCH
    INSERT INTO #ValidationResults
    (
        CheckGroup,
        CheckName,
        ExpectedValue,
        ActualValue,
        Result,
        Details
    )
    VALUES
    (
        'Snapshot execution',
        'dbo.usp_Snapshot_All runs for sample date',
        'Completes without error',
        'Error',
        'Fail',
        ERROR_MESSAGE()
    );
END CATCH;

/* Warehouse dimensions should mirror the transactional source tables. */
DECLARE @ExpectedInventoryRows INT =
(
    SELECT COUNT(*)
    FROM dbo.Inventory
    WHERE QuantityOnHand <> 0
);

DECLARE @LocationMismatchCount INT =
(
    SELECT COUNT(*)
    FROM dbo.Location AS L
    INNER JOIN dbo.LocationType AS LT
        ON LT.LocationTypeID = L.LocationTypeID
    FULL OUTER JOIN dbo.Dim_Location AS DL
        ON DL.LocationID = L.LocationID
    WHERE L.LocationID IS NULL
       OR DL.LocationID IS NULL
       OR DL.LocationName <> LEFT(L.LocationName, 50)
       OR DL.LocationType <> LEFT(LT.LocationTypeName, 20)
       OR ISNULL(DL.ContactInfo, '') <> ISNULL(LEFT(L.Phone, 15), '')
       OR ISNULL(DL.ParentLocationID, -1) <> ISNULL(L.ParentLocationID, -1)
);

INSERT INTO #ValidationResults
VALUES
(
    'Warehouse dimensions',
    'Dim_Location mirrors Location',
    '0 mismatches',
    CONVERT(VARCHAR(120), @LocationMismatchCount),
    CASE WHEN @LocationMismatchCount = 0 THEN 'Pass' ELSE 'Fail' END,
    NULL
);

DECLARE @ProductMismatchCount INT =
(
    SELECT COUNT(*)
    FROM dbo.Product AS P
    INNER JOIN dbo.ProductCategory AS PC
        ON PC.ProductCategoryID = P.ProductCategoryID
    FULL OUTER JOIN dbo.Dim_Product AS DP
        ON DP.ProductID = P.ProductID
    WHERE P.ProductID IS NULL
       OR DP.ProductID IS NULL
       OR DP.ProductName <> LEFT(P.ProductName, 50)
       OR DP.ProductCategory <> LEFT(PC.CategoryName, 30)
);

INSERT INTO #ValidationResults
VALUES
(
    'Warehouse dimensions',
    'Dim_Product mirrors Product',
    '0 mismatches',
    CONVERT(VARCHAR(120), @ProductMismatchCount),
    CASE WHEN @ProductMismatchCount = 0 THEN 'Pass' ELSE 'Fail' END,
    NULL
);

DECLARE @UserMismatchCount INT =
(
    SELECT COUNT(*)
    FROM dbo.Employee AS E
    FULL OUTER JOIN dbo.Dim_User AS DU
        ON DU.UserID = E.EmployeeID
    WHERE E.EmployeeID IS NULL
       OR DU.UserID IS NULL
       OR DU.Username <> LEFT(LOWER(CONCAT(E.FirstName, '.', E.LastName)), 50)
);

INSERT INTO #ValidationResults
VALUES
(
    'Warehouse dimensions',
    'Dim_User mirrors Employee',
    '0 mismatches',
    CONVERT(VARCHAR(120), @UserMismatchCount),
    CASE WHEN @UserMismatchCount = 0 THEN 'Pass' ELSE 'Fail' END,
    NULL
);

DECLARE @DateRowCount INT =
(
    SELECT COUNT(*)
    FROM dbo.Dim_Date
    WHERE DateID = @SnapshotDateID
      AND FullDate = @SnapshotDate
      AND DayNum = DAY(@SnapshotDate)
      AND MonthNum = MONTH(@SnapshotDate)
      AND YearNum = YEAR(@SnapshotDate)
);

INSERT INTO #ValidationResults
VALUES
(
    'Warehouse dimensions',
    'Dim_Date contains sample snapshot date',
    '1 matching row',
    CONVERT(VARCHAR(120), @DateRowCount),
    CASE WHEN @DateRowCount = 1 THEN 'Pass' ELSE 'Fail' END,
    NULL
);

/* Snapshot facts should match current inventory quantity and cost. */
DECLARE @SnapshotFactRows INT =
(
    SELECT COUNT(*)
    FROM dbo.Fact_Inventory_Movement
    WHERE DateID = @SnapshotDateID
      AND TransactionType = 'Snapshot'
);

INSERT INTO #ValidationResults
VALUES
(
    'Warehouse facts',
    'Snapshot fact row count for sample date',
    CONVERT(VARCHAR(120), @ExpectedInventoryRows),
    CONVERT(VARCHAR(120), @SnapshotFactRows),
    CASE WHEN @SnapshotFactRows = @ExpectedInventoryRows THEN 'Pass' ELSE 'Fail' END,
    NULL
);

DECLARE @SnapshotFactMismatchCount INT =
(
    SELECT COUNT(*)
    FROM
    (
        SELECT
            I.LocationID,
            I.ProductID,
            CASE
                WHEN I.QuantityOnHand > 0 AND I.QuantityOnHand < 1 THEN 1
                ELSE CAST(ROUND(I.QuantityOnHand, 0) AS INT)
            END AS Quantity,
            CAST(ROUND(I.QuantityOnHand * COALESCE(P.StandardUnitCost, 0), 2) AS DECIMAL(10,2)) AS Cost
        FROM dbo.Inventory AS I
        INNER JOIN dbo.Product AS P
            ON P.ProductID = I.ProductID
        WHERE I.QuantityOnHand <> 0

        EXCEPT

        SELECT
            F.LocationID,
            F.ProductID,
            F.Quantity,
            F.Cost
        FROM dbo.Fact_Inventory_Movement AS F
        WHERE F.DateID = @SnapshotDateID
          AND F.TransactionType = 'Snapshot'
    ) AS MissingOrDifferent
);

INSERT INTO #ValidationResults
VALUES
(
    'Warehouse facts',
    'Snapshot facts match Inventory rows',
    '0 missing or different rows',
    CONVERT(VARCHAR(120), @SnapshotFactMismatchCount),
    CASE WHEN @SnapshotFactMismatchCount = 0 THEN 'Pass' ELSE 'Fail' END,
    NULL
);

/* Aggregate rows should equal the facts when summed by location and product. */
DECLARE @AggregateMismatchCount INT =
(
    SELECT COUNT(*)
    FROM
    (
        SELECT
            Expected.LocationID,
            Expected.ProductID,
            Expected.TotalQuantity,
            Expected.TotalCost,
            Expected.TransactionCount
        FROM
        (
            SELECT
                F.LocationID,
                F.ProductID,
                SUM(F.Quantity) AS TotalQuantity,
                CAST(SUM(F.Cost) AS DECIMAL(12,2)) AS TotalCost,
                COUNT(*) AS TransactionCount
            FROM dbo.Fact_Inventory_Movement AS F
            GROUP BY F.LocationID, F.ProductID
        ) AS Expected

        EXCEPT

        SELECT
            Actual.LocationID,
            Actual.ProductID,
            Actual.TotalQuantity,
            Actual.TotalCost,
            Actual.TransactionCount
        FROM
        (
            SELECT
                A.location_id AS LocationID,
                A.product_id AS ProductID,
                SUM(A.total_quantity) AS TotalQuantity,
                CAST(SUM(A.total_cost) AS DECIMAL(12,2)) AS TotalCost,
                SUM(A.transaction_count) AS TransactionCount
            FROM dbo.Aggregate_Inventory_Summary AS A
            GROUP BY A.location_id, A.product_id
        ) AS Actual

        UNION ALL

        SELECT
            Actual.LocationID,
            Actual.ProductID,
            Actual.TotalQuantity,
            Actual.TotalCost,
            Actual.TransactionCount
        FROM
        (
            SELECT
                A.location_id AS LocationID,
                A.product_id AS ProductID,
                SUM(A.total_quantity) AS TotalQuantity,
                CAST(SUM(A.total_cost) AS DECIMAL(12,2)) AS TotalCost,
                SUM(A.transaction_count) AS TransactionCount
            FROM dbo.Aggregate_Inventory_Summary AS A
            GROUP BY A.location_id, A.product_id
        ) AS Actual

        EXCEPT

        SELECT
            Expected.LocationID,
            Expected.ProductID,
            Expected.TotalQuantity,
            Expected.TotalCost,
            Expected.TransactionCount
        FROM
        (
            SELECT
                F.LocationID,
                F.ProductID,
                SUM(F.Quantity) AS TotalQuantity,
                CAST(SUM(F.Cost) AS DECIMAL(12,2)) AS TotalCost,
                COUNT(*) AS TransactionCount
            FROM dbo.Fact_Inventory_Movement AS F
            GROUP BY F.LocationID, F.ProductID
        ) AS Expected
    ) AS AggregateDifferences
);

INSERT INTO #ValidationResults
VALUES
(
    'Warehouse aggregate',
    'Aggregate totals equal fact totals',
    '0 differences',
    CONVERT(VARCHAR(120), @AggregateMismatchCount),
    CASE WHEN @AggregateMismatchCount = 0 THEN 'Pass' ELSE 'Fail' END,
    NULL
);

DECLARE @AggregateCompatibilityMismatchCount INT =
(
    SELECT COUNT(*)
    FROM dbo.Aggregate_Inventory_Summary
    WHERE LocationID <> location_id
       OR ProductID <> product_id
       OR TotalQuantity <> total_quantity
       OR TotalCost <> total_cost
       OR TransactionCount <> transaction_count
       OR LocationID IS NULL
       OR ProductID IS NULL
       OR TotalQuantity IS NULL
       OR TotalCost IS NULL
       OR TransactionCount IS NULL
);

INSERT INTO #ValidationResults
VALUES
(
    'Warehouse aggregate',
    'Aggregate snake_case and PascalCase columns stay synced',
    '0 mismatches',
    CONVERT(VARCHAR(120), @AggregateCompatibilityMismatchCount),
    CASE WHEN @AggregateCompatibilityMismatchCount = 0 THEN 'Pass' ELSE 'Fail' END,
    NULL
);

/* Function checks against known dimension and aggregate data. */
DECLARE @SampleLocationID INT = (SELECT MIN(LocationID) FROM dbo.Dim_Location);
DECLARE @SampleProductID INT = (SELECT MIN(ProductID) FROM dbo.Dim_Product);
DECLARE @SampleUserID INT = (SELECT MIN(UserID) FROM dbo.Dim_User);

INSERT INTO #ValidationResults
SELECT
    'Functions',
    'ufn_GetLocationName returns Dim_Location.LocationName',
    DL.LocationName,
    dbo.ufn_GetLocationName(@SampleLocationID),
    CASE WHEN dbo.ufn_GetLocationName(@SampleLocationID) = DL.LocationName THEN 'Pass' ELSE 'Fail' END,
    NULL
FROM dbo.Dim_Location AS DL
WHERE DL.LocationID = @SampleLocationID;

INSERT INTO #ValidationResults
SELECT
    'Functions',
    'ufn_GetProductName returns Dim_Product.ProductName',
    DP.ProductName,
    dbo.ufn_GetProductName(@SampleProductID),
    CASE WHEN dbo.ufn_GetProductName(@SampleProductID) = DP.ProductName THEN 'Pass' ELSE 'Fail' END,
    NULL
FROM dbo.Dim_Product AS DP
WHERE DP.ProductID = @SampleProductID;

INSERT INTO #ValidationResults
SELECT
    'Functions',
    'ufn_GetUsername returns Dim_User.Username',
    DU.Username,
    dbo.ufn_GetUsername(@SampleUserID),
    CASE WHEN dbo.ufn_GetUsername(@SampleUserID) = DU.Username THEN 'Pass' ELSE 'Fail' END,
    NULL
FROM dbo.Dim_User AS DU
WHERE DU.UserID = @SampleUserID;

INSERT INTO #ValidationResults
SELECT
    'Functions',
    'ufn_GetFullDate returns Dim_Date.FullDate',
    CONVERT(VARCHAR(120), DD.FullDate, 23),
    CONVERT(VARCHAR(120), dbo.ufn_GetFullDate(@SnapshotDateID), 23),
    CASE WHEN dbo.ufn_GetFullDate(@SnapshotDateID) = DD.FullDate THEN 'Pass' ELSE 'Fail' END,
    NULL
FROM dbo.Dim_Date AS DD
WHERE DD.DateID = @SnapshotDateID;

DECLARE @ExpectedProductQuantity INT =
(
    SELECT ISNULL(SUM(Quantity), 0)
    FROM dbo.Fact_Inventory_Movement
    WHERE ProductID = @SampleProductID
);

INSERT INTO #ValidationResults
VALUES
(
    'Functions',
    'ufn_GetTotalProductQuantity returns fact sum',
    CONVERT(VARCHAR(120), @ExpectedProductQuantity),
    CONVERT(VARCHAR(120), dbo.ufn_GetTotalProductQuantity(@SampleProductID)),
    CASE WHEN dbo.ufn_GetTotalProductQuantity(@SampleProductID) = @ExpectedProductQuantity THEN 'Pass' ELSE 'Fail' END,
    NULL
);

DECLARE @ExpectedLocationCost DECIMAL(12,2) =
(
    SELECT ISNULL(SUM(TotalCost), 0)
    FROM dbo.Aggregate_Inventory_Summary
    WHERE LocationID = @SampleLocationID
);

INSERT INTO #ValidationResults
VALUES
(
    'Functions',
    'ufn_GetLocationInventoryCost returns aggregate sum',
    CONVERT(VARCHAR(120), @ExpectedLocationCost),
    CONVERT(VARCHAR(120), dbo.ufn_GetLocationInventoryCost(@SampleLocationID)),
    CASE WHEN dbo.ufn_GetLocationInventoryCost(@SampleLocationID) = @ExpectedLocationCost THEN 'Pass' ELSE 'Fail' END,
    NULL
);

/* Trigger behavior is tested inside a transaction and rolled back. */
DECLARE @TriggerResult VARCHAR(10) = 'Pass';
DECLARE @TriggerDetails VARCHAR(1000) = NULL;
DECLARE @InsertAggregateMatches INT = 0;
DECLARE @UpdateAggregateMatches INT = 0;
DECLARE @DeleteAggregateMatches INT = 0;

BEGIN TRY
    DECLARE @TriggerTestLocationID INT = (SELECT MIN(LocationID) FROM dbo.Dim_Location);
    DECLARE @TriggerTestProductID INT = (SELECT MIN(ProductID) FROM dbo.Dim_Product);
    DECLARE @TriggerTestUserID INT = (SELECT MIN(UserID) FROM dbo.Dim_User);
    DECLARE @TriggerTestFactID INT;

    BEGIN TRANSACTION;

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
    VALUES
    (
        @TriggerTestLocationID,
        @TriggerTestProductID,
        @TriggerTestUserID,
        @SnapshotDateID,
        12345,
        'Trigger Test',
        987.65
    );

    SET @TriggerTestFactID = CONVERT(INT, SCOPE_IDENTITY());

    SELECT @InsertAggregateMatches = COUNT(*)
    FROM dbo.Aggregate_Inventory_Summary
    WHERE location_id = @TriggerTestLocationID
      AND product_id = @TriggerTestProductID
      AND total_quantity = 12345
      AND total_cost = 987.65
      AND transaction_count = 1
      AND LocationID = location_id
      AND ProductID = product_id
      AND TotalQuantity = total_quantity
      AND TotalCost = total_cost
      AND TransactionCount = transaction_count;

    UPDATE dbo.Fact_Inventory_Movement
    SET
        Quantity = 23456,
        Cost = 1234.56
    WHERE FactID = @TriggerTestFactID;

    SELECT @UpdateAggregateMatches = COUNT(*)
    FROM dbo.Aggregate_Inventory_Summary
    WHERE location_id = @TriggerTestLocationID
      AND product_id = @TriggerTestProductID
      AND total_quantity = 23456
      AND total_cost = 1234.56
      AND transaction_count = 1
      AND LocationID = location_id
      AND ProductID = product_id
      AND TotalQuantity = total_quantity
      AND TotalCost = total_cost
      AND TransactionCount = transaction_count;

    DELETE FROM dbo.Fact_Inventory_Movement
    WHERE FactID = @TriggerTestFactID;

    SELECT @DeleteAggregateMatches = COUNT(*)
    FROM dbo.Aggregate_Inventory_Summary
    WHERE location_id = @TriggerTestLocationID
      AND product_id = @TriggerTestProductID
      AND total_quantity = 23456
      AND total_cost = 1234.56
      AND transaction_count = 1;

    ROLLBACK TRANSACTION;

    IF @InsertAggregateMatches <> 1
       OR @UpdateAggregateMatches <> 1
       OR @DeleteAggregateMatches <> 0
    BEGIN
        SET @TriggerResult = 'Fail';
        SET @TriggerDetails = CONCAT(
            'Insert matches: ', @InsertAggregateMatches,
            '; update matches: ', @UpdateAggregateMatches,
            '; delete matches after delete: ', @DeleteAggregateMatches
        );
    END;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    SET @TriggerResult = 'Fail';
    SET @TriggerDetails = ERROR_MESSAGE();
END CATCH;

INSERT INTO #ValidationResults
VALUES
(
    'Triggers',
    'Fact triggers maintain Aggregate_Inventory_Summary',
    'Insert/update/delete trigger behavior works inside rollback transaction',
    CASE WHEN @TriggerResult = 'Pass' THEN 'Worked' ELSE 'Failed' END,
    @TriggerResult,
    @TriggerDetails
);

/* Constraint and dependency checks. */
DECLARE @BadConstraintCount INT =
(
    SELECT COUNT(*)
    FROM
    (
        SELECT name
        FROM sys.foreign_keys
        WHERE is_disabled = 1
           OR is_not_trusted = 1

        UNION ALL

        SELECT name
        FROM sys.check_constraints
        WHERE is_disabled = 1
           OR is_not_trusted = 1
    ) AS BadConstraints
);

INSERT INTO #ValidationResults
VALUES
(
    'Constraints',
    'No disabled or untrusted FK/check constraints',
    '0 bad constraints',
    CONVERT(VARCHAR(120), @BadConstraintCount),
    CASE WHEN @BadConstraintCount = 0 THEN 'Pass' ELSE 'Fail' END,
    NULL
);

DECLARE @DisabledTriggerCount INT =
(
    SELECT COUNT(*)
    FROM sys.triggers
    WHERE is_disabled = 1
      AND name IN
      (
          N'trg_FactInventory_Insert',
          N'trg_FactInventory_Delete',
          N'trg_FactInventory_Update',
          N'trg_AggregateInventory_SyncPascalCase'
      )
);

INSERT INTO #ValidationResults
VALUES
(
    'Triggers',
    'Expected triggers are enabled',
    '0 disabled triggers',
    CONVERT(VARCHAR(120), @DisabledTriggerCount),
    CASE WHEN @DisabledTriggerCount = 0 THEN 'Pass' ELSE 'Fail' END,
    NULL
);

DECLARE @UnexpectedDependencyCount INT =
(
    SELECT COUNT(*)
    FROM sys.sql_expression_dependencies AS D
    INNER JOIN sys.objects AS O
        ON O.object_id = D.referencing_id
    WHERE D.referenced_id IS NULL
      AND D.referenced_database_name IS NULL
      AND D.referenced_server_name IS NULL
      AND ISNULL(D.referenced_entity_name, N'') NOT IN (N'inserted', N'deleted')
      AND O.is_ms_shipped = 0
);

INSERT INTO #ValidationResults
VALUES
(
    'Dependencies',
    'No unresolved SQL references except trigger pseudo tables',
    '0 unexpected unresolved references',
    CONVERT(VARCHAR(120), @UnexpectedDependencyCount),
    CASE WHEN @UnexpectedDependencyCount = 0 THEN 'Pass' ELSE 'Fail' END,
    NULL
);

PRINT '============================================================';
PRINT 'VALIDATION RESULTS';
PRINT '============================================================';

SELECT
    CheckGroup,
    CheckName,
    ExpectedValue,
    ActualValue,
    Result,
    Details
FROM #ValidationResults
ORDER BY
    CASE WHEN Result = 'Fail' THEN 0 ELSE 1 END,
    CheckGroup,
    CheckName;

SELECT @FailureCount = COUNT(*)
FROM #ValidationResults
WHERE Result <> 'Pass';

IF @FailureCount > 0
BEGIN
    PRINT '============================================================';
    PRINT 'VALIDATION FAILED';
    PRINT '============================================================';

    SELECT
        CheckGroup,
        CheckName,
        ExpectedValue,
        ActualValue,
        Details
    FROM #ValidationResults
    WHERE Result <> 'Pass'
    ORDER BY CheckGroup, CheckName;

    THROW 51000, 'BurgersAndFries validation failed. Review failed rows above.', 1;
END;

PRINT '============================================================';
PRINT 'VALIDATION COMPLETE: all checks passed.';
PRINT '============================================================';
GO