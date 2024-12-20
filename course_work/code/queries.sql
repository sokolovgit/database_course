-- Перелік всіх громадян та їх водійських посвідчень
SELECT
    citizens.first_name,
    citizens.last_name,
    drivers.license_number,
    drivers.license_issued_time
FROM
    citizens
    LEFT JOIN drivers ON citizens.id = drivers.citizen_id;

-- Протоколи для певного громадянина
SELECT
    citizens.first_name,
    citizens.last_name,
    accident_protocols.id,
    accident_protocols.series,
    accident_protocols.number,
    accident_protocols.defendant_explanation,
    accident_protocols.time_of_drawing_up,
    accident_protocols.violation_id,
    accident_protocols.police_officer_id,
    accident_protocols.defendant_id
FROM
    accident_protocols
    JOIN citizens_on_protocol ON accident_protocols.id = citizens_on_protocol.protocol_id
    JOIN citizens ON citizens_on_protocol.citizen_id = citizens.id
WHERE
    citizens.first_name = 'Володимир'
    AND citizens.last_name = 'Скиба';

-- поліцейські, які склали найбільше протоколів та постанов
WITH officer_counts AS (
    SELECT
        po.id AS officer_id,
        get_citizen_full_name(po.citizen_id) AS full_name,
        po.rank,
        po.badge_number,
        get_officer_protocol_count(po.id) AS protocol_count,
        get_officer_resolution_count(po.id) AS resolution_count
    FROM
        police_officers po
)
SELECT
    full_name,
    rank,
    badge_number,
    protocol_count,
    resolution_count
FROM
    officer_counts
ORDER BY
    protocol_count DESC,
    resolution_count DESC;

-- постанови, де автомобіль знаходиться у власності поліцейського
SELECT
    ar.id AS resolution_id,
    ar.series,
    ar.number,
    ar.time_of_consideration,
    ar.time_of_entry_into_force,
    get_citizen_full_name(po.citizen_id) AS officer_full_name,
    v.registration_number,
    v.vin
FROM
    accident_resolutions ar
    JOIN vehicles v ON ar.violation_id = v.id
    JOIN police_officers po ON v.owner_id = po.citizen_id
ORDER BY
    ar.time_of_consideration DESC;

-- знайти громадян, які порушували ПДР найчастіше за останній рік
SELECT
    c.id AS citizen_id,
    get_citizen_full_name(c.id) AS full_name,
    COUNT(v.id) AS violation_count
FROM
    citizens c
    JOIN vehicles ve ON c.id = ve.owner_id
    JOIN violations v ON ve.id = v.vehicle_id
WHERE
    v.time_of_violation >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY
    c.id
ORDER BY
    violation_count DESC
LIMIT
    10;

-- знайти кількість порушників та порушень, які скоєні на автомобілях із звичайними номерами та іменними
WITH categorized_vehicles AS (
    SELECT
        v.id AS vehicle_id,
        v.registration_number,
        get_plate_type(v.registration_number) AS plate_type
    FROM
        vehicles v
),
violations_summary AS (
    SELECT
        cv.plate_type,
        COUNT(v.id) AS violation_count
    FROM
        categorized_vehicles cv
        JOIN violations v ON cv.vehicle_id = v.vehicle_id
    WHERE
        cv.plate_type IN ('regular', 'personalized')
    GROUP BY
        cv.plate_type
)
SELECT
    plate_type,
    violation_count
FROM
    violations_summary;

-- знайти кількість порушень по регіону реєстрації машини
WITH categorized_vehicles AS (
    SELECT
        v.id AS vehicle_id,
        v.registration_number,
        get_plate_type(v.registration_number) AS plate_type
    FROM
        vehicles v
),
region_violations AS (
    SELECT
        get_region_by_code(
            SUBSTRING(
                cv.registration_number
                FROM
                    1 FOR 2
            )
        ) AS region,
        COUNT(v.id) AS violation_count
    FROM
        categorized_vehicles cv
        JOIN violations v ON cv.vehicle_id = v.vehicle_id
    WHERE
        cv.plate_type = 'regular'
    GROUP BY
        region
)
SELECT
    region,
    violation_count
FROM
    region_violations
ORDER BY
    violation_count DESC;

-- знайти кількість порушень машинами із та без страхового полісу
SELECT
    CASE
        WHEN v.insurance_policy_number IS NOT NULL THEN 'With Insurance'
        ELSE 'Without Insurance'
    END AS insurance_status,
    COUNT(vi.id) AS violation_count
FROM
    vehicles v
    LEFT JOIN violations vi ON v.id = vi.vehicle_id
GROUP BY
    insurance_status
ORDER BY
    violation_count DESC;

-- знайти перелік транспортних засобів, що порушили ПДР за останній місяць
SELECT
    fvi.vehicle_id,
    fvi.registration_number,
    fvi.model,
    fvi.brand,
    fvi.color,
    fvi.year_of_manufacture,
    fvi.vin,
    fvi.insurance_policy_number,
    fvi.engine_type,
    fvi.engine_capacity,
    fvi.seating_capacity,
    fvi.owner_full_name,
    fvi.region,
    COUNT(vi.id) AS violation_count
FROM
    full_vehicle_info fvi
    JOIN violations vi ON fvi.vehicle_id = vi.vehicle_id
WHERE
    vi.time_of_violation >= CURRENT_DATE - INTERVAL '1 month'
GROUP BY
    fvi.vehicle_id,
    fvi.registration_number,
    fvi.model,
    fvi.brand,
    fvi.color,
    fvi.year_of_manufacture,
    fvi.vin,
    fvi.insurance_policy_number,
    fvi.engine_type,
    fvi.engine_capacity,
    fvi.seating_capacity,
    fvi.owner_full_name,
    fvi.region
ORDER BY
    violation_count DESC;

-- знайти постанови із штрафами
SELECT
    ar.id AS resolution_id,
    ar.series,
    ar.number,
    ar.time_of_consideration,
    ar.time_of_entry_into_force,
    ar.violation_id,
    ar.police_officer_id,
    ar.location_id,
    ao.penalty_fee
FROM
    accident_resolutions ar
    JOIN violations v ON ar.violation_id = v.id
    JOIN administrative_offenses ao ON v.administrative_offense_id = ao.id
WHERE
    ao.penalty_fee > 0
ORDER BY
    ar.time_of_consideration DESC;

-- список адміністративних порушень із кількістю порушень
SELECT
    ao.id AS offense_id,
    get_administrative_offense_info(ao.id),
    ao.description,
    ao.penalty_fee,
    COUNT(v.id) AS violation_count
FROM
    administrative_offenses ao
    LEFT JOIN violations v ON ao.id = v.administrative_offense_id
GROUP BY
    ao.id,
    ao.article,
    ao.part,
    ao.description,
    ao.penalty_fee
ORDER BY
    violation_count DESC;

-- список доказів для конкретного порушення
SELECT
    e.id AS evidence_id,
    e.violation_id,
    e.type AS evidence_type,
    e.url AS evidence_url
FROM
    evidences e
ORDER BY
    e.violation_id,
    e.id;

-- водії, які зробили два однакові порушення  за перші два роки після отримання водійскього посвідчення
SELECT
    d.id AS driver_id,
    get_citizen_full_name(c.id) AS driver_name,
    v.administrative_offense_id,
    ao.article || COALESCE('(' || ao.sup || ').', '.') || ao.part AS offense_article,
    ao.description AS offense_description,
    ao.penalty_fee,
    COUNT(v.id) AS violation_count
FROM
    drivers d
    JOIN citizens c ON d.citizen_id = c.id
    JOIN vehicles veh ON veh.owner_id = c.id
    JOIN violations v ON v.vehicle_id = veh.id
    JOIN administrative_offenses ao ON v.administrative_offense_id = ao.id
WHERE
    v.time_of_violation BETWEEN d.license_issued_time
    AND d.license_issued_time + INTERVAL '2 years'
GROUP BY
    d.id,
    c.id,
    v.administrative_offense_id,
    ao.article,
    ao.sup,
    ao.part,
    ao.description,
    ao.penalty_fee
HAVING
    COUNT(v.id) >= 2
ORDER BY
    driver_id,
    violation_count DESC;

--топ моделей автомобілів з найбільшою відносною кількістю правопорушень
SELECT
    veh.brand,
    COUNT(veh.id) AS total_vehicles,
    COUNT(v.id) AS total_violations,
    (COUNT(v.id) :: DECIMAL / COUNT(veh.id) * 100) AS violation_percentage
FROM
    vehicles veh
    LEFT JOIN violations v ON veh.id = v.vehicle_id
GROUP BY
    veh.brand
HAVING
    COUNT(veh.id) > 0
    AND COUNT(veh.id) > 200
ORDER BY
    violation_percentage DESC;

-- кількість порушень без протоколів, постанов, із протоколами та постановами, загальна кількість порушень
SELECT
    COUNT(*) FILTER (
        WHERE
            ap.id IS NULL
            AND ar.id IS NULL
    ) AS violations_without_protocol_or_resolution,
    COUNT(*) FILTER (
        WHERE
            ap.id IS NOT NULL
            OR ar.id IS NOT NULL
    ) AS violations_with_protocol_or_resolution,
    COUNT(*) AS total_violations
FROM
    violations v
    LEFT JOIN accident_protocols ap ON v.id = ap.violation_id
    LEFT JOIN accident_resolutions ar ON v.id = ar.violation_id;

-- громадяни з найбільшою кількістю свідчень на інших осіб
SELECT
    c.id,
    c.first_name,
    c.last_name,
    c.patronymic,
    COUNT(cop.id) AS testimony_count
FROM
    citizens c
    JOIN citizens_on_protocol cop ON c.id = cop.citizen_id
WHERE
    cop.role = 'witness'
GROUP BY
    c.id,
    c.first_name,
    c.last_name,
    c.patronymic
ORDER BY
    testimony_count DESC
LIMIT
    10;

-- громадяни які були і свідками і порушниками
SELECT
    get_citizen_full_name(c.id) AS full_name,
    COUNT(
        CASE
            WHEN cop_witness.role = 'witness' THEN 1
        END
    ) AS witness_count,
    COUNT(
        CASE
            WHEN cop_defendant.role = 'victim' THEN 1
        END
    ) AS victim_count
FROM
    citizens c
    JOIN citizens_on_protocol cop_witness ON c.id = cop_witness.citizen_id
    JOIN accident_protocols ap ON cop_witness.protocol_id = ap.id
    JOIN citizens_on_protocol cop_defendant ON ap.defendant_id = cop_defendant.citizen_id
WHERE
    cop_witness.role = 'witness'
    AND cop_defendant.role = 'victim'
GROUP BY
    c.id,
    full_name;

-- топ громадян за сумою штрафів
SELECT
    CONCAT(
        c.first_name,
        ' ',
        c.last_name,
        ' ',
        COALESCE(c.patronymic, '')
    ) AS full_name,
    COALESCE(SUM(ao.penalty_fee), 0) AS total_fines,
    COALESCE(COUNT(vio.id), 0) AS total_violations
FROM
    citizens c
    LEFT JOIN vehicles v ON c.id = v.owner_id
    LEFT JOIN violations vio ON v.id = vio.vehicle_id
    LEFT JOIN administrative_offenses ao ON vio.administrative_offense_id = ao.id
GROUP BY
    c.id
ORDER BY
    total_fines DESC
LIMIT
    50;

-- найчастіше порушувані статті за типом транспортного засобу
SELECT
    vt.name AS vehicle_type,
    get_administrative_offense_info(ao.id) as administrative_offense,
    ao.description,
    COUNT(vio.id) AS violations_count
FROM
    vehicles v
    JOIN vehicle_types vt ON v.vehicle_type_id = vt.id
    JOIN violations vio ON v.id = vio.vehicle_id
    JOIN administrative_offenses ao ON vio.administrative_offense_id = ao.id
GROUP BY
    vt.name,
    administrative_offense,
    ao.description
ORDER BY
    vt.name,
    violations_count DESC;

-- топ водіїв автобусів, які отримали протокол чи постанову за керування у нетверезому стані
SELECT
    c.id as citizen_id,
    get_citizen_full_name(c.id) AS full_name,
    COUNT(ap.id) AS protocol_count
FROM
    drivers d
    JOIN vehicles v ON d.citizen_id = v.owner_id
    JOIN vehicle_types vt ON v.vehicle_type_id = vt.id
    JOIN accident_protocols ap ON ap.defendant_id = d.citizen_id
    JOIN violations vio ON vio.id = ap.violation_id
    JOIN traffic_rules tr ON tr.id = vio.traffic_rule_id
    JOIN administrative_offenses ao ON ao.id = vio.administrative_offense_id
    JOIN citizens c ON c.id = d.citizen_id
WHERE
    vt.name = 'Bus'
    AND (
        --         пункт ПДР або КУпАП про водіння у нетверезому стані
        (
            tr.article = 2
            AND tr.part = 9
        )
        OR (
            ao.article = 130
            AND ao.part = 1
        )
    )
GROUP BY
    c.id,
    full_name
ORDER BY
    protocol_count DESC
LIMIT
    10;

-- ---------------------------------------------------------------------------------------
-- знайти кількість свідків та жертв для протоколів
SELECT
    ap.id AS protocol_id,
    COUNT(
        CASE
            WHEN cop.role = 'witness' THEN 1
        END
    ) AS witness_count,
    COUNT(
        CASE
            WHEN cop.role = 'victim' THEN 1
        END
    ) AS victim_count
FROM
    accident_protocols ap
    LEFT JOIN citizens_on_protocol cop ON ap.id = cop.protocol_id
GROUP BY
    ap.id
ORDER BY
    ap.id;

-- Найпоширеніший тип порушень ПДР по кожній вулиці
SELECT
    locations.street,
    get_administrative_offense_info(v.administrative_offense_id) as administrative_offense,
    COUNT(v.id) AS violation_count
FROM
    violations v
    JOIN locations ON v.location_id = locations.id
GROUP BY
    locations.street,
    administrative_offense
ORDER BY
    locations.street,
    violation_count DESC;

-- Водії, які мають транспортні засоби різних типів
SELECT
    c.first_name,
    c.last_name,
    COUNT(DISTINCT v.vehicle_type_id) AS vehicle_types
FROM
    citizens c
    JOIN vehicles v ON c.id = v.owner_id
GROUP BY
    c.id
HAVING
    COUNT(DISTINCT v.vehicle_type_id) > 1
ORDER BY
    vehicle_types DESC;

WITH ranked_officers AS (
    SELECT
        po.rank,
        po.id AS officer_id,
        COUNT(ap.id) AS protocol_count,
        COUNT(ar.id) as resolution_count,
        RANK() OVER (
            PARTITION BY po.rank
            ORDER BY
                COUNT(ap.id) DESC
        ) AS rank
    FROM
        police_officers po
        LEFT JOIN accident_protocols ap ON po.id = ap.police_officer_id
        LEFT JOIN accident_resolutions ar ON po.id = ar.police_officer_id
    GROUP BY
        po.rank,
        po.id
)
SELECT
    po.rank,
    po.badge_number,
    ro.protocol_count,
    ro.resolution_count
FROM
    police_officers po
    JOIN ranked_officers ro ON po.id = ro.officer_id;