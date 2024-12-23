-- a. Створення функції, яка повертає скалярне значення
CREATE OR REPLACE FUNCTION get_available_vehicles_count()
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    available_count INT;
BEGIN
    SELECT COUNT(*) INTO available_count
    FROM vehicle
    WHERE status = 'available';

    RETURN available_count;
END;
$$;

SELECT get_available_vehicles_count();


-- b. Створення функції, яка повертає таблицю з динамічним набором стовпців
CREATE OR REPLACE FUNCTION get_vehicle_details_json(route_id_param INT)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
    result JSONB;
BEGIN
    SELECT jsonb_agg(
        jsonb_build_object(
            'vehicle_id', vehicle.id,
            'model', vehicle.model,
            'capacity', vehicle.capacity,
            'status', vehicle.status
        )
    )
    INTO result
    FROM vehicle
    INNER JOIN vehicle_route ON vehicle.id = vehicle_route.vehicle_id
    WHERE vehicle_route.route_id = route_id_param;

    RETURN result;
END;
$$;

SELECT get_vehicle_details_json(4);



-- c. Створення функції, яка повертає таблицю наперед заданої структури
CREATE OR REPLACE FUNCTION get_vehicle_details_for_route(route_id_param INT)
RETURNS TABLE (
    vehicle_id INT,
    model VARCHAR,
    capacity INT,
    status vehicle_status
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT vehicle.id, vehicle.model, vehicle.capacity, vehicle.status
    FROM vehicle
    INNER JOIN vehicle_route ON vehicle.id = vehicle_route.vehicle_id
    WHERE vehicle_route.route_id = route_id_param;
END;
$$;

SELECT * FROM get_vehicle_details_for_route(4);
