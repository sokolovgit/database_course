"""
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
"""

from calendar import c
from os import write
from faker import Faker
from faker_vehicle import VehicleProvider
import csv


fake = Faker("uk_UA")
fake.add_provider(VehicleProvider)


def generate_vehicles(filename, count):
    vehicles = []
    
    for i in range(count):
        vehicle = {
            "id": i+1,
            "registration_number": fake.license_plate(),
            "model": fake.vehicle_model(),
            "brand": fake.vehicle_make(),
            "color": fake.color_name(),
            "max_speed": fake.random_int(min=100, max=300),
            "seating_capacity": fake.random_int(min=1, max=50),
            "year_of_manufacture": fake.random_int(min=1886, max=2021)
        }
        vehicles.append(vehicle)
        
    with open(filename, "w") as file:
        writer = csv.DictWriter(file, fieldnames=vehicles[0].keys())
        writer.writeheader()
        writer.writerows(vehicles)

def generate_employees(filename, count):
    employees = []
    
    for i in range(count):
        employee = {
            "id": i+1,
            "first_name": fake.first_name(),
            "last_name": fake.last_name(),
            "patronymic": fake.first_name(),
            "birth_date": fake.date_of_birth(minimum_age=18, maximum_age=65),
            "phone_number": fake.phone_number(),
            "email": fake.email()
        }
        employees.append(employee)
        
    with open(filename, "w") as file:
        writer = csv.DictWriter(file, fieldnames=employees[0].keys())
        writer.writeheader()
        writer.writerows(employees)

def generate_locations(filename, count):
    locations = []

    for i in range(count):
        location = {
            "id": i + 1,
            "longitude": fake.longitude(),
            "latitude": fake.latitude(),
            "street": fake.street_name(),
            "building_number": fake.building_number(),
            "description": fake.text(),
        }
        locations.append(location)

    with open(filename, "w") as file:
        writer = csv.DictWriter(file, fieldnames=locations[0].keys())
        writer.writeheader()
        writer.writerows(locations)

def generate_alarms(filename, count):
    alarms = []
    
    for i in range(count):
        alarm = {
            "id": i+1,
            "power": fake.random_element(elements=("accumulator", "wired", "combined")),
            "sensor": fake.random_element(elements=("movement", "glass_breakage", "door_opening", "temperature", "vibration")),
            "connection": fake.random_element(elements=("wired", "wifi", "radio")),
            "alert": fake.random_element(elements=("sms", "email", "phone_call", "app_notification")),
            "max_range": fake.random_int(min=1, max=100),
            "model": fake.word(),
            "brand": fake.word(),
            "details": fake.text()
        }
        alarms.append(alarm)
        
    with open(filename, "w") as file:
        writer = csv.DictWriter(file, fieldnames=alarms[0].keys())
        writer.writeheader()
        writer.writerows(alarms)

def generate_protected_objects(filename, count):
    protected_objects = []

    for i in range(count):
        protected_object = {
            "id": i + 1,
            "name": fake.word(),
            "location_id": fake.random_int(min=1, max=count),
        }
        protected_objects.append(protected_object)

    with open(filename, "w") as file:
        writer = csv.DictWriter(file, fieldnames=protected_objects[0].keys())
        writer.writeheader()
        writer.writerows(protected_objects)

def generate_alarms_on_objects(filename, count):
    alarms_on_objects = []

    for i in range(count):
        alarm_on_object = {
            "id": i + 1,
            "alarm_id": fake.random_int(min=1, max=count),
            "object_id": fake.random_int(min=1, max=count),
        }
        alarms_on_objects.append(alarm_on_object)

    with open(filename, "w") as file:
        writer = csv.DictWriter(file, fieldnames=alarms_on_objects[0].keys())
        writer.writeheader()
        writer.writerows(alarms_on_objects)

def generate_alarm_events(filename, count):
    alarm_events = []

    for i in range(count):
        alarm_event = {
            "id": i + 1,
            "alarm_id": fake.random_int(min=1, max=count),
            "triggered_at": fake.date_time_this_year(),
        }
        alarm_events.append(alarm_event)

    with open(filename, "w") as file:
        writer = csv.DictWriter(file, fieldnames=alarm_events[0].keys())
        writer.writeheader()
        writer.writerows(alarm_events)

def generate_alarm_events_results(filename, count):
    alarm_events_results = []
    alarm_event_result_options = ["відсутність взлому", "виявлено взлом", "виявлено відкриті двері", "виявлено відкрите вікно", 
                                  "виявлено відкриту дверцята", "виявлено відкриту люк", "виявлено відкриту кришку", "виявлено відкритий люк",
                                  "виявлено підпал", "виявлено витік газу", "виявлено витік води", "виявлено витік палива", "виявлено витік рідини",
                                  "крадіжка", "пожежа", "проникнення", "проникнення в приміщення", "проникнення на територію", "проникнення на об'єкт",
                                  ]

    for i in range(count):
        alarm_event_result = {
            "id": i + 1,
            "event_id": fake.random_int(min=1, max=count),
            "result": fake.random_element(elements=alarm_event_result_options),
        }
        alarm_events_results.append(alarm_event_result)

    with open(filename, "w") as file:
        writer = csv.DictWriter(file, fieldnames=alarm_events_results[0].keys())
        writer.writeheader()
        writer.writerows(alarm_events_results)

def generate_employees_departure_on_events(filename, count):
    employees_departure_on_events = []

    for i in range(count):
        employee_departure_on_event = {
            "id": i + 1,
            "employee_id": fake.random_int(min=1, max=count),
            "event_id": fake.random_int(min=1, max=count),
            "vehicle_id": fake.random_int(min=1, max=count),
            "arrived_at": fake.date_time_this_year(),
        }
        employees_departure_on_events.append(employee_departure_on_event)

    with open(filename, "w") as file:
        writer = csv.DictWriter(file, fieldnames=employees_departure_on_events[0].keys())
        writer.writeheader()
        writer.writerows(employees_departure_on_events)

if __name__ == "__main__":
    count = 10000
    generate_vehicles("vehicles.csv", count)
    generate_employees("employees.csv", count)
    generate_alarms("alarms.csv", count)
    generate_locations("locations.csv", count)
    generate_protected_objects("protected_objects.csv", count)
    generate_alarms_on_objects("alarms_on_objects.csv", count)
    generate_alarm_events("alarm_events.csv", count)
    generate_alarm_events_results("alarm_events_results.csv", count)
    generate_employees_departure_on_events("employees_departure_on_events.csv", count)
