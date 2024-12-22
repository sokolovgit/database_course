-- Створення ролей
CREATE ROLE cw_admin;
CREATE ROLE cw_police_officer;
CREATE ROLE cw_driver;
CREATE ROLE cw_citizen;

-- Доступи для ролі admin
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO cw_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO cw_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO cw_admin;

-- Доступи для ролі police_officer
GRANT SELECT, INSERT, UPDATE ON TABLE violations, evidences, accident_protocols, accident_resolutions, locations TO cw_police_officer;
GRANT SELECT ON TABLE citizens, drivers, vehicles, vehicle_types, traffic_rules, administrative_offenses TO cw_police_officer;

-- Доступи для ролі driver
GRANT SELECT ON TABLE citizens, drivers, vehicles, violations, evidences, accident_resolutions TO cw_driver;

-- Доступи для ролі citizen
GRANT SELECT ON TABLE citizens, traffic_rules, administrative_offenses TO cw_citizen;

-- Обмеження доступу для ролі driver (фільтрація за власним citizen_id або driver_id)
CREATE OR REPLACE VIEW driver_view AS
SELECT *
FROM citizens
WHERE id = current_setting('app.current_citizen_id')::int;
GRANT SELECT ON driver_view TO cw_driver;

-- Обмеження доступу для ролі citizen (фільтрація за власним citizen_id)
CREATE OR REPLACE VIEW citizen_view AS
SELECT *
FROM citizens
WHERE id = current_setting('app.current_citizen_id')::int;
GRANT SELECT ON citizen_view TO cw_citizen;

-----------------------------------------
-- створення користувачів із ролями

CREATE USER cw_admin_user WITH PASSWORD 'admin_password';
CREATE USER cw_police_user WITH PASSWORD 'police_password';
CREATE USER cw_driver_user WITH PASSWORD 'driver_password';
CREATE USER cw_citizen_user WITH PASSWORD 'citizen_password';

-- Призначення ролей користувачам
GRANT cw_admin TO cw_admin_user;
GRANT cw_police_officer TO cw_police_user;
GRANT cw_driver TO cw_driver_user;
GRANT cw_citizen TO cw_citizen_user;

-- Тестування доступів
-- Перемикаємося на користувача admin_user
SET ROLE cw_admin_user;
SET app.current_citizen_id = 1;

-- Перевіряємо доступ admin до всіх таблиць
SELECT *
FROM citizens; -- Успішно
SELECT *
FROM violations;
-- Успішно

-- Повертаємося до стандартного користувача
RESET ROLE;

-- Перемикаємося на користувача police_user
SET ROLE cw_police_user;

-- Тест доступу police_officer
SELECT *
FROM violations; -- Успішно
INSERT INTO violations (id, time_of_violation, description, vehicle_id, location_id, administrative_offense_id,
                        traffic_rule_id)
VALUES (DEFAULT, '2023-01-01 12:00:00', 'Швидкість перевищено', 1, 1, 1, 1); -- Успішно
SELECT *
FROM citizens; -- Успішно (тільки читання)
DELETE
FROM violations
WHERE id = 1;
-- Помилка, недостатньо прав

-- Повертаємося до стандартного користувача
RESET ROLE;

-- Перемикаємося на користувача driver_user
SET ROLE cw_driver_user;

-- Тест доступу driver
SELECT *
FROM driver_view; -- Успішно, доступ тільки до власних даних
SELECT *
FROM violations; -- Успішно, доступ до своїх порушень (через фільтрацію)
INSERT INTO violations (id, time_of_violation, description, vehicle_id, location_id, administrative_offense_id,
                        traffic_rule_id)
VALUES (DEFAULT, '2023-01-01 12:00:00', 'Швидкість перевищено', 1, 1, 1, 1);

-- Помилка, недостатньо прав

-- Повертаємося до стандартного користувача
RESET ROLE;

-- Перемикаємося на користувача citizen_user
SET ROLE cw_citizen_user;

-- Тест доступу citizen
SELECT *
FROM citizen_view; -- Успішно, доступ тільки до власних даних
SELECT *
FROM traffic_rules; -- Успішно, доступ до загальнодоступної таблиці
INSERT INTO traffic_rules (id, article, part, description)
VALUES (DEFAULT, 60, 1, 'Нові правила');
-- Помилка, недостатньо прав

-- Повертаємося до стандартного користувача
RESET ROLE;