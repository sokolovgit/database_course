-- Час прибуття на подію не може бути раніше часу спрацювання сигналу.

CREATE OR REPLACE FUNCTION check_arrival_time()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.arrived_at < (SELECT triggered_at FROM alarm_events WHERE id = NEW.event_id) THEN
        RAISE EXCEPTION 'Arrival time cannot be before the event time.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_arrival_time
    BEFORE INSERT OR UPDATE
    ON employees_departure_on_events
    FOR EACH ROW
EXECUTE FUNCTION check_arrival_time();

INSERT INTO employees_departure_on_events (employee_id, event_id, vehicle_id, arrived_at)
VALUES (1, 1, 1, '2021-01-01 12:00:00');


-- Швидкість транспортного засобу не може перевищувати 200 км/год.
CREATE OR REPLACE FUNCTION check_max_speed()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.max_speed > 200 THEN
        RAISE EXCEPTION 'Speed cannot be greater than 200 km/h.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_check_max_speed
    BEFORE INSERT OR UPDATE
    ON vehicles
    FOR EACH ROW
EXECUTE FUNCTION check_max_speed();

INSERT INTO vehicles (id, registration_number, model, brand, color, max_speed, seating_capacity, year_of_manufacture)
VALUES (1, 'AA1234AA', 'Model', 'Brand', 'Color', 201, 5, 2021);

