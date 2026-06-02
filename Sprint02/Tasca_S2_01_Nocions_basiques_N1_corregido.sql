
-- Crear la base de datos 
CREATE DATABASE IF NOT EXISTS transaction;

USE transactions;

/*=======================================================================================================================
Ejercicio 1
A partir de los documentos adjuntos (estructura_datos y datos_introducir), importa las dos tablas. 
Muestra las principales características del esquema creado y explica las diferentes tablas y 
variables que existen. Asegúrate de incluir un diagrama que ilustre la relación entre las diferentes tablas y variables
============================================================================================================================*/

 -- Creamos la tabla company
    CREATE TABLE IF NOT EXISTS company (
        id VARCHAR(15) PRIMARY KEY,
        company_name VARCHAR(255),
        phone VARCHAR(15),
        email VARCHAR(100),
        country VARCHAR(100),
        website VARCHAR(255)
    );
    
    -- Creamos la tabla transaction
	-- La tabla al crearla, se olvido aplicar las buenas prácticas, colocar los contrains al final, es por ello  que se borró y se volvio a crear

  DROP TABLE IF EXISTS transaction;

	CREATE TABLE IF NOT EXISTS transaction (
		id VARCHAR(255),
		credit_card_id VARCHAR(15),
		company_id VARCHAR(20), 
		user_id INT,
		lat FLOAT,
		longitude FLOAT,
		timestamp TIMESTAMP,
		amount DECIMAL(10, 2),
		declined BOOLEAN,
    
    CONSTRAINT pk_transaction PRIMARY KEY (id),
    CONSTRAINT fk_transaction_credit_card FOREIGN KEY (credit_card_id) REFERENCES credit_card(id),
    CONSTRAINT fk_transaction_user FOREIGN KEY (user_id) REFERENCES user(id),
    CONSTRAINT fk_transaction_company FOREIGN KEY (company_id) REFERENCES company(id)
);


-- Aanlizando la estructura de la tabla company
DESCRIBE company;

-- Ver registros
SELECT count(*)
FROM company;

-- Aanlizando la estructura de la tabla transaction
DESCRIBE transaction;

-- Ver registros
SELECT count(*)
FROM transaction;

-- Verificar sus relaciones
-- Esquema en el pdf

SHOW CREATE TABLE company;
SHOW CREATE TABLE transaction;

-- Creamos la tabla credit_card

	CREATE TABLE IF NOT EXISTS credit_card(
		id VARCHAR(15) PRIMARY KEY,
		iban VARCHAR(50),
		pan VARCHAR(20),
		pin VARCHAR(10),
		cvv VARCHAR(5),
		expiring_date VARCHAR(10)
	);

-- Creamos la tabla user
CREATE TABLE IF NOT EXISTS user (
    id INT PRIMARY KEY,
    name VARCHAR(100),
    surname VARCHAR(100),
    phone VARCHAR(50),
    email VARCHAR(100),
    birth_date DATE,
    country VARCHAR(100),
    city VARCHAR(15),
    postal_code VARCHAR(15),
    address VARCHAR(100),
    signup_date DATE,
    user_segment VARCHAR(50),
    income_band VARCHAR(15)
);

-- Verificar que todas las tabls existan
SHOW TABLES;


/*
========================================================================================
Ejercicio 2
Utilizando JOIN realizarás las siguientes consultas:
========================================================================================*/

-- 2.1 Listado de paises

SELECT DISTINCT c.country AS paises_operadores
FROM company c
JOIN transaction t
ON t.company_id = c.id
WHERE declined = 0;

-- 2.2 Desde cuántos países se generen las ventas.
SELECT COUNT(DISTINCT c.country) AS TotL_paises_operan
FROM company c
JOIN transaction t
ON t.company_id = c.id
WHERE declined = 0;

-- 2.3  Compañia con mayor media de ventas

SELECT c.company_name, 
ROUND(AVG(t.amount),3) AS media_ventas
FROM company c
JOIN transaction t
ON t.company_id = c.id
WHERE declined = 0
GROUP BY c.company_name, c.id
ORDER BY AVG(t.amount) DESC
LIMIT 1;

/*========================================================================================================================
Ejercicio 3. Utilizando sólo subconsultas (sin utilizar JOIN):

Muestra todas las transacciones realizadas por empresas de Alemania.
Lista las empresas que han realizado transacciones por un amount superior a 
la media de todas las transacciones.
Eliminarán del sistema las empresas que carecen de transacciones 
registradas, entrega el listado de estas empresas.
=============================================================================================================================*/

-- 3.1 Muestra todas las transacciones realizadas por empresas de Alemania.
SELECT id, credit_card_id, company_id
FROM transaction t
WHERE declined = 0
AND EXISTS  (
	SELECT id
	FROM company C
	WHERE c.id = t.company_id
    AND country = 'Germany');

-- 3.2 Lista las empresas que han realizado transacciones por un amount superior a la media de todas las transacciones.

SELECT DISTINCT company_name AS nombre_empresa
FROM company c
WHERE EXISTS (
	SELECT company_id
	FROM transaction t
	WHERE t.company_id = c.id
	GROUP BY company_id
	HAVING AVG(amount) > (SELECT AVG(amount) FROM transaction
    WHERE declined = 0)
);

-- 3.3 Eliminarán del sistema las empresas que carecen de transacciones registradas, entrega el listado de estas empresas.

SELECT company_name
FROM company c
WHERE NOT EXISTS (
	SELECT company_id
	FROM transaction t
	WHERE c.id = t.company_id
    AND declined = 1);

-- Comprobar
SELECT COUNT(*) 
FROM transaction 
WHERE company_id IS NULL;

/* ============================================================================================================================
Ejercicio 4
Tu tarea es diseñar y crear una tabla llamada "credit_card" que almacene detalles cruciales sobre las tarjetas de crédito.
 La nueva tabla debe ser capaz de identificar de forma única cada tarjeta y establecer una relación adecuada 
 con las otras dos tablas ("transaction" y "company"). Después de crear la tabla será necesario que ingreses 
 la información del documento denominado "datos_introducir_credit". 
Recuerda mostrar el diagrama y realizar una breve descripción del mismo.
================================================================================================================================*/

-- Se diseñó desde el ejercicio 1

CREATE TABLE IF NOT EXISTS credit_card(
		id VARCHAR(15) PRIMARY KEY,
		iban VARCHAR(50),
		pan VARCHAR(25),
		pin CHAR(4),
		cvv CHAR(3),
		expiring_date VARCHAR(20)
	);

-- Ejecutar dades_introduir_credit.sql

-- Verificación de la cárga de datos
SELECT * FROM credit_card
LIMIT 10;

-- Verificando la estructura de las fechas
SELECT expiring_date FROM credit_card
LIMIT 10;

-- Cambio de VRACHAR A DATE
UPDATE credit_card
SET expiring_date = STR_TO_DATE(expiring_date, '%m/%d/%y')
WHERE id IS NOT NULL
LIMIT 9999999999;

-- Comprobación de datos una vez hecho la conversion
SELECT * FROM credit_card
LIMIT 100;

SELECT COUNT(*)
FROM credit_card
WHERE expiring_date IS NULL;

SELECT expiring_date FROM credit_card LIMIT 5;

-- Cambio del tipo de columna a DATE
ALTER TABLE credit_card
MODIFY expiring_date DATE;

-- Revisión de la estructura de tablas

SHOW CREATE TABLE transaction;
SHOW CREATE TABLE credit_card;
SHOW CREATE TABLE company;

-- Diagram en el PDF Consultes_Tasca_Sprint2_N1.pdf

/* ========================================================================================================================================================================================================
Ejercicio 5
El departamento de Recursos Humanos ha identificado un error en el número de cuenta asociado a su tarjeta de crédito con ID CcU-2938. La información que debe mostrarse para este registro es: 
TR323456312213576817699999. Recuerda mostrar que el cambio se realizó
=============================================================================================================================================================================================================*/



-- Modificación de datos asociados a credit_card
UPDATE credit_card
SET iban = 'TR323456312213576817699999'
WHERE id = 'CcU-2938';

-- Comprobación
SELECT iban
FROM credit_card
WHERE id = 'CcU-2938';


/*
===================================================================================================
Ejercicio 6 En la tabla "transaction" ingresa una nueva transacción con la siguiente información
====================================================================================================*/

-- Los valores CcU-9999, b-9999 y 9999 no existen en sus tablas padre.
-- Para respetar la integridad referencial, los insertamos primero en sus tablas padre
-- antes de poder insertar la transacción.

INSERT INTO credit_card (id, iban, pin, cvv, expiring_date)
VALUES ('CcU-9999', NULL, NULL, NULL, NULL);

INSERT INTO company (id, company_name, phone, email, country, website)
VALUES ('b-9999', NULL, NULL, NULL, NULL, NULL);

INSERT INTO user (id, name, surname, phone, email, birth_date, country, city, postal_code, address, signup_date, user_segment, income_band)
VALUES (9999, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- Eliminamos la entrada si ya existe de un intento anterior
DELETE FROM transaction
WHERE id = '108B1D1D-5B23-A76C-55EF-C568E49A99DD';


INSERT INTO transaction (id, credit_card_id, company_id, user_id, lat, longitude, timestamp, amount, declined)
VALUES ('108B1D1D-5B23-A76C-55EF-C568E49A99DD', 'CcU-9999', 'b-9999', 9999, 829.999, -117.999, NULL, 111.11, 0);

-- Comporbamos que este
SELECT * FROM transaction
WHERE id = '108B1D1D-5B23-A76C-55EF-C568E49A99DD';


/*
============================================================================================
Ejercicio 7
Desde recursos humanos te solicitan eliminar la columna "pan" de la tabla credit_card. 
Recuerda mostrar el cambio realizado.
=============================================================================================*/


ALTER TABLE credit_card
DROP COLUMN pan;

SELECT * FROM credit_card;

/*Ejercicio 8
Estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui, almenys 4 taules de les
 quals puguis realitzar les següents consultes:
 N1-Ex.8__american_users.csv
N1-Ex.8__companies.csv N1-Ex.8__companies.csv
N1-Ex.8__credit_cards.csv N1-Ex.8__credit_cards.csv
N1-Ex.8__european_users.csv N1-Ex.8__european_users.csv
N1-Ex.8__products.csv N1-Ex.8__products.csv
N1-Ex.8__transactions.csv N1-Ex.8__transactions.csv
La taula de products.csv l'utilitzarem més endavant.*/

-- 8.1 Creación de una base de datos nueva para poder crear el diagrama estrella y no haya
-- solapamiento con las tablas ya ceadas
CREATE DATABASE IF NOT EXISTS operations;
USE operations;

-- 8.2 Creación de tablas temporales para poder vaciar los datos mas fácil como los de fecha y decimales
-- ponemos todo como VARCHAR para que no haya errores desde el inicio


-- Tabla temporal para companies
DROP TABLE IF EXISTS tmp_companies;

CREATE TABLE tmp_companies (
    id VARCHAR(20),
    company_name VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(255),
    country VARCHAR(100),
    website VARCHAR(255),
    merchant_category VARCHAR(100),
    merchant_price_position VARCHAR(50)
);


-- Tabla temporal para american_users

CREATE TABLE tmp_american_users (
    id VARCHAR(20),
    name VARCHAR(255),
    surname VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(255),
    birth_date VARCHAR(30),
    country VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    address VARCHAR(255),
    signup_date VARCHAR(20),
    user_segment VARCHAR(50),
    income_band VARCHAR(20)
);

CREATE TABLE tmp_european_users (
    id VARCHAR(20),
    name VARCHAR(255),
    surname VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(255),
    birth_date VARCHAR(30),
    country VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    address VARCHAR(255),
    signup_date VARCHAR(20),
    user_segment VARCHAR(50),
    income_band VARCHAR(20)
);

CREATE TABLE tmp_credit_cards (
    id VARCHAR(20),
    user_id VARCHAR(20),
    iban VARCHAR(50),
    pan VARCHAR(50),
    pin VARCHAR(10),
    cvv VARCHAR(10),
    track1 VARCHAR(255),
    track2 VARCHAR(255),
    expiring_date VARCHAR(20),
    card_type VARCHAR(20),
    card_renewal_flag VARCHAR(5)
);

DROP TABLE IF EXISTS tmp_transactions;

CREATE TABLE tmp_transactions (
    id VARCHAR(100),
    card_id VARCHAR(20),
    business_id VARCHAR(20),
    timestamp VARCHAR(30),
    amount VARCHAR(20),
    declined VARCHAR(10),
    product_ids VARCHAR(255),
    user_id VARCHAR(20),
    lat VARCHAR(30),
    longitude VARCHAR(30),
    discount_amount VARCHAR(20),
    tax_amount VARCHAR(20),
    shipping_amount VARCHAR(20),
    channel VARCHAR(20),
    campaign_id VARCHAR(50),
    device_type VARCHAR(20),
    is_international VARCHAR(5),
    decline_reason VARCHAR(100),
    distance_km VARCHAR(20)
);

-- Me equivoque en las columnas
DROP TABLE IF EXISTS tmp_american_users;
DROP TABLE IF EXISTS tmp_european_users;
DROP TABLE IF EXISTS tmp_credit_cards;
DROP TABLE IF EXISTS tmp_transactions;

-- 8.3 Cargar los datos desde los archivos del ordenador
-- Importante: Cambiar esta ruta por la carpeta Uploads de MySQL
-- Ejecutar primero: SHOW VARIABLES LIKE 'secure_file_priv';

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.6/Uploads/N1-Ex.8__companies.csv'
INTO TABLE tmp_companies
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.6/Uploads/N1-Ex.8__american_users.csv'
INTO TABLE tmp_american_users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.6/Uploads/N1-Ex.8__european_users.csv'
INTO TABLE tmp_european_users
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.6/Uploads/N1-Ex.8__credit_cards.csv'
INTO TABLE tmp_credit_cards
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 9.6/Uploads/N1-Ex.8__transactions.csv'
INTO TABLE tmp_transactions
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- 8.4 Crear las Tablas definitivas

CREATE TABLE companies (
    company_id VARCHAR(20) PRIMARY KEY,
    company_name VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(255),
    country VARCHAR(100),
    website VARCHAR(255),
    merchant_category VARCHAR(100),
    merchant_price_position VARCHAR(50)
);

CREATE TABLE users (
    user_key INT AUTO_INCREMENT PRIMARY KEY,
    source_user_id VARCHAR(20),
    name VARCHAR(255),
    surname VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(255),
    birth_date DATE,
    country VARCHAR(100),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    address VARCHAR(255),
    signup_date DATE,
    user_segment VARCHAR(50),
    income_band VARCHAR(20),
    continent VARCHAR(20)
);

CREATE TABLE credit_cards (
    id VARCHAR(20) PRIMARY KEY,
    user_id INT,
    iban VARCHAR(50),
    pan VARCHAR(50),
    pin VARCHAR(10),
    cvv VARCHAR(10),
    track1 VARCHAR(255),
    track2 VARCHAR(255),
    expiring_date DATE,
    card_type VARCHAR(20),
    card_renewal_flag TINYINT
);

CREATE TABLE transactions (
    id VARCHAR(100) PRIMARY KEY,
    card_id VARCHAR(20),
    business_id VARCHAR(20),
    timestamp DATETIME,
    amount DECIMAL(10,2),
    declined TINYINT,
    product_ids VARCHAR(255),
    user_id INT,
    lat DECIMAL(18,15),
    longitude DECIMAL(18,15),
    discount_amount DECIMAL(10,2),
    tax_amount DECIMAL(10,2),
    shipping_amount DECIMAL(10,2),
    channel VARCHAR(20),
    campaign_id VARCHAR(50),
    device_type VARCHAR(20),
    is_international TINYINT,
    decline_reason VARCHAR(100),
    distance_km DECIMAL(10,2)
);

-- 8.5 Transferencia de datos a las tablas definitivas

-- Companies
INSERT INTO companies
SELECT * FROM tmp_companies;

-- Users (americanos + europeos juntos)
INSERT INTO users (source_user_id, name, surname, phone, email, birth_date, country, city, postal_code, address, signup_date, user_segment, income_band, continent)
SELECT id, name, surname, phone, email, STR_TO_DATE(birth_date, '%b %d, %Y'), country, city, postal_code, address, signup_date, user_segment, income_band, 'America'
FROM tmp_american_users
UNION ALL
SELECT id, name, surname, phone, email, STR_TO_DATE(birth_date, '%b %d, %Y'), country, city, postal_code, address, signup_date, user_segment, income_band, 'Europe'
FROM tmp_european_users;

-- Credit cards
INSERT INTO credit_cards (id, user_id, iban, pan, pin, cvv, track1, track2, expiring_date, card_type, card_renewal_flag)
SELECT id, user_id, iban, pan, pin, cvv, track1, track2, STR_TO_DATE(expiring_date, '%m/%d/%y'), card_type, card_renewal_flag
FROM tmp_credit_cards;

-- Transactions
INSERT INTO transactions
SELECT id, card_id, business_id, timestamp, amount, declined, product_ids, user_id, lat, longitude, discount_amount, tax_amount, shipping_amount, channel, campaign_id, device_type, is_international, decline_reason, distance_km
FROM tmp_transactions;

-- Error en decimales, por eso lo cambie a DOUBLE
ALTER TABLE transactions 
MODIFY COLUMN lat DOUBLE,
MODIFY COLUMN longitude DOUBLE;


-- 8.6 Crear la tabla de date para crear la realcion estrella que pide el ejercicio
-- para no calcular 
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE,
    day INT,
    month INT,
    month_name VARCHAR(20),
    quarter INT,
    year INT,
    weekday_number INT,
    weekday_name VARCHAR(20),
    is_weekend TINYINT
);

INSERT INTO dim_date
SELECT
    DATE_FORMAT(full_date, '%Y%m%d') AS date_key,
    full_date,
    DAY(full_date) AS day,
    MONTH(full_date) AS month,
    MONTHNAME(full_date) AS month_name,
    QUARTER(full_date) AS quarter,
    YEAR(full_date) AS year,
    WEEKDAY(full_date) AS weekday_number,
    DAYNAME(full_date) AS weekday_name,
    IF(WEEKDAY(full_date) >= 5, 1, 0) AS is_weekend
FROM (
    SELECT ADDDATE('2010-01-01', t) AS full_date
    FROM (
        SELECT ones.n + tens.n * 10 + hundreds.n * 100 + thousands.n * 1000 AS t
        FROM
            (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) ones,
            (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) tens,
            (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) hundreds,
            (SELECT 0 AS n UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) thousands
    ) numbers
    WHERE ADDDATE('2010-01-01', t) <= '2030-12-31'
) dates;

-- 8.7 Crear claves foráneas para garantizar la integridad de la referencia de los datos

-- Creamos un indice porque me daba error al referenciar user_id en transaction y 
-- al añadirlo asi aseguramos que existe por si  MYSQL no lo crea desde el inicio

CREATE INDEX idx_transactions_user_id ON transactions(user_id);

ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_card
FOREIGN KEY (card_id) REFERENCES credit_cards(id);

ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_business
FOREIGN KEY (business_id) REFERENCES companies(company_id);

ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_user
FOREIGN KEY (user_id) REFERENCES users(user_key);

-- transactions -> dim_date
-- Añadir la columna que al principio no se creó
ALTER TABLE transactions
ADD COLUMN date_key INT;

-- Rellenarla a partir del timestamp
UPDATE transactions
SET date_key = DATE_FORMAT(timestamp, '%Y%m%d')
WHERE id != '';

-- Crear la FK de dim_date
ALTER TABLE transactions
ADD CONSTRAINT fk_transactions_date
FOREIGN KEY (date_key) REFERENCES dim_date(date_key);

-- Verificación de todas las FK
SELECT * FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_NAME = 'transactions'
AND TABLE_SCHEMA = 'operations';


-- 8.8 Borrar tablas temporales

DROP TABLE tmp_companies;
DROP TABLE tmp_american_users;
DROP TABLE tmp_european_users;
DROP TABLE tmp_credit_cards;
DROP TABLE tmp_transactions;


-- ver las calves foráneas. Asi nos aseguramos que existen
SELECT CONSTRAINT_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_NAME = 'transactions'
AND TABLE_SCHEMA = 'operations'
AND REFERENCED_TABLE_NAME IS NOT NULL;

-- El diagrama se encuentra en el PDF Consultes_Tasca_Sprint2_N1.pdf

/*=======================================================================================
Ejercicio 9
Realiza una subconsulta que muestre a todos los usuarios con 
más de 80 transacciones utilizando al menos 2 tablas.
==========================================================================================*/
USE operations;

SELECT * FROM users u
WHERE EXISTS (
SELECT user_id
FROM transactions t
WHERE t.user_id = u.user_key
GROUP BY user_id
HAVING COUNT(user_id)>80);

/*================================================================================================
Ejercicio 10
Muestra la media de amount por IBAN de las tarjetas de crédito en la compañía Donec Ltd., 
utiliza por lo menos 2 tablas.
=================================================================================================*/

USE operations;

SELECT cd.iban, c.company_name, AVG(t.amount) AS media_cantidad
FROM transactions t
JOIN credit_cards cd
ON t.card_id = cd.id
JOIN companies c
ON t.business_id = c.company_id
WHERE c.company_name = 'Donec Ltd'
GROUP BY cd.iban;

/*=====================================================================================================
-- Nivel 02--
=======================================================================================================
Ejericio 01
Identifica los cinco días que se generará la mayor cantidad de ingresos en la empresa por ventas. 
Muestra la fecha de cada transacción junto con el total de ventas.*/

USE operations;

SELECT DATE(timestamp) AS fecha, 
SUM(amount) AS Total
FROM transactions
GROUP BY DATE(timestamp) 
ORDER BY Total DESC
LIMIT 5;


/*========================================================================================================
Ejercicio 2
Presenta el nombre, teléfono, país, fecha y amount, de aquellas empresas que 
realizaron transacciones con un valor comprendido entre 350 y 400 euros y 
en alguna de estas fechas: 29 de abril de 2015, 20 de julio de 2018 y 13 de marzo de 2024.
 Ordena los resultados de mayor a menor cantidad.
 ======================================================================================*/
 
 USE operations;
 -- Nota: En la BBDD de transactions son 100001 porque añadimos una nueva fila en el ejercicio 6
 -- En BBDD operations son 10000
 -- Para no usar IN use un tipo OR
SELECT company_name, phone, country, amount, DATE(timestamp)
FROM transactions t
JOIN companies c
ON t.business_id = c.company_id
WHERE amount BETWEEN 350 AND 400
AND (
    DATE(timestamp) = '2015-04-29'
    OR DATE(timestamp) = '2018-07-20'
    OR DATE(timestamp) = '2024-03-13'
)
ORDER BY amount DESC;



/*================================================================================================
Ejercicio 3
Necesitamos optimizar la asignación de los recursos y 
dependerá de la capacidad operativa que se requiera, 
por lo que te piden la información sobre la cantidad de transacciones que realizan las empresas,
pero el departamento de recursos humanos es exigente y quiere un listado de las empresas 
 en las que especifiques si tienen igual o más de 400 transacciones o menos.
 ===================================================================================================*/
 
SELECT c.company_name, COUNT(*) AS cantidad_transacciones,
	CASE
	WHEN COUNT(*)>= 400 THEN 'Igual o más de 400 transacciones'
    ELSE 'Cantidad de transacciones menores'
    END AS capacidad_operativa
FROM transactions t
JOIN companies c
ON t.business_id = c.company_id
GROUP BY c.company_name;


/*=======================================================================
Exercici 4
Elimina de la tabla transacción el registro con ID 000447FE-B650-4DCF-85DE-C7ED0EE1CAAD de la base de datos.
===========================================================================================================*/
USE operations;

-- 4.1 Verificamos si existe el usuario
SELECT id 
FROM transactions
WHERE  id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

-- 4.2 Borramos
DELETE FROM transactions
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

-- 4.3 Verificar
-- 4.3 Verificamos que se borró
SELECT id 
FROM transactions
WHERE id = '000447FE-B650-4DCF-85DE-C7ED0EE1CAAD';

/*================================================================================
Ejercicio 5
La sección de marketing desea tener acceso a información específica para realizar análisis 
y estrategias efectivas. Se ha solicitado crear una vista que proporcione detalles clave sobre las compañías y sus transacciones.
 Será necesaria que crees una vista llamada VistaMarketing que contenga la siguiente información:
 Nombre de la compañía. Teléfono de contacto. País de residencia. Media de compra realizado por cada compañía. 
 Presenta la vista creada, ordenando los datos de mayor a menor promedio de compra
 =================================================================================================================*/
USE operations;

DROP VIEW IF EXISTS VistaMarketing;

CREATE VIEW VistaMarketing AS
SELECT company_name, phone, country, AVG(t.amount) AS media_compra
FROM transactions t
JOIN companies c
ON t.business_id = c.company_id
GROUP BY company_name, phone, country
ORDER BY  media_compra DESC;

SELECT * FROM VistaMarketing;
