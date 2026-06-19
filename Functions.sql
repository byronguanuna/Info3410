-----------------------------------------------------------
-- 1. Dim_Location Function
-----------------------------------------------------------
/*=========================================================
  Function: fn_GetLocationName
  Purpose : Returns the name of a location from location_id
=========================================================*/
CREATE FUNCTION dbo.fn_GetLocationName
(
    @location_id INT
)
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @location_name VARCHAR(50);

    SELECT @location_name = location_name
    FROM Dim_Location
    WHERE location_id = @location_id;

    RETURN @location_name;
END;
GO

-----------------------------------------------------------
-- 2. Dim_Product Function
-----------------------------------------------------------
/*=========================================================
  Function: fn_ProductDisplayName
  Purpose : Formats product name with category
=========================================================*/
CREATE FUNCTION dbo.fn_ProductDisplayName
(
    @product_name VARCHAR(50),
    @product_category VARCHAR(30)
)
RETURNS VARCHAR(100)
AS
BEGIN
    RETURN @product_category + ' - ' + @product_name;
END;
GO


-----------------------------------------------------------
-- 3. Dim_User Function
-----------------------------------------------------------
/*=========================================================
  Function: fn_FormatUsername
  Purpose : Standardizes username formatting (uppercase)
=========================================================*/
CREATE FUNCTION dbo.fn_FormatUsername
(
    @username VARCHAR(50)
)
RETURNS VARCHAR(50)
AS
BEGIN
    RETURN UPPER(@username);
END;
GO


-----------------------------------------------------------
-- 4. Dim_Date Function
-----------------------------------------------------------
/*=========================================================
  Function: fn_GetQuarter
  Purpose : Returns quarter (1–4) from a date
=========================================================*/
CREATE FUNCTION dbo.fn_GetQuarter
(
    @full_date DATE
)
RETURNS INT
AS
BEGIN
    RETURN DATEPART(QUARTER, @full_date);
END;
GO


-----------------------------------------------------------
-- 5. Fact_Inventory_Movement Function
-----------------------------------------------------------
/*=========================================================
  Function: fn_FactNetMovement
  Purpose : Converts IN/OUT transactions into net value
=========================================================*/
CREATE FUNCTION dbo.fn_FactNetMovement
(
    @quantity INT,
    @transaction_type VARCHAR(20)
)
RETURNS INT
AS
BEGIN
    RETURN 
        CASE 
            WHEN @transaction_type = 'IN' THEN @quantity
            WHEN @transaction_type = 'OUT' THEN -@quantity
            ELSE 0
        END;
END;
GO