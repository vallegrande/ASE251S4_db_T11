--liquibase formatted sql

--changeset equipo11:004-seed-demo-data
--comment: Datos de ejemplo. Los ids de producto, cliente y proveedor coinciden con los de MongoDB (ver liquibase/mongodb, cambio 002).
INSERT INTO dbo.store (store_name, address, phone, ubigeo_id)
VALUES (N'AgriMarket - Local Imperial (Cañete)', N'Imperial, Cañete, Lima', N'999333444', 5);

INSERT INTO dbo.inventory (product_id, store_id, current_stock, minimum_stock)
SELECT p.product_id, s.store_id, p.stock, p.min_stock
FROM (VALUES (N'1', 50, 5), (N'2', 30, 5), (N'3', 20, 3)) AS p(product_id, stock, min_stock)
CROSS JOIN (SELECT TOP (1) store_id FROM dbo.store ORDER BY store_id) AS s;

INSERT INTO dbo.[order] (status, delivery_type, total_amount, store_id, customer_id, checkout_key)
SELECT N'CONFIRMED', N'recogida', 37.00, store_id, N'1', N'SEED-ORDER-1' FROM (SELECT TOP (1) store_id FROM dbo.store ORDER BY store_id) AS s;

INSERT INTO dbo.[order] (status, delivery_type, total_amount, store_id, customer_id, checkout_key)
SELECT N'PENDING', N'recogida', 95.00, store_id, N'2', N'SEED-ORDER-2' FROM (SELECT TOP (1) store_id FROM dbo.store ORDER BY store_id) AS s;

INSERT INTO dbo.order_detail (order_id, product_id, quantity, unit_price)
SELECT order_id, N'1', 2, 18.50 FROM dbo.[order] WHERE checkout_key = N'SEED-ORDER-1';

INSERT INTO dbo.order_detail (order_id, product_id, quantity, unit_price)
SELECT order_id, N'2', 1, 95.00 FROM dbo.[order] WHERE checkout_key = N'SEED-ORDER-2';

INSERT INTO dbo.purchase_order (status, supplier_id, store_id, total_amount, notes)
SELECT N'PENDING', N'1', store_id, 1284.00, N'SEED-PO-1: orden de compra de ejemplo' FROM (SELECT TOP (1) store_id FROM dbo.store ORDER BY store_id) AS s;

INSERT INTO dbo.purchase_order_detail (purchase_order_id, product_id, quantity, unit_cost)
SELECT purchase_order_id, N'1', 20, 15.20 FROM dbo.purchase_order WHERE notes LIKE N'SEED-PO-1%';

INSERT INTO dbo.purchase_order_detail (purchase_order_id, product_id, quantity, unit_cost)
SELECT purchase_order_id, N'3', 10, 98.00 FROM dbo.purchase_order WHERE notes LIKE N'SEED-PO-1%';
--rollback DELETE FROM dbo.purchase_order WHERE notes LIKE N'SEED-PO-1%';
--rollback DELETE FROM dbo.[order] WHERE checkout_key IN (N'SEED-ORDER-1', N'SEED-ORDER-2');
--rollback DELETE FROM dbo.inventory WHERE product_id IN (N'1', N'2', N'3');
--rollback DELETE FROM dbo.store WHERE store_name = N'AgriMarket - Local Imperial (Cañete)';
