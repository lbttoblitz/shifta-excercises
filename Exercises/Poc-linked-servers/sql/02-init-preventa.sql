CREATE DATABASE [GMegatlon.Preventa];
GO

USE [GMegatlon.Preventa];
GO

CREATE TABLE [dbo].[Prospectos] (
    [Id]            INT           NOT NULL PRIMARY KEY,
    [TipoDocumento] NVARCHAR(20)  NULL,
    [Documento]     NVARCHAR(30)  NULL,
    [Nombre]        NVARCHAR(100) NULL,
    [Apellido]      NVARCHAR(100) NULL,
    [Celular]       NVARCHAR(30)  NULL,
    [Email]         NVARCHAR(200) NULL,
    [Tipo]          NVARCHAR(50)  NULL,
    [Estado]        NVARCHAR(50)  NULL,
    [SedeId]        INT           NULL,
    [VendedorId]    INT           NULL,
    [FechaAlta]     DATETIME      NULL,
    [Active]        BIT           NOT NULL DEFAULT 1,
    [SistemaOrigen] NVARCHAR(100) NULL,
    [EmpresaId]     INT           NULL
);
GO

INSERT INTO [dbo].[Prospectos]
    ([Id],[TipoDocumento],[Documento],[Nombre],[Apellido],[Celular],[Email],[Tipo],[Estado],[SedeId],[VendedorId],[FechaAlta],[Active],[SistemaOrigen],[EmpresaId])
VALUES
    (1, N'DNI', N'30123456', N'Juan',  N'Perez',    N'1134567890', N'juan.perez@mail.com',     N'Lead', N'Activo', 2, 10, GETDATE(), 1, N'1',     1),
    (2, N'DNI', N'28987654', N'María', N'González', N'1145678901', N'maria.gonzalez@mail.com', N'Lead', N'Activo', 2, 10, GETDATE(), 1, N'1', 1);
GO

PRINT 'GMegatlon.Preventa OK — 2 prospectos insertados';
GO
