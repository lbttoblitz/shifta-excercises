
USE [master];
GO

-- Linked Server sql-preventa
EXEC sp_addlinkedserver
    @server     = N'sql-preventa',
    @srvproduct = N'',
    @provider   = N'MSOLEDBSQL',
    @datasrc    = N'sql-preventa';  -- hostname resuelto por DNS interno Docker

EXEC sp_addlinkedsrvlogin
    @rmtsrvname  = N'sql-preventa',
    @useself     = N'false',
    @locallogin  = NULL,
    @rmtuser     = N'sa',
    @rmtpassword = N'P@ssw0rd123!';

EXEC sp_serveroption N'sql-preventa', 'rpc',     'true';
EXEC sp_serveroption N'sql-preventa', 'rpc out', 'true';
GO

-- Linked Server sql-pagos
EXEC sp_addlinkedserver
    @server     = N'sql-pagos',
    @srvproduct = N'',
    @provider   = N'MSOLEDBSQL',
    @datasrc    = N'sql-pagos';

EXEC sp_addlinkedsrvlogin
    @rmtsrvname  = N'sql-pagos',
    @useself     = N'false',
    @locallogin  = NULL,
    @rmtuser     = N'sa',
    @rmtpassword = N'P@ssw0rd123!';

EXEC sp_serveroption N'sql-pagos', 'rpc',     'true';
EXEC sp_serveroption N'sql-pagos', 'rpc out', 'true';
GO

-- ── Verificación: debe listar 2 linked servers ───────────────
SELECT [name], [product], [provider], [data_source]
FROM   sys.servers
WHERE  is_linked = 1;
GO
