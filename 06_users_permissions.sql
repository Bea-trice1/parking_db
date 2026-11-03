-- ============================================================
--  Parking Management System (Group 8)
--  File   : 06_users_permissions.sql
--  Stage  : 6. Users and Permissions (Authentication & RBAC)
--  Run    : mysql -u root -p < 06_users_permissions.sql
-- ============================================================

USE parking_db;

-- ------------------------------------------------------------
-- 1. CLEANUP & USER CREATION (Authentication)
-- ------------------------------------------------------------
DROP USER IF EXISTS 'parking_admin'@'localhost';
DROP USER IF EXISTS 'parking_attendant'@'localhost';
DROP USER IF EXISTS 'kiosk_app'@'localhost';

-- Passwords adhere to enterprise complexity standards
CREATE USER 'parking_admin'@'localhost' IDENTIFIED BY 'Admin@Pass2026';
CREATE USER 'parking_attendant'@'localhost' IDENTIFIED BY 'Attendant@Pass2026';
CREATE USER 'kiosk_app'@'localhost' IDENTIFIED BY 'Kiosk@Pass2026';

-- ------------------------------------------------------------
-- 2. ADMINISTRATOR PRIVILEGES (Full Control)
-- ------------------------------------------------------------
-- Full DDL and DML access across the parking database
GRANT ALL PRIVILEGES ON parking_db.* TO 'parking_admin'@'localhost';

-- ------------------------------------------------------------
-- 3. PARKING ATTENDANT PRIVILEGES (Principle of Least Privilege)
-- ------------------------------------------------------------
-- Can view and register drivers and vehicles
GRANT SELECT, INSERT, UPDATE ON parking_db.Drivers TO 'parking_attendant'@'localhost';
GRANT SELECT, INSERT, UPDATE ON parking_db.Vehicles TO 'parking_attendant'@'localhost';
GRANT SELECT ON parking_db.VehicleTypes TO 'parking_attendant'@'localhost';

-- Can view lots, spaces, and rates
GRANT SELECT ON parking_db.ParkingLots TO 'parking_attendant'@'localhost';
GRANT SELECT ON parking_db.ParkingSpaces TO 'parking_attendant'@'localhost';
GRANT SELECT ON parking_db.Rates TO 'parking_attendant'@'localhost';

-- Can create sessions (entry) and update exit_time (exit)
GRANT SELECT, INSERT, UPDATE ON parking_db.ParkingSessions TO 'parking_attendant'@'localhost';

-- Can accept cash payments at booth
GRANT SELECT, INSERT ON parking_db.Payments TO 'parking_attendant'@'localhost';

-- Operational Views ONLY (Cannot see revenue analytics or audit leaks)
GRANT SELECT ON parking_db.vw_live_occupancy TO 'parking_attendant'@'localhost';
GRANT SELECT ON parking_db.vw_currently_parked TO 'parking_attendant'@'localhost';
GRANT SELECT ON parking_db.vw_overstayers TO 'parking_attendant'@'localhost';

-- ------------------------------------------------------------
-- 4. KIOSK / PAYMENT MACHINE PRIVILEGES (Automated Device)
-- ------------------------------------------------------------
-- Needs to query amounts due and record successful card/MoMo payments
GRANT SELECT ON parking_db.vw_amount_due TO 'kiosk_app'@'localhost';
GRANT SELECT, INSERT ON parking_db.Payments TO 'kiosk_app'@'localhost';
GRANT SELECT ON parking_db.ParkingSessions TO 'kiosk_app'@'localhost';

-- ------------------------------------------------------------
-- 5. APPLY PRIVILEGES & AUDIT
-- ------------------------------------------------------------
FLUSH PRIVILEGES;

-- Verification queries to confirm security matrix
SHOW GRANTS FOR 'parking_admin'@'localhost';
SHOW GRANTS FOR 'parking_attendant'@'localhost';
SHOW GRANTS FOR 'kiosk_app'@'localhost';
