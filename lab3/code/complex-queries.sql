-- 2.a.i Підзапити в рядку вибірки полів та секції FROM
-- Виводить назви маршрутів та кількість транспортних засобів, закріплених за кожним маршрутом.
SELECT
    route.name AS route_name,
    (
        SELECT
            COUNT(*)
        FROM
            vehicle_route
        WHERE
            vehicle_route.route_id = route.id
    ) AS vehicle_count
FROM
    route;

-- 2.a.ii Підзапити в рядку вибірки з таблиць FORM 
-- Виводить список транспортних засобів, які є доступними
SELECT
    vehicle.registration_number,
    vehicle.status,
    (
        SELECT
            vehicle_type.name
        FROM
            vehicle_type
        WHERE
            vehicle_type.id = vehicle.vehicle_type_id
    ) AS vehicle_type
FROM
    (
        SELECT
            *
        FROM
            vehicle
        WHERE
            vehicle.status = 'available'
    ) AS vehicle;

-- 2.b.i Використання підзапитів в умовах з конструкціями EXISTS
-- Виводить водіїв які керують транспортним засобом, який є закріплений за хоча б одним маршрутом 
SELECT
    driver.first_name,
    driver.last_name
FROM
    driver
WHERE
    EXISTS (
        SELECT
            1
        FROM
            vehicle_driver
        WHERE
            vehicle_driver.driver_id = driver.id
            AND EXISTS (
                SELECT
                    1
                FROM
                    vehicle_route
                WHERE
                    vehicle_route.vehicle_id = vehicle_driver.vehicle_id
            )
    );

-- 2.b.ii Використання підзапитів в умовах з конструкціями IN
-- Виводить список водіїв, які закріплені за транспортними засобами типу "Bus"
SELECT
    driver.first_name,
    driver.last_name
FROM
    driver
WHERE
    driver.id IN (
        SELECT
            vehicle_driver.driver_id
        FROM
            vehicle_driver
        WHERE
            vehicle_driver.vehicle_id IN (
                SELECT
                    vehicle.id
                FROM
                    vehicle
                WHERE
                    vehicle.vehicle_type_id IN (
                        SELECT
                            vehicle_type.id
                        FROM
                            vehicle_type
                        WHERE
                            vehicle_type.name = 'Bus'
                    )
            )
    );

-- 2.c Декартовий добуток
-- Виводить всі комбінаціїї транспортних засобів та маршрутів, де тип транспортного засобу 
-- 'Bus' і довжина маршруту більше 10 км
SELECT
    v.registration_number AS vehicle,
    r.name AS route
FROM
    vehicle v
    CROSS JOIN route r
WHERE
    v.vehicle_type_id = (
        SELECT
            id
        FROM
            vehicle_type
        WHERE
            name = 'Bus'
    )
    AND r.distance > 10;

-- 2.d З’єднання декількох таблиць за рівністю та умовою відбору
-- Виводить номер машини, тип машини та імʼя водія 
SELECT
    vehicle.registration_number,
    vehicle_type.name,
    driver.first_name || ' ' || driver.last_name as driver_name
FROM
    vehicle
    JOIN vehicle_type ON vehicle.vehicle_type_id = vehicle_type.id
    JOIN vehicle_driver ON vehicle.id = vehicle_driver.vehicle_id
    JOIN driver ON vehicle_driver.driver_id = driver.id;

-- 2.e Внутрішнього з’єднання
-- Виводить водіїв, разом із їхніми транспортними засобами (реєстраційний номер), які мають статус "available"
SELECT
    driver.first_name,
    driver.last_name,
    vehicle.registration_number
FROM
    driver
    INNER JOIN vehicle_driver ON driver.id = vehicle_driver.driver_id
    INNER JOIN vehicle ON vehicle_driver.vehicle_id = vehicle.id
WHERE
    vehicle.status = 'available';

-- 2.f Лівого зовнішнього з’єднання
-- Виводить список всіх водіїв та їхні транспортні засоби, або їх відсутність
SELECT
    driver.first_name,
    driver.last_name,
    vehicle.registration_number
FROM
    driver
    LEFT JOIN vehicle_driver ON driver.id = vehicle_driver.driver_id
    LEFT JOIN vehicle ON vehicle_driver.vehicle_id = vehicle.id;

-- g. Правого зовнішнього з’єднання
-- Виводить список всіх транспортних засобів та їхні маршрути, або їх відсутність
SELECT
    vehicle.registration_number AS vehicle,
    route.name AS route
FROM
    vehicle
    RIGHT JOIN vehicle_route ON vehicle.id = vehicle_route.vehicle_id
    RIGHT JOIN route ON vehicle_route.route_id = route.id;

-- h. Об’єднання запитів
-- Виводить список всіх номерів ТЗ які або Автобуси, або на маршрутах із маршрутом більше 80 км
SELECT
    vehicle.registration_number,
    vehicle_type.name,
    route.distance
FROM
    vehicle
    JOIN vehicle_type ON vehicle.vehicle_type_id = vehicle_type.id
    JOIN vehicle_route ON vehicle.id = vehicle_route.vehicle_id
    JOIN route ON vehicle_route.route_id = route.id
WHERE
    vehicle_type.name = 'Bus'
UNION
SELECT
    vehicle.registration_number,
    vehicle_type.name,
    route.distance
FROM
    vehicle
    JOIN vehicle_type ON vehicle.vehicle_type_id = vehicle_type.id
    JOIN vehicle_route ON vehicle.id = vehicle_route.vehicle_id
    JOIN route ON vehicle_route.route_id = route.id
WHERE
    route.distance > 80;

-- h. Перетин  запитів
-- Виводить список всіх номерів ТЗ які і Таксі, і на маршрутах із дистанцією більше менше 15 км
SELECT
    registration_number
FROM
    vehicle
    JOIN vehicle_type ON vehicle.vehicle_type_id = vehicle_type.id
WHERE
    vehicle_type.name = 'Taxi'
INTERSECT
SELECT
    registration_number
FROM
    vehicle
    JOIN vehicle_route ON vehicle.id = vehicle_route.vehicle_id
    JOIN route ON vehicle_route.route_id = route.id
WHERE
    route.distance < 15;