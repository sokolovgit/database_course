CREATE SCHEMA IF NOT EXISTS public;

CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50),
    birth_date DATE NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(50) NOT NULL,
    CONSTRAINT ck_birth_date CHECK (birth_date <= CURRENT_DATE),
    CONSTRAINT uq_phone_number UNIQUE (phone_number),
    CONSTRAINT uq_email UNIQUE (email)
);

CREATE TABLE vehicles (
    id SERIAL PRIMARY KEY,
    registration_number VARCHAR(8) NOT NULL,
    model VARCHAR(50) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    color VARCHAR(50) NOT NULL,
    max_speed INT,
    seating_capacity INT,
    year_of_manufacture INT NOT NULL,

    CONSTRAINT ck_year_of_manufacture CHECK (
        year_of_manufacture >= 1886
        AND year_of_manufacture <= EXTRACT(
            YEAR
            FROM
                CURRENT_DATE
        )
    ),
    CONSTRAINT uq_registration_number UNIQUE (registration_number),
    CONSTRAINT ck_seating_capacity CHECK (seating_capacity BETWEEN 1 AND 50)
);

CREATE TABLE locations (
    id SERIAL PRIMARY KEY,
    longitude DECIMAL(9, 6) NOT NULL,
    latitude DECIMAL(9, 6) NOT NULL,
    street VARCHAR(50),
    building_number VARCHAR(10),
    description TEXT
);

CREATE TYPE power_type AS ENUM ('accumulator', 'wired', 'combined');
CREATE TYPE sensor_type AS ENUM ('movement', 'glass_breakage', 'door_opening', 'temperature', 'vibration');
CREATE TYPE connection_type AS ENUM ('wired', 'wifi', 'radio');
CREATE TYPE alert_type AS ENUM ('sms', 'email', 'phone_call', 'app_notification');

CREATE TABLE alarms (
    id SERIAL PRIMARY KEY,
    power power_type NOT NULL,
    sensor sensor_type NOT NULL,
    connection connection_type NOT NULL,
    alert alert_type NOT NULL,
    max_range DECIMAL(5, 2),
    model VARCHAR(50) NOT NULL,
    brand VARCHAR(50) NOT NULL,
    details TEXT
);

CREATE TABLE protected_objects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    location_id INT NOT NULL,

    CONSTRAINT fk_location_id FOREIGN KEY (location_id) REFERENCES locations (id) ON DELETE CASCADE
);

CREATE TABLE alarms_on_objects (
    id SERIAL PRIMARY KEY,
    alarm_id INT NOT NULL,
    object_id INT NOT NULL,

    CONSTRAINT fk_alarm_id FOREIGN KEY (alarm_id) REFERENCES alarms (id) ON DELETE CASCADE,
    CONSTRAINT fk_object_id FOREIGN KEY (object_id) REFERENCES protected_objects (id) ON DELETE CASCADE
);

CREATE TABLE alarm_events (
    id SERIAL PRIMARY KEY,
    alarm_id INT NOT NULL,
    triggered_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_alarm_id FOREIGN KEY (alarm_id) REFERENCES alarms (id) ON DELETE CASCADE,
    CONSTRAINT fk_triggered_at CHECK (triggered_at <= CURRENT_TIMESTAMP)
);

CREATE TABLE alarm_events_results (
    id SERIAL PRIMARY KEY,
    event_id INT NOT NULL,
    result TEXT NOT NULL,

    CONSTRAINT fk_event_id FOREIGN KEY (event_id) REFERENCES alarm_events (id) ON DELETE CASCADE
);

CREATE TABLE employees_departure_on_events (
    id SERIAL PRIMARY KEY,
    employee_id INT NOT NULL,
    event_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    arrived_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_employee_id FOREIGN KEY (employee_id) REFERENCES employees (id) ON DELETE CASCADE,
    CONSTRAINT fk_event_id FOREIGN KEY (event_id) REFERENCES alarm_events (id) ON DELETE CASCADE,
    CONSTRAINT fk_vehicle_id FOREIGN KEY (vehicle_id) REFERENCES vehicles (id) ON DELETE CASCADE
)




