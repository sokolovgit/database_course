ALTER TABLE driver
DROP COLUMN phone_number;

ALTER TABLE route
DROP CONSTRAINT unique_route_name;

ALTER TABLE vehicle
DROP CONSTRAINT vehicle_status_check;

-- DROP TABLE vehicle_route;

ALTER TABLE driver
DROP CONSTRAINT driver_team_id_fkey;