-- a. запит з використанням функції COUNT;
-- Запит групує транспортні засоби за категоріями та підраховує кількість списаних транспортних засобів.
SELECT
    vehicle_type.name AS vehicle_category,
    COUNT(vehicle.id) AS decommissioned_count
FROM
    vehicle
    JOIN vehicle_type ON vehicle.vehicle_type_id = vehicle_type.id
WHERE
    vehicle.status = 'decommissioned'
GROUP BY
    vehicle_type.name
ORDER BY
    decommissioned_count DESC;

-- b. Запит з використанням функції SUM
-- Запит групує маршрути за назвою та підраховує загальну кількість пасажирів, які користувались кожним маршрутом.
SELECT
    route.name,
    SUM(passenger_record.passenger_count) AS total_passengers
FROM
    route
    JOIN passenger_record ON route.id = passenger_record.route_id
WHERE
    passenger_count IS NOT NULL
GROUP BY
    route.name
ORDER BY
    total_passengers DESC;

-- 1.c. Запит з групуванням по декільком стовпцям
-- Підрахунок кількості транспортних засобів за категорією транспорту та статусом.
SELECT
    vehicle_type.name,
    vehicle.status,
    COUNT(vehicle.id) AS vehicle_count
FROM
    vehicle
    JOIN vehicle_type ON vehicle.vehicle_type_id = vehicle_type.id
GROUP BY
    vehicle_type.name,
    vehicle.status
ORDER BY
    vehicle_type.name,
    vehicle.status;

-- 1.d. Запит з використанням умови відбору груп HAVING
-- Запит групує транспортні засоби за реєстраційним номером та підраховує кількість водіїв, які керували кожним транспортним засобом.
SELECT
    vehicle.registration_number AS vehicle_number,
    COUNT(vehicle_driver.driver_id) AS driver_count
FROM
    vehicle
    JOIN vehicle_driver ON vehicle.id = vehicle_driver.vehicle_id
GROUP BY
    vehicle.registration_number
HAVING
    COUNT(vehicle_driver.driver_id) > 1;

-- 1.e. Запит з використанням HAVING без GROUP BY
-- Запит знаходить кількість транспортних засобів, якщо в автопарку їх більше 100.
SELECT
    COUNT(vehicle.id) AS total_vehicles
FROM
    vehicle
HAVING
    COUNT(vehicle.id) > 100;

-- 1.f. Запит з використанням ROW_NUMBER() OVER (...)
-- Запит виводить інформацію про транспортні засоби та маршрути, які були їм призначені, впорядковані за датою призначення.
SELECT
    vehicle.registration_number AS vehicle_number,
    route.name AS route_name,
    vehicle_route.assignment_date AS assignment_date,
    ROW_NUMBER() OVER (
        PARTITION BY vehicle.id
        ORDER BY
            vehicle_route.assignment_date DESC
    ) AS route_order
FROM
    vehicle
    JOIN vehicle_route ON vehicle.id = vehicle_route.vehicle_id
    JOIN route ON vehicle_route.route_id = route.id;

-- 1.g. Запит, в якому значення одного зі стовпців будуть виведені в рядок через кому
-- Запит групує транспортні засоби за реєстраційним номером та виводить водіїв, які керували кожним транспортним засобом через кому.
SELECT
    vehicle.registration_number AS vehicle_number,
    STRING_AGG(
        driver.first_name || ' ' || driver.last_name,
        ', '
    ) AS drivers
FROM
    vehicle
    JOIN vehicle_driver ON vehicle.id = vehicle_driver.vehicle_id
    JOIN driver ON vehicle_driver.driver_id = driver.id
GROUP BY
    vehicle.registration_number;

-- 1.h. Запит з використанням сортування по декільком стовпцям у різному порядку
-- Виведення інформації про транспортні засоби, відсортованих спочатку за статусом у зростаючому порядку, а потім за роком випуску у спадному порядку.
SELECT
    vehicle.id,
    vehicle.brand,
    vehicle.model,
    vehicle.status,
    vehicle.year_of_manufacture
FROM
    vehicle
ORDER BY
    vehicle.status ASC,
    vehicle.year_of_manufacture DESC;