-- a. Тригер на видалення даних

CREATE OR REPLACE FUNCTION log_vehicle_deletion()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO vehicle_operations_log (operation, vehicle_id, model, operation_date)
    VALUES ('DELETE', OLD.id, OLD.model, CURRENT_TIMESTAMP);

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER vehicle_delete_trigger
AFTER DELETE ON vehicle
FOR EACH ROW
EXECUTE FUNCTION log_vehicle_deletion();


INSERT INTO vehicle (id, registration_number, model, brand, year_of_manufacture, status, vehicle_type_id, capacity, load_capacity, team_id)
VALUES (33234, 'AB1223CD', 'Test Model', 'Test Brand', 2020, 'available', 1, 50, 1000, 1);

DELETE FROM vehicle WHERE id = 33234;

SELECT * FROM vehicle_operations_log WHERE operation = 'DELETE';

-- b. Тригер на модифікацію даних

CREATE OR REPLACE FUNCTION log_vehicle_update()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO vehicle_operations_log (operation, vehicle_id, old_status, new_status, operation_date)
    VALUES ('UPDATE', OLD.id, OLD.status, NEW.status, CURRENT_TIMESTAMP);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER vehicle_update_trigger
AFTER UPDATE ON vehicle
FOR EACH ROW
EXECUTE FUNCTION log_vehicle_update();


INSERT INTO vehicle (id, registration_number, model, brand, year_of_manufacture, status, vehicle_type_id, capacity, load_capacity, team_id)
VALUES (33234, 'AB1113CD', 'Test Model', 'Test Brand', 2020, 'available', 1, 50, 1000, 1);

UPDATE vehicle SET status = 'available' WHERE id = 33234;

SELECT * FROM vehicle_operations_log WHERE operation = 'UPDATE';


--  c. Тригер на додавання даних

CREATE OR REPLACE FUNCTION log_vehicle_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO vehicle_operations_log (operation, vehicle_id, model, operation_date)
    VALUES ('INSERT', NEW.id, NEW.model, CURRENT_TIMESTAMP);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER vehicle_insert_trigger
AFTER INSERT ON vehicle
FOR EACH ROW
EXECUTE FUNCTION log_vehicle_insert();

INSERT INTO vehicle (id, registration_number, model, brand, year_of_manufacture, status, vehicle_type_id, capacity, load_capacity, team_id)
VALUES (33336, 'AB1445CD', 'Test Model', 'Test Brand', 2020, 'available', 1, 50, 1000, 1);

SELECT * FROM vehicle_operations_log WHERE operation = 'INSERT';
