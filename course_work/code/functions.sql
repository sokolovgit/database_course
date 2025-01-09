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

SELECT citizens.id,
       get_citizen_full_name(citizens.id),
       citizens.date_of_birth,
       is_citizen_older_than(citizens.id, 18)
FROM citizens
LIMIT 10;


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

SELECT
    vehicles.id,
    vehicles.registration_number,
    get_region_by_code(SUBSTRING(vehicles.registration_number FROM 1 FOR 2))
FROM vehicles
WHERE
    LENGTH(vehicles.registration_number) = 8
    AND SUBSTRING(vehicles.registration_number FROM 1 FOR 2) IN (
        SELECT DISTINCT LEFT(code_2004, 2)
        FROM regions
        UNION
        SELECT DISTINCT LEFT(code_2013, 2)
        FROM regions
        UNION
        SELECT DISTINCT LEFT(code_2021, 2)
        FROM regions
    )
GROUP BY
    get_region_by_code(SUBSTRING(vehicles.registration_number FROM 1 FOR 2)), vehicles.id,
    vehicles.registration_number;


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


SELECT
    violations.id,
    violations.time_of_violation,
    violations.description,
    get_administrative_offense_info(violations.administrative_offense_id)
FROM violations
LIMIT 10;


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


SELECT
    police_officers.id,
    get_citizen_full_name(police_officers.id),
    get_officer_protocol_count(police_officers.id)
FROM police_officers;


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

SELECT
    police_officers.id,
    get_citizen_full_name(police_officers.id),
    get_officer_resolution_count(police_officers.id)
FROM police_officers;


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


SELECT
    citizens.id,
    get_citizen_full_name(citizens.id)
FROM citizens;


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

SELECT
    vehicles.id,
    vehicles.registration_number,
    get_plate_type(vehicles.registration_number)
FROM vehicles;



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

SELECT citizens.id,
       get_citizen_full_name(citizens.id),
       get_total_penalty_fees(citizens.id)
FROM citizens;


























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

SELECT
    vehicles.id,
    vehicles.registration_number,
    get_vehicle_owner(vehicles.id)
FROM vehicles;

CREATE OR REPLACE FUNCTION get_total_violations_for_vehicle(veh_id INT)
RETURNS INT AS $$
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

SELECT
    vehicles.id,
    vehicles.registration_number,
    get_total_violations_for_vehicle(vehicles.id)
FROM vehicles;



