# PoC: Linked Servers y Particionamiento de Tablas


## Ejercicio 1: Realizar una PoC de Linked Servers con las bases de datos de Mega. explicar por qué se eligieron las bases
## Contexto

Prueba de concepto sobre dos funcionalidades avanzadas de SQL Server utilizando las bases de datos de GMegatlon distribuidas en contenedores Docker independientes.

---

## Arquitectura

```
[Host Windows]
    localhost:1433  →  sql-ventas    →  GMegatlon.Ventas
    localhost:1434  →  sql-preventa  →  GMegatlon.Preventa
    localhost:1435  →  sql-pagos     →  GMegatlon.Pagos

[Red Docker interna: poc-network]
    sql-ventas tiene Linked Server → sql-preventa
    sql-ventas tiene Linked Server → sql-pagos
```

---

| Base | Rol | Tabla principal |
|---|---|---|
| `GMegatlon.Ventas` | Servidor origen (local) | `dbo.Ventas` |
| `GMegatlon.Preventa` | Linked Server remoto | `dbo.Prospectos` |
| `GMegatlon.Pagos` | Linked Server remoto | `dbo.PagoVentas`, `dbo.PagosCaja` |

**Motivo de elección:**
- Una venta nace como prospecto en Preventa, se registra en Ventas y se cobra en Pagos.
- En producción estas bases viven en el mismo servidor, pero en muchos escenarios reales pueden separarse por dominio en servidores distintos.
- Distribuirlas en contenedores separados simula ese escenario de forma realista y controlada.

### Caso de negocio implementado

> Ventas en estado 3 o 7 con Pago Caja del día de hoy, cruzadas con el prospecto que originó la venta.

La cadena de joins cross-server es:

```
sql-ventas  → Ventas.ProspectoID
                └── sql-preventa → Prospectos.Id

sql-ventas  → Ventas.Id
                └── sql-pagos → PagoVentas.VentaId
                                    └── PagosCaja.PagoVentaId  (confirma que es pago caja)
```

El `INNER JOIN` a `PagosCaja` actúa como filtro implícito: si el pago no tiene entrada ahí, la venta no aparece en el resultado.

---

## Ejercicio 2: Realizar una PoC de particiones de tablas. Elegir una tabla para particionar y explicar elección

### Tabla elegida: `Ventas`

| Criterio | Justificación |
|---|---|
| **Crecimiento** | Cada transacción agrega una fila nueva de forma indefinida |
| **Partition key natural** | `FechaVenta` es la columna más filtrada en consultas de negocio |
| **Patron de acceso** | Datos históricos (años anteriores) se consultan esporádicamente vs el mes actual que se consulta constantemente |
| **Archivado** | Facilita comprimir o archivar particiones de años cerrados sin afectar la operación |

### Estrategia: RANGE RIGHT anual

```
Boundaries: 01/01/2024 | 01/01/2025 | 01/01/2026 | 01/01/2027

  P1 (< 2024)  |  P2 (2024)  |  P3 (2025)  |  P4 (2026)  |  P5 (futuro)
```

`RANGE RIGHT` se eligió porque los boundaries son el **primer día de cada año**, lo que resulta en fechas limpias y fáciles de mantener.

### Partition Elimination

Al filtrar por año, el optimizador descarta las particiones que no aplican antes de leer datos:

```sql
WHERE FechaVenta >= '20260101' AND FechaVenta < '20270101'
-- → Solo lee Partición 4. Las particiones 1, 2 y 3 no se tocan.
```

Verificable en SSMS activando el plan de ejecución real: el operador `Clustered Index Scan` mostrará `Actual Partition Count = 1`.

---

## Prerrequisitos

- Docker Desktop instalado y corriendo
- PowerShell
- SQL Server Management Studio (SSMS) o Azure Data Studio *(opcional, para exploración visual)*

---

## Estructura del proyecto

```
poc-linked-servers/
├── docker-compose.yml               ← 3 contenedores SQL Server 2022
├── run-poc.ps1                      ← script de orquestación automática
└── sql/
    ├── 01-init-ventas.sql           ← crea GMegatlon.Ventas + datos
    ├── 02-init-preventa.sql         ← crea GMegatlon.Preventa + datos
    ├── 03-init-pagos.sql            ← crea GMegatlon.Pagos + datos
    ├── 04-setup-linked-servers.sql  ← registra Linked Servers en sql-ventas
    ├── 05-query-caso-negocio.sql    ← query cross-server del caso de negocio
    └── 06-particiones.sql           ← PoC de particionamiento sobre Ventas
```

---

## Ejecución

**1. Levantar contenedores**
```powershell
docker compose up -d
```

**2. Verificar que los 3 estén healthy (~45 segundos)**
```powershell
docker ps
# STATUS debe mostrar (healthy) en los 3 contenedores
```

**3. Inicializar las bases de datos**
```powershell
Get-Content sql\01-init-ventas.sql   | docker exec -i sql-ventas   /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "P@ssw0rd123!" -No
Get-Content sql\02-init-preventa.sql | docker exec -i sql-preventa /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "P@ssw0rd123!" -No
Get-Content sql\03-init-pagos.sql    | docker exec -i sql-pagos    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "P@ssw0rd123!" -No
```

**4. Configurar Linked Servers en sql-ventas**
```powershell
Get-Content sql\04-setup-linked-servers.sql | docker exec -i sql-ventas /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "P@ssw0rd123!" -No
```

**5. Ejecutar Poc con linked servers (Ejercicio 1)**
```powershell
Get-Content sql\05-query-caso-negocio.sql | docker exec -i sql-ventas /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "P@ssw0rd123!" -No
```

**6. Ejecutar PoC de particiones (Ejercicio 2)**
```powershell
Get-Content sql\06-particiones.sql | docker exec -i sql-ventas /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "P@ssw0rd123!" -No
```

**7. Bajar los contenedores al terminar**
```powershell
docker compose down
```

---

## Conexión desde SSMS

| Servidor | Server name | Puerto |
|---|---|---|
| sql-ventas | `localhost,1433` | 1433 |
| sql-preventa | `localhost,1434` | 1434 |
| sql-pagos | `localhost,1435` | 1435 |

- **Authentication:** SQL Server Authentication
- **Login:** `sa`
- **Password:** `P@ssw0rd123!`
- Si solicita certificado SSL: tildar **Trust Server Certificate**

### Exploración visual en SSMS

**Linked Servers** (conectado a `localhost,1433`):
```
Server Objects → Linked Servers → sql-preventa / sql-pagos
```

**Particiones** (conectado a `localhost,1433`):
```
Databases → GMegatlon.Ventas → Tables → dbo.VentasParticionada
  → click derecho → Properties → Storage
```

---

## Resultado esperado

### Ejercicio 1 — Query caso de negocio
2 filas: Venta 1 (Estado 3, Juan Pérez) y Venta 2 (Estado 7, María González).
Las ventas 3 y 4 quedan excluidas por el filtro de estado y por ausencia en `PagosCaja`.

### Ejercicio 2 — Distribución de particiones

| NroParticion | DesdeInclusive | HastaExclusive | CantidadFilas |
|---|---|---|---|
| 1 | NULL | 2024-01-01 | 2 |
| 2 | 2024-01-01 | 2025-01-01 | 2 |
| 3 | 2025-01-01 | 2026-01-01 | 2 |
| 4 | 2026-01-01 | 2027-01-01 | 6 |
| 5 | 2027-01-01 | NULL | 0 |
