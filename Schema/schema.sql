-----------------------------
--Dim Location
-----------------------------
CREATE TABLE Dim_Location (
    location_id INT PRIMARY KEY,
    location_name VARCHAR(50),
    location_type VARCHAR(20), -- Main, Sub, Restaurant
    contact_info VARCHAR(15),
    parent_location_id INT NULL
);
-----------------------------
--Dim Product
-----------------------------
CREATE TABLE Dim_Product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50),
    product_category VARCHAR(30)
);
-----------------------------
--Dim User
-----------------------------
CREATE TABLE Dim_User (
    user_id INT PRIMARY KEY,
    username VARCHAR(50)
);
-----------------------------
--Dim Date
-----------------------------
CREATE TABLE Dim_Date (
    date_id INT PRIMARY KEY,
    full_date DATE,
    day INT,
    month INT,
    year INT
);

-----------------------------
--Fact Inventory Movement
-----------------------------

CREATE TABLE Fact_Inventory_Movement (
    fact_id INT IDENTITY(1,1) PRIMARY KEY,

    location_id INT NOT NULL,
    product_id INT NOT NULL,
    user_id INT NOT NULL,
    date_id INT NOT NULL,

    quantity INT NOT NULL,
    transaction_type VARCHAR(20), -- IN / OUT / TRANSFER
    cost DECIMAL(10,2),

    CONSTRAINT FK_Fact_Location FOREIGN KEY (location_id)
        REFERENCES Dim_Location(location_id),

    CONSTRAINT FK_Fact_Product FOREIGN KEY (product_id)
        REFERENCES Dim_Product(product_id),

    CONSTRAINT FK_Fact_User FOREIGN KEY (user_id)
        REFERENCES Dim_User(user_id),

    CONSTRAINT FK_Fact_Date FOREIGN KEY (date_id)
        REFERENCES Dim_Date(date_id)
);

-----------------------------
--Aggregate Inventory Summary
-----------------------------

CREATE TABLE Aggregate_Inventory_Summary (
    summary_id INT IDENTITY(1,1) PRIMARY KEY,

    location_id INT,
    product_id INT,

    total_quantity INT,
    total_cost DECIMAL(12,2),
    transaction_count INT
);