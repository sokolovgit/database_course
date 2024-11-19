-- 1.a. Використання простих умов та операторів порівняння

-- Вибірка всіх транспортних засобів, виготовлених після 2015 року.
SELECT *
FROM vehicle
WHERE year_of_manufacture > 2010;

-- 1.b. Умови з використанням логічних операторів AND, OR, NOT

-- Вибірка всіх транспортних засобів, виготовлених після 2010 року та вироблених компанією Mercedes-Benz.
SELECT *
FROM vehicle
WHERE year_of_manufacture > 2010 AND brand = 'Mercedes-Benz';

-- Вибірка всіх водіїв, які не призначені на жодну команду або влаштовані на роботу після 2020-01-01.
SELECT *
FROM driver
WHERE team_id IS NULL OR employment_date > '2020-01-01';


-- 1.c. Використання виразів над стовпцями

-- Обрахування загальної вантажопідйомності транспортних засобів в кг.
SELECT 
    id,
    capacity * 100 + load_capacity * 1000 AS max_capacity
FROM vehicle;


-- Вибірка всіх транспортних засобів, загальна вантажопідйомність яких перевищує 10 тонн.
SELECT
    id,
    capacity * 100 + load_capacity * 1000 > 10000 AS total_capacity_exceeds_10_tons
FROM vehicle; 

-- 1.d. Використання операторів

-- i. Приналежність множині
-- Вибірка всіх транспортних засобів, які доступні або знаходяться в обслуговуванні.

SELECT *
FROM vehicle
WHERE status IN ('available', 'in_service');


-- ii. Приналежність діапазону
-- Вибірка всіх транспортних засобів, вироблених між 2010 та 2015 роками.

SELECT *
FROM vehicle
WHERE year_of_manufacture BETWEEN 2010 AND 2015;


-- iii. Відповідність шаблону 
-- Вибірка всіх водіїв, ім'я яких починається на 'An'.

SELECT *
FROM driver
WHERE first_name LIKE 'An%';





