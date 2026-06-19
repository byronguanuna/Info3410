USE BurgersAndFries;
GO

SET NOCOUNT ON;
GO

PRINT '============================================================';
PRINT 'DATABASE CHECK';
PRINT '============================================================';

SELECT
    DB_NAME() AS CurrentDatabase,
    @@SERVERNAME AS SqlServerInstance,
    SUSER_SNAME() AS CurrentLogin,
    SYSDATETIME() AS TestRunTime;
GO

PRINT '============================================================';
PRINT 'MISSING EXPECTED TABLES';
PRINT 'Expected result: zero rows.';
PRINT '============================================================';

WITH ExpectedTables AS
(
    SELECT TableName
    FROM (VALUES
        (N'LocationType'),
        (N'Location'),
        (N'ProductCategory'),
        (N'UnitOfMeasure'),
        (N'Product'),
        (N'Inventory'),
        (N'EmployeeRole'),
        (N'Employee'),
        (N'InventoryRequest'),
        (N'InventoryRequestLine'),
        (N'Shipment'),
        (N'ShipmentLine'),
        (N'Dim_Location'),
        (N'Dim_Product'),
        (N'Dim_User'),
        (N'Dim_Date'),
        (N'Fact_Inventory_Movement'),
        (N'Aggregate_Inventory_Summary')
    ) AS V(TableName)
)
SELECT E.TableName AS MissingTable
FROM ExpectedTables AS E
LEFT JOIN sys.tables AS T
    ON T.name = E.TableName
   AND SCHEMA_NAME(T.schema_id) = N'dbo'
WHERE T.object_id IS NULL
ORDER BY E.TableName;
GO

PRINT '============================================================';
PRINT 'MISSING EXPECTED VIEWS';
PRINT 'Expected result: zero rows.';
PRINT '============================================================';

WITH ExpectedViews AS
(
    SELECT ViewName
    FROM (VALUES
        (N'vw_CurrentInventory'),
        (N'vw_LowStockInventory'),
        (N'vw_OpenInventoryRequests')
    ) AS V(ViewName)
)
SELECT E.ViewName AS MissingView
FROM ExpectedViews AS E
LEFT JOIN sys.views AS V
    ON V.name = E.ViewName
   AND SCHEMA_NAME(V.schema_id) = N'dbo'
WHERE V.object_id IS NULL
ORDER BY E.ViewName;
GO

PRINT '============================================================';
PRINT 'MISSING EXPECTED FUNCTIONS';
PRINT 'Expected result: zero rows.';
PRINT '============================================================';

WITH ExpectedFunctions AS
(
    SELECT FunctionName
    FROM (VALUES
        (N'ufn_GetLocationName'),
        (N'ufn_GetProductName'),
        (N'ufn_GetUsername'),
        (N'ufn_GetFullDate'),
        (N'ufn_GetTotalProductQuantity'),
        (N'ufn_GetLocationInventoryCost')
    ) AS V(FunctionName)
)
SELECT E.FunctionName AS MissingFunction
FROM ExpectedFunctions AS E
LEFT JOIN sys.objects AS O
    ON O.name = E.FunctionName
   AND SCHEMA_NAME(O.schema_id) = N'dbo'
   AND O.type IN (N'FN', N'IF', N'TF')
WHERE O.object_id IS NULL
ORDER BY E.FunctionName;
GO

PRINT '============================================================';
PRINT 'MISSING EXPECTED TRIGGERS';
PRINT 'Expected result: zero rows.';
PRINT '============================================================';

WITH ExpectedTriggers AS
(
    SELECT TriggerName
    FROM (VALUES
        (N'trg_FactInventory_Insert'),
        (N'trg_FactInventory_Delete'),
        (N'trg_FactInventory_Update'),
        (N'trg_AggregateInventory_SyncPascalCase')
    ) AS V(TriggerName)
)
SELECT E.TriggerName AS MissingTrigger
FROM ExpectedTriggers AS E
LEFT JOIN sys.triggers AS T
    ON T.name = E.TriggerName
WHERE T.object_id IS NULL
ORDER BY E.TriggerName;
GO

PRINT '============================================================';
PRINT 'MISSING EXPECTED PROCEDURES';
PRINT 'Expected result: zero rows.';
PRINT '============================================================';

WITH ExpectedProcedures AS
(
    SELECT ProcedureName
    FROM (VALUES
        (N'usp_Snapshot_Dimensions'),
        (N'usp_Snapshot_InventoryFact'),
        (N'usp_Snapshot_All')
    ) AS V(ProcedureName)
)
SELECT E.ProcedureName AS MissingProcedure
FROM ExpectedProcedures AS E
LEFT JOIN sys.procedures AS P
    ON P.name = E.ProcedureName
   AND SCHEMA_NAME(P.schema_id) = N'dbo'
WHERE P.object_id IS NULL
ORDER BY E.ProcedureName;
GO

PRINT '============================================================';
PRINT 'MISSING EXPECTED WAREHOUSE COMPATIBILITY COLUMNS';
PRINT 'Expected result: zero rows.';
PRINT '============================================================';

WITH ExpectedColumns AS
(
    SELECT TableName, ColumnName
    FROM (VALUES
        (N'Fact_Inventory_Movement', N'LocationID'),
        (N'Fact_Inventory_Movement', N'ProductID'),
        (N'Fact_Inventory_Movement', N'UserID'),
        (N'Fact_Inventory_Movement', N'DateID'),
        (N'Fact_Inventory_Movement', N'Quantity'),
        (N'Fact_Inventory_Movement', N'TransactionType'),
        (N'Fact_Inventory_Movement', N'Cost'),
        (N'Fact_Inventory_Movement', N'location_id'),
        (N'Fact_Inventory_Movement', N'product_id'),
        (N'Aggregate_Inventory_Summary', N'location_id'),
        (N'Aggregate_Inventory_Summary', N'product_id'),
        (N'Aggregate_Inventory_Summary', N'total_quantity'),
        (N'Aggregate_Inventory_Summary', N'total_cost'),
        (N'Aggregate_Inventory_Summary', N'transaction_count'),
        (N'Aggregate_Inventory_Summary', N'LocationID'),
        (N'Aggregate_Inventory_Summary', N'ProductID'),
        (N'Aggregate_Inventory_Summary', N'TotalQuantity'),
        (N'Aggregate_Inventory_Summary', N'TotalCost'),
        (N'Aggregate_Inventory_Summary', N'TransactionCount')
    ) AS V(TableName, ColumnName)
)
SELECT
    E.TableName,
    E.ColumnName AS MissingColumn
FROM ExpectedColumns AS E
LEFT JOIN sys.tables AS T
    ON T.name = E.TableName
   AND SCHEMA_NAME(T.schema_id) = N'dbo'
LEFT JOIN sys.columns AS C
    ON C.object_id = T.object_id
   AND C.name = E.ColumnName
WHERE C.column_id IS NULL
ORDER BY E.TableName, E.ColumnName;
GO

PRINT '============================================================';
PRINT 'LOOKUP AND SAMPLE COUNTS';
PRINT 'Expected counts assume sql/02_seed_required_lookups.sql has run once or more.';
PRINT '============================================================';

WITH ExpectedCounts AS
(
    SELECT TableName, ExpectedMinimum
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
    ) AS V(TableName, ExpectedMinimum)
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
SELECT
    E.TableName,
    E.ExpectedMinimum,
    A.ActualCount,
    CASE WHEN A.ActualCount >= E.ExpectedMinimum THEN 'Pass' ELSE 'Review' END AS Result
FROM ExpectedCounts AS E
INNER JOIN ActualCounts AS A
    ON A.TableName = E.TableName
ORDER BY E.TableName;
GO

PRINT '============================================================';
PRINT 'WAREHOUSE SNAPSHOT COUNTS';
PRINT 'Expected after EXEC dbo.usp_Snapshot_All: all rows should be Pass.';
PRINT '============================================================';

WITH ExpectedCounts AS
(
    SELECT TableName, ExpectedMinimum
    FROM (VALUES
        (N'Dim_Location', 7),
        (N'Dim_Product', 12),
        (N'Dim_User', 8),
        (N'Dim_Date', 1),
        (N'Fact_Inventory_Movement', 20),
        (N'Aggregate_Inventory_Summary', 20)
    ) AS V(TableName, ExpectedMinimum)
),
ActualCounts AS
(
    SELECT N'Dim_Location' AS TableName, COUNT(*) AS ActualCount FROM dbo.Dim_Location
    UNION ALL SELECT N'Dim_Product', COUNT(*) FROM dbo.Dim_Product
    UNION ALL SELECT N'Dim_User', COUNT(*) FROM dbo.Dim_User
    UNION ALL SELECT N'Dim_Date', COUNT(*) FROM dbo.Dim_Date
    UNION ALL SELECT N'Fact_Inventory_Movement', COUNT(*) FROM dbo.Fact_Inventory_Movement
    UNION ALL SELECT N'Aggregate_Inventory_Summary', COUNT(*) FROM dbo.Aggregate_Inventory_Summary
)
SELECT
    E.TableName,
    E.ExpectedMinimum,
    A.ActualCount,
    CASE WHEN A.ActualCount >= E.ExpectedMinimum THEN 'Pass' ELSE 'Review' END AS Result
FROM ExpectedCounts AS E
INNER JOIN ActualCounts AS A
    ON A.TableName = E.TableName
ORDER BY E.TableName;
GO

PRINT '============================================================';
PRINT 'AGGREGATE COMPATIBILITY COLUMN SYNC CHECK';
PRINT 'Expected result: zero rows.';
PRINT '============================================================';

SELECT
    SummaryID,
    location_id,
    LocationID,
    product_id,
    ProductID,
    total_quantity,
    TotalQuantity,
    total_cost,
    TotalCost,
    transaction_count,
    TransactionCount
FROM dbo.Aggregate_Inventory_Summary
WHERE LocationID <> location_id
   OR ProductID <> product_id
   OR TotalQuantity <> total_quantity
   OR TotalCost <> total_cost
   OR TransactionCount <> transaction_count
   OR LocationID IS NULL
   OR ProductID IS NULL;
GO
PRINT '============================================================';
PRINT 'DISABLED OR UNTRUSTED CONSTRAINTS';
PRINT 'Expected result: zero rows.';
PRINT '============================================================';

SELECT
    'FOREIGN KEY' AS ConstraintType,
    OBJECT_SCHEMA_NAME(parent_object_id) AS SchemaName,
    OBJECT_NAME(parent_object_id) AS TableName,
    name AS ConstraintName,
    is_disabled AS IsDisabled,
    is_not_trusted AS IsNotTrusted
FROM sys.foreign_keys
WHERE is_disabled = 1
   OR is_not_trusted = 1

UNION ALL

SELECT
    'CHECK' AS ConstraintType,
    OBJECT_SCHEMA_NAME(parent_object_id) AS SchemaName,
    OBJECT_NAME(parent_object_id) AS TableName,
    name AS ConstraintName,
    is_disabled AS IsDisabled,
    is_not_trusted AS IsNotTrusted
FROM sys.check_constraints
WHERE is_disabled = 1
   OR is_not_trusted = 1
ORDER BY ConstraintType, SchemaName, TableName, ConstraintName;
GO

PRINT 'VALIDATION COMPLETE';
GO
