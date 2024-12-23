CREATE SCHEMA IF NOT EXISTS public;
----------------------------------
CREATE TYPE EVIDENCE_TYPE AS ENUM ('photo', 'video');
CREATE TYPE CITIZEN_ON_PROTOCOL_ROLE AS ENUM ('victim', 'witness');
CREATE TYPE POLICE_OFFICER_RANK AS ENUM (
    'junior_sergeant',
    'sergeant',
    'senior_sergeant',
    'junior_lieutenant',
    'lieutenant',
    'senior_lieutenant',
    'captain',
    'major',
    'lieutenant_colonel',
    'colonel'
    );
----------------------------------
CREATE OR REPLACE FUNCTION is_citizen_older_than(citizen_id INT, years INT)
    RETURNS BOOLEAN AS
$$
DECLARE
    citizen_age INT;
BEGIN

    SELECT EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_of_birth))
    INTO citizen_age
    FROM citizens
    WHERE id = citizen_id;

    RETURN citizen_age >= years;
END;
$$ LANGUAGE plpgsql;
----------------------------------
CREATE TABLE citizens
(
    id            SERIAL PRIMARY KEY,
    first_name    VARCHAR(50) NOT NULL,
    last_name     VARCHAR(50) NOT NULL,
    patronymic    VARCHAR(50),
    date_of_birth DATE        NOT NULL,

    CONSTRAINT check_date_of_birth CHECK (
        date_of_birth > CURRENT_DATE - INTERVAL '120 years'
            AND date_of_birth < CURRENT_DATE
        )
);
CREATE TABLE drivers
(
    id                  SERIAL PRIMARY KEY,
    citizen_id          INT         NOT NULL,
    license_number      CHAR(9)     NOT NULL,
    license_issued_time TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_citizen_id FOREIGN KEY (citizen_id) REFERENCES citizens (id) ON DELETE CASCADE,
    CONSTRAINT check_license_number CHECK (
        license_number ~ '^[A-Z]{3}[0-9]{6}$'
        ),
    CONSTRAINT check_license_issued_time CHECK (
        license_issued_time < CURRENT_TIMESTAMP
        ),

    CONSTRAINT uq_license_number UNIQUE (license_number),
    CONSTRAINT ck_is_driver_more_than_16_years_old CHECK (is_citizen_older_than(citizen_id, 16))
);
CREATE TABLE police_officers
(
    id           SERIAL PRIMARY KEY,
    citizen_id   INT                 NOT NULL,
    badge_number CHAR(9)             NOT NULL,
    rank         POLICE_OFFICER_RANK NOT NULL,

    CONSTRAINT fk_citizen_id FOREIGN KEY (citizen_id) REFERENCES citizens (id) ON DELETE CASCADE,
    CONSTRAINT check_badge_number CHECK (
        badge_number ~ '^[A-Z]{3}[0-9]{6}$'
        ),
    CONSTRAINT uq_badge_number UNIQUE (badge_number),
    CONSTRAINT ck_is_police_officer_more_than_18_years_old CHECK (is_citizen_older_than(citizen_id, 18))
);
CREATE TABLE vehicle_types
(
    id                   SERIAL PRIMARY KEY,
    name                 VARCHAR(50) NOT NULL,
    description          TEXT,
    min_seating_capacity INT,
    max_seating_capacity INT,
    min_engine_capacity  DECIMAL(4, 2),
    max_engine_capacity  DECIMAL(4, 2),

    CONSTRAINT uq_name UNIQUE (name),
    CONSTRAINT ck_seating_capacity CHECK (
        (min_seating_capacity IS NULL AND max_seating_capacity IS NULL) OR
        (min_seating_capacity >= 0 AND max_seating_capacity >= min_seating_capacity)
        ),
    CONSTRAINT ck_engine_capacity CHECK (
        (min_engine_capacity IS NULL AND max_engine_capacity IS NULL) OR
        (min_engine_capacity >= 0 AND max_engine_capacity >= min_engine_capacity)
        )
);

CREATE TABLE vehicles
(
    id                      SERIAL PRIMARY KEY,
    owner_id                INT         NOT NULL,
    vehicle_type_id         INT         NOT NULL,
    registration_number     VARCHAR(8)  NOT NULL,
    vin                     CHAR(17)    NOT NULL,
    insurance_policy_number CHAR(9),
    model                   VARCHAR(50) NOT NULL,
    brand                   VARCHAR(50) NOT NULL,
    color                   VARCHAR(50) NOT NULL,
    engine_capacity         DECIMAL(4, 2),
    seating_capacity        INT,
    year_of_manufacture     INT         NOT NULL,


    CONSTRAINT fk_owner_id FOREIGN KEY (owner_id) REFERENCES citizens (id) ON DELETE CASCADE,
    CONSTRAINT fk_vehicle_type_id FOREIGN KEY (vehicle_type_id) REFERENCES vehicle_types (id) ON DELETE CASCADE,

    CONSTRAINT ck_valid_vin CHECK (vin ~ '^[A-HJ-NPR-Z0-9]{17}$'),
    CONSTRAINT ck_year_of_manufacture CHECK (
        year_of_manufacture >= 1886
            AND year_of_manufacture <= EXTRACT(
                YEAR
                FROM CURRENT_DATE
                                       )
        ),

    CONSTRAINT uq_vin UNIQUE (vin),
    CONSTRAINT uq_insurance_policy_number UNIQUE NULLS NOT DISTINCT (insurance_policy_number)
);
CREATE TABLE traffic_rules
(
    id          SERIAL PRIMARY KEY,
    article     INT NOT NULL,
    part        INT NOT NULL,
    description TEXT,

    CONSTRAINT uq_article_part UNIQUE (article, part)
);
CREATE TABLE administrative_offenses
(
    id          SERIAL PRIMARY KEY,
    article     INT NOT NULL,
    sup         INT,
    part        INT,
    description TEXT,
    penalty_fee DECIMAL(10, 2),

    CONSTRAINT uq_article_sup_part UNIQUE (article, sup, part),

    CONSTRAINT ck_article CHECK ( article >= 1 ),
    CONSTRAINT ck_sup CHECK ( sup >= 1 ),
    CONSTRAINT ck_part CHECK ( part >= 1 ),
    CONSTRAINT ck_penalty_fee CHECK (penalty_fee >= 0)
);
CREATE TABLE locations
(
    id              SERIAL PRIMARY KEY,
    longitude       DECIMAL(9, 6) NOT NULL,
    latitude        DECIMAL(9, 6) NOT NULL,
    street          VARCHAR(50),
    building_number VARCHAR(10),
    description     TEXT
);
CREATE TABLE violations
(
    id                        SERIAL PRIMARY KEY,
    time_of_violation         TIMESTAMPTZ NOT NULL,
    description               TEXT,
    vehicle_id                INT         NOT NULL,
    location_id               INT         NOT NULL,
    administrative_offense_id INT         NOT NULL,
    traffic_rule_id           INT         NOT NULL,

    CONSTRAINT fk_vehicle_id FOREIGN KEY (vehicle_id) REFERENCES vehicles (id) ON DELETE CASCADE,
    CONSTRAINT fk_location_id FOREIGN KEY (location_id) REFERENCES locations (id) ON DELETE CASCADE,
    CONSTRAINT fk_administrative_offense_id FOREIGN KEY (administrative_offense_id) REFERENCES administrative_offenses (id) ON DELETE CASCADE,
    CONSTRAINT fk_traffic_rule_id FOREIGN KEY (traffic_rule_id) REFERENCES traffic_rules (id) ON DELETE CASCADE,

    CONSTRAINT ck_time_of_violation CHECK (
        time_of_violation <= CURRENT_TIMESTAMP
            AND time_of_violation > CURRENT_DATE - INTERVAL '10 years'
        )


);
CREATE TABLE evidences
(
    id           SERIAL PRIMARY KEY,
    violation_id INT           NOT NULL,
    type         EVIDENCE_TYPE NOT NULL,
    url          TEXT          NOT NULL,

    CONSTRAINT fk_violation_id FOREIGN KEY (violation_id) REFERENCES violations (id) ON DELETE CASCADE
);

CREATE TABLE accident_protocols
(
    id                    SERIAL PRIMARY KEY,
    series                CHAR(2)     NOT NULL,
    number                CHAR(6)     NOT NULL,
    defendant_explanation TEXT,
    time_of_drawing_up    TIMESTAMPTZ NOT NULL,
    violation_id          INT         NOT NULL,
    police_officer_id     INT         NOT NULL,
    defendant_id          INT         NOT NULL,

    CONSTRAINT fk_violation_id FOREIGN KEY (violation_id) REFERENCES violations (id) ON DELETE CASCADE,
    CONSTRAINT fk_police_officer_id FOREIGN KEY (police_officer_id) REFERENCES police_officers (id) ON DELETE CASCADE,
    CONSTRAINT fk_defendant_id FOREIGN KEY (defendant_id) REFERENCES citizens (id) ON DELETE CASCADE,

    CONSTRAINT uq_series_number_protocol UNIQUE (series, number)
);
CREATE TABLE citizens_on_protocol
(
    id          SERIAL PRIMARY KEY,
    role        CITIZEN_ON_PROTOCOL_ROLE NOT NULL,
    citizen_id  INT                      NOT NULL,
    protocol_id INT                      NOT NULL,
    testimony   TEXT,

    CONSTRAINT fk_citizen_id FOREIGN KEY (citizen_id) REFERENCES citizens (id) ON DELETE CASCADE,
    CONSTRAINT fk_protocol_id FOREIGN KEY (protocol_id) REFERENCES accident_protocols (id) ON DELETE CASCADE
);
CREATE TABLE accident_resolutions
(
    id                       SERIAL PRIMARY KEY,
    series                   CHAR(2)     NOT NULL,
    number                   CHAR(6)     NOT NULL,
    time_of_consideration    TIMESTAMPTZ NOT NULL,
    time_of_entry_into_force TIMESTAMPTZ NOT NULL,
    violation_id             INT         NOT NULL,
    police_officer_id        INT         NOT NULL,
    location_id              INT         NOT NULL,

    CONSTRAINT fk_violation_id FOREIGN KEY (violation_id) REFERENCES violations (id) ON DELETE CASCADE,
    CONSTRAINT fk_police_officer_id FOREIGN KEY (police_officer_id) REFERENCES police_officers (id) ON DELETE CASCADE,
    CONSTRAINT fk_location_id FOREIGN KEY (location_id) REFERENCES locations (id) ON DELETE CASCADE,
    CONSTRAINT uq_series_number_resolution UNIQUE (series, number)
);

CREATE TABLE regions
(
    id          SERIAL PRIMARY KEY,
    region_name VARCHAR(100),
    code_2004   CHAR(2),
    code_2013   CHAR(2),
    code_2021   CHAR(2)
);
---------------------------------------------------------
CREATE OR REPLACE FUNCTION get_region_by_code(input_code VARCHAR)
    RETURNS VARCHAR AS
$$
DECLARE
    region VARCHAR;
BEGIN
    SELECT region_name
    INTO region
    FROM regions
    WHERE input_code = ANY (string_to_array(code_2004 || ',' || code_2013 || ',' || code_2021, ','));

    IF region IS NULL THEN
        RETURN 'Регіон не знайдено';
    ELSE
        RETURN region;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_administrative_offense_info(offense_id INT) RETURNS VARCHAR AS
$$
DECLARE
    offense_string VARCHAR;
BEGIN
    SELECT article || COALESCE(COALESCE('(' || sup || ').', '.') || part, '')
    INTO offense_string
    FROM administrative_offenses
    WHERE id = offense_id;

    IF offense_string IS NULL THEN
        RETURN 'Offense not found';
    ELSE
        RETURN offense_string;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_officer_protocol_count(officer_id INT)
    RETURNS INT AS
$$
DECLARE
    protocol_count INT;
BEGIN
    SELECT COUNT(*)
    INTO protocol_count
    FROM accident_protocols
    WHERE police_officer_id = officer_id;

    RETURN protocol_count;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_officer_resolution_count(officer_id INT)
    RETURNS INT AS
$$
DECLARE
    resolution_count INT;
BEGIN
    SELECT COUNT(*)
    INTO resolution_count
    FROM accident_resolutions
    WHERE police_officer_id = officer_id;

    RETURN resolution_count;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_citizen_full_name(citizen_id INT)
    RETURNS VARCHAR AS
$$
DECLARE
    full_name VARCHAR;
BEGIN
    SELECT first_name || ' ' || last_name || COALESCE(' ' || patronymic, '')
    INTO full_name
    FROM citizens
    WHERE id = citizen_id;

    RETURN full_name;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_plate_type(registration_number VARCHAR)
    RETURNS VARCHAR AS
$$
BEGIN
    IF registration_number ~ '^[A-Z]{2}[0-9]{4}[A-Z]{2}$' THEN
        RETURN 'regular';
    ELSIF LENGTH(registration_number) BETWEEN 3 AND 8 THEN
        RETURN 'personalized';
    ELSE
        RETURN 'unknown';
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION get_total_penalty_fees(driver_id INT)
    RETURNS DECIMAL AS
$$
DECLARE
    total_fees DECIMAL;
BEGIN
    SELECT SUM(ao.penalty_fee)
    INTO total_fees
    FROM violations v
             JOIN vehicles veh ON v.vehicle_id = veh.id
             JOIN administrative_offenses ao ON v.administrative_offense_id = ao.id
    WHERE veh.owner_id = driver_id;

    RETURN COALESCE(total_fees, 0);
END;
$$ LANGUAGE plpgsql;

-- Function to get the full name of the owner of a specific vehicle
CREATE OR REPLACE FUNCTION get_vehicle_owner(vehicle_id INT)
    RETURNS VARCHAR AS
$$
DECLARE
    owner_name VARCHAR;
BEGIN
    SELECT get_citizen_full_name(c.id)
    INTO owner_name
    FROM vehicles v
             JOIN citizens c ON v.owner_id = c.id
    WHERE v.id = vehicle_id;

    RETURN owner_name;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_total_violations_for_vehicle(veh_id INT)
    RETURNS INT AS
$$
DECLARE
    total_violations INT;
BEGIN
    SELECT COUNT(*)
    INTO total_violations
    FROM violations
    WHERE violations.vehicle_id = veh_id;

    RETURN total_violations;
END;
$$ LANGUAGE plpgsql;

---------------------------------------------------------
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

-- INSERT INTO vehicles
-- VALUES (1, 1, 1, 'AA1234AA', '3FA6P0H79ER135093', '123456789', 'Model', 'Brand', 'Color', 'electric', NULL, NULL, 2000);


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

-- INSERT INTO vehicles
-- VALUES (1, 1, 1, 'AA1234AA', '3FA6P0H79ER135093', '123456789', 'Model', 'Brand', 'Color', 'diesel', 2.4, 20, 2000);


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

-- INSERT INTO accident_protocols
-- VALUES (DEFAULT, 'GF', '043655', 'some text', '2024-12-16 16:31:31.952822 +00:00', 1, 1, 1);


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

-- INSERT INTO accident_resolutions
-- VALUES (DEFAULT, 'GF', '342543', '2024-12-16 16:31:31.952822 +00:00', '2024-12-16 16:31:31.952822 +00:00', 1, 1, 1),


CREATE OR REPLACE FUNCTION check_violation_exclusivity()
    RETURNS TRIGGER AS
$$
BEGIN
    -- Check if there is already an associated protocol or resolution for the violation
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
---------------------------------------------------------------


INSERT INTO vehicle_types (NAME, DESCRIPTION, MIN_SEATING_CAPACITY, MAX_SEATING_CAPACITY, MIN_ENGINE_CAPACITY,
                           MAX_ENGINE_CAPACITY)
VALUES ('Car', 'Passenger car used for personal or commercial purposes.', 2, 8, 1.0, 6.0),
       ('Electric Car', 'Vehicle powered exclusively by electricity.', 2, 8, NULL, NULL),
       ('Hybrid Vehicle', 'Vehicle powered by a combination of internal combustion engine and electric motor.', 2, 8,
        1.0, 6.0),
       ('Motorcycle', 'Two-wheeled motor vehicle.', 1, 2, 0.1, 2.0),
       ('Van', 'Larger motor vehicle designed for passenger or cargo transport.', 2, 15, 2.0, 6.0),
       ('Truck', 'Motor vehicle designed to transport goods or materials.', 2, 2, 2.0, 15.0),
       ('Bus', 'Motor vehicle designed to carry multiple passengers.', 9, NULL, 4.0, 15.0),
       ('Special Purpose Vehicle', 'Vehicles such as fire trucks, ambulances, or police cars.', 1, 10, 2.0, 10.0),
       ('Trailer', 'Unpowered vehicle towed by another vehicle.', NULL, NULL, NULL, NULL),
       ('Agricultural Vehicle', 'Vehicles such as tractors used for farming purposes.', 1, 3, 1.0, 5.0),
       ('ATV', 'All-terrain vehicle used for off-road travel.', 1, 2, 0.5, 1.5),
       ('Dump Truck', 'Truck designed to transport and unload materials.', 2, 2, 2.0, 15.0);

COPY traffic_rules (article, part, description) FROM '/private/tmp/traffic_rules.csv' DELIMITER ',' CSV HEADER;
COPY administrative_offenses (article, sup, part, penalty_fee, description) FROM '/private/tmp/administrative_offenses.csv' DELIMITER ',' CSV HEADER;

INSERT INTO regions (region_name, code_2004, code_2013, code_2021)
VALUES ('AR Krym', 'AK', 'KK', 'TK'),
       ('Vinnytska oblast', 'AB', 'KB', 'IM'),
       ('Volynska oblast', 'AC', 'KC', 'CM'),
       ('Dnipropetrovska oblast', 'AE', 'KE', 'PP'),
       ('Donetska oblast', 'AH', 'KH', 'TH'),
       ('Zhytomyrska oblast', 'AM', 'KM', 'TM'),
       ('Zakarpatska oblast', 'AO', 'KO', 'MT'),
       ('Zaporizka oblast', 'AP', 'KP', 'TP'),
       ('Ivano-Frankivska oblast', 'AT', 'KT', 'TO'),
       ('Kyivska oblast', 'AI', 'KI', 'TI'),
       ('misto Kyiv', 'AA', 'KA', 'TT'),
       ('Kirovohradska oblast', 'BA', 'HA', 'XA'),
       ('Luhanska oblast', 'BB', 'HB', 'EP'),
       ('Lvivska oblast', 'BC', 'HC', 'CC'),
       ('Mykolaivska oblast', 'BE', 'HE', 'XE'),
       ('Odeska oblast', 'BH', 'HH', 'OO'),
       ('Poltavska oblast', 'BI', 'HI', 'XI'),
       ('Rivnenska oblast', 'BK', 'HK', 'XK'),
       ('Sumska oblast', 'BM', 'HM', 'XM'),
       ('Ternopilska oblast', 'BO', 'HO', 'XO'),
       ('Kharkivska oblast', 'AX', 'KX', 'XX'),
       ('Khersonska oblast', 'BT', 'HT', 'XT'),
       ('Khmelnytska oblast', 'BX', 'HX', 'OX'),
       ('Cherkaska oblast', 'CA', 'IA', 'OA'),
       ('Chernihivska oblast', 'CB', 'IB', 'OB'),
       ('Chernivetska oblast', 'CE', 'IE', 'OE'),
       ('misto Sevastopol', 'CH', 'IH', 'OH');


---------------------------------------------------------

CREATE OR REPLACE VIEW violation_details AS
SELECT v.id                                                       AS violation_id,
       get_citizen_full_name(c.id)                                AS driver_name,
       veh.registration_number,
       loc.street || ', ' || loc.building_number                  AS location,
       loc.description                                            as location_description,
       v.time_of_violation,
       v.description                                              AS violation_description,
       tr.article || '.' || tr.part                               AS traffic_rule,
       get_administrative_offense_info(administrative_offense_id) AS administrative_offense,
       ao.description                                             AS administrative_offense_description,
       ao.penalty_fee


FROM violations v
         JOIN vehicles veh ON v.vehicle_id = veh.id
         JOIN citizens c ON veh.owner_id = c.id
         JOIN locations loc ON v.location_id = loc.id
         JOIN traffic_rules tr ON v.traffic_rule_id = tr.id
         JOIN administrative_offenses ao ON v.administrative_offense_id = ao.id;



CREATE OR REPLACE VIEW full_vehicle_info AS
SELECT v.id                              AS vehicle_id,
       v.registration_number,
       v.model,
       v.brand,
       v.color,
       v.year_of_manufacture,
       v.vin,
       v.insurance_policy_number,

       v.engine_capacity,
       v.seating_capacity,
       get_citizen_full_name(v.owner_id) AS owner_full_name,
       CASE
           WHEN get_plate_type(v.registration_number) = 'regular'
               THEN get_region_by_code(SUBSTRING(v.registration_number FROM 1 FOR 2))
           ELSE 'N/A'
           END                           AS region
FROM vehicles v;



CREATE OR REPLACE VIEW driver_violation_summary AS
SELECT c.id                                                            AS driver_id,
       get_citizen_full_name(c.id)                                     AS driver_name,
       COUNT(CASE WHEN ap.id IS NULL AND ar.id IS NULL THEN 1 END)     AS violations_without_document,
       COUNT(CASE WHEN ap.id IS NOT NULL AND ar.id IS NULL THEN 1 END) AS violations_with_protocol,
       COUNT(CASE WHEN ar.id IS NOT NULL THEN 1 END)                   AS violations_with_resolution,
       COUNT(v.id)                                                     AS total_violations,
       SUM(ao.penalty_fee)                                             AS total_penalty_fees
FROM citizens c
         JOIN
     vehicles veh ON c.id = veh.owner_id
         JOIN
     violations v ON veh.id = v.vehicle_id
         JOIN
     administrative_offenses ao ON v.administrative_offense_id = ao.id
         LEFT JOIN
     accident_protocols ap ON v.id = ap.violation_id
         LEFT JOIN
     accident_resolutions ar ON v.id = ar.violation_id
GROUP BY c.id;



