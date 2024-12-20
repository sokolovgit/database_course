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


