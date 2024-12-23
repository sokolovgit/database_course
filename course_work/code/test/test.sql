CREATE OR REPLACE FUNCTION get_region_by_code(input_code VARCHAR) RETURNS VARCHAR AS $$ BEGIN RETURN CASE
        WHEN input_code IN ('AK', 'КК', 'TK', 'MK') THEN 'АР Крим'
        WHEN input_code IN ('AB', 'KB', 'IM', 'PI') THEN 'Вінницька область'
        WHEN input_code IN ('AC', 'KC', 'CM', 'TC') THEN 'Волинська область'
        WHEN input_code IN ('AE', 'KE', 'PP', 'MI') THEN 'Дніпропетровська область'
        WHEN input_code IN ('AH', 'KH', 'TH', 'MH') THEN 'Донецька область'
        WHEN input_code IN ('AM', 'KM', 'TM', 'MB') THEN 'Житомирська область'
        WHEN input_code IN ('AO', 'KO', 'MT', 'MO') THEN 'Закарпатська область'
        WHEN input_code IN ('AP', 'KP', 'TP', 'MP') THEN 'Запорізька область'
        WHEN input_code IN ('AT', 'KT', 'TO', 'XC') THEN 'Івано-Франківська область'
        WHEN input_code IN ('AI', 'KI', 'TI', 'EE') THEN 'Київська область'
        WHEN input_code IN ('AA', 'KA', 'TT', 'KK') THEN 'місто Київ'
        WHEN input_code IN ('BA', 'HA', 'XA', 'EA') THEN 'Кіровоградська область'
        WHEN input_code IN ('BB', 'HB', 'EP', 'EB') THEN 'Луганська область'
        WHEN input_code IN ('BC', 'HC', 'CC', 'EC') THEN 'Львівська область'
        WHEN input_code IN ('BE', 'HE', 'XE', 'XH') THEN 'Миколаївська область'
        WHEN input_code IN ('BH', 'HH', 'OO', 'EH') THEN 'Одеська область'
        WHEN input_code IN ('BI', 'HI', 'XI', 'EI') THEN 'Полтавська область'
        WHEN input_code IN ('BK', 'HK', 'XK', 'EK') THEN 'Рівненська область'
        WHEN input_code IN ('BM', 'HM', 'XM', 'EM') THEN 'Сумська область'
        WHEN input_code IN ('BO', 'HO', 'XO', 'EO') THEN 'Тернопільська область'
        WHEN input_code IN ('AX', 'KX', 'XX', 'EX') THEN 'Харківська область'
        WHEN input_code IN ('BT', 'HT', 'XT', 'ET') THEN 'Херсонська область'
        WHEN input_code IN ('BX', 'HX', 'OX', 'PX') THEN 'Хмельницька область'
        WHEN input_code IN ('CA', 'IA', 'OA', 'PA') THEN 'Черкаська область'
        WHEN input_code IN ('CB', 'IB', 'OB', 'PB') THEN 'Чернігівська область'
        WHEN input_code IN ('CE', 'IE', 'OE', 'PE') THEN 'Чернівецька область'
        WHEN input_code IN ('CH', 'IH', 'OH', 'PH') THEN 'місто Севастополь'
        ELSE 'Регіон не знайдено'
    END;
END;
$$ LANGUAGE plpgsql;


DO $$
DECLARE
    col_list TEXT;
    sql_query TEXT;
BEGIN
    -- Generate the list of dynamic columns
    SELECT string_agg(
        'SUM(CASE WHEN v.vehicle_type_id = ' || vehicle_type_id ||
        ' THEN 1 ELSE 0 END) AS type_' || vehicle_type_id, ', '
    ) INTO col_list
    FROM (SELECT DISTINCT vehicle_type_id FROM vehicles) t;

    -- Create the dynamic SQL query
    sql_query :=
    'SELECT
        c.first_name,
        c.last_name, ' || col_list ||
    ' FROM citizens c
      LEFT JOIN vehicles v ON c.id = v.owner_id
      GROUP BY c.id, c.first_name, c.last_name
      ORDER BY c.last_name, c.first_name;';

    -- Execute the dynamic SQL
    EXECUTE sql_query;
END $$;

SELECT * FROM violations WHERE violations.id = 1411  ;
