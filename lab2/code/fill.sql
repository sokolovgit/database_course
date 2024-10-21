COPY foreman (id, name) FROM '/private/tmp/csvs/foreman.csv' DELIMITER ',' CSV HEADER;
COPY team (id, name, foreman_id) FROM '/private/tmp/csvs/team.csv' DELIMITER ',' CSV HEADER;
COPY driver (id, name, license_number, employment_date, team_id) FROM '/private/tmp/csvs/driver.csv' DELIMITER ',' CSV HEADER;
COPY vehicle_type (id, name) FROM '/private/tmp/csvs/vehicle_type.csv' DELIMITER ',' CSV HEADER;
COPY vehicle (id, registration_number, model, brand, year_of_manufacture, status, vehicle_type_id, capacity, load_capacity, team_id) FROM '/private/tmp/csvs/vehicle.csv' DELIMITER ',' CSV HEADER;
COPY route (id, name, start_location, end_location, distance) FROM '/private/tmp/csvs/route.csv' DELIMITER ',' CSV HEADER;
COPY passenger_record (id, vehicle_id, route_id, date, passenger_count) FROM '/private/tmp/csvs/passenger_record.csv' DELIMITER ',' CSV HEADER;
COPY vehicle_driver (vehicle_id, driver_id, assignment_start_date, assignment_end_date) FROM '/private/tmp/csvs/vehicle_driver.csv' DELIMITER ',' CSV HEADER;
COPY vehicle_route (vehicle_id, route_id, departure_time, arrival_time) FROM '/private/tmp/csvs/vehicle_route.csv' DELIMITER ',' CSV HEADER;