CREATE ROLE db_admin;
CREATE ROLE manager;
CREATE ROLE driver;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO db_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON team, driver, vehicle TO manager;
GRANT SELECT ON passenger_record, route TO driver;

CREATE USER admin_user WITH PASSWORD 'admin_password';
CREATE USER manager_user WITH PASSWORD 'manager_password';
CREATE USER driver_user WITH PASSWORD 'driver_password';

GRANT db_admin TO admin_user;
GRANT manager TO manager_user;
GRANT driver TO driver_user;