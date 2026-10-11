-- V002 - Índice por estado de pedido (consultas del panel de ventas)
USE Agrimarket;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_order_status' AND object_id = OBJECT_ID('dbo.[order]'))
BEGIN
    CREATE INDEX IX_order_status ON dbo.[order] (status);
END
GO

PRINT 'AgriMarket SQL Server V002 ejecutado correctamente.';
GO
