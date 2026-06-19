/*=========================================================
DIMENSION TABLES
=========================================================*/

CREATE TABLE Dim_Location (
    LocationID INT PRIMARY KEY,
    LocationName VARCHAR(50) NOT NULL,
    LocationType VARCHAR(20) NOT NULL, -- Main, Sub, Restaurant
    ContactInfo VARCHAR(15),
    ParentLocationID INT NULL
);

CREATE TABLE Dim_Product (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(50) NOT NULL,
    ProductCategory VARCHAR(30) NOT NULL
);

CREATE TABLE Dim_User (
    UserID INT PRIMARY KEY,
    Username VARCHAR(50) NOT NULL
);

CREATE TABLE Dim_Date (
    DateID INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    DayNum INT NOT NULL,
    MonthNum INT NOT NULL,
    YearNum INT NOT NULL
);

/*=========================================================
FACT TABLE
=========================================================*/

CREATE TABLE Fact_Inventory_Movement (
    FactID INT IDENTITY(1,1) PRIMARY KEY,

    LocationID INT NOT NULL,
    ProductID INT NOT NULL,
    UserID INT NOT NULL,
    DateID INT NOT NULL,

    Quantity INT NOT NULL,
    TransactionType VARCHAR(20) NOT NULL,
    Cost DECIMAL(10,2) NOT NULL,

    CONSTRAINT FK_Fact_Location
        FOREIGN KEY (LocationID)
        REFERENCES Dim_Location(LocationID),

    CONSTRAINT FK_Fact_Product
        FOREIGN KEY (ProductID)
        REFERENCES Dim_Product(ProductID),

    CONSTRAINT FK_Fact_User
        FOREIGN KEY (UserID)
        REFERENCES Dim_User(UserID),

    CONSTRAINT FK_Fact_Date
        FOREIGN KEY (DateID)
        REFERENCES Dim_Date(DateID)
);

/*=========================================================
AGGREGATE TABLE
=========================================================*/

CREATE TABLE Aggregate_Inventory_Summary (
    SummaryID INT IDENTITY(1,1) PRIMARY KEY,

    LocationID INT NOT NULL,
    ProductID INT NOT NULL,

    TotalQuantity INT,
    TotalCost DECIMAL(12,2),
    TransactionCount INT
);
