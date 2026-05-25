
-- Recuperar las Ventas en estado 3 o 7 con Pago Caja del día de hoy
-- Pagos, Preventa se encuentra en diferentes servidores
-- Ventas es el servidor local y Preventa y Pagos son los linked server

SELECT
    -- Venta (servidor local: sql-ventas)
    v.[Id]               AS VentaId,
    v.[FechaVenta],
    v.[Monto]            AS MontoVenta,
    v.[MontoDescuento],
    v.[Estado]           AS EstadoVenta,
    v.[SedeId],
    v.[VendedorId],
    v.[NombreCategoria],

    -- Prospecto (Linked Server: sql-preventa)
    p.[Nombre]           AS ProspectoNombre,
    p.[Apellido]         AS ProspectoApellido,
    p.[Email],
    p.[Celular],
    p.[Documento],
    p.[SistemaOrigen],

    -- Pago Venta (Linked Server: sql-pagos)
    pv.[Id]              AS PagoVentaId,
    pv.[TipoPago],
    pv.[Monto]           AS MontoPago,
    pv.[FechaPago],

    -- Pago Caja — su existencia confirma que el pago es de tipo Caja
    pc.[Id]              AS PagoCajaId,
    pc.[MonedaId],
    pc.[Monto]           AS MontoCaja,
    pc.[MontoDescuento]  AS DescuentoCaja,
    pc.[Cotizacion]

FROM [GMegatlon.Ventas].[dbo].[Ventas]  AS v

-- Prospecto que originó la venta (servidor remoto)
INNER JOIN [sql-preventa].[GMegatlon.Preventa].[dbo].[Prospectos]  AS p
    ON  p.[Id]       = v.[ProspectoID]

-- Pagos registrados para esta venta, filtrando por fecha de hoy
INNER JOIN [sql-pagos].[GMegatlon.Pagos].[dbo].[PagoVentas]        AS pv
    ON  pv.[VentaId] = v.[Id]
    AND pv.[Active]  = 1
    AND CAST(pv.[FechaPago] AS DATE) = CAST(GETDATE() AS DATE)

-- Confirma que el pago es de tipo Caja (si no existe acá, el INNER JOIN lo excluye)
INNER JOIN [sql-pagos].[GMegatlon.Pagos].[dbo].[PagosCaja]         AS pc
    ON  pc.[PagoVentaId] = pv.[Id]
    AND pc.[Active]      = 1

WHERE
    v.[Active] = 1
    AND v.[Estado] IN (3, 7)

ORDER BY v.[FechaVenta] DESC;
