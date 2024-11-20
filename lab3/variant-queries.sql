-- а) Визначить маршрути, по яким в поточному місяці був виконаний
-- перерозподіл транспорту.
WITH route_changes AS (
    SELECT
        vehicle_route.route_id,
        vehicle_route.vehicle_id,
        vehicle_route.assignment_date
    FROM
        vehicle_route
    WHERE
        EXTRACT(
            MONTH
            FROM
                vehicle_route.assignment_date
        ) = EXTRACT(
            MONTH
            FROM
                CURRENT_DATE
        )
        AND EXTRACT(
            YEAR
            FROM
                vehicle_route.assignment_date
        ) = EXTRACT(
            YEAR
            FROM
                CURRENT_DATE
        )
)
SELECT
    DISTINCT route.id,
    route.name
FROM
    route_changes
    JOIN route ON route.id = route_changes.route_id
WHERE
    route_changes.assignment_date IS NOT NULL;

-- б) Визначить водіїв, котрі закріплені за маршрутом, котрі починаються на
-- Шулявці.
SELECT
    DISTINCT driver.first_name,
    driver.last_name,
    route.start_location
FROM
    driver
    JOIN vehicle_driver ON vehicle_driver.driver_id = driver.id
    JOIN vehicle ON vehicle.id = vehicle_driver.vehicle_id
    JOIN vehicle_route ON vehicle_route.vehicle_id = vehicle.id
    JOIN route ON route.id = vehicle_route.route_id
WHERE
    REGEXP_REPLACE(route.start_location, '^\d+\s', '') LIKE 'Old%';