-- ============================================================
-- SPRINT 3 BIG QUERY — YONA MANRIQUEZ
-- Proyecto: sprint3-analytics-yonamanrique
-- ============================================================


-- ============================================================
-- NIVEL 1: ENTORNO E INGESTA HÍBRIDA
-- ============================================================


-- ------------------------------------------------------------
-- Ex. 1 — Arquitectura de Datos: Dataset Silver (SQL)
-- Bronze se creó por UI y Gold por Cloud Shell.
-- ------------------------------------------------------------

CREATE SCHEMA `sprint3-analytics-yonamanrique.sprint3_silver`
OPTIONS (
  description = 'Silver: datos limpios',
  location = 'EU'
);

-- Gold se creó desde Cloud Shell con el comando:
-- bq --location=EU mk --dataset --description="Gold: datos de negocio" sprint3-analytics-yonamanrique:sprint3_gold


-- ------------------------------------------------------------
-- Ex. 2 — Ingesta en Capa Bronze: 5 Tablas Externas
-- Esquema definido manualmente para evitar errores de autodetect.
-- ------------------------------------------------------------

-- transactions_raw
CREATE EXTERNAL TABLE `sprint3-analytics-yonamanrique.sprint3_bronze.transactions_raw`
(
  id STRING,
  card_id STRING,
  business_id STRING,
  timestamp TIMESTAMP,
  amount FLOAT64,
  declined INT64,
  product_ids STRING,
  user_id STRING,
  lat FLOAT64,
  longitude FLOAT64
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/transactions.csv'],
  skip_leading_rows = 1,
  field_delimiter = ';'
);

-- companies_raw
CREATE EXTERNAL TABLE `sprint3-analytics-yonamanrique.sprint3_bronze.companies_raw`
(
  company_id STRING,
  company_name STRING,
  phone STRING,
  email STRING,
  country STRING,
  website STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/ERP/companies.csv'],
  skip_leading_rows = 1
);

-- american_users_raw
CREATE EXTERNAL TABLE `sprint3-analytics-yonamanrique.sprint3_bronze.american_users_raw`
(
  id STRING,
  name STRING,
  surname STRING,
  phone STRING,
  email STRING,
  birth_date STRING,
  country STRING,
  city STRING,
  postal_code STRING,
  address STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/american_users.csv'],
  skip_leading_rows = 1
);

-- european_users_raw
CREATE EXTERNAL TABLE `sprint3-analytics-yonamanrique.sprint3_bronze.european_users_raw`
(
  id STRING,
  name STRING,
  surname STRING,
  phone STRING,
  email STRING,
  birth_date STRING,
  country STRING,
  city STRING,
  postal_code STRING,
  address STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/european_users.csv'],
  skip_leading_rows = 1
);

-- credit_cards_raw
CREATE EXTERNAL TABLE `sprint3-analytics-yonamanrique.sprint3_bronze.credit_cards_raw`
(
  id STRING,
  user_id STRING,
  iban STRING,
  pan STRING,
  pin STRING,
  cvv STRING,
  track1 STRING,
  track2 STRING,
  expiring_date STRING
)
OPTIONS (
  format = 'CSV',
  uris = ['gs://bootcamp-data-analytics-public/CRM/credit_cards.csv'],
  skip_leading_rows = 1
);


-- ------------------------------------------------------------
-- Ex. 3 — Carga de Datos Locales (products_raw)
-- Realizado desde la UI de BigQuery subiendo el fichero products.csv.
-- No hay código SQL para este ejercicio.
-- ------------------------------------------------------------


-- ------------------------------------------------------------
-- Ex. 4a — Materialización: transactions_raw_native
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE `sprint3-analytics-yonamanrique.sprint3_bronze.transactions_raw_native`
AS
SELECT * FROM `sprint3-analytics-yonamanrique.sprint3_bronze.transactions_raw`;


-- ------------------------------------------------------------
-- Ex. 4b — Auditoría de Costos
-- Resultado: externa 12.61 MB procesados, nativa 3.62 MB (3.5x menos).
-- ------------------------------------------------------------

-- Tabla externa
SELECT id FROM `sprint3-analytics-yonamanrique.sprint3_bronze.transactions_raw`;

-- Tabla nativa
SELECT id FROM `sprint3-analytics-yonamanrique.sprint3_bronze.transactions_raw_native`;


-- ------------------------------------------------------------
-- Ex. 4c — El Peligro del LIMIT
-- ------------------------------------------------------------

-- Con LIMIT
SELECT * FROM `sprint3-analytics-yonamanrique.sprint3_bronze.transactions_raw_native` LIMIT 10;

-- Sin LIMIT (mismo coste)
SELECT * FROM `sprint3-analytics-yonamanrique.sprint3_bronze.transactions_raw_native`;


-- ------------------------------------------------------------
-- Ex. 5 — Top 5 Días con Más Ingresos (2021)
-- ------------------------------------------------------------

SELECT
  DATE(timestamp) AS fecha,
  ROUND(SUM(amount), 2) AS total_vendido
FROM `sprint3-analytics-yonamanrique.sprint3_bronze.transactions_raw_native`
WHERE EXTRACT(YEAR FROM timestamp) = 2021
GROUP BY fecha
ORDER BY total_vendido DESC
LIMIT 5;


-- ------------------------------------------------------------
-- Ex. 6 — Consultas Complejas: Cruce de Datos
-- ------------------------------------------------------------

SELECT
  c.company_name AS nombre_empresa,
  c.country AS pais,
  DATE(t.timestamp) AS fecha_transaccion,
  ROUND(t.amount, 2) AS monto
FROM `sprint3-analytics-yonamanrique.sprint3_bronze.companies_raw` c
JOIN `sprint3-analytics-yonamanrique.sprint3_bronze.transactions_raw` t
  ON c.company_id = t.business_id
WHERE t.amount BETWEEN 100 AND 200
  AND DATE(t.timestamp) IN ('2015-04-29', '2018-07-20', '2024-03-13')
ORDER BY t.amount DESC;


-- ============================================================
-- NIVEL 2: LIMPIEZA Y TRANSFORMACIÓN (ELT)
-- ============================================================


-- ------------------------------------------------------------
-- Ex. 1 — Limpieza de Productos (products_clean)
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE `sprint3-analytics-yonamanrique.sprint3_silver.products_clean`
AS
SELECT
  CAST(id AS STRING) AS product_id,
  product_name AS name,
  colour,
  weight,
  CAST(REGEXP_EXTRACT(warehouse_id, r'(\d+)') AS INT64) AS warehouse_id,
  CAST(REGEXP_REPLACE(CAST(price AS STRING), r'[^0-9.]', '') AS FLOAT64) AS price
FROM `sprint3-analytics-yonamanrique.sprint3_bronze.products_raw`;


-- ------------------------------------------------------------
-- Ex. 2 — Transacciones Limpias (transactions_clean)
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE `sprint3-analytics-yonamanrique.sprint3_silver.transactions_clean`
AS
SELECT
  id AS transaction_id,
  card_id,
  business_id,
  CAST(timestamp AS TIMESTAMP) AS timestamp,
  IFNULL(SAFE_CAST(amount AS FLOAT64), 0) AS amount,
  declined,
  ARRAY(
    SELECT CAST(x AS INT64)
    FROM UNNEST(SPLIT(product_ids, ', ')) AS x
  ) AS product_ids,
  user_id,
  SAFE_CAST(lat AS FLOAT64) AS lat,
  SAFE_CAST(longitude AS FLOAT64) AS longitude
FROM `sprint3-analytics-yonamanrique.sprint3_bronze.transactions_raw`;


-- ------------------------------------------------------------
-- Ex. 3 — Unificación de Usuarios (users_combined)
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE `sprint3-analytics-yonamanrique.sprint3_silver.users_combined`
AS
SELECT
  id AS user_id,
  name, surname, phone, email, birth_date,
  country, city, postal_code, address,
  'America' AS origin
FROM `sprint3-analytics-yonamanrique.sprint3_bronze.american_users_raw`
WHERE id != 'id'

UNION ALL

SELECT
  id AS user_id,
  name, surname, phone, email, birth_date,
  country, city, postal_code, address,
  'Europe' AS origin
FROM `sprint3-analytics-yonamanrique.sprint3_bronze.european_users_raw`
WHERE id != 'id';


-- ------------------------------------------------------------
-- Ex. 4 — Materialización: companies_clean y credit_cards_clean
-- ------------------------------------------------------------

-- companies_clean
CREATE OR REPLACE TABLE `sprint3-analytics-yonamanrique.sprint3_silver.companies_clean`
AS
SELECT
  company_id,
  company_name AS name,
  phone, email, country, website
FROM `sprint3-analytics-yonamanrique.sprint3_bronze.companies_raw`;

-- credit_cards_clean
CREATE OR REPLACE TABLE `sprint3-analytics-yonamanrique.sprint3_silver.credit_cards_clean`
AS
SELECT
  id AS credit_card_id,
  user_id, iban, pan, pin, cvv,
  track1, track2, expiring_date
FROM `sprint3-analytics-yonamanrique.sprint3_bronze.credit_cards_raw`;


-- ============================================================
-- NIVEL 3: PRESENTACIÓN DE DATOS Y CREACIÓN DE VISTAS
-- ============================================================


-- ------------------------------------------------------------
-- Ex. 1 — Vista de Marketing KPIs (v_marketing_kpis)
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW `sprint3-analytics-yonamanrique.sprint3_gold.v_marketing_kpis`
AS
SELECT
  c.name,
  c.phone,
  c.country,
  ROUND(AVG(t.amount), 2) AS avg_amount,
  CASE
    WHEN AVG(t.amount) > 260 THEN 'Premium'
    ELSE 'Standard'
  END AS client_tier
FROM `sprint3-analytics-yonamanrique.sprint3_silver.companies_clean` c
LEFT JOIN `sprint3-analytics-yonamanrique.sprint3_silver.transactions_clean` t
  ON c.company_id = t.business_id
GROUP BY c.name, c.phone, c.country;

-- SELECT sobre la vista
SELECT *
FROM `sprint3-analytics-yonamanrique.sprint3_gold.v_marketing_kpis`
ORDER BY avg_amount DESC;


-- ------------------------------------------------------------
-- Ex. 2 — Ranking de Productos (product_sales_ranking)

-- ------------------------------------------------------------

CREATE OR REPLACE TABLE `sprint3-analytics-yonamanrique.sprint3_gold.product_sales_ranking`
AS
WITH product_sales AS (
  SELECT transaction_id, product_id
  FROM `sprint3-analytics-yonamanrique.sprint3_silver.transactions_clean`,
  UNNEST(product_ids) AS product_id
)
SELECT
  p.product_id,
  p.name,
  p.price,
  p.colour,
  COUNT(ps.transaction_id) AS total_sold
FROM `sprint3-analytics-yonamanrique.sprint3_silver.products_clean` AS p
LEFT JOIN product_sales AS ps ON ps.product_id = p.product_id
GROUP BY p.product_id, p.name, p.price, p.colour
ORDER BY total_sold DESC;

-- SELECT para exportar resultados
SELECT *
FROM `sprint3-analytics-yonamanrique.sprint3_gold.product_sales_ranking`;


-- ------------------------------------------------------------
-- Ex. 3 — Exportación de Resultados
-- No hay código. Se descarga el resultado del SELECT
-- ------------------------------------------------------------
