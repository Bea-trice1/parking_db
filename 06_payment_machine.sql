USE parking_db;

DROP TRIGGER  IF EXISTS trg_payments_staff_fee;
DROP TRIGGER  IF EXISTS trg_sessions_before_exit;
DROP FUNCTION IF EXISTS fn_assist_fee;
DROP FUNCTION IF EXISTS fn_amount_due;

DELIMITER //

-- 1. SURCHARGE: 3000 if a staff member took a successful payment on this ticket
CREATE FUNCTION fn_assist_fee(p_session_id INT)
RETURNS DECIMAL(8,2)
READS SQL DATA
BEGIN
  IF EXISTS (SELECT 1 FROM Payments
             WHERE session_id = p_session_id
               AND payment_status = 'Success'
               AND processed_by_staff_id IS NOT NULL) THEN
    RETURN 3000;
  END IF;
  RETURN 0;
END//

-- 2. CALCULATOR: parking charge for a ticket, as if it ended at time p_at
-- Includes 5,000 UGX surcharge per extra hour parked beyond the 8-hour (480-minute) threshold
CREATE FUNCTION fn_amount_due(p_session_id INT, p_at DATETIME)
RETURNS DECIMAL(8,2)
READS SQL DATA
BEGIN
  DECLARE v_entry            DATETIME;
  DECLARE v_type             INT;
  DECLARE v_rate             DECIMAL(8,2);
  DECLARE v_grace            INT;
  DECLARE v_minutes          INT;
  DECLARE v_base             DECIMAL(8,2);
  DECLARE v_extra_hours      INT DEFAULT 0;
  DECLARE v_overstay_penalty DECIMAL(8,2) DEFAULT 0.00;

  SELECT ps.entry_time, v.vehicle_type_id
    INTO v_entry, v_type
  FROM ParkingSessions ps
  JOIN Vehicles v ON v.vehicle_id = ps.vehicle_id
  WHERE ps.session_id = p_session_id;

  SELECT r.rate_per_hour, r.grace_period_minutes
    INTO v_rate, v_grace
  FROM Rates r
  WHERE r.vehicle_type_id = v_type
    AND r.effective_from <= v_entry
  ORDER BY r.effective_from DESC
  LIMIT 1;

  SET v_minutes = TIMESTAMPDIFF(MINUTE, v_entry, p_at);
  SET v_base = CEIL(GREATEST(v_minutes - v_grace, 0) / 60) * v_rate;

  -- Surcharge: 5,000 UGX per extra hour beyond 8 hours (480 minutes)
  IF v_minutes > 480 THEN
    SET v_extra_hours = CEIL((v_minutes - 480) / 60);
    SET v_overstay_penalty = v_extra_hours * 5000.00;
  END IF;

  RETURN v_base + v_overstay_penalty;
END//

-- 3. THE EXIT RULE: no exit unless parking charge + surcharge is paid
CREATE TRIGGER trg_sessions_before_exit
BEFORE UPDATE ON ParkingSessions
FOR EACH ROW
BEGIN
  IF OLD.exit_time IS NULL AND NEW.exit_time IS NOT NULL THEN

    IF COALESCE((SELECT SUM(amount) FROM Payments
                 WHERE session_id = NEW.session_id
                   AND payment_status = 'Success'), 0)
       < fn_amount_due(NEW.session_id, NEW.exit_time - INTERVAL 15 MINUTE)
         + fn_assist_fee(NEW.session_id) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Cannot record exit: amount paid is less than the amount due';
    END IF;

    SET NEW.overstay_flag =
        (TIMESTAMPDIFF(MINUTE, NEW.entry_time, NEW.exit_time) > 480);

  END IF;
END//

DELIMITER ;

-- 4. THE MACHINE'S SCREEN: one row per car still inside
CREATE OR REPLACE VIEW vw_amount_due AS
SELECT ps.session_id,
       v.plate_number,
       l.name                                        AS lot,
       s.space_number,
       ps.entry_time,
       TIMESTAMPDIFF(MINUTE, ps.entry_time, NOW())   AS minutes_parked,
       fn_amount_due(ps.session_id, NOW())
         + fn_assist_fee(ps.session_id)              AS amount_due,
       fn_assist_fee(ps.session_id)                  AS assist_fee,
       COALESCE(pd.paid, 0)                          AS amount_paid,
       fn_amount_due(ps.session_id, NOW())
         + fn_assist_fee(ps.session_id)
         - COALESCE(pd.paid, 0)                      AS balance
FROM ParkingSessions ps
JOIN Vehicles      v ON v.vehicle_id = ps.vehicle_id
JOIN ParkingSpaces s ON s.space_id   = ps.space_id
JOIN ParkingLots   l ON l.lot_id     = s.lot_id
LEFT JOIN (SELECT session_id, SUM(amount) AS paid
           FROM Payments
           WHERE payment_status = 'Success'
           GROUP BY session_id) pd ON pd.session_id = ps.session_id
WHERE ps.exit_time IS NULL;