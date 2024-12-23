CREATE INDEX idx_drivers_citizen_id ON drivers (citizen_id);
CREATE INDEX idx_police_officers_citizen_id ON police_officers (citizen_id);
CREATE INDEX idx_violations_vehicle_id ON violations (vehicle_id);
CREATE INDEX idx_violations_location_id ON violations (location_id);
CREATE INDEX idx_violations_administrative_offense_id ON violations (administrative_offense_id);
CREATE INDEX idx_violations_traffic_rule_id ON violations (traffic_rule_id);
CREATE INDEX idx_accident_protocols_violation_id ON accident_protocols (violation_id);
CREATE INDEX idx_accident_protocols_police_officer_id ON accident_protocols (police_officer_id);
CREATE INDEX idx_accident_protocols_defendant_id ON accident_protocols (defendant_id);
CREATE INDEX idx_citizens_on_protocol_citizen_id ON citizens_on_protocol (citizen_id);
CREATE INDEX idx_citizens_on_protocol_protocol_id ON citizens_on_protocol (protocol_id);

EXPLAIN ANALYZE
SELECT
    v.id AS violation_id,
    v.time_of_violation,
    v.description AS violation_description,
    v.location_id,
    v.administrative_offense_id,
    v.traffic_rule_id,
    a.series AS protocol_series,
    a.number AS protocol_number,
    a.time_of_drawing_up AS protocol_time,
    c.first_name AS police_officer_first_name,
    c.last_name AS police_officer_last_name,
    po.rank,
    ve.model AS vehicle_model,
    ve.registration_number AS vehicle_registration_number,
    ve.color AS vehicle_color,
    t.description AS traffic_rule_description,
    ao.penalty_fee AS administrative_offense_penalty
FROM
    violations v
JOIN
    accident_protocols a ON v.id = a.violation_id
JOIN
    police_officers po ON a.police_officer_id = po.id
JOIN
    citizens c ON po.citizen_id = c.id
JOIN
    vehicles ve ON v.vehicle_id = ve.id
JOIN
    traffic_rules t ON v.traffic_rule_id = t.id
JOIN
    administrative_offenses ao ON v.administrative_offense_id = ao.id;