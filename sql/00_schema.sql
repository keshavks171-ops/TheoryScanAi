/*=============================================================================
  Provider Datamart - 00_schema.sql
  Creates the database schemas used to organize datamart objects.
  Target: Microsoft SQL Server (T-SQL)

  Run order: 00 -> 01 -> 02 -> 03 -> 04
=============================================================================*/

-- Optionally create the database (uncomment and adjust to your environment):
-- IF DB_ID('ProviderDatamart') IS NULL
--     CREATE DATABASE ProviderDatamart;
-- GO
-- USE ProviderDatamart;
-- GO

-- Dimension objects
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'dim')
    EXEC('CREATE SCHEMA dim');
GO

-- Fact objects
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'fact')
    EXEC('CREATE SCHEMA fact');
GO

-- Bridge / many-to-many objects
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'bridge')
    EXEC('CREATE SCHEMA bridge');
GO

-- Staging (reserved for the ETL phase; no objects created in this prototype)
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'stg')
    EXEC('CREATE SCHEMA stg');
GO
