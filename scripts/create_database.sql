/*
======================================

Create database and Schemas

======================================

Script Purpose: 
	-Creates a new database named 'DataWarehouse' after checking if it already exists.
	-If the database exists, it is dropped and recreated.
	-Creates three schemas within the database: bronze, silver and gold

WARNING:

	Running this script will drop the entire 'DataWharehouse' if it exists.
	All data in the database will be permanently deleted. Proceed with caution and ensure you have backups. 

*/

USE master;
GO 

--Drop and recreate the DataWareHouse' database

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWharehouse')
BEGIN
	ALTER DATABSE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;
END;
GO

--Create the 'DataWhareHouse' database

CREATE DATABASE DataWarehouse; 
GO

USE DataWarehouse;
GO


--Create Schemas

CREATE SCHEMA bronze
GO
CREATE SCHEMA silver
GO
CREATE SCHEMA gold
GO
