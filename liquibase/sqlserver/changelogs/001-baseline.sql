--liquibase formatted sql

--changeset equipo11:001-baseline
--comment: Tablas transaccionales de AgriMarket (los maestros viven en MongoDB, por eso customer_id/product_id/supplier_id no tienen FK)
CREATE TABLE dbo.store (
    store_id    INT IDENTITY(1,1) PRIMARY KEY,
    store_name  NVARCHAR(150) NOT NULL,
    address     NVARCHAR(255),
    phone       NVARCHAR(50),
    ubigeo_id   INT,
    created_at  DATETIME2 DEFAULT GETDATE(),
    updated_at  DATETIME2 DEFAULT GETDATE()
);

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

CREATE UNIQUE INDEX UX_inventory_product_store ON dbo.inventory (product_id, store_id);

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

CREATE INDEX IX_order_customer ON dbo.[order] (customer_id);
CREATE INDEX IX_order_store ON dbo.[order] (store_id);
CREATE UNIQUE INDEX UX_order_checkout_key ON dbo.[order] (checkout_key) WHERE checkout_key IS NOT NULL;

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

CREATE INDEX IX_orderdetail_order ON dbo.order_detail (order_id);
CREATE INDEX IX_orderdetail_product ON dbo.order_detail (product_id);

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

CREATE INDEX IX_po_supplier ON dbo.purchase_order (supplier_id);
CREATE INDEX IX_po_store ON dbo.purchase_order (store_id);

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

CREATE INDEX IX_pod_po ON dbo.purchase_order_detail (purchase_order_id);
CREATE INDEX IX_pod_product ON dbo.purchase_order_detail (product_id);
--rollback DROP TABLE dbo.purchase_order_detail;
--rollback DROP TABLE dbo.purchase_order;
--rollback DROP TABLE dbo.order_detail;
--rollback DROP TABLE dbo.[order];
--rollback DROP TABLE dbo.inventory;
--rollback DROP TABLE dbo.store;
