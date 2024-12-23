CREATE TABLE vehicle_operations_log (
    operation VARCHAR(10),
    vehicle_id INT,
    model VARCHAR(50),
    old_status VARCHAR(50),
    new_status VARCHAR(50),
    operation_date TIMESTAMP
);