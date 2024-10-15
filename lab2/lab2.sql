-- a. створення БД згідно з розробленою в роботі No1 ER-моделлю;
-- CREATE DATABASE transport_company;

-- \c lab2;

-- b. створення таблиць в БД засобами мови SQL. Передбачити наявність
-- обмежень для підтримки цілісності та коректності даних, котрі
-- зберігаються та вводяться;

-- c. встановлення зв’язків між таблицями засобами мови SQL;
CREATE TABLE foreman (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE team (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    foreman_id INT,
    FOREIGN KEY (foreman_id) REFERENCES foreman(id) ON DELETE SET NULL
);

CREATE TABLE driver (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    license_number VARCHAR(50) UNIQUE NOT NULL,
    employment_date DATE,
    team_id INT,
    FOREIGN KEY (team_id) REFERENCES team(id) ON DELETE SET NULL
);

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
    year_of_manufacture INT CHECK (year_of_manufacture >= 1886 AND year_of_manufacture <= EXTRACT(YEAR FROM CURRENT_DATE)),
    status VARCHAR(50),
    vehicle_type_id INT,
    capacity INT CHECK (capacity > 0),
    load_capacity DECIMAL(10, 2) CHECK (load_capacity >= 0),
    team_id INT,
    FOREIGN KEY (vehicle_type_id) REFERENCES vehicle_type(id) ON DELETE SET NULL,
    FOREIGN KEY (team_id) REFERENCES team(id) ON DELETE SET NULL
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
    PRIMARY KEY (vehicle_id, route_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicle(id) ON DELETE CASCADE,
    FOREIGN KEY (route_id) REFERENCES route(id) ON DELETE CASCADE
);

-- d. зміни в структурах таблиць, обмежень засобами мови SQL (до 10
-- різних за суттю запитів для декількох таблиць (використати DDL-
-- команди SQL));

ALTER TABLE driver
ADD COLUMN phone_number VARCHAR(15);

ALTER TABLE vehicle
ALTER COLUMN status TYPE VARCHAR(20);

ALTER TABLE route
ADD CONSTRAINT unique_route_name UNIQUE (name);

ALTER TABLE vehicle_type
DROP COLUMN description;

ALTER TABLE vehicle
ADD CONSTRAINT vehicle_status_check CHECK (status IN ('active', 'maintenance', 'retired'));

ALTER TABLE team
ADD COLUMN team_lead BOOLEAN DEFAULT FALSE;

ALTER TABLE vehicle
DROP CONSTRAINT vehicle_year_of_manufacture_check;

ALTER TABLE vehicle
ADD CONSTRAINT vehicle_year_of_manufacture_check CHECK (year_of_manufacture >= 1886 AND year_of_manufacture <= EXTRACT(YEAR FROM CURRENT_DATE) + 1);

ALTER TABLE vehicle_route
ADD CONSTRAINT valid_time_check CHECK (departure_time < arrival_time);

-- e. видалення окремих елементів таблиць/обмежень або самих таблиць
-- засобами мови SQL (до 10 різних за суттю запитів (використати
-- DDL-команди SQL));

ALTER TABLE driver
DROP COLUMN phone_number;

ALTER TABLE route
DROP CONSTRAINT unique_route_name;

ALTER TABLE vehicle
DROP CONSTRAINT vehicle_status_check;

-- DROP TABLE vehicle_route;

ALTER TABLE driver
DROP CONSTRAINT driver_team_id_fkey;

-- f. визначити декілька (2-3) типів користувачів, котрі будуть
-- працювати з розробленою базою даних. Для кожного користувача
-- визначити набір привілеїв, котрі він буде мати;

-- g. для визначених типів користувачів створити відповідні ролі та
-- наділити їх необхідними привілеями;

-- h. створити по одному користувачу в базі даних для кожного типу та
-- присвоїти їм відповідні ролі.

CREATE ROLE admin;
CREATE ROLE manager;
CREATE ROLE driver;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON team, driver, vehicle TO manager;
GRANT SELECT ON passenger_record, route TO driver;

CREATE USER admin_user WITH PASSWORD 'admin_password';
CREATE USER manager_user WITH PASSWORD 'manager_password';
CREATE USER driver_user WITH PASSWORD 'driver_password';

GRANT admin TO admin_user;
GRANT manager TO manager_user;
GRANT driver TO driver_user;
