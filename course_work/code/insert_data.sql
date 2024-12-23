COPY traffic_rules (article, part, description)
FROM
        '/private/tmp/traffic_rules.csv' DELIMITER ',' CSV HEADER;

COPY administrative_offenses (article, sup, part, description, penalty_fee)
FROM
        '/private/tmp/administrative_offenses.csv' DELIMITER ',' CSV HEADER;

COPY citizens (
        id,
        first_name,
        last_name,
        patronymic,
        date_of_birth
)
FROM
        '/private/tmp/citizens.csv' DELIMITER ',' CSV HEADER;

COPY drivers (
        id,
        citizen_id,
        license_number,
        license_issued_time
)
FROM
        '/private/tmp/drivers.csv' DELIMITER ',' CSV HEADER;

COPY police_officers (id, citizen_id, badge_number, rank)
FROM
        '/private/tmp/police_officers.csv' DELIMITER ',' CSV HEADER;

COPY vehicles (
        id,
        owner_id,
        vehicle_type_id,
        registration_number,
        vin,
        insurance_policy_number,
        model,
        brand,
        color,
        engine_capacity,
        seating_capacity,
        year_of_manufacture
)
FROM
        '/private/tmp/vehicles.csv' DELIMITER ',' CSV HEADER;

COPY locations (
        id,
        longitude,
        latitude,
        street,
        building_number,
        description
)
FROM
        '/private/tmp/locations.csv' DELIMITER ',' CSV HEADER;

COPY violations (
        id,
        time_of_violation,
        description,
        vehicle_id,
        location_id,
        administrative_offense_id,
        traffic_rule_id
)
FROM
        '/private/tmp/violations.csv' DELIMITER ',' CSV HEADER;

COPY evidences (id, violation_id, type, url)
FROM
        '/private/tmp/evidences.csv' DELIMITER ',' CSV HEADER;

COPY accident_protocols (
        id,
        series,
        number,
        defendant_explanation,
        time_of_drawing_up,
        violation_id,
        police_officer_id,
        defendant_id
)
FROM
        '/private/tmp/accident_protocols.csv' DELIMITER ',' CSV HEADER;

COPY citizens_on_protocol (id, role, citizen_id, protocol_id, testimony)
FROM
        '/private/tmp/citizens_on_protocol.csv' DELIMITER ',' CSV HEADER;

COPY accident_resolutions (
        id,
        series,
        number,
        time_of_consideration,
        time_of_entry_into_force,
        violation_id,
        police_officer_id,
        location_id
)
FROM
        '/private/tmp/accident_resolutions.csv' DELIMITER ',' CSV HEADER;

INSERT INTO
        vehicle_types (
                NAME,
                DESCRIPTION,
                MIN_SEATING_CAPACITY,
                MAX_SEATING_CAPACITY,
                MIN_ENGINE_CAPACITY,
                MAX_ENGINE_CAPACITY
        )
VALUES
        (
                'Car',
                'Passenger car used for personal or commercial purposes.',
                2,
                8,
                1.0,
                6.0
        ),
        (
                'Electric Car',
                'Vehicle powered exclusively by electricity.',
                2,
                8,
                NULL,
                NULL
        ),
        (
                'Hybrid Vehicle',
                'Vehicle powered by a combination of internal combustion engine and electric motor.',
                2,
                8,
                1.0,
                6.0
        ),
        (
                'Motorcycle',
                'Two-wheeled motor vehicle.',
                1,
                2,
                0.1,
                2.0
        ),
        (
                'Van',
                'Larger motor vehicle designed for passenger or cargo transport.',
                2,
                15,
                2.0,
                6.0
        ),
        (
                'Truck',
                'Motor vehicle designed to transport goods or materials.',
                2,
                2,
                2.0,
                15.0
        ),
        (
                'Bus',
                'Motor vehicle designed to carry multiple passengers.',
                9,
                NULL,
                4.0,
                15.0
        ),
        (
                'Special Purpose Vehicle',
                'Vehicles such as fire trucks, ambulances, or police cars.',
                1,
                10,
                2.0,
                10.0
        ),
        (
                'Trailer',
                'Unpowered vehicle towed by another vehicle.',
                NULL,
                NULL,
                NULL,
                NULL
        ),
        (
                'Agricultural Vehicle',
                'Vehicles such as tractors used for farming purposes.',
                1,
                3,
                1.0,
                5.0
        ),
        (
                'ATV',
                'All-terrain vehicle used for off-road travel.',
                1,
                2,
                0.5,
                1.5
        ),
        (
                'Dump Truck',
                'Truck designed to transport and unload materials.',
                2,
                2,
                2.0,
                15.0
        );

INSERT INTO
        regions (region_name, code_2004, code_2013, code_2021)
VALUES
        ('AR Krym', 'AK', 'KK', 'TK'),
        ('Vinnytska oblast', 'AB', 'KB', 'IM'),
        ('Volynska oblast', 'AC', 'KC', 'CM'),
        ('Dnipropetrovska oblast', 'AE', 'KE', 'PP'),
        ('Donetska oblast', 'AH', 'KH', 'TH'),
        ('Zhytomyrska oblast', 'AM', 'KM', 'TM'),
        ('Zakarpatska oblast', 'AO', 'KO', 'MT'),
        ('Zaporizka oblast', 'AP', 'KP', 'TP'),
        ('Ivano-Frankivska oblast', 'AT', 'KT', 'TO'),
        ('Kyivska oblast', 'AI', 'KI', 'TI'),
        ('misto Kyiv', 'AA', 'KA', 'TT'),
        ('Kirovohradska oblast', 'BA', 'HA', 'XA'),
        ('Luhanska oblast', 'BB', 'HB', 'EP'),
        ('Lvivska oblast', 'BC', 'HC', 'CC'),
        ('Mykolaivska oblast', 'BE', 'HE', 'XE'),
        ('Odeska oblast', 'BH', 'HH', 'OO'),
        ('Poltavska oblast', 'BI', 'HI', 'XI'),
        ('Rivnenska oblast', 'BK', 'HK', 'XK'),
        ('Sumska oblast', 'BM', 'HM', 'XM'),
        ('Ternopilska oblast', 'BO', 'HO', 'XO'),
        ('Kharkivska oblast', 'AX', 'KX', 'XX'),
        ('Khersonska oblast', 'BT', 'HT', 'XT'),
        ('Khmelnytska oblast', 'BX', 'HX', 'OX'),
        ('Cherkaska oblast', 'CA', 'IA', 'OA'),
        ('Chernihivska oblast', 'CB', 'IB', 'OB'),
        ('Chernivetska oblast', 'CE', 'IE', 'OE'),
        ('misto Sevastopol', 'CH', 'IH', 'OH');