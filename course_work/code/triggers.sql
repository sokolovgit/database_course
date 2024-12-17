CREATE OR REPLACE FUNCTION check_engine_capacity() 
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.engine_type = 'electric' AND NEW.engine_capacity IS NOT NULL THEN
        RAISE EXCEPTION 'Electric vehicles cannot have an engine capacity value.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_engine_capacity
BEFORE INSERT OR UPDATE ON vehicles
FOR EACH ROW EXECUTE FUNCTION check_engine_capacity();

INSERT INTO vehicles VALUES (1, 1, 1, 'AA1234AA', '3FA6P0H79ER135093', '123456789', 'Model', 'Brand', 'Color', 'electric', NULL, NULL, 2000 );


CREATE OR REPLACE FUNCTION check_seating_capacity()
RETURNS TRIGGER AS $$
DECLARE
    min_capacity INT := NULL;
    max_capacity INT := NULL;
    exact_capacity INT := NULL;
BEGIN
    -- Determine the seating capacity rules based on vehicle type
    CASE NEW.vehicle_type_id
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Car' OR name = 'Electric Car') THEN
            min_capacity := 2; max_capacity := 8;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Motorcycle') THEN
            min_capacity := 1; max_capacity := 2;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Bus') THEN
            min_capacity := 9;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Truck') THEN
            exact_capacity := 2;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Trailer') THEN
            exact_capacity := NULL;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Special Purpose Vehicle') THEN
            min_capacity := 1; max_capacity := 10;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Dump Truck') THEN
            exact_capacity := 2;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Agricultural Vehicle') THEN
            min_capacity := 1; max_capacity := 3;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'ATV') THEN
            min_capacity := 1; max_capacity := 2;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Electric Scooter') THEN
            exact_capacity := 1;
        ELSE
            RAISE EXCEPTION 'Unknown vehicle_type_id: %', NEW.vehicle_type_id;
    END CASE;

    -- Validate seating capacity based on determined rules
    IF exact_capacity IS NOT NULL AND NEW.seating_capacity != exact_capacity THEN
        RAISE EXCEPTION 'Seating capacity must be exactly %.', exact_capacity;
    ELSIF min_capacity IS NOT NULL AND NEW.seating_capacity < min_capacity THEN
        RAISE EXCEPTION 'Seating capacity must be at least %.', min_capacity;
    ELSIF max_capacity IS NOT NULL AND NEW.seating_capacity > max_capacity THEN
        RAISE EXCEPTION 'Seating capacity must not exceed %.', max_capacity;
    ELSIF NEW.vehicle_type_id = (SELECT id FROM vehicle_types WHERE name = 'Trailer')
          AND NEW.seating_capacity IS NOT NULL THEN
        RAISE EXCEPTION 'Trailer must not have a seating capacity.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_seating_capacity
BEFORE INSERT OR UPDATE ON vehicles
FOR EACH ROW EXECUTE FUNCTION check_seating_capacity();

INSERT INTO vehicles VALUES (1, 1, 1, 'AA1234AA', '3FA6P0H79ER135093', '123456789', 'Model', 'Brand', 'Color', 'diesel', 2.4, 20, 2000 );


CREATE OR REPLACE FUNCTION check_protocol_time()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.time_of_drawing_up < (SELECT time_of_violation FROM violations WHERE id = NEW.violation_id) THEN
        RAISE EXCEPTION 'Protocol time cannot be before the violation time.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_protocol_time
BEFORE INSERT OR UPDATE ON accident_protocols
FOR EACH ROW EXECUTE FUNCTION check_protocol_time();

INSERT INTO accident_protocols VALUES (DEFAULT, 'GF', '043655', 'some text', '2024-12-16 16:31:31.952822 +00:00', 1, 1, 1)


CREATE OR REPLACE FUNCTION check_resolution_times()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.time_of_consideration < (SELECT time_of_violation FROM violations WHERE id = NEW.violation_id) THEN
        RAISE EXCEPTION 'Resolution consideration time cannot be before the violation time.';
    END IF;

    IF NEW.time_of_entry_into_force <= NEW.time_of_consideration THEN
        RAISE EXCEPTION 'Time of entry into force must be after the time of consideration.';
    END IF;

    IF NEW.police_officer_id = (SELECT owner_id FROM vehicles WHERE id = (SELECT vehicle_id FROM violations WHERE id = NEW.violation_id)) THEN
        RAISE EXCEPTION 'Police officer cannot be the same as the owner of the vehicle involved in the violation.';
    END IF;

    IF NEW.location_id = (SELECT location_id FROM violations WHERE id = NEW.violation_id) THEN
        RAISE EXCEPTION 'Location of resolution cannot be the same as the violation location.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_resolution_times
BEFORE INSERT OR UPDATE ON accident_resolutions
FOR EACH ROW EXECUTE FUNCTION check_resolution_times();

INSERT INTO accident_resolutions VALUES (DEFAULT, 'GF', '342543', '2024-12-16 16:31:31.952822 +00:00', '2024-12-16 16:31:31.952822 +00:00', 1, 1, 1)



