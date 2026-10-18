--liquibase formatted sql

--changeset equipo11:002-order-status-index
--comment: Índice por estado de pedido (consultas del panel de ventas)
CREATE INDEX IX_order_status ON dbo.[order] (status);
--rollback DROP INDEX IX_order_status ON dbo.[order];
