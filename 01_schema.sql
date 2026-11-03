DROP DATABASE IF EXISTS parking_db;
CREATE DATABASE parking_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE parking_db;

CREATE TABLE Drivers (
    driver_id INT AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    CONSTRAINT pk_driver PRIMARY KEY (driver_id),
    CONSTRAINT uq_driver_email UNIQUE (email)
);

CREATE TABLE VehicleTypes (
    vehicle_type_id INT  AUTO_INCREMENT,
    type_name VARCHAR(50) NOT NULL,
    CONSTRAINT pk_vehicletypes PRIMARY KEY (vehicle_type_id),
    CONSTRAINT uq_vehicletypes_type_name UNIQUE (type_name)
);

CREATE TABLE Staff (
    staff_id INT AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(30) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    lot_id INT NULL,
    CONSTRAINT pk_staff PRIMARY KEY (staff_id)
);

CREATE TABLE ParkingLots (
    lot_id INT AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    location VARCHAR(150) NOT NULL,
    capacity INT NOT NULL,
    manager_staff_id INT NULL,
    CONSTRAINT pk_parkinglots PRIMARY KEY (lot_id),
    CONSTRAINT chk_lot_capacity CHECK (capacity > 0),
    CONSTRAINT fk_lot_manager FOREIGN KEY (manager_staff_id)
       REFERENCES Staff(staff_id) ON DELETE SET NULL
);

ALTER TABLE Staff
    ADD CONSTRAINT fk_staff_lot FOREIGN KEY (lot_id)
       REFERENCES ParkingLots(lot_id) ON DELETE SET NULL;

CREATE TABLE Vehicles (
    vehicle_id  INT AUTO_INCREMENT,
    driver_id INT NOT NULL,
    plate_number VARCHAR(20) NOT NULL,
    vehicle_type_id INT NOT NULL,
    CONSTRAINT pk_vehicles PRIMARY KEY (vehicle_id),
    CONSTRAINT uq_vehicles_plate UNIQUE (plate_number),
    CONSTRAINT fk_vehicles_driver FOREIGN KEY (driver_id)
        REFERENCES Drivers(driver_id),
    CONSTRAINT fk_vehicles_type FOREIGN KEY (vehicle_type_id)
        REFERENCES VehicleTypes(vehicle_type_id)
);

CREATE TABLE ParkingSpaces (
    space_id INT AUTO_INCREMENT,
    lot_id INT NOT NULL,
    space_number VARCHAR(10) NOT NULL,
    space_type VARCHAR(30) NOT NULL,
    CONSTRAINT pk_parkingspaces PRIMARY KEY (space_id),
    CONSTRAINT uq_space_per_lot UNIQUE (lot_id, space_number),
    CONSTRAINT chk_space_type CHECK (space_type IN ('standard', 'disabled', 'EV-charging')),
    CONSTRAINT fk_spaces_lot FOREIGN KEY (lot_id)
        REFERENCES ParkingLots(lot_id) 
);

CREATE TABLE Rates (
    rate_id INT AUTO_INCREMENT,
    vehicle_type_id INT NOT NULL,
    rate_per_hour DECIMAL(8,2) NOT NULL,
    grace_period_minutes INT NOT NULL DEFAULT 0,
    effective_from DATETIME NOT NULL,
    CONSTRAINT pk_rates PRIMARY KEY (rate_id),
    CONSTRAINT chk_rate_amount CHECK (rate_per_hour >= 0),
    CONSTRAINT uq_rates_type_date UNIQUE (vehicle_type_id, effective_from),
    CONSTRAINT fk_rates_type FOREIGN KEY (vehicle_type_id)
        REFERENCES VehicleTypes(vehicle_type_id)
);

CREATE TABLE Reservations (
  reservation_id INT AUTO_INCREMENT,
  driver_id      INT NOT NULL,
  space_id       INT NOT NULL,
  start_time     DATETIME NOT NULL,
  end_time       DATETIME NOT NULL,
  status         VARCHAR(20) NOT NULL DEFAULT 'Pending',
  CONSTRAINT pk_reservations PRIMARY KEY (reservation_id),
  CONSTRAINT chk_reservation_times CHECK (end_time > start_time),
  CONSTRAINT chk_reservation_status
    CHECK (status IN ('Pending','Fulfilled','Expired','Cancelled')),
  CONSTRAINT fk_reservations_driver FOREIGN KEY (driver_id)
    REFERENCES Drivers(driver_id),
  CONSTRAINT fk_reservations_space FOREIGN KEY (space_id)
    REFERENCES ParkingSpaces(space_id)
);

CREATE TABLE ParkingSessions (
  session_id     INT AUTO_INCREMENT,
  vehicle_id     INT NOT NULL,
  space_id       INT NOT NULL,
  reservation_id INT NULL,
  entry_time     DATETIME NOT NULL,
  exit_time      DATETIME NULL,
  overstay_flag  BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT pk_parkingsessions PRIMARY KEY (session_id),
  CONSTRAINT chk_session_times
    CHECK (exit_time IS NULL OR exit_time > entry_time),
  CONSTRAINT fk_sessions_vehicle FOREIGN KEY (vehicle_id)
    REFERENCES Vehicles(vehicle_id),
  CONSTRAINT fk_sessions_space FOREIGN KEY (space_id)
    REFERENCES ParkingSpaces(space_id),
  CONSTRAINT fk_sessions_reservation FOREIGN KEY (reservation_id)
    REFERENCES Reservations(reservation_id) ON DELETE SET NULL
);

CREATE TABLE Payments (
  payment_id            INT AUTO_INCREMENT,
  session_id            INT NOT NULL,
  amount                DECIMAL(8,2) NOT NULL,
  payment_method        VARCHAR(30) NOT NULL,
  payment_time          DATETIME NOT NULL,
  payment_status        VARCHAR(20) NOT NULL,
  processed_by_staff_id INT NULL,
  CONSTRAINT pk_payments PRIMARY KEY (payment_id),
  CONSTRAINT chk_payment_amount CHECK (amount >= 0),
  CONSTRAINT chk_payment_method
    CHECK (payment_method IN ('Cash','Card','Mobile Money')),
  CONSTRAINT chk_payment_status
    CHECK (payment_status IN ('Success','Failed','Refunded','Partial')),
  CONSTRAINT fk_payments_session FOREIGN KEY (session_id)
    REFERENCES ParkingSessions(session_id),
  CONSTRAINT fk_payments_staff FOREIGN KEY (processed_by_staff_id)
    REFERENCES Staff(staff_id) ON DELETE SET NULL
);

CREATE TABLE SpaceStatusLog (
  log_id     INT AUTO_INCREMENT,
  space_id   INT NOT NULL,
  status     VARCHAR(20) NOT NULL,
  changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  session_id INT NULL,
  CONSTRAINT pk_spacestatuslog PRIMARY KEY (log_id),
  CONSTRAINT chk_log_status
    CHECK (status IN ('Occupied','Vacant','Reserved','Out-of-Service')),
  CONSTRAINT fk_log_space FOREIGN KEY (space_id)
    REFERENCES ParkingSpaces(space_id),
  CONSTRAINT fk_log_session FOREIGN KEY (session_id)
    REFERENCES ParkingSessions(session_id) ON DELETE SET NULL
);