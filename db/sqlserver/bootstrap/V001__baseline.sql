-- ================================================================
-- AgriMarket - SQL Server
-- V001 - Baseline
--
-- Tablas transaccionales del backend (modelo com.agrimarket.demo.model.sql):
--   store, inventory, order, order_detail, purchase_order, purchase_order_detail
-- Los maestros (customer, product, supplier...) viven en MongoDB, por eso
-- customer_id, product_id y supplier_id son NVARCHAR sin FK (referencian al
-- _id del documento Mongo). ubigeo_id referencia el catálogo ubigeos de Mongo.
-- ================================================================

IF DB_NAME() <> 'Agrimarket'
BEGIN
    THROW 50000, 'La base de datos debe ser Agrimarket.', 1;
END;
GO

-- 1. Tienda --------------------------------------------------------
IF OBJECT_ID('dbo.store', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.store (
        store_id    INT IDENTITY(1,1) PRIMARY KEY,
        store_name  NVARCHAR(150) NOT NULL,
        address     NVARCHAR(255),
        phone       NVARCHAR(50),
        ubigeo_id   INT,
        created_at  DATETIME2 DEFAULT GETDATE(),
        updated_at  DATETIME2 DEFAULT GETDATE()
    );
END;
GO

-- 2. Inventario (qué productos hay en cada tienda + stock) ----------
IF OBJECT_ID('dbo.inventory', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.inventory (
        inventory_id  INT IDENTITY(1,1) PRIMARY KEY,
        product_id    NVARCHAR(100) NOT NULL,
        store_id      INT NOT NULL,
        current_stock INT NOT NULL DEFAULT 0,
        minimum_stock INT NOT NULL DEFAULT 0,
        updated_at    DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT CK_inventory_current_stock CHECK (current_stock >= 0),
        CONSTRAINT CK_inventory_minimum_stock CHECK (minimum_stock >= 0),
        CONSTRAINT FK_inventory_store FOREIGN KEY (store_id) REFERENCES dbo.store (store_id)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_inventory_product_store' AND object_id = OBJECT_ID('dbo.inventory'))
    CREATE UNIQUE INDEX UX_inventory_product_store ON dbo.inventory (product_id, store_id);
GO

-- 3. Pedido / venta ("order" es palabra reservada) -------------------
IF OBJECT_ID('dbo.[order]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[order] (
        order_id         INT IDENTITY(1,1) PRIMARY KEY,
        order_date       DATETIME2 NOT NULL DEFAULT GETDATE(),
        status           NVARCHAR(30) NOT NULL DEFAULT 'PENDING',
        delivery_type    NVARCHAR(30) NOT NULL,
        delivery_address NVARCHAR(255),
        delivery_date    DATETIME2,
        total_amount     DECIMAL(18,2) NOT NULL DEFAULT 0,
        store_id         INT,
        customer_id      NVARCHAR(100) NOT NULL,
        checkout_key     NVARCHAR(100),
        created_at       DATETIME2 DEFAULT GETDATE(),
        updated_at       DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_order_store FOREIGN KEY (store_id) REFERENCES dbo.store (store_id),
        CONSTRAINT CK_order_delivery_type CHECK (delivery_type = N'recogida')
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_order_customer' AND object_id = OBJECT_ID('dbo.[order]'))
    CREATE INDEX IX_order_customer ON dbo.[order] (customer_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_order_store' AND object_id = OBJECT_ID('dbo.[order]'))
    CREATE INDEX IX_order_store ON dbo.[order] (store_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_order_checkout_key' AND object_id = OBJECT_ID('dbo.[order]'))
    CREATE UNIQUE INDEX UX_order_checkout_key ON dbo.[order] (checkout_key) WHERE checkout_key IS NOT NULL;
GO

-- 4. Detalle de pedido ------------------------------------------------
IF OBJECT_ID('dbo.order_detail', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.order_detail (
        order_detail_id INT IDENTITY(1,1) PRIMARY KEY,
        order_id        INT NOT NULL,
        product_id      NVARCHAR(100) NOT NULL,
        quantity        INT NOT NULL,
        unit_price      DECIMAL(18,2) NOT NULL,
        CONSTRAINT FK_order_detail_order FOREIGN KEY (order_id) REFERENCES dbo.[order] (order_id) ON DELETE CASCADE,
        CONSTRAINT CK_order_detail_quantity CHECK (quantity > 0),
        CONSTRAINT CK_order_detail_unit_price CHECK (unit_price > 0)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_orderdetail_order' AND object_id = OBJECT_ID('dbo.order_detail'))
    CREATE INDEX IX_orderdetail_order ON dbo.order_detail (order_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_orderdetail_product' AND object_id = OBJECT_ID('dbo.order_detail'))
    CREATE INDEX IX_orderdetail_product ON dbo.order_detail (product_id);
GO

-- 5. Orden de compra a proveedor -------------------------------------
IF OBJECT_ID('dbo.purchase_order', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.purchase_order (
        purchase_order_id INT IDENTITY(1,1) PRIMARY KEY,
        order_date        DATETIME2 NOT NULL DEFAULT GETDATE(),
        status            NVARCHAR(30) NOT NULL DEFAULT 'PENDING',
        supplier_id       NVARCHAR(100) NOT NULL,
        store_id          INT,
        total_amount      DECIMAL(18,2) NOT NULL DEFAULT 0,
        notes             NVARCHAR(1000),
        created_at        DATETIME2 DEFAULT GETDATE(),
        updated_at        DATETIME2 DEFAULT GETDATE(),
        CONSTRAINT FK_purchase_order_store FOREIGN KEY (store_id) REFERENCES dbo.store (store_id)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_po_supplier' AND object_id = OBJECT_ID('dbo.purchase_order'))
    CREATE INDEX IX_po_supplier ON dbo.purchase_order (supplier_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_po_store' AND object_id = OBJECT_ID('dbo.purchase_order'))
    CREATE INDEX IX_po_store ON dbo.purchase_order (store_id);
GO

-- 6. Detalle de orden de compra --------------------------------------
IF OBJECT_ID('dbo.purchase_order_detail', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.purchase_order_detail (
        purchase_order_detail_id INT IDENTITY(1,1) PRIMARY KEY,
        purchase_order_id        INT NOT NULL,
        product_id               NVARCHAR(100) NOT NULL,
        quantity                 INT NOT NULL,
        unit_cost                DECIMAL(18,2) NOT NULL,
        CONSTRAINT FK_pod_purchase_order FOREIGN KEY (purchase_order_id) REFERENCES dbo.purchase_order (purchase_order_id) ON DELETE CASCADE,
        CONSTRAINT CK_purchase_order_detail_quantity CHECK (quantity > 0),
        CONSTRAINT CK_purchase_order_detail_unit_cost CHECK (unit_cost > 0)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_pod_po' AND object_id = OBJECT_ID('dbo.purchase_order_detail'))
    CREATE INDEX IX_pod_po ON dbo.purchase_order_detail (purchase_order_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_pod_product' AND object_id = OBJECT_ID('dbo.purchase_order_detail'))
    CREATE INDEX IX_pod_product ON dbo.purchase_order_detail (product_id);
GO

-- ================================================================
-- Datos semilla (coinciden con los ids sembrados en MongoDB V001:
-- productos 1-3, clientes 1-2, proveedores 1-2). Son repetibles.
-- ================================================================

IF NOT EXISTS (SELECT 1 FROM dbo.store)
BEGIN
    INSERT INTO dbo.store (store_name, address, phone, ubigeo_id)
    VALUES (N'AgriMarket - Local Imperial (Cañete)', N'Imperial, Cañete, Lima', N'999333444', 5);
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.inventory)
BEGIN
    DECLARE @StoreId INT = (SELECT TOP (1) store_id FROM dbo.store ORDER BY store_id);
    INSERT INTO dbo.inventory (product_id, store_id, current_stock, minimum_stock) VALUES
        (N'1', @StoreId, 50, 5),
        (N'2', @StoreId, 30, 5),
        (N'3', @StoreId, 20, 3);
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.[order])
BEGIN
    DECLARE @StoreIdOrder INT = (SELECT TOP (1) store_id FROM dbo.store ORDER BY store_id);

    INSERT INTO dbo.[order] (status, delivery_type, total_amount, store_id, customer_id)
    VALUES (N'CONFIRMED', N'recogida', 37.00, @StoreIdOrder, N'1');
    INSERT INTO dbo.order_detail (order_id, product_id, quantity, unit_price)
    VALUES (SCOPE_IDENTITY(), N'1', 2, 18.50);

    INSERT INTO dbo.[order] (status, delivery_type, total_amount, store_id, customer_id)
    VALUES (N'PENDING', N'recogida', 95.00, @StoreIdOrder, N'2');
    INSERT INTO dbo.order_detail (order_id, product_id, quantity, unit_price)
    VALUES (SCOPE_IDENTITY(), N'2', 1, 95.00);
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.purchase_order)
BEGIN
    DECLARE @StoreIdPo INT = (SELECT TOP (1) store_id FROM dbo.store ORDER BY store_id);

    INSERT INTO dbo.purchase_order (status, supplier_id, store_id, total_amount, notes)
    VALUES (N'PENDING', N'1', @StoreIdPo, 1284.00, N'Orden de compra de ejemplo; no incrementa inventario automáticamente');
    DECLARE @PoId INT = SCOPE_IDENTITY();
    INSERT INTO dbo.purchase_order_detail (purchase_order_id, product_id, quantity, unit_cost) VALUES
        (@PoId, N'1', 20, 15.20),
        (@PoId, N'3', 10, 98.00);
END;
GO

PRINT 'AgriMarket SQL Server V001 baseline ejecutado correctamente.';
GO
