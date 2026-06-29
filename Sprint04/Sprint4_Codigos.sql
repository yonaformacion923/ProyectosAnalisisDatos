-- ============================================================
-- SPRINT 4 BIG QUERY AVANÇAT & ANALYTICS ENGINEERING — YONA MANRIQUEZ
-- Proyecto: sprint3-analytics-yonamanrique
-- ============================================================


-- ============================================================
-- NIVEL 1: ENTORNO E INGESTA HÍBRIDA (CODE-FIRST)
-- ============================================================


-- ------------------------------------------------------------
-- Ex. 1 — Consulta sobre Tabla no Optimizada (Diagnóstico)
-- El Country Manager de Alemania necesita revisar urgentemente
-- las transacciones del día 12 de marzo de 2022.
-- Tarea:
-- 1. Escribe la consulta que une (JOIN) transacciones y compañías.
-- 2. Filtra los resultados por la fecha indicada y el país "Germany".
-- 3. Sin ejecutar la consulta, realiza un "Dry Run" (auditoría de costos).
-- Dry Run: 11.64 MB procesados (Full Table Scan confirmado).
-- ------------------------------------------------------------

SELECT *
FROM `sprint3-analytics-yonamanrique.sprint3_silver.transactions_clean` t
JOIN `sprint3-analytics-yonamanrique.sprint3_silver.companies_clean` c
  ON t.business_id = c.company_id
WHERE c.country = 'Germany'
  AND DATE(t.timestamp) = '2022-03-12';


-- ------------------------------------------------------------
-- Ex. 2 — Re-arquitectura y Optimización del Almacenaje (Partition & Cluster)
-- Escenario: Full Table Scan confirmado en Ex.1. Se materializa una versión
-- optimizada de la tabla de hechos en la capa Gold.
-- Problema del sandbox: BigQuery borra particiones con más de 60 días.
-- Se resuelve en dos pasos: mocking de fechas recientes + optimización física.
--
-- Paso 1: Generación de Datos Recientes (Mocking Data)
-- Crear tabla intermedia sprint3_silver.transactions_recent con timestamps
-- aleatorios dentro de los últimos 50 días.
-- ------------------------------------------------------------

-- PASO 1: Mocking Data
CREATE OR REPLACE TABLE `sprint3-analytics-yonamanrique.sprint3_silver.transactions_recent`
AS
SELECT * EXCEPT(timestamp),
  TIMESTAMP_SUB(
    CURRENT_TIMESTAMP(),
    INTERVAL CAST(RAND() * 50 AS INT64) DAY
  ) AS timestamp
FROM `sprint3-analytics-yonamanrique.sprint3_silver.transactions_clean`;


-- ------------------------------------------------------------
-- Paso 2: Creación de la Tabla Optimizada (Partitioning & Clustering)
-- Crear tabla sprint3_gold.fact_transactions_optimized particionada por DAY
-- (campo timestamp) y clusterizada por business_id.
-- Se usa TIMESTAMP_TRUNC en lugar de DATE para mantener el tipo TIMESTAMP.
-- ------------------------------------------------------------

-- PASO 2: Tabla Optimizada
CREATE OR REPLACE TABLE `sprint3-analytics-yonamanrique.sprint3_gold.fact_transactions_optimized`
PARTITION BY TIMESTAMP_TRUNC(timestamp, DAY)
CLUSTER BY business_id
OPTIONS (
  description = 'Optimised transactions table, partitioned by date and clustered by business ID'
)
AS
SELECT *
FROM `sprint3-analytics-yonamanrique.sprint3_silver.transactions_recent`;


-- ------------------------------------------------------------
-- Ex. 3 — La Prueba del Algodón (Benchmark)
-- Escenario: Demostrar la mejora de rendimiento entre tabla no optimizada
-- y tabla optimizada. Petición de negocio: transacciones de los últimos 30 días.
-- NO ejecutar: solo usar el validador de BigQuery (Dry Run).
-- Tabla sin particionar: 11.63 MB | Tabla optimizada: 6.84 MB | Ahorro: 41.2%
-- ------------------------------------------------------------

-- PASO 1: Tabla no optimizada (Dry Run)
SELECT *
FROM `sprint3-analytics-yonamanrique.sprint3_silver.transactions_recent`
WHERE DATE(timestamp) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND CURRENT_DATE();

-- PASO 2: Tabla optimizada (Dry Run)
SELECT *
FROM `sprint3-analytics-yonamanrique.sprint3_gold.fact_transactions_optimized`
WHERE DATE(timestamp) BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND CURRENT_DATE();


-- ------------------------------------------------------------
-- Ex. 4 — Smart Caching (Vistas Materializadas)
-- Escenario: El Director General y 50 managers refrescan constantemente
-- un gráfico de Ventas Totales por Día. Una vista normal recalcula millones
-- de filas en cada refresco. La vista materializada guarda el resultado en
-- caché y solo lo actualiza si entran datos nuevos (incremental).
-- Resultado: SELECT * procesa 816 B (vs recalcular toda la tabla).
-- ------------------------------------------------------------

CREATE MATERIALIZED VIEW IF NOT EXISTS
  `sprint3-analytics-yonamanrique.sprint3_gold.mv_daily_sales`
AS
SELECT
  DATE(timestamp) AS fecha,
  SUM(amount) AS venta_diaria
FROM `sprint3-analytics-yonamanrique.sprint3_gold.fact_transactions_optimized`
GROUP BY DATE(timestamp);

-- Consulta de comprobación
SELECT *
FROM `sprint3-analytics-yonamanrique.sprint3_gold.mv_daily_sales`;


-- ============================================================
-- NIVEL 2: SQL ANALÍTICO AVANZADO
-- ============================================================


-- ------------------------------------------------------------
-- Ex. 1 — Perfilado de Clientes VIP (Métricas Agregadas con CTEs)
-- Escenario: El equipo de Marketing define "VIP" como gasto acumulado > 500€.
-- Necesitan: nombre, contacto, num_compras, ticket_medio, max_compra, total_gastado.
-- Tarea:
-- 1. CTE VIP_stats: SUM, COUNT, AVG, MAX por user_id. HAVING SUM > 500.
-- 2. JOIN con users_combined para obtener datos personales.
-- Nota: Se usa HAVING SUM(amount) > 500 (no el alias) porque BigQuery
-- no permite referenciar aliases en la cláusula HAVING.
-- ------------------------------------------------------------

WITH VIP_stats AS (
  SELECT
    user_id,
    ROUND(SUM(amount), 2) AS total_gastado,
    COUNT(*) AS num_compras,
    ROUND(AVG(amount), 2) AS ticket_medio,
    ROUND(MAX(amount), 2) AS max_compra
  FROM `sprint3-analytics-yonamanrique.sprint3_gold.fact_transactions_optimized`
  GROUP BY user_id
  HAVING SUM(amount) > 500
)
SELECT
  u.user_id,
  CONCAT(u.name, ' ', u.surname) AS nombre_completo,
  u.email,
  v.num_compras,
  v.ticket_medio,
  v.max_compra,
  v.total_gastado
FROM `sprint3-analytics-yonamanrique.sprint3_silver.users_combined` u
JOIN VIP_stats v ON u.user_id = v.user_id
ORDER BY v.total_gastado DESC;


-- ------------------------------------------------------------
-- Ex. 2 — Análisis de Tendencias (Window Functions sobre Vistas)
-- Escenario: La Dirección Financiera necesita comparar ventas de cada día
-- contra el día anterior (Day-over-Day Growth).
-- Estrategia: Usar mv_daily_sales en lugar de la tabla original para no
-- recalcular la suma de millones de filas en cada consulta.
-- Columnas: fecha, ventas_hoy, ventas_ayer, diff_percentual.
-- Se usa SAFE_DIVIDE para evitar error al dividir entre cero o null.
-- ------------------------------------------------------------

WITH daily_sales_temp AS (
  SELECT
    fecha,
    venta_diaria AS ventas_hoy,
    LAG(venta_diaria, 1) OVER (ORDER BY fecha) AS ventas_ayer
  FROM `sprint3-analytics-yonamanrique.sprint3_gold.mv_daily_sales`
)
SELECT
  fecha,
  ROUND(ventas_hoy, 2) AS ventas_hoy,
  ROUND(ventas_ayer, 2) AS ventas_ayer,
  ROUND(SAFE_DIVIDE(ventas_hoy - ventas_ayer, ventas_ayer) * 100, 2) AS diff_percentual
FROM daily_sales_temp
ORDER BY fecha DESC;


-- ------------------------------------------------------------
-- Ex. 3 — Totales Acumulados (Running Totales sobre Vistas)
-- Escenario: El CFO necesita visualizar la curva de crecimiento anual (YTD).
-- Columnas: fecha, ventas_del_dia, ventas_acumuladas_ytd.
-- La suma acumulada se reinicia cada 1 de enero con PARTITION BY EXTRACT(YEAR).
-- ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW define la ventana acumulada.
-- ORDER BY fecha ASC al final para presentación cronológica.
-- ------------------------------------------------------------

SELECT
  fecha,
  ROUND(venta_diaria, 2) AS ventas_del_dia,
  ROUND(
    SUM(venta_diaria) OVER (
      PARTITION BY EXTRACT(YEAR FROM fecha)
      ORDER BY fecha
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2
  ) AS ventas_acumuladas_ytd
FROM `sprint3-analytics-yonamanrique.sprint3_gold.mv_daily_sales`
ORDER BY fecha ASC;


-- ------------------------------------------------------------
-- Ex. 4 — Fidelización y Valor del Cliente (Filtraje Avanzado)
-- Escenario: Campaña "A la tercera va la vencida". Regalo a usuarios que
-- hayan completado su 3ª transacción. El presupuesto depende del ticket
-- medio de sus 3 primeras compras.
-- Columnas: user_id, nombre_completo, email, fecha_3a_compra,
--           monto_3a_compra, prom_3_compras.
-- Optimización: filtrar con QUALIFY <= 3 ANTES de calcular el AVG,
-- para que BigQuery procese 3 filas por usuario en lugar de todas.
-- ------------------------------------------------------------

WITH primeras_3_compras AS (
  SELECT
    user_id,
    timestamp,
    amount,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY timestamp) AS num_compra
  FROM `sprint3-analytics-yonamanrique.sprint3_gold.fact_transactions_optimized`
  QUALIFY num_compra <= 3
)
SELECT
  u.user_id,
  CONCAT(u.name, ' ', u.surname) AS nombre_completo,
  u.email,
  DATE(p.timestamp) AS fecha_3a_compra,
  p.amount AS monto_3a_compra,
  ROUND(AVG(p.amount) OVER (PARTITION BY p.user_id), 2) AS prom_3_compras
FROM primeras_3_compras p
JOIN `sprint3-analytics-yonamanrique.sprint3_silver.users_combined` u
  ON p.user_id = u.user_id
QUALIFY p.num_compra = 3;


-- ============================================================
-- NIVEL 3: ANALYTICS ENGINEERING (ARRAYS & AUTOMATIZACIÓN)
-- ============================================================


-- ------------------------------------------------------------
-- Ex. 1 — Desanidado y Aplanado de Datos (Unnesting)
-- Escenario: Los productos vendidos están dentro de un Array en la tabla
-- de transacciones. El equipo de ventas necesita una Flat Table donde
-- cada fila represente un producto vendido.
-- Pasos:
-- 1. CROSS JOIN UNNEST(product_ids) para transformar el Array en filas.
-- 2. JOIN con products_clean para obtener name y price.
-- Nota: product_ids es INT64 y product_id en products_clean es STRING
-- (decisión del Sprint 3). Por eso se usa CAST(flat_product_id AS STRING).
-- Resultado: 253,391 filas.
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE `sprint3-analytics-yonamanrique.sprint3_gold.dim_transactions_flat`
AS
SELECT
  t.transaction_id,
  DATE(t.timestamp) AS fecha,
  p.product_id,
  p.name,
  p.price
FROM `sprint3-analytics-yonamanrique.sprint3_gold.fact_transactions_optimized` t
CROSS JOIN UNNEST(t.product_ids) AS flat_product_id
JOIN `sprint3-analytics-yonamanrique.sprint3_silver.products_clean` p
  ON p.product_id = CAST(flat_product_id AS STRING);


-- ------------------------------------------------------------
-- Ex. 2 — El Ranking de Ventas (Agregación Simple)
-- Escenario: Generar el Top 5 de productos más vendidos en la historia
-- de la compañía a partir de la tabla desnormalizada dim_transactions_flat.
-- GROUP BY por product_id Y name para evitar fusión incorrecta de productos
-- distintos con el mismo nombre.
-- ------------------------------------------------------------

SELECT
  product_id,
  name,
  COUNT(*) AS sold_units
FROM `sprint3-analytics-yonamanrique.sprint3_gold.dim_transactions_flat`
GROUP BY product_id, name
ORDER BY sold_units DESC
LIMIT 5;


-- ------------------------------------------------------------
-- Ex. 3 — Automatización del Pipeline y Visualización
-- Escenario: El Director de Marketing necesita precio con IVA (21%)
-- sin hardcodear el cálculo. Se crea una UDF reutilizable.
-- El tablero debe actualizarse automáticamente cada día a las 07:00 AM.
--
-- Paso 1: UDF calculate_tax
-- Recibe un precio FLOAT64 y devuelve el precio con 21% de IVA, redondeado a 2 decimales.
-- ------------------------------------------------------------

-- PASO 1: Creación de la UDF
CREATE OR REPLACE FUNCTION
  `sprint3-analytics-yonamanrique.sprint3_gold.calculate_tax`(price FLOAT64)
RETURNS FLOAT64
AS (ROUND(price * 1.21, 2));


-- ------------------------------------------------------------
-- Paso 2: Recreación de dim_transactions_flat con columna product_price_tax_inc
-- Se usa la UDF calculate_tax para calcular el precio con IVA.
-- Se añade también la columna fecha (DATE) necesaria para Looker Studio.
-- ------------------------------------------------------------

-- PASO 2: Tabla actualizada con UDF
CREATE OR REPLACE TABLE `sprint3-analytics-yonamanrique.sprint3_gold.dim_transactions_flat`
AS
SELECT
  t.transaction_id,
  DATE(t.timestamp) AS fecha,
  p.product_id,
  p.name,
  p.price,
  `sprint3-analytics-yonamanrique.sprint3_gold.calculate_tax`(p.price) AS product_price_tax_inc
FROM `sprint3-analytics-yonamanrique.sprint3_gold.fact_transactions_optimized` t
CROSS JOIN UNNEST(t.product_ids) AS flat_product_id
JOIN `sprint3-analytics-yonamanrique.sprint3_silver.products_clean` p
  ON p.product_id = CAST(flat_product_id AS STRING);


-- ------------------------------------------------------------
-- Paso 3: Scheduled Query
-- La Scheduled Query se configuró desde la UI de BigQuery con los siguientes
-- parámetros: nombre "Daily Product Report Query", frecuencia diaria, 07:00 UTC.
-- No se pudo guardar por limitación del sandbox (cuenta sin facturación).
-- Captura de pantalla tomada como evidencia (igual que Jorge).
-- ------------------------------------------------------------


-- ------------------------------------------------------------
-- Paso 4: Looker Studio — Dashboard "Monitor de Rendimiento de Ventas"
-- Fuente de datos: sprint3-analytics-yonamanrique.sprint3_gold.dim_transactions_flat
-- Sección 1 — KPIs (Scorecards):
--   KPI 1: SUM(product_price_tax_inc) → "Ingresos Totales (con IVA)"
--   KPI 2: COUNT_DISTINCT(transaction_id) → "Transacciones Únicas (Pedidos)"
--   KPI 3: Campo calculado: SUM(product_price_tax_inc) / COUNT_DISTINCT(transaction_id)
--          → "Ticket Promedio (ingreso por pedido)"
-- Sección 2 — Gráfico de series temporales:
--   Dimensión: fecha | Métrica: SUM(product_price_tax_inc)
--   Línea de tendencia lineal activada.
-- Sección 3 — Tabla con mapa de calor:
--   Dimensión: name
--   Métrica 1: COUNT(*) → "Unidades Vendidas" (con mapa de calor)
--   Métrica 2: SUM(product_price_tax_inc) → "Ingresos Totales" (con barras)
--   Métrica 3: Campo calculado: SUM(product_price_tax_inc) - SUM(price)
--              → "IVA Recaudado"
-- Link: https://datastudio.google.com/reporting/7c496a69-7186-4c3f-b129-6deca1a007f5
-- ------------------------------------------------------------
