USE Agrimarket;
GO

IF COL_LENGTH('dbo.inventory', 'is_active') IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM sys.default_constraints WHERE name = 'DF_inventory_is_active')
        ALTER TABLE dbo.inventory DROP CONSTRAINT DF_inventory_is_active;
    ALTER TABLE dbo.inventory DROP COLUMN is_active;
END
GO

PRINT 'AgriMarket SQL Server V003 revertido.';
GO
