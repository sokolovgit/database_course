-- 2.a. Створення представлення з конкретним переліком атрибутів
CREATE VIEW vehicle_overview AS
SELECT
    vehicle.id,
    vehicle.registration_number,
    vehicle.brand,
    vehicle.model,
    vehicle_type.name AS vehicle_type,
    vehicle.status,
    driver.first_name || ' ' || driver.last_name AS driver_name
FROM
    vehicle
    JOIN vehicle_type ON vehicle.vehicle_type_id = vehicle_type.id
    JOIN vehicle_driver ON vehicle.id = vehicle_driver.vehicle_id
    JOIN driver ON vehicle_driver.driver_id = driver.id;

-- 2.b. Створення представлення, що використовує попереднє представлення
CREATE VIEW decommissioned_vehicles_with_drivers AS
SELECT
    *
FROM
    vehicle_overview
WHERE
    status = 'decommissioned';

-- 2.c. Модифікація представлення за допомогою ALTER VIEW
ALTER VIEW decommissioned_vehicles_with_drivers RENAME COLUMN driver_name TO driver_full_name;

