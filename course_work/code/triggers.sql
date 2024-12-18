CREATE OR REPLACE FUNCTION check_engine_capacity()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.engine_type = 'electric' AND NEW.engine_capacity IS NOT NULL THEN
        RAISE EXCEPTION 'Electric vehicles cannot have an engine capacity value.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_engine_capacity
    BEFORE INSERT OR UPDATE
    ON vehicles
    FOR EACH ROW
EXECUTE FUNCTION check_engine_capacity();

INSERT INTO vehicles
VALUES (1, 1, 1, 'AA1234AA', '3FA6P0H79ER135093', '123456789', 'Model', 'Brand', 'Color', 'electric', NULL, NULL, 2000);


CREATE OR REPLACE FUNCTION check_seating_capacity()
    RETURNS TRIGGER AS
$$
DECLARE
    min_capacity   INT := NULL;
    max_capacity   INT := NULL;
    exact_capacity INT := NULL;
BEGIN
    -- Determine the seating capacity rules based on vehicle type
    CASE NEW.vehicle_type_id
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Car' OR name = 'Electric Car')
            THEN min_capacity := 2; max_capacity := 8;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Motorcycle') THEN min_capacity := 1; max_capacity := 2;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Bus') THEN min_capacity := 9;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Truck') THEN exact_capacity := 2;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Trailer') THEN exact_capacity := NULL;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Special Purpose Vehicle')
            THEN min_capacity := 1; max_capacity := 10;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Dump Truck') THEN exact_capacity := 2;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Agricultural Vehicle')
            THEN min_capacity := 1; max_capacity := 3;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'ATV') THEN min_capacity := 1; max_capacity := 2;
        WHEN (SELECT id FROM vehicle_types WHERE name = 'Electric Scooter') THEN exact_capacity := 1;
        ELSE RAISE EXCEPTION 'Unknown vehicle_type_id: %', NEW.vehicle_type_id;
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
    BEFORE INSERT OR UPDATE
    ON vehicles
    FOR EACH ROW
EXECUTE FUNCTION check_seating_capacity();

INSERT INTO vehicles
VALUES (1, 1, 1, 'AA1234AA', '3FA6P0H79ER135093', '123456789', 'Model', 'Brand', 'Color', 'diesel', 2.4, 20, 2000);


CREATE OR REPLACE FUNCTION check_protocol_validity()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.time_of_drawing_up < (SELECT time_of_violation FROM violations WHERE id = NEW.violation_id) THEN
        RAISE EXCEPTION 'Protocol time cannot be before the violation time.';
    END IF;

    IF (SELECT citizen_id FROM police_officers WHERE id = NEW.police_officer_id) = NEW.defendant_id THEN
        RAISE EXCEPTION 'The police officer cannot be the same as the defendant.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_protocol_validity
    BEFORE INSERT OR UPDATE
    ON accident_protocols
    FOR EACH ROW
EXECUTE FUNCTION check_protocol_validity();

INSERT INTO accident_protocols
VALUES (DEFAULT, 'GF', '043655', 'some text', '2024-12-16 16:31:31.952822 +00:00', 1, 1, 1);


CREATE OR REPLACE FUNCTION check_citizens_on_protocol_validity()
    RETURNS TRIGGER AS
$$
BEGIN
    -- Prevent citizen from being the same as defendant
    IF NEW.citizen_id = (SELECT defendant_id
                         FROM accident_protocols
                         WHERE id = NEW.protocol_id) THEN
        RAISE EXCEPTION 'Citizen cannot be the same as the defendant.';
    END IF;

    -- Prevent citizen from being the same as the police officer
    IF NEW.citizen_id = (SELECT citizen_id
                         FROM police_officers
                         WHERE id = (SELECT police_officer_id
                                     FROM accident_protocols
                                     WHERE id = NEW.protocol_id)) THEN
        RAISE EXCEPTION 'Citizen cannot be the same as the police officer.';
    END IF;

    -- Prevent duplicate roles for the same citizen in the same protocol
    IF EXISTS (SELECT 1
               FROM citizens_on_protocol
               WHERE protocol_id = NEW.protocol_id
                 AND citizen_id = NEW.citizen_id) THEN
        RAISE EXCEPTION 'Duplicate citizen in the same protocol.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_citizens_on_protocol
    BEFORE INSERT OR UPDATE
    ON citizens_on_protocol
    FOR EACH ROW
EXECUTE FUNCTION check_citizens_on_protocol_validity();


CREATE OR REPLACE FUNCTION check_resolution_validity()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.time_of_consideration < (SELECT time_of_violation FROM violations WHERE id = NEW.violation_id) THEN
        RAISE EXCEPTION 'Resolution consideration time cannot be before the violation time.';
    END IF;

    IF NEW.time_of_entry_into_force <= NEW.time_of_consideration THEN
        RAISE EXCEPTION 'Time of entry into force must be after the time of consideration.';
    END IF;


    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_resolution_validity
    BEFORE INSERT OR UPDATE
    ON accident_resolutions
    FOR EACH ROW
EXECUTE FUNCTION check_resolution_validity();

INSERT INTO accident_resolutions
VALUES (DEFAULT, 'GF', '342543', '2024-12-16 16:31:31.952822 +00:00', '2024-12-16 16:31:31.952822 +00:00', 1, 1, 1)


CREATE OR REPLACE FUNCTION check_violation_exclusivity()
    RETURNS TRIGGER AS
$$
BEGIN
    -- Check if there is already an associated protocol or resolution for the violation
    IF TG_TABLE_NAME = 'accident_protocols' THEN
        IF EXISTS (
            SELECT 1
            FROM accident_resolutions
            WHERE violation_id = NEW.violation_id
        ) THEN
            RAISE EXCEPTION 'A violation can only have either a protocol or a resolution. Found an existing resolution for violation_id = %.', NEW.violation_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'accident_resolutions' THEN
        IF EXISTS (
            SELECT 1
            FROM accident_protocols
            WHERE violation_id = NEW.violation_id
        ) THEN
            RAISE EXCEPTION 'A violation can only have either a protocol or a resolution. Found an existing protocol for violation_id = %.', NEW.violation_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_violation_exclusivity_protocol
    BEFORE INSERT OR UPDATE
    ON accident_protocols
    FOR EACH ROW
EXECUTE FUNCTION check_violation_exclusivity();

CREATE TRIGGER trg_check_violation_exclusivity_resolution
    BEFORE INSERT OR UPDATE
    ON accident_resolutions
    FOR EACH ROW
EXECUTE FUNCTION check_violation_exclusivity();



