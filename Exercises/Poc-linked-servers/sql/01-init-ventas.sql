CREATE DATABASE [GMegatlon.Ventas];
GO

USE [GMegatlon.Ventas];
GO

CREATE TABLE [dbo].[Ventas] (
    [Id]              INT           NOT NULL PRIMARY KEY,
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
    [Tipo]            NVARCHAR(50)  NULL
);
GO

INSERT INTO [dbo].[Ventas]
    ([Id],[FechaVenta],[Monto],[MontoDescuento],[VendedorId],[Active],[SedeId],[Estado],[CategoriaId],[ProspectoID],[NombreCategoria],[EmpresaId])
VALUES (1, GETDATE(), 15000.00, 500.00, 10, 1, 2, 3, 1, 1, N'Red', 1);

INSERT INTO [dbo].[Ventas]
    ([Id],[FechaVenta],[Monto],[MontoDescuento],[VendedorId],[Active],[SedeId],[Estado],[CategoriaId],[ProspectoID],[NombreCategoria],[EmpresaId])
VALUES (2, GETDATE(), 8500.00, 0.00, 10, 1, 2, 7, 2, 2, N'Black', 1);

INSERT INTO [dbo].[Ventas]
    ([Id],[FechaVenta],[Monto],[MontoDescuento],[VendedorId],[Active],[SedeId],[Estado],[CategoriaId],[ProspectoID],[NombreCategoria],[EmpresaId])
VALUES (3, GETDATE(), 5000.00, 0.00, 11, 1, 2, 5, 1, 1, N'Red', 1);

INSERT INTO [dbo].[Ventas]
    ([Id],[FechaVenta],[Monto],[MontoDescuento],[VendedorId],[Active],[SedeId],[Estado],[CategoriaId],[ProspectoID],[NombreCategoria],[EmpresaId])
VALUES (4, GETDATE(), 12000.00, 200.00, 11, 1, 3, 3, 1, 2, N'Black', 1);
GO

PRINT 'GMegatlon.Ventas OK — 4 ventas insertadas (esperadas en resultado: 2)';
GO
