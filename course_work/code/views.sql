CREATE OR REPLACE VIEW violation_details AS
SELECT
    v.id AS violation_id,
    get_citizen_full_name(c.id) AS driver_name,
    veh.registration_number,
    loc.street || ', ' || loc.building_number AS location,
    loc.description as location_description,
    v.time_of_violation,
    v.description AS violation_description,
    tr.article || '.' || tr.part AS traffic_rule,
    ao.article || COALESCE('(' || ao.sup || ').', '.') || ao.part AS administrative_offense,
    ao.description AS administrative_offense_description,
    ao.penalty_fee


FROM violations v
JOIN vehicles veh ON v.vehicle_id = veh.id
JOIN citizens c ON veh.owner_id = c.id
JOIN locations loc ON v.location_id = loc.id
JOIN traffic_rules tr ON v.traffic_rule_id = tr.id
JOIN administrative_offenses ao ON v.administrative_offense_id = ao.id;



CREATE OR REPLACE VIEW full_vehicle_info AS
SELECT
    v.id AS vehicle_id,
    v.registration_number,
    v.model,
    v.brand,
    v.color,
    v.year_of_manufacture,
    v.vin,
    v.insurance_policy_number,
    v.engine_type,
    v.engine_capacity,
    v.seating_capacity,
    get_citizen_full_name(v.owner_id) AS owner_full_name,
    CASE
        WHEN get_plate_type(v.registration_number) = 'regular' THEN get_region_by_code(SUBSTRING(v.registration_number FROM 1 FOR 2))
        ELSE 'N/A'
    END AS region
FROM
    vehicles v;