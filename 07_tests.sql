USE parking_db;

-- TEST 1: cash paid at the machine (no staff id) for 9-hour stay (includes 5k overstay penalty).
-- Base (9h x 1,500 = 13,500) + Overstay (1h x 5,000 = 5,000) = 18,500 UGX. Expect exit to SUCCEED.
INSERT INTO ParkingSessions (vehicle_id, space_id, entry_time)
VALUES (2, 4, '2026-10-16 06:00:00');
SET @sid = LAST_INSERT_ID();

INSERT INTO Payments (session_id, amount, payment_method, payment_time, payment_status)
VALUES (@sid, 18500, 'Cash', '2026-10-16 14:55:00', 'Success');

UPDATE ParkingSessions SET exit_time = '2026-10-16 15:00:00' WHERE session_id = @sid;
SELECT 'Test 1: exit recorded with overstay' AS result, session_id, exit_time, overstay_flag
FROM ParkingSessions WHERE session_id = @sid;

DELETE FROM Payments WHERE session_id = @sid;
DELETE FROM ParkingSessions WHERE session_id = @sid;

-- TEST 2: staff takes the bill (18,500 parking+overstay) but not the 3,000 assistance surcharge.
-- Expect ONE refusal, then success once the 3,000 surcharge is paid.
INSERT INTO ParkingSessions (vehicle_id, space_id, entry_time)
VALUES (2, 4, '2026-10-16 06:00:00');
SET @sid = LAST_INSERT_ID();

INSERT INTO Payments (session_id, amount, payment_method, payment_time, payment_status, processed_by_staff_id)
VALUES (@sid, 18500, 'Cash', '2026-10-16 14:55:00', 'Success', 3);

SELECT 'Test 2: surcharge' AS result, fn_assist_fee(@sid) AS surcharge;

-- this one should be REFUSED:
UPDATE ParkingSessions SET exit_time = '2026-10-16 15:00:00' WHERE session_id = @sid;

INSERT INTO Payments (session_id, amount, payment_method, payment_time, payment_status, processed_by_staff_id)
VALUES (@sid, 3000, 'Cash', '2026-10-16 14:57:00', 'Success', 3);

-- this one should SUCCEED:
UPDATE ParkingSessions SET exit_time = '2026-10-16 15:00:00' WHERE session_id = @sid;
SELECT 'Test 2: exit recorded' AS result, session_id, exit_time, overstay_flag
FROM ParkingSessions WHERE session_id = @sid;

DELETE FROM Payments WHERE session_id = @sid;
DELETE FROM ParkingSessions WHERE session_id = @sid;

-- TEST 3: entry rules. Each INSERT should be REFUSED.
INSERT INTO ParkingSessions (vehicle_id, space_id, entry_time) VALUES (1, 6, NOW());
INSERT INTO ParkingSessions (vehicle_id, space_id, entry_time) VALUES (2, 3, NOW());
INSERT INTO ParkingSessions (vehicle_id, space_id, entry_time) VALUES (2, 8, '2026-10-16 10:00:00');