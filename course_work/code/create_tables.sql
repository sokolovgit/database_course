CREATE SCHEMA IF NOT EXISTS public;

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

CREATE TABLE citizens (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50),
    date_of_birth DATE NOT NULL,
    CONSTRAINT check_date_of_birth CHECK (
        date_of_birth > CURRENT_DATE - INTERVAL '120 years'
        AND date_of_birth < CURRENT_DATE
    )
);

CREATE TABLE drivers (
    id SERIAL PRIMARY KEY,
    citizen_id INT NOT NULL,
    license_number CHAR(9) NOT NULL,
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

CREATE TABLE police_officers (
    id SERIAL PRIMARY KEY,
    citizen_id INT NOT NULL,
    badge_number CHAR(9) NOT NULL,
    rank POLICE_OFFICER_RANK NOT NULL,
    CONSTRAINT fk_citizen_id FOREIGN KEY (citizen_id) REFERENCES citizens (id) ON DELETE CASCADE,
    CONSTRAINT check_badge_number CHECK (
        badge_number ~ '^[A-Z]{3}[0-9]{6}$'
    ),
    CONSTRAINT uq_badge_number UNIQUE (badge_number),
    CONSTRAINT ck_is_police_officer_more_than_18_years_old CHECK (is_citizen_older_than(citizen_id, 18))
);

CREATE TABLE vehicle_types (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    description TEXT,
    min_seating_capacity INT,
    max_seating_capacity INT,
    min_engine_capacity DECIMAL(4, 2),
    max_engine_capacity DECIMAL(4, 2),
    CONSTRAINT uq_name UNIQUE (name),
    CONSTRAINT ck_seating_capacity CHECK (
        (
            min_seating_capacity IS NULL
            AND max_seating_capacity IS NULL
        )
        OR (
            min_seating_capacity >= 0
            AND max_seating_capacity >= min_seating_capacity
        )
    ),
    CONSTRAINT ck_engine_capacity CHECK (
        (
            min_engine_capacity IS NULL
            AND max_engine_capacity IS NULL
        )
        OR (
            min_engine_capacity >= 0
            AND max_engine_capacity >= min_engine_capacity
        )
    )
);

CREATE TABLE vehicles (
    id SERIAL PRIMARY KEY,
    owner_id INT NOT NULL,
    vehicle_type_id INT NOT NULL,
    registration_number VARCHAR(8) NOT NULL,
    vin CHAR(17) NOT NULL,
    insurance_policy_number CHAR(9),
    model VARCHAR(50) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    color VARCHAR(50) NOT NULL,
    engine_capacity DECIMAL(4, 2),
    seating_capacity INT,
    year_of_manufacture INT NOT NULL,
    CONSTRAINT fk_owner_id FOREIGN KEY (owner_id) REFERENCES citizens (id) ON DELETE CASCADE,
    CONSTRAINT fk_vehicle_type_id FOREIGN KEY (vehicle_type_id) REFERENCES vehicle_types (id) ON DELETE CASCADE,
    CONSTRAINT ck_valid_vin CHECK (vin ~ '^[A-HJ-NPR-Z0-9]{17}$'),
    CONSTRAINT ck_year_of_manufacture CHECK (
        year_of_manufacture >= 1886
        AND year_of_manufacture <= EXTRACT(
            YEAR
            FROM
                CURRENT_DATE
        )
    ),
    CONSTRAINT uq_vin UNIQUE (vin),
    CONSTRAINT uq_insurance_policy_number UNIQUE NULLS NOT DISTINCT (insurance_policy_number)
);

CREATE TABLE traffic_rules (
    id SERIAL PRIMARY KEY,
    article INT NOT NULL,
    part INT NOT NULL,
    description TEXT,
    CONSTRAINT uq_article_part UNIQUE (article, part)
);

CREATE TABLE administrative_offenses (
    id SERIAL PRIMARY KEY,
    article INT NOT NULL,
    sup INT,
    part INT,
    description TEXT,
    penalty_fee DECIMAL(10, 2),
    CONSTRAINT uq_article_sup_part UNIQUE (article, sup, part),
    CONSTRAINT ck_article CHECK (article >= 1),
    CONSTRAINT ck_sup CHECK (sup >= 1),
    CONSTRAINT ck_part CHECK (part >= 1),
    CONSTRAINT ck_penalty_fee CHECK (penalty_fee >= 0)
);

CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    longitude DECIMAL(9, 6) NOT NULL,
    latitude DECIMAL(9, 6) NOT NULL,
    street VARCHAR(50),
    building_number VARCHAR(10),
    description TEXT
);

CREATE TABLE violations (
    id SERIAL PRIMARY KEY,
    time_of_violation TIMESTAMPTZ NOT NULL,
    description TEXT,
    vehicle_id INT NOT NULL,
    location_id INT NOT NULL,
    administrative_offense_id INT NOT NULL,
    traffic_rule_id INT NOT NULL,
    CONSTRAINT fk_vehicle_id FOREIGN KEY (vehicle_id) REFERENCES vehicles (id) ON DELETE CASCADE,
    CONSTRAINT fk_location_id FOREIGN KEY (location_id) REFERENCES locations (id) ON DELETE CASCADE,
    CONSTRAINT fk_administrative_offense_id FOREIGN KEY (administrative_offense_id) REFERENCES administrative_offenses (id) ON DELETE CASCADE,
    CONSTRAINT fk_traffic_rule_id FOREIGN KEY (traffic_rule_id) REFERENCES traffic_rules (id) ON DELETE CASCADE,
    CONSTRAINT ck_time_of_violation CHECK (
        time_of_violation <= CURRENT_TIMESTAMP
        AND time_of_violation > CURRENT_DATE - INTERVAL '10 years'
    )
);

CREATE TABLE evidences (
    id SERIAL PRIMARY KEY,
    violation_id INT NOT NULL,
    type EVIDENCE_TYPE NOT NULL,
    url TEXT NOT NULL,
    CONSTRAINT fk_violation_id FOREIGN KEY (violation_id) REFERENCES violations (id) ON DELETE CASCADE
);

CREATE TABLE accident_protocols (
    id SERIAL PRIMARY KEY,
    series CHAR(2) NOT NULL,
    number CHAR(6) NOT NULL,
    defendant_explanation TEXT,
    time_of_drawing_up TIMESTAMPTZ NOT NULL,
    violation_id INT NOT NULL,
    police_officer_id INT NOT NULL,
    defendant_id INT NOT NULL,
    CONSTRAINT fk_violation_id FOREIGN KEY (violation_id) REFERENCES violations (id) ON DELETE CASCADE,
    CONSTRAINT fk_police_officer_id FOREIGN KEY (police_officer_id) REFERENCES police_officers (id) ON DELETE CASCADE,
    CONSTRAINT fk_defendant_id FOREIGN KEY (defendant_id) REFERENCES citizens (id) ON DELETE CASCADE,
    CONSTRAINT uq_series_number_protocol UNIQUE (series, number)
);

CREATE TABLE citizens_on_protocol (
    id SERIAL PRIMARY KEY,
    role CITIZEN_ON_PROTOCOL_ROLE NOT NULL,
    citizen_id INT NOT NULL,
    protocol_id INT NOT NULL,
    testimony TEXT,
    CONSTRAINT fk_citizen_id FOREIGN KEY (citizen_id) REFERENCES citizens (id) ON DELETE CASCADE,
    CONSTRAINT fk_protocol_id FOREIGN KEY (protocol_id) REFERENCES accident_protocols (id) ON DELETE CASCADE
);

CREATE TABLE accident_resolutions (
    id SERIAL PRIMARY KEY,
    series CHAR(2) NOT NULL,
    number CHAR(6) NOT NULL,
    time_of_consideration TIMESTAMPTZ NOT NULL,
    time_of_entry_into_force TIMESTAMPTZ NOT NULL,
    violation_id INT NOT NULL,
    police_officer_id INT NOT NULL,
    location_id INT NOT NULL,
    CONSTRAINT fk_violation_id FOREIGN KEY (violation_id) REFERENCES violations (id) ON DELETE CASCADE,
    CONSTRAINT fk_police_officer_id FOREIGN KEY (police_officer_id) REFERENCES police_officers (id) ON DELETE CASCADE,
    CONSTRAINT fk_location_id FOREIGN KEY (location_id) REFERENCES locations (id) ON DELETE CASCADE,
    CONSTRAINT uq_series_number_resolution UNIQUE (series, number)
);

CREATE TABLE regions (
    id SERIAL PRIMARY KEY,
    region_name VARCHAR(100),
    code_2004 CHAR(2),
    code_2013 CHAR(2),
    code_2021 CHAR(2)
);