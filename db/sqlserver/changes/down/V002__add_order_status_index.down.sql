USE Agrimarket;
GO

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_order_status' AND object_id = OBJECT_ID('dbo.[order]'))
BEGIN
    DROP INDEX IX_order_status ON dbo.[order];
END
GO

PRINT 'AgriMarket SQL Server V002 revertido.';
GO
