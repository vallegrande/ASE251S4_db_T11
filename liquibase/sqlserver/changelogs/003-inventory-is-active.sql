--liquibase formatted sql

--changeset equipo11:003-inventory-is-active
--comment: Estado activo/inactivo del inventario
ALTER TABLE dbo.inventory ADD is_active BIT NOT NULL CONSTRAINT DF_inventory_is_active DEFAULT 1;
--rollback ALTER TABLE dbo.inventory DROP CONSTRAINT DF_inventory_is_active;
--rollback ALTER TABLE dbo.inventory DROP COLUMN is_active;
