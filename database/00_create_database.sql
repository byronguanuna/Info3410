USE master;
GO

IF DB_ID(N'BurgersAndFries') IS NULL
BEGIN
    CREATE DATABASE BurgersAndFries;
END;
GO

SELECT name
FROM sys.databases
WHERE name = N'BurgersAndFries';
GO