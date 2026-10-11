-- ================================================================
-- Contrato de la versión: comprueba que SQL Server quedó exactamente como
-- debe estar en la versión $(TARGET) (historial, tablas, índices, columnas y datos).
-- ================================================================
USE Agrimarket;
GO

DECLARE @target INT = $(TARGET);

IF (SELECT COUNT(*) FROM dbo.schema_changes) <> @target
    THROW 50010, 'CONTRATO NO CUMPLIDO: el historial no coincide con la version objetivo.', 1;

IF (SELECT MAX(change_seq) FROM dbo.schema_changes) <> @target
    THROW 50011, 'CONTRATO NO CUMPLIDO: la ultima version registrada no es la objetivo.', 1;

IF EXISTS (
    SELECT 1
    FROM (VALUES ('store'), ('inventory'), ('order'), ('order_detail'), ('purchase_order'), ('purchase_order_detail'), ('schema_changes')) AS t(table_name)
    WHERE OBJECT_ID('dbo.[' + t.table_name + ']', 'U') IS NULL
)
    THROW 50012, 'CONTRATO NO CUMPLIDO: falta una tabla del baseline.', 1;

IF @target >= 2 AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_order_status' AND object_id = OBJECT_ID('dbo.[order]'))
    THROW 50013, 'CONTRATO NO CUMPLIDO: falta el indice IX_order_status (V002).', 1;
IF @target < 2 AND EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_order_status' AND object_id = OBJECT_ID('dbo.[order]'))
    THROW 50014, 'CONTRATO NO CUMPLIDO: IX_order_status no deberia existir antes de V002.', 1;

IF @target >= 3 AND COL_LENGTH('dbo.inventory', 'is_active') IS NULL
    THROW 50015, 'CONTRATO NO CUMPLIDO: falta la columna inventory.is_active (V003).', 1;
IF @target < 3 AND COL_LENGTH('dbo.inventory', 'is_active') IS NOT NULL
    THROW 50016, 'CONTRATO NO CUMPLIDO: inventory.is_active no deberia existir antes de V003.', 1;

IF (SELECT COUNT(*) FROM dbo.store) < 1
    THROW 50017, 'CONTRATO NO CUMPLIDO: no hay ninguna tienda sembrada.', 1;

PRINT 'SQL Server: contrato verificado para la version objetivo.';
GO
