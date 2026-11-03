USE parking_db;

-- Remove earlier drafts, so the file can be re-run safely
DROP TRIGGER IF EXISTS trg_sessions_set_overstay;
DROP TRIGGER IF EXISTS trg_sessions_overstay_ins;
DROP TRIGGER IF EXISTS trg_sessions_overstay_upd;
DROP TRIGGER IF EXISTS trg_sessions_one_open_per_vehicle;
DROP TRIGGER IF EXISTS trg_sessions_space_free;
DROP TRIGGER IF EXISTS trg_sessions_space_in_service;
DROP TRIGGER IF EXISTS trg_spaces_lot_capacity;
DROP TRIGGER IF EXISTS trg_sessions_validate_entry;
DROP TRIGGER IF EXISTS trg_sessions_before_exit;

DELIMITER //

-- A. Entry check: runs when a ticket (session) is created
CREATE TRIGGER trg_sessions_validate_entry
BEFORE INSERT ON ParkingSessions
FOR EACH ROW
BEGIN
  IF NEW.exit_time IS NULL THEN

    IF EXISTS (SELECT 1 FROM ParkingSessions
               WHERE vehicle_id = NEW.vehicle_id
                 AND exit_time IS NULL) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This vehicle is already inside the lot';
    END IF;

    IF EXISTS (SELECT 1 FROM ParkingSessions
               WHERE space_id = NEW.space_id
                 AND exit_time IS NULL) THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This space is already occupied';
    END IF;

    IF (SELECT status FROM SpaceStatusLog
        WHERE space_id = NEW.space_id
          AND changed_at <= NEW.entry_time
        ORDER BY changed_at DESC, log_id DESC
        LIMIT 1) = 'Out-of-Service' THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This space is out of service';
    END IF;

  END IF;
END//

DELIMITER ;

DROP EVENT IF EXISTS evt_flag_open_overstays;

CREATE EVENT evt_flag_open_overstays
ON SCHEDULE EVERY 5 MINUTE
DO
  UPDATE ParkingSessions
  SET overstay_flag = TRUE
  WHERE exit_time IS NULL
    AND TIMESTAMPDIFF(MINUTE, entry_time, NOW()) > 480;

