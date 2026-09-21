-- ================================================================
-- AgriMarket - SQL Server
-- V001 - Baseline
-- ================================================================

IF DB_NAME() <> 'Agrimarket'
BEGIN
    THROW 50000, 'La base de datos debe ser Agrimarket.', 1;
END;
GO

-- ================================================================
-- 1. TIENDA
-- ================================================================

IF OBJECT_ID('dbo.store', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.store (
        store_id       INT IDENTITY(1,1) PRIMARY KEY,
        store_name     NVARCHAR(150) NOT NULL,
        address        NVARCHAR(255),
        phone          NVARCHAR(50),
        ubigeo_id      INT,
        created_at     DATETIME2 DEFAULT GETDATE(),
        updated_at     DATETIME2 DEFAULT GETDATE()
    );
END;
GO

-- ================================================================
-- 2. INVENTARIO
-- ================================================================

IF OBJECT_ID('dbo.inventory', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.inventory (
        inventory_id  INT IDENTITY(1,1) PRIMARY KEY,
        product_id    NVARCHAR(100) NOT NULL,
        store_id      INT NOT NULL,
        quantity      INT NOT NULL DEFAULT 0,
        unit_cost     DECIMAL(18,2) DEFAULT 0,
        updated_at    DATETIME2 DEFAULT GETDATE(),

        CONSTRAINT FK_inventory_store
            FOREIGN KEY (store_id)
            REFERENCES dbo.store(store_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_inventory_product_store'
      AND object_id = OBJECT_ID('dbo.inventory')
)
BEGIN
    CREATE INDEX IX_inventory_product_store
        ON dbo.inventory (product_id, store_id);
END;
GO

-- ================================================================
-- 3. USUARIOS
-- ================================================================

IF OBJECT_ID('dbo.app_user', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.app_user (
        user_id        INT IDENTITY(1,1) PRIMARY KEY,
        username       NVARCHAR(50) NOT NULL UNIQUE,
        email          NVARCHAR(255) NOT NULL UNIQUE,
        password_hash  NVARCHAR(255) NOT NULL,
        role            NVARCHAR(20) NOT NULL,
        store_id       INT,
        is_active      BIT DEFAULT 1,
        created_at     DATETIME2 DEFAULT GETDATE(),
        updated_at     DATETIME2 DEFAULT GETDATE(),

        CONSTRAINT FK_app_user_store
            FOREIGN KEY (store_id)
            REFERENCES dbo.store(store_id)
    );
END;
GO

-- ================================================================
-- 4. PEDIDO / VENTA
-- ================================================================

IF OBJECT_ID('dbo.[order]', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.[order] (
        order_id         INT IDENTITY(1,1) PRIMARY KEY,
        order_date       DATETIME2 NOT NULL DEFAULT GETDATE(),
        status            NVARCHAR(30) NOT NULL DEFAULT 'PENDING',
        delivery_type    NVARCHAR(30) NOT NULL,
        delivery_address NVARCHAR(255),
        delivery_date    DATETIME2,
        total_amount     DECIMAL(18,2) NOT NULL DEFAULT 0,
        store_id         INT,
        customer_id      NVARCHAR(100) NOT NULL,
        created_at       DATETIME2 DEFAULT GETDATE(),
        updated_at       DATETIME2 DEFAULT GETDATE(),

        CONSTRAINT FK_order_store
            FOREIGN KEY (store_id)
            REFERENCES dbo.store(store_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_order_customer'
      AND object_id = OBJECT_ID('dbo.[order]')
)
BEGIN
    CREATE INDEX IX_order_customer
        ON dbo.[order] (customer_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_order_store'
      AND object_id = OBJECT_ID('dbo.[order]')
)
BEGIN
    CREATE INDEX IX_order_store
        ON dbo.[order] (store_id);
END;
GO

-- ================================================================
-- 5. DETALLE DE PEDIDO
-- ================================================================

IF OBJECT_ID('dbo.order_detail', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.order_detail (
        order_detail_id INT IDENTITY(1,1) PRIMARY KEY,
        order_id        INT NOT NULL,
        product_id      NVARCHAR(100) NOT NULL,
        quantity        INT NOT NULL,
        unit_price      DECIMAL(18,2) NOT NULL,

        CONSTRAINT FK_order_detail_order
            FOREIGN KEY (order_id)
            REFERENCES dbo.[order](order_id)
            ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_orderdetail_order'
      AND object_id = OBJECT_ID('dbo.order_detail')
)
BEGIN
    CREATE INDEX IX_orderdetail_order
        ON dbo.order_detail (order_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_orderdetail_product'
      AND object_id = OBJECT_ID('dbo.order_detail')
)
BEGIN
    CREATE INDEX IX_orderdetail_product
        ON dbo.order_detail (product_id);
END;
GO

-- ================================================================
-- 6. ORDEN DE COMPRA A PROVEEDOR
-- ================================================================

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

        CONSTRAINT FK_purchase_order_store
            FOREIGN KEY (store_id)
            REFERENCES dbo.store(store_id)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_po_supplier'
      AND object_id = OBJECT_ID('dbo.purchase_order')
)
BEGIN
    CREATE INDEX IX_po_supplier
        ON dbo.purchase_order (supplier_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_po_store'
      AND object_id = OBJECT_ID('dbo.purchase_order')
)
BEGIN
    CREATE INDEX IX_po_store
        ON dbo.purchase_order (store_id);
END;
GO

-- ================================================================
-- 7. DETALLE DE ORDEN DE COMPRA
-- ================================================================

IF OBJECT_ID('dbo.purchase_order_detail', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.purchase_order_detail (
        purchase_order_detail_id INT IDENTITY(1,1) PRIMARY KEY,
        purchase_order_id        INT NOT NULL,
        product_id               NVARCHAR(100) NOT NULL,
        quantity                 INT NOT NULL,
        unit_cost                DECIMAL(18,2) NOT NULL,

        CONSTRAINT FK_pod_purchase_order
            FOREIGN KEY (purchase_order_id)
            REFERENCES dbo.purchase_order(purchase_order_id)
            ON DELETE CASCADE
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_pod_po'
      AND object_id = OBJECT_ID('dbo.purchase_order_detail')
)
BEGIN
    CREATE INDEX IX_pod_po
        ON dbo.purchase_order_detail (purchase_order_id);
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = 'IX_pod_product'
      AND object_id = OBJECT_ID('dbo.purchase_order_detail')
)
BEGIN
    CREATE INDEX IX_pod_product
        ON dbo.purchase_order_detail (product_id);
END;
GO

-- ================================================================
-- 8. DATOS SEMILLA
-- ================================================================

IF NOT EXISTS (
    SELECT 1
    FROM dbo.store
    WHERE store_id = 1
)
BEGIN
    SET IDENTITY_INSERT dbo.store ON;

    INSERT INTO dbo.store
        (store_id, store_name, address, phone, ubigeo_id)
    VALUES
        (
            1,
            'AgriMarket - Tienda Principal Lima',
            'Av. Abancay 333, Cercado de Lima',
            '(01) 420-1234',
            NULL
        );

    SET IDENTITY_INSERT dbo.store OFF;
END;
GO

PRINT 'AgriMarket V001 baseline ejecutado correctamente.';
GO