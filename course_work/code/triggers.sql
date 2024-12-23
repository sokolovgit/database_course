CREATE OR REPLACE FUNCTION check_engine_capacity()
    RETURNS TRIGGER AS
$$
DECLARE
    min_capacity DECIMAL(4, 2);
    max_capacity DECIMAL(4, 2);
BEGIN
    SELECT min_engine_capacity, max_engine_capacity
    INTO min_capacity, max_capacity
    FROM vehicle_types
    WHERE id = NEW.vehicle_type_id;

    IF min_capacity IS NULL AND max_capacity IS NULL AND NEW.engine_capacity IS NOT NULL THEN
        RAISE EXCEPTION 'Unpowered vehicles cannot have an engine capacity value.';
    ELSIF min_capacity IS NOT NULL AND NEW.engine_capacity < min_capacity THEN
        RAISE EXCEPTION 'Engine capacity must be at least %.', min_capacity;
    ELSIF max_capacity IS NOT NULL AND NEW.engine_capacity > max_capacity THEN
        RAISE EXCEPTION 'Engine capacity must not exceed %.', max_capacity;
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
VALUES (15000, 1, 1, 'AA1234AA', '3FA6P0H79ER135093', '123456789', 'Model', 'Brand', 'Color', 0, 4, 2000);
INSERT INTO vehicles
VALUES (15001, 1, 1, 'AA1234AA', '3FA6P0H79ER135093', '123456789', 'Model', 'Brand', 'Color', 25, 4, 2000);
INSERT INTO vehicles
VALUES (15002, 2, 2, 'AA1234AA', '3FA6P0H79ER135093', '123456789', 'Model', 'Brand', 'Color', 2.4, 4, 2000);


CREATE OR REPLACE FUNCTION check_seating_capacity()
    RETURNS TRIGGER AS
$$
DECLARE
    min_capacity INT;
    max_capacity INT;
BEGIN
    SELECT min_seating_capacity, max_seating_capacity
    INTO min_capacity, max_capacity
    FROM vehicle_types
    WHERE id = NEW.vehicle_type_id;

    IF min_capacity IS NOT NULL AND NEW.seating_capacity < min_capacity THEN
        RAISE EXCEPTION 'Seating capacity must be at least %.', min_capacity;
    ELSIF max_capacity IS NOT NULL AND NEW.seating_capacity > max_capacity THEN
        RAISE EXCEPTION 'Seating capacity must not exceed %.', max_capacity;
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
VALUES (1, 1, 1, 'AA1234AA', '3FA6P0H79ER135093', '123456789', 'Model', 'Brand', 'Color', 2.4, 0, 2000);
INSERT INTO vehicles
VALUES (1, 1, 1, 'AA1234AA', '3FA6P0H79ER135093', '123456789', 'Model', 'Brand', 'Color', 2.4, 20, 2000);


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
VALUES (100002, 'GF', '043654', 'some text', '2004-12-16 16:31:31.952822 +00:00', 1, 1, 1);
INSERT INTO accident_protocols
VALUES (100002, 'GF', '043654', 'some text', '2024-12-16 16:31:31.952822 +00:00', 1, 1, 19858);

CREATE OR REPLACE FUNCTION check_citizens_on_protocol_validity()
    RETURNS TRIGGER AS
$$
BEGIN
    IF NEW.citizen_id = (SELECT defendant_id
                         FROM accident_protocols
                         WHERE id = NEW.protocol_id) THEN
        RAISE EXCEPTION 'Citizen cannot be the same as the defendant.';
    END IF;

    IF NEW.citizen_id = (SELECT citizen_id
                         FROM police_officers
                         WHERE id = (SELECT police_officer_id
                                     FROM accident_protocols
                                     WHERE id = NEW.protocol_id)) THEN
        RAISE EXCEPTION 'Citizen cannot be the same as the police officer.';
    END IF;

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


INSERT INTO citizens_on_protocol (id, role, citizen_id, protocol_id, testimony)
VALUES (120001, 'witness', 969, 1, 'some text');
INSERT INTO citizens_on_protocol (id, role, citizen_id, protocol_id, testimony)
VALUES (120004, 'witness', 970, 1, 'some text');
INSERT INTO citizens_on_protocol (id, role, citizen_id, protocol_id, testimony)
VALUES (120001, 'witness', 7327, 1, 'some text');



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



INSERT INTO accident_resolutions (id, series, number, time_of_consideration, time_of_entry_into_force, violation_id,
                                  police_officer_id, location_id)
VALUES (100002, 'GF', '043654', '2000-12-16 16:31:31.952822 +00:00', '2024-12-16 16:31:31.952822 +00:00', 1, 1, 1);
INSERT INTO accident_resolutions (id, series, number, time_of_consideration, time_of_entry_into_force, violation_id,
                                  police_officer_id, location_id)
VALUES (100002, 'GF', '043654', '2024-12-16 16:31:31.952822 +00:00', '2004-12-16 16:31:31.952822 +00:00', 1, 1, 1);



CREATE OR REPLACE FUNCTION check_violation_exclusivity()
    RETURNS TRIGGER AS
$$
BEGIN
    IF TG_TABLE_NAME = 'accident_protocols' THEN
        IF EXISTS (SELECT 1
                   FROM accident_resolutions
                   WHERE violation_id = NEW.violation_id) THEN
            RAISE EXCEPTION 'A violation can only have either a protocol or a resolution. Found an existing resolution for violation_id = %.', NEW.violation_id;
        END IF;
    ELSIF TG_TABLE_NAME = 'accident_resolutions' THEN
        IF EXISTS (SELECT 1
                   FROM accident_protocols
                   WHERE violation_id = NEW.violation_id) THEN
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

INSERT INTO accident_protocols (id, series, number, defendant_explanation, time_of_drawing_up, violation_id,
                                police_officer_id, defendant_id)
VALUES (100006, 'GD', '043653', 'some text', '2024-12-16 16:31:31.952822 +00:00', 1, 1, 1);

INSERT INTO accident_resolutions (id, series, number, time_of_consideration, time_of_entry_into_force, violation_id,
                                  police_officer_id, location_id)
VALUES (100006, 'GD', '043653', '2022-12-16 16:31:31.952822 +00:00', '2024-12-16 16:31:31.952822 +00:00', 1, 1, 1);


