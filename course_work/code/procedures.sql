CREATE OR REPLACE PROCEDURE transfer_vehicle_ownership(
    vehicle_id INT,
    new_owner_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_owner_id INT;
BEGIN

    SELECT owner_id INTO current_owner_id
    FROM vehicles
    WHERE id = vehicle_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Vehicle with ID % does not exist.', vehicle_id;
    END IF;


    IF NOT EXISTS (
        SELECT 1 FROM citizens WHERE id = new_owner_id
    ) THEN
        RAISE EXCEPTION 'New owner with ID % does not exist.', new_owner_id;
    END IF;

    UPDATE vehicles
    SET owner_id = new_owner_id
    WHERE id = vehicle_id;

    RAISE NOTICE 'Ownership of vehicle ID % transferred to citizen ID %', vehicle_id, new_owner_id;
END;
$$;

SELECT * FROM vehicles WHERE id = 1;
CALL transfer_vehicle_ownership(1, 2);
SELECT * FROM vehicles WHERE id = 1;


CREATE OR REPLACE PROCEDURE register_violation(
    p_vehicle_id INT,
    p_location_id INT,
    p_administrative_offense_id INT,
    p_traffic_rule_id INT,
    p_time_of_violation TIMESTAMPTZ,
    p_description TEXT,
    p_evidence_type EVIDENCE_TYPE DEFAULT NULL,
    p_evidence_url TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    violation_id INT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM vehicles WHERE id = p_vehicle_id
    ) THEN
        RAISE EXCEPTION 'Vehicle with ID % does not exist.', p_vehicle_id;
    END IF;

    INSERT INTO violations (
        vehicle_id, location_id, administrative_offense_id, traffic_rule_id,
        time_of_violation, description
    )
    VALUES (
        p_vehicle_id, p_location_id, p_administrative_offense_id, p_traffic_rule_id,
        p_time_of_violation, p_description
    )
    RETURNING id INTO violation_id;

    IF p_evidence_type IS NOT NULL AND p_evidence_url IS NOT NULL THEN
        INSERT INTO evidences (violation_id, type, url)
        VALUES (violation_id, p_evidence_type, p_evidence_url);
    END IF;

    RAISE NOTICE 'Violation ID % registered successfully.', violation_id;
END;
$$;


CALL register_violation(2, 1, 1, 1, CURRENT_TIMESTAMP, 'Speeding');
CALL register_violation(
    2, 1, 1, 1, CURRENT_TIMESTAMP, 'Speeding with proof', 'photo', 'http://example.com/photo.jpg'
);


-- Verify Results
SELECT * FROM violations WHERE vehicle_id = 2;
SELECT * FROM evidences WHERE violation_id = 30005;






