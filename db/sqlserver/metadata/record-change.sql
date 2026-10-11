-- Registra un cambio aplicado. Variables sqlcmd: SEQ, ID, CHECKSUM, GIT, REL (las pasa run.sh con -v).
USE Agrimarket;
GO

IF OBJECT_ID('dbo.schema_changes', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.schema_changes (
        change_seq      INT           NOT NULL PRIMARY KEY,
        change_id       NVARCHAR(200) NOT NULL,
        checksum        CHAR(64)      NOT NULL,
        git_sha         NVARCHAR(64),
        release_version NVARCHAR(64),
        applied_at      DATETIME2     NOT NULL DEFAULT SYSUTCDATETIME()
    );
END
GO

INSERT INTO dbo.schema_changes (change_seq, change_id, checksum, git_sha, release_version)
VALUES ($(SEQ), N'$(ID)', '$(CHECKSUM)', N'$(GIT)', N'$(REL)');
GO
