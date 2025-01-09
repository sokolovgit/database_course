-- 3) Необхідно передбачити можливість отримання звіту
-- про роботу охоронного підприємства з вказанням інформації
-- про клієнтів та кількості виїздів до них за останній рік.
-- Для розвʼязання поставленої задачі використати курсори.
CREATE OR REPLACE FUNCTION generate_report_clients()
    RETURNS TABLE
            (
                object_name      VARCHAR,
                departures_count INT
            )
AS
$$
DECLARE
    client_cursor CURSOR FOR
        SELECT protected_objects.name, COUNT(employees_departure_on_events.id) as departure_count
        FROM protected_objects
                 LEFT JOIN employees_departure_on_events
                           ON protected_objects.id = employees_departure_on_events.event_id
        WHERE employees_departure_on_events.arrived_at > CURRENT_DATE - INTERVAL '1 year'
        GROUP BY protected_objects.name;
    client_record RECORD;
BEGIN
    OPEN client_cursor;

    LOOP
        FETCH client_cursor INTO client_record;

        EXIT WHEN NOT FOUND;

        object_name := client_record.name;
        departures_count := client_record.departure_count;

        RETURN NEXT;
    END LOOP;

    CLOSE client_cursor;
END;
$$ LANGUAGE plpgsql;


SELECT *
FROM generate_report_clients();