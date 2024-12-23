CREATE OR REPLACE PROCEDURE get_vehicle_details_with_cursor(route_id_param INT)
LANGUAGE plpgsql
AS $$
DECLARE
    vehicle_cursor CURSOR FOR
        SELECT vehicle.id, vehicle.model, vehicle.capacity, vehicle.status
        FROM vehicle
        INNER JOIN vehicle_route ON vehicle.id = vehicle_route.vehicle_id
        WHERE vehicle_route.route_id = route_id_param;

    vehicle_id INT;
    model VARCHAR(50);
    capacity INT;
    status vehicle_status;
BEGIN
    OPEN vehicle_cursor;

    LOOP
        FETCH vehicle_cursor INTO vehicle_id, model, capacity, status;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE 'Vehicle ID: %, Model: %, Capacity: %, Status: %',
            vehicle_id, model, capacity, status;
    END LOOP;

    CLOSE vehicle_cursor;
END;
$$;

CALL get_vehicle_details_with_cursor(4);
