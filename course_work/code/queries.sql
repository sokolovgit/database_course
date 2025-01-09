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
    AND citizens.last_name = 'Тарасенко';

-- поліцейські, які склали найбільше протоколів та постанов
WITH officer_counts AS (
    SELECT
        police_officers.id AS officer_id,
        get_citizen_full_name(police_officers.citizen_id) AS full_name,
        police_officers.rank,
        police_officers.badge_number,
        get_officer_protocol_count(police_officers.id) AS protocol_count,
        get_officer_resolution_count(police_officers.id) AS resolution_count
    FROM
        police_officers
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
    accident_resolutions.id AS resolution_id,
    accident_resolutions.series,
    accident_resolutions.number,
    accident_resolutions.time_of_consideration,
    accident_resolutions.time_of_entry_into_force,
    get_citizen_full_name(police_officers.citizen_id) AS officer_full_name,
    vehicles.registration_number,
    vehicles.vin
FROM
    accident_resolutions
    JOIN vehicles ON accident_resolutions.violation_id = vehicles.id
    JOIN police_officers ON vehicles.owner_id = police_officers.citizen_id
ORDER BY
    accident_resolutions.time_of_consideration DESC;

-- знайти громадян, які порушували ПДР найчастіше за останній рік
SELECT
    citizens.id,
    get_citizen_full_name(citizens.id),
    COUNT(violations.id)
FROM
    citizens
    JOIN vehicles ON citizens.id = vehicles.owner_id
    JOIN violations ON vehicles.id = violations.vehicle_id
WHERE
    violations.time_of_violation >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY
    citizens.id
ORDER BY
    COUNT(violations.id) DESC
LIMIT
    10;

-- знайти кількість порушників та порушень, які скоєні на автомобілях із звичайними номерами та іменними
WITH categorized_vehicles AS (
    SELECT
        vehicles.id,
        vehicles.registration_number,
        get_plate_type(vehicles.registration_number) AS plate_type
    FROM
        vehicles
),
violations_summary AS (
    SELECT
        categorized_vehicles.plate_type,
        COUNT(violations.id) AS violation_count
    FROM
        categorized_vehicles
        JOIN violations ON categorized_vehicles.id = violations.vehicle_id
    WHERE
        categorized_vehicles.plate_type IN ('regular', 'personalized')
    GROUP BY
        categorized_vehicles.plate_type
)
SELECT
    plate_type,
    violation_count
FROM
    violations_summary;

-- знайти кількість порушень по регіону реєстрації машини
SELECT
    get_region_by_code(
        SUBSTRING(
            vehicles.registration_number
            FROM
                1 FOR 2
        )
    ),
    COUNT(violations.id)
FROM
    violations
    JOIN vehicles ON violations.vehicle_id = vehicles.id
WHERE
    LENGTH(vehicles.registration_number) = 8
    AND SUBSTRING(
        vehicles.registration_number
        FROM
            1 FOR 2
    ) IN (
        SELECT
            DISTINCT LEFT(code_2004, 2)
        FROM
            regions
        UNION
        SELECT
            DISTINCT LEFT(code_2013, 2)
        FROM
            regions
        UNION
        SELECT
            DISTINCT LEFT(code_2021, 2)
        FROM
            regions
    )
GROUP BY
    get_region_by_code(
        SUBSTRING(
            vehicles.registration_number
            FROM
                1 FOR 2
        )
    )
ORDER BY
    COUNT(violations.id) DESC;

-- знайти кількість порушень машинами із та без страхового полісу
SELECT
    CASE
        WHEN vehicles.insurance_policy_number IS NOT NULL THEN 'With Insurance'
        ELSE 'Without Insurance'
    END AS insurance_status,
    COUNT(violations.id) AS violation_count
FROM
    vehicles
    LEFT JOIN violations ON vehicles.id = violations.vehicle_id
GROUP BY
    CASE
        WHEN vehicles.insurance_policy_number IS NOT NULL THEN 'With Insurance'
        ELSE 'Without Insurance'
    END
ORDER BY
    violation_count DESC;

-- знайти перелік транспортних засобів, що порушили ПДР за останній місяць
SELECT
    full_vehicle_info.vehicle_id,
    full_vehicle_info.registration_number,
    full_vehicle_info.model,
    full_vehicle_info.brand,
    full_vehicle_info.color,
    full_vehicle_info.year_of_manufacture,
    full_vehicle_info.vin,
    full_vehicle_info.insurance_policy_number,
    full_vehicle_info.engine_capacity,
    full_vehicle_info.seating_capacity,
    full_vehicle_info.owner_full_name,
    full_vehicle_info.region,
    COUNT(violations.id) AS violation_count
FROM
    full_vehicle_info
    JOIN violations ON full_vehicle_info.vehicle_id = violations.vehicle_id
WHERE
    violations.time_of_violation >= CURRENT_DATE - INTERVAL '1 month'
GROUP BY
    full_vehicle_info.vehicle_id,
    full_vehicle_info.registration_number,
    full_vehicle_info.model,
    full_vehicle_info.brand,
    full_vehicle_info.color,
    full_vehicle_info.year_of_manufacture,
    full_vehicle_info.vin,
    full_vehicle_info.insurance_policy_number,
    full_vehicle_info.engine_capacity,
    full_vehicle_info.seating_capacity,
    full_vehicle_info.owner_full_name,
    full_vehicle_info.region
ORDER BY
    violation_count DESC;

-- знайти постанови із штрафами
SELECT
    accident_resolutions.id AS resolution_id,
    accident_resolutions.series,
    accident_resolutions.number,
    accident_resolutions.time_of_consideration,
    accident_resolutions.time_of_entry_into_force,
    accident_resolutions.violation_id,
    accident_resolutions.police_officer_id,
    accident_resolutions.location_id,
    administrative_offenses.penalty_fee
FROM
    accident_resolutions
    JOIN violations ON accident_resolutions.violation_id = violations.id
    JOIN administrative_offenses ON violations.administrative_offense_id = administrative_offenses.id
WHERE
    administrative_offenses.penalty_fee > 0
ORDER BY
    accident_resolutions.time_of_consideration DESC;

-- список адміністративних порушень із кількістю порушень
SELECT
    administrative_offenses.id AS offense_id,
    get_administrative_offense_info(administrative_offenses.id),
    administrative_offenses.description,
    administrative_offenses.penalty_fee,
    COUNT(violations.id) AS violation_count
FROM
    administrative_offenses
    LEFT JOIN violations ON administrative_offenses.id = violations.administrative_offense_id
GROUP BY
    administrative_offenses.id,
    administrative_offenses.article,
    administrative_offenses.part,
    administrative_offenses.description,
    administrative_offenses.penalty_fee
ORDER BY
    violation_count DESC;

-- список доказів для конкретного порушення
SELECT
    evidences.id AS evidence_id,
    evidences.violation_id,
    evidences.type AS evidence_type,
    evidences.url AS evidence_url
FROM
    evidences
WHERE
    violation_id = 1
ORDER BY
    evidences.violation_id,
    evidences.id;

-- водії, які зробили два однакові порушення  за перші два роки після отримання водійскього посвідчення
SELECT
    drivers.id AS driver_id,
    get_citizen_full_name(citizens.id) AS driver_name,
    violations.administrative_offense_id,
    get_administrative_offense_info(administrative_offense_id) AS offense_article,
    administrative_offenses.description AS offense_description,
    administrative_offenses.penalty_fee,
    COUNT(violations.id) AS violation_count
FROM
    drivers
    JOIN citizens ON drivers.citizen_id = citizens.id
    JOIN vehicles ON vehicles.owner_id = citizens.id
    JOIN violations ON violations.vehicle_id = vehicles.id
    JOIN administrative_offenses ON violations.administrative_offense_id = administrative_offenses.id
WHERE
    violations.time_of_violation BETWEEN drivers.license_issued_time
    AND drivers.license_issued_time + INTERVAL '2 years'
GROUP BY
    drivers.id,
    citizens.id,
    violations.administrative_offense_id,
    administrative_offenses.article,
    administrative_offenses.sup,
    administrative_offenses.part,
    administrative_offenses.description,
    administrative_offenses.penalty_fee
HAVING
    COUNT(violations.id) >= 2
ORDER BY
    driver_id,
    violation_count DESC;





















--топ моделей автомобілів з найбільшою відносною кількістю правопорушень
SELECT
    vehicles.brand,
    COUNT(vehicles.id) AS total_vehicles,
    COUNT(violations.id) AS total_violations,
    (
        COUNT(violations.id) :: DECIMAL / COUNT(vehicles.id) * 100
    ) AS violation_percentage
FROM
    vehicles
    LEFT JOIN violations ON vehicles.id = violations.vehicle_id
GROUP BY
    vehicles.brand
HAVING
    COUNT(vehicles.id) > 0
    AND COUNT(vehicles.id) > 200
ORDER BY
    violation_percentage DESC;























-- кількість порушень без протоколів, постанов, із протоколами та постановами, загальна кількість порушень
SELECT
    COUNT(*) FILTER (
        WHERE
            accident_protocols.id IS NULL
            AND accident_resolutions.id IS NULL
    ) AS violations_without_protocol_or_resolution,
    COUNT(*) FILTER (
        WHERE
            accident_protocols.id IS NOT NULL
            OR accident_resolutions.id IS NOT NULL
    ) AS violations_with_protocol_or_resolution,
    COUNT(*) AS total_violations
FROM
    violations
    LEFT JOIN accident_protocols ON violations.id = accident_protocols.violation_id
    LEFT JOIN accident_resolutions ON violations.id = accident_resolutions.violation_id;

-- громадяни з найбільшою кількістю свідчень на інших осіб
SELECT
    citizens.id,
    citizens.first_name,
    citizens.last_name,
    citizens.patronymic,
    COUNT(citizens_on_protocol.id) AS testimony_count
FROM
    citizens
    JOIN citizens_on_protocol ON citizens.id = citizens_on_protocol.citizen_id
WHERE
    citizens_on_protocol.role = 'witness'
GROUP BY
    citizens.id,
    citizens.first_name,
    citizens.last_name,
    citizens.patronymic
ORDER BY
    testimony_count DESC
LIMIT
    10;

-- громадяни які були і свідками і порушниками
SELECT
    get_citizen_full_name(c.id) AS full_name,
    COUNT(
        CASE
            WHEN citizens_on_protocol.role = 'witness' THEN 1
        END
    ) AS witness_count,
    COUNT(
        CASE
            WHEN cop_defendant.role = 'victim' THEN 1
        END
    ) AS victim_count
FROM
    citizens c
    JOIN citizens_on_protocol ON c.id = citizens_on_protocol.citizen_id
    JOIN accident_protocols ON citizens_on_protocol.protocol_id = accident_protocols.id
    JOIN citizens_on_protocol cop_defendant ON accident_protocols.defendant_id = cop_defendant.citizen_id
WHERE
    citizens_on_protocol.role = 'witness'
    AND cop_defendant.role = 'victim'
GROUP BY
    c.id,
    full_name;

-- топ громадян за сумою штрафів
SELECT
    get_citizen_full_name(citizens.id) AS full_name,
    COALESCE(SUM(administrative_offenses.penalty_fee), 0) AS total_fines,
    COALESCE(COUNT(violations.id), 0) AS total_violations
FROM
    citizens
    LEFT JOIN vehicles ON citizens.id = vehicles.owner_id
    LEFT JOIN violations ON vehicles.id = violations.vehicle_id
    LEFT JOIN administrative_offenses ON violations.administrative_offense_id = administrative_offenses.id
GROUP BY
    citizens.id
ORDER BY
    total_fines DESC
LIMIT
    50;

-- найчастіше порушувані статті за типом транспортного засобу
SELECT
    vehicle_types.name AS vehicle_type,
    get_administrative_offense_info(administrative_offenses.id) AS administrative_offense,
    administrative_offenses.description,
    COUNT(violations.id) AS violations_count
FROM
    vehicles
    JOIN vehicle_types ON vehicles.vehicle_type_id = vehicle_types.id
    JOIN violations ON vehicles.id = violations.vehicle_id
    JOIN administrative_offenses ON violations.administrative_offense_id = administrative_offenses.id
GROUP BY
    vehicle_types.name,
    administrative_offense,
    administrative_offenses.description
ORDER BY
    vehicle_types.name,
    violations_count DESC;

-- топ водіїв автобусів, які отримали протокол чи постанову за керування у нетверезому стані
SELECT
    citizens.id AS citizen_id,
    get_citizen_full_name(citizens.id) AS full_name,
    COUNT(accident_protocols.id) AS protocol_count
FROM
    drivers
    JOIN vehicles ON drivers.citizen_id = vehicles.owner_id
    JOIN vehicle_types ON vehicles.vehicle_type_id = vehicle_types.id
    JOIN accident_protocols ON accident_protocols.defendant_id = drivers.citizen_id
    JOIN violations ON violations.id = accident_protocols.violation_id
    JOIN traffic_rules ON traffic_rules.id = violations.traffic_rule_id
    JOIN administrative_offenses ON administrative_offenses.id = violations.administrative_offense_id
    JOIN citizens ON citizens.id = drivers.citizen_id
WHERE
    vehicle_types.name = 'Bus'
    AND (
        --         пункт ПДР або КУпАП про водіння у нетверезому стані
        (
            traffic_rules.article = 2
            AND traffic_rules.part = 9
        )
        OR (
            administrative_offenses.article = 130
            AND administrative_offenses.part = 1
        )
    )
GROUP BY
    citizens.id,
    full_name
ORDER BY
    protocol_count DESC
LIMIT
    10;








-- знайти кількість свідків та жертв для протоколів
SELECT
    accident_protocols.id AS protocol_id,
    COUNT(
        CASE
            WHEN citizens_on_protocol.role = 'witness' THEN 1
        END
    ) AS witness_count,
    COUNT(
        CASE
            WHEN citizens_on_protocol.role = 'victim' THEN 1
        END
    ) AS victim_count
FROM
    accident_protocols
    LEFT JOIN citizens_on_protocol ON accident_protocols.id = citizens_on_protocol.protocol_id
GROUP BY
    accident_protocols.id
ORDER BY
    accident_protocols.id;

-- Найпоширеніший тип порушень ПДР по кожній вулиці
SELECT
    locations.street,
    get_administrative_offense_info(violations.administrative_offense_id) AS administrative_offense,
    COUNT(violations.id) AS violation_count
FROM
    violations
    JOIN locations ON violations.location_id = locations.id
GROUP BY
    locations.street,
    administrative_offense
ORDER BY
    locations.street,
    violation_count DESC;























-- Водії, які мають транспортні засоби різних типів
SELECT
    citizens.first_name,
    citizens.last_name,
    COUNT(DISTINCT vehicles.vehicle_type_id) AS vehicle_types
FROM
    citizens
    JOIN vehicles ON citizens.id = vehicles.owner_id
GROUP BY
    citizens.id
HAVING
    COUNT(DISTINCT vehicles.vehicle_type_id) > 1
ORDER BY
    vehicle_types DESC;
