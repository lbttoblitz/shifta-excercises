CREATE DATABASE [GMegatlon.Pagos];
GO

USE [GMegatlon.Pagos];
GO

CREATE TABLE [dbo].[PagoVentas] (
    [Id]                    INT           NOT NULL PRIMARY KEY,
    [VentaId]               INT           NOT NULL,
    [RegistroPagoParcialId] INT           NULL,
    [TipoPago]              NVARCHAR(50)  NOT NULL,
    [Monto]                 DECIMAL(18,2) NOT NULL,
    [FechaPago]             DATETIME      NOT NULL,
    [Active]                BIT           NOT NULL DEFAULT 1
);
GO

CREATE TABLE [dbo].[PagosCaja] (
    [Id]             INT           NOT NULL PRIMARY KEY,
    [PagoVentaId]    INT           NOT NULL,
    [MonedaId]       INT           NULL,
    [Monto]          DECIMAL(18,2) NOT NULL,
    [MontoDescuento] DECIMAL(18,2) NULL,
    [Cotizacion]     DECIMAL(18,4) NULL,
    [Active]         BIT           NOT NULL DEFAULT 1
);
GO

INSERT INTO [dbo].[PagoVentas] ([Id],[VentaId],[TipoPago],[Monto],[FechaPago],[Active])
VALUES (1, 1, N'PagoCaja', 14500.00, GETDATE(), 1);

INSERT INTO [dbo].[PagoVentas] ([Id],[VentaId],[TipoPago],[Monto],[FechaPago],[Active])
VALUES (2, 2, N'PagoCaja', 8500.00, GETDATE(), 1);

INSERT INTO [dbo].[PagoVentas] ([Id],[VentaId],[TipoPago],[Monto],[FechaPago],[Active])
VALUES (3, 4, N'Transferencia', 12000.00, GETDATE(), 1);

INSERT INTO [dbo].[PagosCaja] ([Id],[PagoVentaId],[MonedaId],[Monto],[MontoDescuento],[Cotizacion],[Active])
VALUES
    (1, 1, 1, 14500.00, 500.00, 1.0000, 1),
    (2, 2, 1,  8500.00,   0.00, 1.0000, 1);
GO

PRINT 'GMegatlon.Pagos OK — PagoVentas (3) y PagosCaja (2) insertados';
GO
