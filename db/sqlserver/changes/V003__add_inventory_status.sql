USE Agrimarket;
GO

IF COL_LENGTH('inventory', 'is_active') IS NULL
BEGIN
    ALTER TABLE inventory
    ADD is_active BIT NOT NULL
        CONSTRAINT DF_inventory_is_active DEFAULT 1;
END
GO

PRINT 'AgriMarket SQL Server V002 ejecutado correctamente.';
GO