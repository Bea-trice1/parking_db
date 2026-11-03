-- ============================================================
--  Parking Management System (Group 8)
--  File   : 04_queries.sql
--  Stage  : 4. Run the reports
--  Needs  : 04_views.sql loaded first
--  Run    : mysql -u beatrice -p -t < 04_queries.sql
--
--  All report logic lives in the views (04_views.sql). This file
--  only queries them and decides the presentation order. The Stage
--  7 interface and the chart script query the same views.
-- ============================================================

USE parking_db;

-- REPORT 1: Total revenue
SELECT * FROM vw_total_revenue;

-- REPORT 2: Revenue by payment method
SELECT * FROM vw_revenue_by_method
ORDER BY total DESC;

-- REPORT 3: Revenue per parking lot
SELECT lot, payments, revenue FROM vw_revenue_by_lot
ORDER BY revenue DESC;

-- REPORT 4: Overstayers
SELECT driver, plate_number, entry_time, exit_time, minutes_parked
FROM vw_overstayers
ORDER BY minutes_parked DESC;

-- REPORT 5: Live occupancy per lot
SELECT lot, capacity, occupied, available, occupancy_pct
FROM vw_live_occupancy
ORDER BY occupancy_pct DESC;

-- REPORT 6: Vehicles currently parked
SELECT driver, phone, plate_number, vehicle_type, lot, space_number,
       entry_time, minutes_parked, time_parked
FROM vw_currently_parked
ORDER BY minutes_parked DESC;


-- REPORT 7: Daily revenue trend
SELECT * FROM vw_daily_revenue
ORDER BY payment_date;


-- REPORT 8: Revenue leakage (outstanding first)
SELECT * FROM vw_revenue_leakage
ORDER BY successful_payments, exit_time;

-- REPORT 9a: Reservation outcomes
SELECT * FROM vw_reservation_outcomes
ORDER BY reservations DESC;

-- REPORT 9b: Reservation no-show rate
SELECT * FROM vw_reservation_no_show;

-- REPORT 10: Staff-assisted collections
SELECT staff, role, assigned_lot, payments_processed,
       sessions_assisted, amount_collected, cash_collected
FROM vw_staff_collection
ORDER BY amount_collected DESC, staff;

-- REPORT 11: Data integrity audit
SELECT * FROM vw_integrity_audit
ORDER BY check_failed, session_id;

-- REPORT 12: Revenue by payment channel
SELECT * FROM vw_revenue_by_channel ORDER BY total DESC;

-- REPORT 14: Historical Parking Sessions Organised by Date & Level
SELECT parking_date, floor_name, space_number, plate_number, driver_name, phone_number,
       entry_time, exit_time, minutes_parked, session_status, amount_paid
FROM vw_parking_history
ORDER BY parking_date DESC, lot_id ASC, entry_time ASC;

