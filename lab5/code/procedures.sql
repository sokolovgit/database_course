-- a. створення процедури, в якій використовується тимчасова таблиця,
-- котра створена через змінну типу TABLE;

CREATE OR REPLACE PROCEDURE get_vehicles_for_route(route_id_param INT)
    LANGUAGE plpgsql
AS
$$
DECLARE
    record RECORD;
BEGIN
    CREATE TEMP TABLE temp_vehicles
    (
        vehicle_id INT,
        model      VARCHAR(50),
        capacity   INT
    );

    INSERT INTO temp_vehicles
    SELECT vehicle.id, vehicle.model, vehicle.capacity
    FROM vehicle
    WHERE vehicle.id IN (SELECT vehicle_route.vehicle_id
                         FROM vehicle_route
                         WHERE vehicle_route.route_id = route_id_param);
END;
$$;


DROP PROCEDURE get_vehicles_for_route(integer);
DROP TABLE temp_vehicles;

SELECT *
FROM temp_vehicles;
CALL get_vehicles_for_route(4);



-- b. створення процедури з використанням умовної конструкції IF;
CREATE OR REPLACE PROCEDURE update_vehicle_status(vehicle_id INT, new_status vehicle_status)
    LANGUAGE plpgsql
AS
$$
BEGIN
    IF new_status = 'decommissioned' THEN
        UPDATE vehicle
        SET status  = new_status,
            team_id = NULL
        WHERE id = vehicle_id;
    ELSE
        UPDATE vehicle
        SET status = new_status
        WHERE id = vehicle_id;
    END IF;
END;
$$;

CALL update_vehicle_status(1, 'decommissioned');

SELECT *
FROM vehicle
WHERE id = 1;



-- c. створення процедури з використанням циклу WHILE;
CREATE OR REPLACE PROCEDURE deactivate_old_vehicles(cutoff_year INT)
    LANGUAGE plpgsql
AS
$$
DECLARE
    current_vehicle RECORD;
BEGIN
    FOR current_vehicle IN
        SELECT id FROM vehicle WHERE year_of_manufacture < cutoff_year
        LOOP
            UPDATE vehicle
            SET status = 'decommissioned'
            WHERE id = current_vehicle.id;
            RAISE NOTICE 'Vehicle ID % has been decommissioned', current_vehicle.id;
        END LOOP;
END;
$$;

CALL deactivate_old_vehicles(1971);

SELECT *
FROM vehicle
WHERE status = 'decommissioned'
ORDER BY vehicle.year_of_manufacture;


-- d. створення процедури без параметрів;

CREATE OR REPLACE PROCEDURE clear_old_routes()
    LANGUAGE plpgsql
AS
$$
BEGIN
    DELETE
    FROM route
    WHERE id NOT IN (SELECT DISTINCT vehicle_route.route_id FROM vehicle_route);
END;
$$;

CALL clear_old_routes();

SELECT *
FROM route
WHERE id NOT IN (SELECT DISTINCT vehicle_route.route_id FROM vehicle_route);

INSERT INTO route (name, start_location, end_location, distance)
VALUES ('Old Route', 'Point A', 'Point B', 15.0);



-- e. створення процедури з вхідним параметром та RETURN;
CREATE OR REPLACE FUNCTION calculate_total_passengers(route_id_param INT)
    RETURNS INT
    LANGUAGE plpgsql
AS
$$
DECLARE
    total_passengers INT;
BEGIN
    SELECT SUM(passenger_record.passenger_count)
    INTO total_passengers
    FROM passenger_record
    WHERE passenger_record.route_id = route_id_param;

    RETURN total_passengers;
END;
$$;

SELECT calculate_total_passengers(1);

INSERT INTO passenger_record (vehicle_id, route_id, date, passenger_count)
VALUES (1, 1, CURRENT_DATE, 50);


-- f. створення процедури оновлення даних в деякій таблиці БД;

CREATE OR REPLACE PROCEDURE update_driver_team(driver_id_param INT, new_team_id_param INT)
    LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE driver
    SET team_id = new_team_id_param
    WHERE id = driver_id_param;
END;
$$;


CALL update_driver_team(1, 2);

SELECT *
FROM driver
WHERE id = 1;



-- g. створення процедури, в котрій робиться вибірка даних.
CREATE OR REPLACE PROCEDURE get_route_vehicles(route_id_param INT)
    LANGUAGE plpgsql
AS
$$
DECLARE
    record RECORD;
BEGIN

    RAISE NOTICE 'Starting get_route_vehicles for route_id: %', route_id_param;


    FOR record IN
        SELECT vehicle.id, vehicle.model, vehicle.capacity, vehicle.status
        FROM vehicle
                 INNER JOIN vehicle_route ON vehicle.id = vehicle_route.vehicle_id
        WHERE vehicle_route.route_id = route_id_param
        LOOP

            RAISE NOTICE 'Vehicle ID: %, Model: %, Capacity: %, Status: %',
                record.id, record.model, record.capacity, record.status;
        END LOOP;


    RAISE NOTICE 'get_route_vehicles completed for route_id: %.', route_id_param;
END;
$$;

CALL get_route_vehicles(1);






