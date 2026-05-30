USE transactions;

SELECT * FROM user;
SELECT * FROM company;
SELECT * FROM credit_card;
SELECT * FROM transaction;

/*Ejercicio 1
A partir de los documentos adjuntos (estructura_datos y datos_introducir), importa las dos tablas. 
Muestra las principales características del esquema creado y explica las diferentes tablas y 
variables que existen. Asegúrate de incluir un diagrama que ilustre la relación entre las diferentes tablas y variables*/


 -- Creamos la tabla company
    CREATE TABLE IF NOT EXISTS company (
        id VARCHAR(15) PRIMARY KEY,
        company_name VARCHAR(255),
        phone VARCHAR(15),
        email VARCHAR(100),
        country VARCHAR(100),
        website VARCHAR(255)
    );

-- Creamos la tabla credit_card

	CREATE TABLE IF NOT EXISTS credit_card(
		id VARCHAR(15) PRIMARY KEY,
		iban VARCHAR(50),
		pan VARCHAR(20),
		pin VARCHAR(10),
		cvv VARCHAR(5),
		expiring_date VARCHAR(10)
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


-- 2. Mostrar las características generales del esquema para ello usaremos la expresión 

DESCRIBE user;
DESCRIBE company;
DESCRIBE credit_card;
DESCRIBE transaction;

/*Ejercicio 2
Utilizando JOIN realizarás las siguientes consultas:*/

-- Listado de paises

SELECT DISTINCT c.country
FROM company c
JOIN transaction t
ON t.company_id = c.id;

-- Desde cuántos países se generen las ventas.
SELECT COUNT(DISTINCT c.country)
FROM company c
JOIN transaction t
ON t.company_id = c.id;

-- Compañia con mayor media de ventas

SELECT c.company_name, 
AVG(t.amount) AS media_ventas
FROM company c
JOIN transaction t
ON t.company_id = c.id
GROUP BY c.company_name
ORDER BY AVG(t.amount) DESC
LIMIT 1;

/*Ejercicio 3. Utilizando sólo subconsultas (sin utilizar JOIN):

Muestra todas las transacciones realizadas por empresas de Alemania.
Lista las empresas que han realizado transacciones por un amount superior a 
la media de todas las transacciones.
Eliminarán del sistema las empresas que carecen de transacciones 
registradas, entrega el listado de estas empresas.*/

SELECT * FROM transaction
WHERE company_id IN (
SELECT id
FROM company
WHERE country = 'Germany');

-- Lista las empresas que han realizado transacciones por un amount superior a la media de todas las transacciones.

SELECT company_name 
FROM company
WHERE id IN (
SELECT company_id
FROM transaction
GROUP BY company_id
HAVING AVG(amount) > (SELECT AVG(amount) FROM transaction)
);

-- Eliminarán del sistema las empresas que carecen de transacciones registradas, entrega el listado de estas empresas.

SELECT company_name
FROM company
WHERE id NOT IN (
SELECT company_id
FROM transaction);

-- Comprobar
SELECT COUNT(*) 
FROM transaction 
WHERE company_id IS NULL;

/*Ejercicio 4
Tu tarea es diseñar y crear una tabla llamada "credit_card" que almacene detalles cruciales sobre las tarjetas de crédito.
 La nueva tabla debe ser capaz de identificar de forma única cada tarjeta y establecer una relación adecuada 
 con las otras dos tablas ("transaction" y "company"). Después de crear la tabla será necesario que ingreses 
 la información del documento denominado "datos_introducir_credit". 
Recuerda mostrar el diagrama y realizar una breve descripción del mismo.*/

CREATE TABLE IF NOT EXISTS credit_card(
		id VARCHAR(15) PRIMARY KEY,
		iban VARCHAR(50),
		pan VARCHAR(20),
		pin VARCHAR(10),
		cvv VARCHAR(5),
		expiring_date VARCHAR(10)
	);

-- Diagram en el PDF Consultes_Tasca_Sprint2_N1.pdf

/*Ejercicio 5
El departamento de Recursos Humanos ha identificado un error en el número de cuenta asociado a su tarjeta de crédito con ID CcU-2938. La información que debe mostrarse para este registro es: 
TR323456312213576817699999. Recuerda mostrar que el cambio se realizó*/

UPDATE credit_card
SET iban = 'TR323456312213576817699999'
WHERE id = 'CcU-2938';

SELECT iban
FROM credit_card
WHERE id = 'CcU-2938';


/*Ejercicio 6 En la tabla "transaction" ingresa una nueva transacción con la siguiente información*/

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


/*Ejercicio 7
Desde recursos humanos te solicitan eliminar la columna "pan" de la tabla credit_card. 
Recuerda mostrar el cambio realizado.*/

ALTER TABLE credit_card
DROP COLUMN pan;

SELECT * FROM credit_card;

/*Ejercicio 8
Estudia'ls i dissenya una base de dades amb un esquema d'estrella que contingui, almenys 4 taules de les quals puguis realitzar les següents consultes:
La taula de products.csv l'utilitzarem més endavant.*/

-- El diagrama se encuentra en el PDF Consultes_Tasca_Sprint2_N1.pdf

/*Ejercicio 9
Realiza una subconsulta que muestre a todos los usuarios con 
más de 80 transacciones utilizando al menos 2 tablas.*/

SELECT * FROM user
WHERE id IN (
SELECT user_id
FROM transaction
GROUP BY user_id
HAVING COUNT(user_id)>80);

/*Ejercicio 10
Muestra la media de amount por IBAN de las tarjetas de crédito en la compañía Donec Ltd., 
utiliza por lo menos 2 tablas.*/


SELECT cd.iban, c.company_name, AVG(t.amount) AS media_cantidad
FROM credit_card cd
JOIN transaction t
ON t.credit_card_id = cd.id
JOIN company c
ON t.company_id = c.id
WHERE c.company_name = 'Donec Ltd'
GROUP BY cd.iban;


-- Nivel 02--

/*Ejericio 01
Identifica los cinco días que se generará la mayor cantidad de ingresos en la empresa por ventas. 
Muestra la fecha de cada transacción junto con el total de ventas.*/

SELECT DATE(timestamp) AS fecha, 
SUM(amount) AS Total
FROM transaction
GROUP BY DATE(timestamp) 
ORDER BY Total DESC
LIMIT 5;


/*Ejercicio 2
Presenta el nombre, teléfono, país, fecha y amount, de aquellas empresas que 
realizaron transacciones con un valor comprendido entre 350 y 400 euros y 
en alguna de estas fechas: 29 de abril de 2015, 20 de julio de 2018 y 13 de marzo de 2024.
 Ordena los resultados de mayor a menor cantidad.*/
 
 
SELECT company_name, phone, country, amount, DATE(timestamp)
FROM transaction t
JOIN company c
ON t.company_id = c.id
WHERE amount BETWEEN 350 AND 400
	AND
	DATE(timestamp) IN ('2015-04-29','2018-07-20','2024-03-13')
ORDER BY amount DESC;

/*Ejercicio 3
Necesitamos optimizar la asignación de los recursos y 
dependerá de la capacidad operativa que se requiera, 
por lo que te piden la información sobre la cantidad de transacciones que realizan las empresas,
pero el departamento de recursos humanos es exigente y quiere un listado de las empresas 
 en las que especifiques si tienen igual o más de 400 transacciones o menos.*/
 
SELECT c.company_name, COUNT(*) AS cantidad_transacciones,
	CASE
	WHEN COUNT(*)>= 400 THEN 'Cantidad de transacciones mayores'
    ELSE 'Cantidad de transacciones menores'
    END AS capacidad_operativa
FROM transaction t
JOIN company c
ON t.company_id = c.id
GROUP BY c.company_name;

