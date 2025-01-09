-- а) Обʼєкти, котрі розміщуються на проспекті
-- Перемоги та на них за минулий рік виїжджали не менше 5 разів.

SELECT protected_objects.name, COUNT(alarm_events.id)
FROM protected_objects
         JOIN locations ON protected_objects.location_id = locations.id
         JOIN alarms_on_objects ON protected_objects.id = alarms_on_objects.object_id
         JOIN alarm_events ON alarms_on_objects.alarm_id = alarm_events.alarm_id
         JOIN alarm_events_results ON alarm_events.id = alarm_events_results.event_id
-- Через обмеження в часі та недосконале генерування даних, тут назва вулиці вказана як 'Тещин міст'
WHERE alarm_events.triggered_at > CURRENT_DATE - INTERVAL '1 year'
  AND locations.street = 'Тещин міст'
GROUP BY protected_objects.name
HAVING COUNT(alarm_events.id) >= 5;



--b) Фірма, котра виробляєнайнадійніші системи сигналізації
-- (надійноює система сигналізації де у випадку виїзду
-- екіпажу результатом є відсутність взлому).

SELECT alarms.brand, COUNT(alarms.brand)
FROM alarms
         JOIN alarms_on_objects ON alarms.id = alarms_on_objects.alarm_id
         JOIN alarm_events ON alarms.id = alarm_events.alarm_id
         JOIN alarm_events_results ON alarm_events.id = alarm_events_results.event_id
WHERE alarm_events_results.result = 'відсутність взлому'
GROUP BY alarms.brand
ORDER BY COUNT(alarms.brand) DESC
LIMIT 1;



-- с) Номер автомобіля, на якому за останній рік
-- виїжджали ни виклики найбільшу кількість разів.

SELECT vehicles.registration_number, COUNT(vehicles.registration_number)
FROM vehicles
         JOIN employees_departure_on_events ON vehicles.id = employees_departure_on_events.vehicle_id
WHERE employees_departure_on_events.arrived_at > CURRENT_DATE - INTERVAL '1 year'
GROUP BY vehicles.registration_number
ORDER BY COUNT(vehicles.registration_number) DESC
LIMIT 1;


-- d) Дні тижня, в які було найбільше виїздів за минулий місяць.
SELECT EXTRACT(DOW FROM employees_departure_on_events.arrived_at) AS day_of_week,
       COUNT(employees_departure_on_events.id)
FROM employees_departure_on_events
WHERE employees_departure_on_events.arrived_at > CURRENT_DATE - INTERVAL '1 month'
GROUP BY day_of_week
ORDER BY COUNT(employees_departure_on_events.id) DESC






























