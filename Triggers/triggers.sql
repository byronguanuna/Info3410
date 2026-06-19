/*=========================================================
  Trigger: trg_FactInventory_Insert
  Purpose : Updates Aggregate table after new transactions
=========================================================*/
CREATE TRIGGER trg_FactInventory_Insert
ON Fact_Inventory_Movement
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Aggregate_Inventory_Summary
    (
        location_id,
        product_id,
        total_quantity,
        total_cost,
        transaction_count
    )
    SELECT
        i.location_id,
        i.product_id,
        SUM(i.quantity),
        SUM(i.cost),
        COUNT(*)
    FROM inserted i
    GROUP BY i.location_id, i.product_id;
END;
GO

/*=========================================================
  Trigger: trg_FactInventory_Delete
  Purpose : Adjusts Aggregate table when records are deleted
=========================================================*/
CREATE TRIGGER trg_FactInventory_Delete
ON Fact_Inventory_Movement
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DELETE a
    FROM Aggregate_Inventory_Summary a
    JOIN deleted d
        ON a.location_id = d.location_id
       AND a.product_id = d.product_id;
END;
GO

/*=========================================================
  Trigger: trg_FactInventory_Update
  Purpose : Maintains aggregate consistency after updates
=========================================================*/
CREATE TRIGGER trg_FactInventory_Update
ON Fact_Inventory_Movement
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Remove old values
    DELETE a
    FROM Aggregate_Inventory_Summary a
    JOIN deleted d
        ON a.location_id = d.location_id
       AND a.product_id = d.product_id;

    -- Recalculate with new values
    INSERT INTO Aggregate_Inventory_Summary
    (
        location_id,
        product_id,
        total_quantity,
        total_cost,
        transaction_count
    )
    SELECT
        i.location_id,
        i.product_id,
        SUM(i.quantity),
        SUM(i.cost),
        COUNT(*)
    FROM inserted i
    GROUP BY i.location_id, i.product_id;
END;
GO