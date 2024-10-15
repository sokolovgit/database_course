-- fill.sql
COPY foreman (id, name) FROM '/docker-entrypoint-initdb.d/csvs/foreman.csv' DELIMITER ',' CSV HEADER;
COPY team (id, name, foreman_id) FROM '/docker-entrypoint-initdb.d/csvs/team.csv' DELIMITER ',' CSV HEADER;
COPY driver (id, name, license_number, employment_date, team_id) FROM '/docker-entrypoint-initdb.d/csvs/driver.csv' DELIMITER ',' CSV HEADER;
COPY vehicle_type (id, name) FROM '/docker-entrypoint-initdb.d/csvs/vehicle_type.csv' DELIMITER ',' CSV HEADER;
COPY vehicle (id, registration_number, model, brand, year_of_manufacture, status, vehicle_type_id, capacity, load_capacity, team_id) FROM '/docker-entrypoint-initdb.d/csvs/vehicle.csv' DELIMITER ',' CSV HEADER;
COPY route (id, name, start_location, end_location, distance) FROM '/docker-entrypoint-initdb.d/csvs/route.csv' DELIMITER ',' CSV HEADER;
COPY passenger_record (id, vehicle_id, route_id, date, passenger_count) FROM '/docker-entrypoint-initdb.d/csvs/passenger_record.csv' DELIMITER ',' CSV HEADER;
COPY vehicle_driver (vehicle_id, driver_id, assignment_start_date, assignment_end_date) FROM '/docker-entrypoint-initdb.d/csvs/vehicle_driver.csv' DELIMITER ',' CSV HEADER;
COPY vehicle_route (vehicle_id, route_id, departure_time, arrival_time) FROM '/docker-entrypoint-initdb.d/csvs/vehicle_route.csv' DELIMITER ',' CSV HEADER;