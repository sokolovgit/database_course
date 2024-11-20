CREATE TYPE vehicle_status AS ENUM (
    'available',
    'in_service',
    'under_maintenance',
    'decommissioned'
);

CREATE TABLE team (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    foreman_id INT
);

CREATE TABLE driver (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    license_number VARCHAR(50) UNIQUE NOT NULL,
    employment_date DATE,
    team_id INT,
    FOREIGN KEY (team_id) REFERENCES team(id) ON DELETE
    SET NULL
);

ALTER TABLE team
ADD CONSTRAINT fk_foreman FOREIGN KEY (foreman_id) REFERENCES driver(id) ON DELETE
SET NULL;
CREATE TABLE vehicle_type (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);
CREATE TABLE vehicle (
    id SERIAL PRIMARY KEY,
    registration_number VARCHAR(50) UNIQUE NOT NULL,
    model VARCHAR(50),
    brand VARCHAR(50),
    year_of_manufacture INT CHECK (
        year_of_manufacture >= 1886
        AND year_of_manufacture <= EXTRACT(
            YEAR
            FROM CURRENT_DATE
        )
    ),
    status vehicle_status,
    vehicle_type_id INT,
    capacity INT CHECK (capacity > 0),
    load_capacity DECIMAL(10, 2) CHECK (load_capacity >= 0),
    team_id INT,
    FOREIGN KEY (vehicle_type_id) REFERENCES vehicle_type(id) ON DELETE
    SET NULL,
        FOREIGN KEY (team_id) REFERENCES team(id) ON DELETE
    SET NULL
);
CREATE TABLE route (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    start_location VARCHAR(100) NOT NULL,
    end_location VARCHAR(100) NOT NULL,
    distance DECIMAL(5, 2) CHECK (distance >= 0) NOT NULL
);
CREATE TABLE passenger_record (
    id SERIAL PRIMARY KEY,
    vehicle_id INT,
    route_id INT,
    date DATE NOT NULL,
    passenger_count INT CHECK (passenger_count >= 0),
    FOREIGN KEY (vehicle_id) REFERENCES vehicle(id) ON DELETE CASCADE,
    FOREIGN KEY (route_id) REFERENCES route(id) ON DELETE CASCADE
);
CREATE TABLE vehicle_driver (
    vehicle_id INT,
    driver_id INT,
    assignment_start_date DATE,
    assignment_end_date DATE,
    PRIMARY KEY (vehicle_id, driver_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicle(id) ON DELETE CASCADE,
    FOREIGN KEY (driver_id) REFERENCES driver(id) ON DELETE CASCADE
);
CREATE TABLE vehicle_route (
    vehicle_id INT,
    route_id INT,
    departure_time TIME NOT NULL,
    arrival_time TIME NOT NULL,
    assignment_date DATE,
    PRIMARY KEY (vehicle_id, route_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicle(id) ON DELETE CASCADE,
    FOREIGN KEY (route_id) REFERENCES route(id) ON DELETE CASCADE
);