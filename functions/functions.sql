/*=========================================================
Function: ufn_GetLocationName
Purpose:
Returns the LocationName from Dim_Location
based on the LocationID provided.
=========================================================*/
CREATE FUNCTION dbo.ufn_GetLocationName
(
    @LocationID INT
)
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @LocationName VARCHAR(50);

    SELECT @LocationName = LocationName
    FROM Dim_Location
    WHERE LocationID = @LocationID;

    RETURN @LocationName;
END;
GO


/*=========================================================
Function: ufn_GetProductName
Purpose:
Returns the ProductName from Dim_Product
based on the ProductID provided.
=========================================================*/
CREATE FUNCTION dbo.ufn_GetProductName
(
    @ProductID INT
)
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @ProductName VARCHAR(50);

    SELECT @ProductName = ProductName
    FROM Dim_Product
    WHERE ProductID = @ProductID;

    RETURN @ProductName;
END;
GO


/*=========================================================
Function: ufn_GetUsername
Purpose:
Returns the Username from Dim_User
based on the UserID provided.
=========================================================*/
CREATE FUNCTION dbo.ufn_GetUsername
(
    @UserID INT
)
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @Username VARCHAR(50);

    SELECT @Username = Username
    FROM Dim_User
    WHERE UserID = @UserID;

    RETURN @Username;
END;
GO


/*=========================================================
Function: ufn_GetFullDate
Purpose:
Returns the FullDate from Dim_Date
based on the DateID provided.
=========================================================*/
CREATE FUNCTION dbo.ufn_GetFullDate
(
    @DateID INT
)
RETURNS DATE
AS
BEGIN
    DECLARE @FullDate DATE;

    SELECT @FullDate = FullDate
    FROM Dim_Date
    WHERE DateID = @DateID;

    RETURN @FullDate;
END;
GO


/*=========================================================
Function: ufn_GetTotalProductQuantity
Purpose:
Returns the total quantity moved for a
specific product from the Fact_Inventory_Movement table.
=========================================================*/
CREATE FUNCTION dbo.ufn_GetTotalProductQuantity
(
    @ProductID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @TotalQuantity INT;

    SELECT @TotalQuantity = SUM(Quantity)
    FROM Fact_Inventory_Movement
    WHERE ProductID = @ProductID;

    RETURN ISNULL(@TotalQuantity, 0);
END;
GO


/*=========================================================
Function: ufn_GetLocationInventoryCost
Purpose:
Returns the total inventory cost for a
specific location from the Aggregate_Inventory_Summary table.
=========================================================*/
CREATE FUNCTION dbo.ufn_GetLocationInventoryCost
(
    @LocationID INT
)
RETURNS DECIMAL(12,2)
AS
BEGIN
    DECLARE @TotalCost DECIMAL(12,2);

    SELECT @TotalCost = SUM(TotalCost)
    FROM Aggregate_Inventory_Summary
    WHERE LocationID = @LocationID;

    RETURN ISNULL(@TotalCost, 0);
END;
GO