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
