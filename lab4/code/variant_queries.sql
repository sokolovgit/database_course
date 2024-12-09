-- Запит (a): Визначити категорію транспорту, по якій була списана найбільша кількість одиниць.
SELECT
    vehicle_type.name,
    COUNT(vehicle.id) AS decommissioned_count
FROM
    vehicle
    JOIN vehicle_type ON vehicle.vehicle_type_id = vehicle_type.id
WHERE
    vehicle.status = 'decommissioned'
GROUP BY
    vehicle_type.name
ORDER BY
    decommissioned_count DESC
LIMIT
    1;

-- Запит (b): На якому маршруті найчастіше проводився перерозподіл транспорту за останній рік.
WITH route_changes AS (
    SELECT
        vehicle_route.route_id,
        COUNT(vehicle_route.vehicle_id) AS redistribution_count
    FROM
        vehicle_route
    WHERE
        vehicle_route.assignment_date >= (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY
        vehicle_route.route_id
)
SELECT
    route.id,
    route.name,
    route_changes.redistribution_count
FROM
    route_changes
    JOIN route ON route.id = route_changes.route_id
ORDER BY
    route_changes.redistribution_count DESC
LIMIT
    1;