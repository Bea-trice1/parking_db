-- ============================================================
--  Parking Management System (Group 8)
--  File   : 04_views.sql
--  Stage  : 4. Reports, stored as views
--  Run    : mysql -u beatrice -p < 04_views.sql
--
--  Each report is saved as a VIEW: a named SELECT that MySQL
--  re-runs every time the view is queried. Views store no data,
--  so their output is always current.
--
--  Conventions
--   * CREATE OR REPLACE: the file can be re-run safely after edits.
--   * No ORDER BY inside views. Ordering is the caller's job
--     (see 04_queries.sql).
--   * Default SQL SECURITY DEFINER: a user granted SELECT on a view
--     can read it without any rights on the underlying tables.
--     Stage 6 relies on this.
-- ============================================================

USE parking_db;

-- ------------------------------------------------------------
-- REPORT 1: Total revenue
-- Only successful payments count as money actually received.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_total_revenue AS
SELECT COALESCE(SUM(amount), 0) AS total_revenue
FROM Payments
WHERE payment_status = 'Success';

-- ------------------------------------------------------------
-- REPORT 2: Revenue by payment method
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_revenue_by_method AS
SELECT payment_method,
       COUNT(*)    AS payments,
       SUM(amount) AS total
FROM Payments
WHERE payment_status = 'Success'
GROUP BY payment_method;

-- ------------------------------------------------------------
-- REPORT 3: Revenue per parking lot
-- Starts from ParkingLots and uses LEFT JOINs so that a lot with
-- no payments still appears (with 0). The status filter is in the
-- ON clause, not WHERE: a WHERE filter would discard the NULL rows
-- and silently turn the LEFT JOIN back into an INNER JOIN.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_revenue_by_lot AS
SELECT l.lot_id,
       l.name                     AS lot,
       COUNT(p.payment_id)        AS payments,
       COALESCE(SUM(p.amount), 0) AS revenue
FROM ParkingLots l
LEFT JOIN ParkingSpaces   s  ON s.lot_id      = l.lot_id
LEFT JOIN ParkingSessions ps ON ps.space_id   = s.space_id
LEFT JOIN Payments        p  ON p.session_id  = ps.session_id
                            AND p.payment_status = 'Success'
GROUP BY l.lot_id, l.name;

-- ------------------------------------------------------------
-- REPORT 4: Overstayers
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_overstayers AS
SELECT ps.session_id,
       d.name AS driver,
       v.plate_number,
       ps.entry_time,
       ps.exit_time,
       TIMESTAMPDIFF(MINUTE, ps.entry_time, COALESCE(ps.exit_time, NOW())) AS minutes_parked,
       IF(ps.exit_time IS NULL, 'Still parked', 'Left') AS state
FROM ParkingSessions ps
JOIN Vehicles v ON ps.vehicle_id = v.vehicle_id
JOIN Drivers  d ON v.driver_id   = d.driver_id
WHERE TIMESTAMPDIFF(MINUTE, ps.entry_time, COALESCE(ps.exit_time, NOW())) > 480;

-- ------------------------------------------------------------
-- REPORT 5: Live occupancy per lot
-- Grain   : one row per parking lot
-- Path    : ParkingLots -> ParkingSpaces -> ParkingSessions
-- "Occupied" = a session on that space with no exit_time yet.
-- exit_time IS NULL sits in the ON clause so that a lot with no
-- parked cars keeps its row and shows 0 occupied, 0%.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_live_occupancy AS
SELECT l.lot_id,
       l.name                                             AS lot,
       l.capacity,
       COUNT(ps.session_id)                               AS occupied,
       l.capacity - COUNT(ps.session_id)                  AS available,
       ROUND(COUNT(ps.session_id) / l.capacity * 100, 1)  AS occupancy_pct
FROM ParkingLots l
LEFT JOIN ParkingSpaces   s  ON s.lot_id    = l.lot_id
LEFT JOIN ParkingSessions ps ON ps.space_id = s.space_id
                            AND ps.exit_time IS NULL
GROUP BY l.lot_id, l.name, l.capacity;

-- ------------------------------------------------------------
-- REPORT 6: Vehicles currently parked (attendant's live list)
-- Grain   : one row per open parking session
-- INNER JOINs are safe: every FK on this path is NOT NULL.
-- NOW() stands in for exit_time, since the car has not left yet.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_currently_parked AS
SELECT ps.session_id,
       d.name                                             AS driver,
       d.phone,
       v.plate_number,
       vt.type_name                                       AS vehicle_type,
       l.name                                             AS lot,
       s.space_number,
       ps.entry_time,
       TIMESTAMPDIFF(MINUTE, ps.entry_time, NOW())        AS minutes_parked,
       SEC_TO_TIME(TIMESTAMPDIFF(SECOND, ps.entry_time, NOW())) AS time_parked
FROM ParkingSessions ps
JOIN Vehicles      v  ON v.vehicle_id       = ps.vehicle_id
JOIN Drivers       d  ON d.driver_id        = v.driver_id
JOIN VehicleTypes  vt ON vt.vehicle_type_id = v.vehicle_type_id
JOIN ParkingSpaces s  ON s.space_id         = ps.space_id
JOIN ParkingLots   l  ON l.lot_id           = s.lot_id
WHERE ps.exit_time IS NULL;


-- ------------------------------------------------------------
-- REPORT 7: Daily revenue trend
-- Grain   : one row per calendar day
-- CTE "daily" totals each day; the window function then adds a
-- cumulative running total.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_daily_revenue AS
WITH daily AS (
    SELECT DATE(payment_time) AS payment_date,
           COUNT(*)           AS payments,
           SUM(amount)        AS daily_revenue
    FROM Payments
    WHERE payment_status = 'Success'
    GROUP BY DATE(payment_time)
)
SELECT payment_date,
       payments,
       daily_revenue,
       SUM(daily_revenue) OVER (ORDER BY payment_date) AS running_total
FROM daily;



-- ------------------------------------------------------------
-- REPORT 8: Revenue leakage
-- Grain   : one row per completed session with a payment problem
-- LEFT JOIN to Payments keeps sessions that have NO payment rows.
-- HAVING filters AFTER grouping (WHERE cannot see the counts).
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_revenue_leakage AS
SELECT ps.session_id,
       v.plate_number,
       d.name                                                     AS driver,
       d.phone,
       ps.exit_time,
       SUM(CASE WHEN p.payment_status = 'Failed'  THEN 1 ELSE 0 END) AS failed_attempts,
       SUM(CASE WHEN p.payment_status = 'Success' THEN 1 ELSE 0 END) AS successful_payments,
       COALESCE(SUM(CASE WHEN p.payment_status = 'Success'
                         THEN p.amount END), 0)                   AS amount_received,
       CASE WHEN SUM(CASE WHEN p.payment_status = 'Success' THEN 1 ELSE 0 END) > 0
            THEN 'Recovered after failure'
            ELSE 'OUTSTANDING'
       END                                                        AS follow_up
FROM ParkingSessions ps
JOIN Vehicles      v ON v.vehicle_id  = ps.vehicle_id
JOIN Drivers       d ON d.driver_id   = v.driver_id
LEFT JOIN Payments p ON p.session_id  = ps.session_id
WHERE ps.exit_time IS NOT NULL
GROUP BY ps.session_id, v.plate_number, d.name, d.phone, ps.exit_time
HAVING successful_payments = 0
    OR failed_attempts > 0;

-- ------------------------------------------------------------
-- REPORT 9a: Reservation outcomes (donut chart)
-- Grain   : one row per reservation status
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_reservation_outcomes AS
SELECT status,
       COUNT(*)                                                       AS reservations,
       ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM Reservations), 1) AS pct_of_total
FROM Reservations
GROUP BY status;

-- ------------------------------------------------------------
-- REPORT 9b: Reservation no-show rate (single KPI)
-- No-show rate = Expired / (Fulfilled + Expired)
-- NULLIF avoids division by zero when nothing is resolved yet.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_reservation_no_show AS
SELECT SUM(status = 'Fulfilled')                       AS fulfilled,
       SUM(status = 'Expired')                         AS expired_no_show,
       ROUND(SUM(status = 'Expired') * 100
             / NULLIF(SUM(status IN ('Fulfilled', 'Expired')), 0), 1)
                                                       AS no_show_rate_pct
FROM Reservations;

-- ------------------------------------------------------------
-- REPORT 10: Staff-assisted collections
-- Grain   : one row per staff member
-- Counts every successful payment a staff member took, whatever
-- the method. Machine payments have no staff id, so they never
-- appear here. Status filter is in ON so idle staff keep a row.
-- Cross-check: SUM(amount_collected) = the 'Staff-assisted' row
-- of vw_revenue_by_channel (Report 12).
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_staff_collection AS
SELECT st.staff_id,
       st.name                      AS staff,
       st.role,
       l.name                       AS assigned_lot,
       COUNT(p.payment_id)          AS payments_processed,
       COUNT(DISTINCT p.session_id) AS sessions_assisted,
       COALESCE(SUM(p.amount), 0)   AS amount_collected,
       COALESCE(SUM(CASE WHEN p.payment_method = 'Cash'
                         THEN p.amount END), 0) AS cash_collected
FROM Staff st
LEFT JOIN ParkingLots l ON l.lot_id = st.lot_id
LEFT JOIN Payments    p ON p.processed_by_staff_id = st.staff_id
                       AND p.payment_status = 'Success'
GROUP BY st.staff_id, st.name, st.role, l.name;


-- ------------------------------------------------------------
-- REPORT 11: Data integrity audit
-- Grain   : one row per rule violation (empty = clean data)
--   (1) Car parked in a space whose latest status was Out-of-Service
--   (2) Two sessions overlapping in time on the same space
--   (3) One vehicle in two sessions at the same time
--   (4) Non-EV vehicle using an EV-charging bay
--   (5) overstay_flag disagrees with the 8-hour (480 min) rule
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_integrity_audit AS
SELECT 'Parked in out-of-service space' AS check_failed,
       ps.session_id,
       CONCAT('Space ', s.space_number, ' marked Out-of-Service at ',
              sl.changed_at, '; car entered ', ps.entry_time) AS detail
FROM ParkingSessions ps
JOIN ParkingSpaces  s  ON s.space_id  = ps.space_id
JOIN SpaceStatusLog sl ON sl.space_id = ps.space_id
                      AND sl.changed_at = (
                            SELECT MAX(sl2.changed_at)
                            FROM SpaceStatusLog sl2
                            WHERE sl2.space_id   = ps.space_id
                              AND sl2.changed_at <= ps.entry_time)
WHERE sl.status = 'Out-of-Service'

UNION ALL

SELECT 'Overlapping sessions on one space',
       a.session_id,
       CONCAT('Overlaps session ', b.session_id, ' on space ', s.space_number)
FROM ParkingSessions a
JOIN ParkingSessions b ON b.space_id   = a.space_id
                      AND b.session_id > a.session_id
                      AND a.entry_time < COALESCE(b.exit_time, NOW())
                      AND b.entry_time < COALESCE(a.exit_time, NOW())
JOIN ParkingSpaces s   ON s.space_id   = a.space_id

UNION ALL

SELECT 'Vehicle in two places at once',
       a.session_id,
       CONCAT(v.plate_number, ' also in session ', b.session_id)
FROM ParkingSessions a
JOIN ParkingSessions b ON b.vehicle_id = a.vehicle_id
                      AND b.session_id > a.session_id
                      AND a.entry_time < COALESCE(b.exit_time, NOW())
                      AND b.entry_time < COALESCE(a.exit_time, NOW())
JOIN Vehicles v        ON v.vehicle_id = a.vehicle_id

UNION ALL

SELECT 'Non-EV in EV-charging bay',
       ps.session_id,
       CONCAT(v.plate_number, ' (', vt.type_name, ') in ', s.space_number)
FROM ParkingSessions ps
JOIN ParkingSpaces s  ON s.space_id         = ps.space_id
JOIN Vehicles      v  ON v.vehicle_id       = ps.vehicle_id
JOIN VehicleTypes  vt ON vt.vehicle_type_id = v.vehicle_type_id
WHERE s.space_type = 'EV-charging'
  AND vt.type_name <> 'EV'

UNION ALL

SELECT 'Overstay flag incorrect',
       ps.session_id,
       CONCAT(TIMESTAMPDIFF(MINUTE, ps.entry_time, COALESCE(ps.exit_time, NOW())),
              ' min parked, flag = ', IF(ps.overstay_flag, 'TRUE', 'FALSE'))
FROM ParkingSessions ps
WHERE (TIMESTAMPDIFF(MINUTE, ps.entry_time, COALESCE(ps.exit_time, NOW())) > 480)
      <> ps.overstay_flag;

-- ------------------------------------------------------------
-- Verification: list every view now stored in the database
-- ------------------------------------------------------------
SHOW FULL TABLES WHERE Table_type = 'VIEW';

-- ------------------------------------------------------------
-- REPORT 12: Revenue by payment channel
-- Machine = no staff id; Staff-assisted = a staff id is recorded.
-- Cross-check: the two rows add up to Report 1.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_revenue_by_channel AS
SELECT IF(processed_by_staff_id IS NULL, 'Machine', 'Staff-assisted') AS channel,
       COUNT(*)    AS payments,
       SUM(amount) AS total
FROM Payments
WHERE payment_status = 'Success'
GROUP BY channel;

-- ------------------------------------------------------------
-- REPORT 14: Historical Parking Sessions Organised by Date & Level
-- Allows management to audit who parked when, broken down by date
-- and separated by individual building level deck.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_parking_history AS
SELECT DATE(ps.entry_time) AS parking_date,
       l.lot_id,
       l.name AS floor_name,
       ps.session_id,
       v.plate_number,
       d.name AS driver_name,
       d.phone_number,
       s.space_number,
       ps.entry_time,
       ps.exit_time,
       TIMESTAMPDIFF(MINUTE, ps.entry_time, COALESCE(ps.exit_time, NOW())) AS minutes_parked,
       CASE 
         WHEN ps.exit_time IS NULL THEN 'Active (Parked)'
         WHEN ps.overstay_flag THEN 'Completed (Overstay)'
         ELSE 'Completed'
       END AS session_status,
       COALESCE(p.amount, 0) AS amount_paid
FROM ParkingSessions ps
JOIN Vehicles v ON v.vehicle_id = ps.vehicle_id
JOIN Drivers d ON d.driver_id = v.driver_id
JOIN ParkingSpaces s ON s.space_id = ps.space_id
JOIN ParkingLots l ON l.lot_id = s.lot_id
LEFT JOIN Payments p ON p.session_id = ps.session_id AND p.payment_status = 'Success';
