-- Base: GMegatlon.Ventas | Servidor: sql-ventas

-- ESTRATEGIA:
--	 RANGE RIGHT anual sobre FechaVenta
--   	Particion 1: FechaVenta <  2024-01-01  (hasta 2023)
--   	Particion 2: 2024-01-01 <= FechaVenta < 2025-01-01  (2024)
--   	Particion 3: 2025-01-01 <= FechaVenta < 2026-01-01  (2025)
--   	Particion 4: 2026-01-01 <= FechaVenta < 2027-01-01  (2026)
--   	Particion 5: FechaVenta >= 2027-01-01  (futuro)
-- ============================================================

USE [GMegatlon.Ventas];
GO

-- 1. Funcion de particion
-- RANGE RIGHT: el boundary es el primer dia de cada año.
-- '2026-01-01' pertenece a la particion derecha (2026).
CREATE PARTITION FUNCTION pf_Ventas_PorAnio (DATETIME)
AS RANGE RIGHT FOR VALUES (
    '20240101',
    '20250101',
    '20260101',
    '20270101'
);
GO

-- 2. Esquema de particion
-- POC: todas las particiones en PRIMARY.
-- Produccion: un filegroup por particion para distribuir I/O.
CREATE PARTITION SCHEME ps_Ventas_PorAnio
AS PARTITION pf_Ventas_PorAnio
ALL TO ([PRIMARY]);
GO

-- 3. Tabla particionada
-- FechaVenta en la PK para alinear el indice clustered
-- con el partition scheme (requisito de SQL Server).
CREATE TABLE [dbo].[VentasParticionada] (
    [Id]              INT           NOT NULL,
    [FechaVenta]      DATETIME      NOT NULL,
    [Monto]           DECIMAL(18,2) NOT NULL,
    [MontoDescuento]  DECIMAL(18,2) NULL,
    [VendedorId]      INT           NULL,
    [Active]          BIT           NOT NULL DEFAULT 1,
    [SedeId]          INT           NULL,
    [Estado]          INT           NOT NULL,
    [CategoriaId]     INT           NULL,
    [ProspectoID]     INT           NULL,
    [NombreCategoria] NVARCHAR(100) NULL,
    [EmpresaId]       INT           NULL,
    [Tipo]            NVARCHAR(50)  NULL,
    CONSTRAINT PK_VentasParticionada PRIMARY KEY CLUSTERED ([Id], [FechaVenta])
)
ON ps_Ventas_PorAnio ([FechaVenta]);
GO

-- 4. Migrar datos de Ventas existente a VentasParticionada
-- SQL Server distribuye cada fila a la particion correcta automaticamente.
INSERT INTO [dbo].[VentasParticionada]
    ([Id],[FechaVenta],[Monto],[MontoDescuento],[VendedorId],
     [Active],[SedeId],[Estado],[CategoriaId],[ProspectoID],
     [NombreCategoria],[EmpresaId])
SELECT
    [Id],[FechaVenta],[Monto],[MontoDescuento],[VendedorId],
    [Active],[SedeId],[Estado],[CategoriaId],[ProspectoID],
    [NombreCategoria],[EmpresaId]
FROM [dbo].[Ventas];
GO

-- 5. Filas historicas para poblar particiones anteriores
INSERT INTO [dbo].[VentasParticionada]
    ([Id],[FechaVenta],[Monto],[MontoDescuento],[VendedorId],
     [Active],[SedeId],[Estado],[CategoriaId],[ProspectoID],
     [NombreCategoria],[EmpresaId])
VALUES
    (101, '20230315 10:00:00', 12000.00,    0.00, 10, 1, 2, 3, 1, 1, N'Musculacion', 1),
    (102, '20231101 14:30:00',  9500.00,  500.00, 10, 1, 2, 7, 2, 2, N'Natacion',    1),
    (103, '20240620 09:00:00', 15000.00, 1000.00, 11, 1, 3, 3, 1, 1, N'Musculacion', 1),
    (104, '20241210 16:45:00',  8000.00,    0.00, 11, 1, 3, 7, 2, 2, N'Natacion',    1),
    (105, '20250301 11:00:00', 18000.00, 2000.00, 10, 1, 2, 3, 1, 1, N'Musculacion', 1),
    (106, '20250901 08:30:00', 11000.00,  500.00, 10, 1, 2, 5, 2, 2, N'Natacion',    1);
GO

-- 6. Verificar distribucion de filas por particion
SELECT
    p.partition_number               AS NroParticion,
    prv_left.value                   AS DesdeInclusive,
    prv_right.value                  AS HastaExclusive,
    p.rows                           AS CantidadFilas,
    fg.name                          AS Filegroup
FROM sys.partitions                  AS p
JOIN sys.indexes                     AS i
    ON  i.object_id = p.object_id
    AND i.index_id  = p.index_id
JOIN sys.partition_schemes           AS ps
    ON  ps.data_space_id = i.data_space_id
JOIN sys.partition_functions         AS pf
    ON  pf.function_id = ps.function_id
LEFT JOIN sys.partition_range_values AS prv_right
    ON  prv_right.function_id = pf.function_id
    AND prv_right.boundary_id = p.partition_number
LEFT JOIN sys.partition_range_values AS prv_left
    ON  prv_left.function_id  = pf.function_id
    AND prv_left.boundary_id  = p.partition_number - 1
JOIN sys.destination_data_spaces     AS dds
    ON  dds.partition_scheme_id = ps.data_space_id
    AND dds.destination_id      = p.partition_number
JOIN sys.filegroups                  AS fg
    ON  fg.data_space_id = dds.data_space_id
WHERE
    p.object_id = OBJECT_ID('dbo.VentasParticionada')
    AND i.index_id = 1
ORDER BY p.partition_number;
GO

-- 7. Partition elimination: solo lee particion 4 (2026)
-- En SSMS: activar plan de ejecucion real, Actual Partition Count = 1
SELECT
    [Id],
    [FechaVenta],
    [Monto],
    [Estado],
    $PARTITION.pf_Ventas_PorAnio([FechaVenta]) AS NroParticion
FROM [dbo].[VentasParticionada]
WHERE [FechaVenta] >= '20260101'
  AND [FechaVenta] <  '20270101';
GO

-- 8. Vision completa: todas las filas con su numero de particion
SELECT
    [Id],
    [FechaVenta],
    [Monto],
    [Estado],
    $PARTITION.pf_Ventas_PorAnio([FechaVenta]) AS NroParticion
FROM [dbo].[VentasParticionada]
ORDER BY NroParticion, [FechaVenta];
GO

PRINT 'PoC Particiones OK';
GO
