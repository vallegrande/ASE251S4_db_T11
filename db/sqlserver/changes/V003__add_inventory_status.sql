-- V003 - Estado activo/inactivo del inventario
USE Agrimarket;
GO

IF COL_LENGTH('dbo.inventory', 'is_active') IS NULL
BEGIN
    ALTER TABLE dbo.inventory
    ADD is_active BIT NOT NULL
        CONSTRAINT DF_inventory_is_active DEFAULT 1;
END
GO

PRINT 'AgriMarket SQL Server V003 ejecutado correctamente.';
GO
