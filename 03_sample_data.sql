USE parking_db;

-- ------------------------------------------------------------
-- 1. DRIVERS (Initial 10 + 30 active parked drivers = 40 total)
-- ------------------------------------------------------------
INSERT INTO Drivers (name, phone, email) VALUES
('Namatovu Esther',   '0700000101', 'esther.namatovu@example.com'),
('Ssebunya David',    '0700000102', 'david.ssebunya@example.com'),
('Akello Joan',       '0700000103', NULL),
('Byaruhanga Moses',  '0700000104', 'moses.byaruhanga@example.com'),
('Nakato Rita',       '0700000105', 'rita.nakato@example.com'),
('Opio Daniel',       '0700000106', NULL),
('Tumusiime Alice',   '0700000107', 'alice.tumusiime@example.com'),
('Mukasa Brian',      '0700000108', 'brian.mukasa@example.com'),
('Atim Sarah',        '0700000109', 'sarah.atim@example.com'),
('Kiiza Henry',       '0700000110', NULL),
-- 30 New Active Drivers currently parked today
('Kigozi Fred',       '0701110001', 'fred.kigozi@example.com'),
('Nalubega Sarah',    '0701110002', 'sarah.nalubega@example.com'),
('Mwesigwa Ronald',   '0701110003', NULL),
('Laker Brenda',      '0701110004', 'brenda.laker@example.com'),
('Wasswa Ivan',       '0701110005', 'ivan.wasswa@example.com'),
('Kato Paul',         '0701110006', NULL),
('Babirye Grace',     '0701110007', 'grace.babirye@example.com'),
('Okot Richard',      '0701110008', 'richard.okot@example.com'),
('Aceng Patricia',    '0701110009', 'patricia.aceng@example.com'),
('Mugerwa Denis',     '0701110010', NULL),
('Ainembabazi Joy',   '0701110011', 'joy.aine@example.com'),
('Tusiime Andrew',    '0701110012', 'andrew.t@example.com'),
('Kembabazi Flavia',  '0701110013', 'flavia.k@example.com'),
('Ochieng Samuel',    '0701110014', NULL),
('Businge Patrick',   '0701110015', 'patrick.b@example.com'),
('Kemigisha Diana',   '0701110016', 'diana.k@example.com'),
('Kasule Robert',     '0701110017', NULL),
('Nabakooza Rehema',  '0701110018', 'rehema.n@example.com'),
('Mutebi Derrick',    '0701110019', 'derrick.m@example.com'),
('Ndagire Prossy',    '0701110020', NULL),
('Kayondo Arthur',    '0701110021', 'arthur.k@example.com'),
('Ahabwe Victor',     '0701110022', 'victor.a@example.com'),
('Nansubuga Claire',  '0701110023', 'claire.n@example.com'),
('Ojok Emmanuel',     '0701110024', NULL),
('Nassozi Sandra',    '0701110025', 'sandra.n@example.com'),
('Alinaitwe Bruce',   '0701110026', 'bruce.a@example.com'),
('Birungi Christine', '0701110027', 'christine.b@example.com'),
('Ssentongo George',  '0701110028', NULL),
('Namaganda Irene',   '0701110029', 'irene.n@example.com'),
('Lukwago Simon',     '0701110030', 'simon.l@example.com');

-- ------------------------------------------------------------
-- 2. VEHICLE TYPES
-- ------------------------------------------------------------
INSERT INTO VehicleTypes (type_name) VALUES
('Car'), ('Motorcycle'), ('Truck'), ('EV');

-- ------------------------------------------------------------
-- 3. BUILDING FLOORS (PARKING LOTS AS FLOORS)
-- ------------------------------------------------------------
INSERT INTO ParkingLots (name, location, capacity, manager_staff_id) VALUES
('Level 1 — Ground Deck',     'Building Complex — Ground Floor',     12, NULL),
('Level 2 — Mezzanine Floor', 'Building Complex — Mezzanine Deck',   10, NULL),
('Level 3 — Upper Deck',      'Building Complex — Upper Floor Deck', 10, NULL),
('Level 4 — Rooftop Deck',    'Building Complex — Rooftop Open Bay',  8, NULL);

-- ------------------------------------------------------------
-- 4. STAFF (2 Managers + Floor Attendants)
-- ------------------------------------------------------------
INSERT INTO Staff (name, role, phone, lot_id) VALUES
('Okello Samuel',  'Manager',   '0700000201', 1), -- Manager 1
('Namuli Grace',   'Manager',   '0700000202', 2), -- Manager 2
('Mugisha Peter',  'Attendant', '0700000203', 1),
('Auma Faith',     'Attendant', '0700000204', 2),
('Kato Ronald',    'Attendant', '0700000205', 3),
('Kyomugisha Hope','Attendant', '0700000206', 4);

-- Set Managers
UPDATE ParkingLots SET manager_staff_id = 1 WHERE lot_id = 1;
UPDATE ParkingLots SET manager_staff_id = 2 WHERE lot_id = 2;
UPDATE ParkingLots SET manager_staff_id = 1 WHERE lot_id = 3;
UPDATE ParkingLots SET manager_staff_id = 2 WHERE lot_id = 4;

-- ------------------------------------------------------------
-- 5. PARKING SPACES ACROSS 4 FLOORS (40 Total Spaces)
-- ------------------------------------------------------------
INSERT INTO ParkingSpaces (lot_id, space_number, space_type) VALUES
-- Floor 1 (Ground Deck): 12 spaces
(1,'G01','disabled'), (1,'G02','disabled'), (1,'G03','EV-charging'), (1,'G04','EV-charging'),
(1,'G05','standard'), (1,'G06','standard'), (1,'G07','standard'),    (1,'G08','standard'),
(1,'G09','standard'), (1,'G10','standard'), (1,'G11','standard'),    (1,'G12','standard'),
-- Floor 2 (Mezzanine): 10 spaces
(2,'M01','standard'), (2,'M02','standard'), (2,'M03','standard'),    (2,'M04','standard'),
(2,'M05','standard'), (2,'M06','standard'), (2,'M07','standard'),    (2,'M08','standard'),
(2,'M09','EV-charging'), (2,'M10','EV-charging'),
-- Floor 3 (Upper Deck): 10 spaces
(3,'U01','standard'), (3,'U02','standard'), (3,'U03','standard'),    (3,'U04','standard'),
(3,'U05','standard'), (3,'U06','standard'), (3,'U07','standard'),    (3,'U08','standard'),
(3,'U09','standard'), (3,'U10','standard'),
-- Floor 4 (Rooftop): 8 spaces
(4,'R01','standard'), (4,'R02','standard'), (4,'R03','standard'),    (4,'R04','standard'),
(4,'R05','standard'), (4,'R06','standard'), (4,'R07','standard'),    (4,'R08','standard');

-- ------------------------------------------------------------
-- 6. VEHICLES (Original 12 + 30 new = 42 total)
-- ------------------------------------------------------------
INSERT INTO Vehicles (driver_id, plate_number, vehicle_type_id) VALUES
(1,'UBA 101A',1), (1,'UBF 202B',2), (2,'UBB 303C',1), (3,'UAX 404D',1),
(4,'UBC 505E',3), (4,'UBD 606F',1), (5,'UBE 707G',4), (6,'UAZ 808H',2),
(7,'UBG 909J',1), (8,'UBH 111K',1), (9,'UBJ 222L',4), (10,'UBK 333M',1),
-- 30 New Active Vehicles
(11,'UBL 001A',1), (12,'UBM 002B',1), (13,'UBN 003C',2), (14,'UBP 004D',4),
(15,'UBQ 005E',1), (16,'UBR 006F',3), (17,'UBS 007G',1), (18,'UBT 008H',1),
(19,'UBU 009J',2), (20,'UBV 010K',1), (21,'UBW 011L',4), (22,'UBX 012M',1),
(23,'UBY 013N',1), (24,'UBZ 014P',1), (25,'UCA 015Q',3), (26,'UCB 016R',1),
(27,'UCC 017S',2), (28,'UCD 018T',1), (29,'UCE 019U',4), (30,'UCF 020V',1),
(31,'UCG 021W',1), (32,'UCH 022X',1), (33,'UCJ 023Y',1), (34,'UCK 024Z',2),
(35,'UCL 025A',1), (36,'UCM 026B',3), (37,'UCN 027C',1), (38,'UCP 028D',1),
(39,'UCQ 029E',4), (40,'UCR 030F',1);

-- ------------------------------------------------------------
-- 7. RATES
-- ------------------------------------------------------------
INSERT INTO Rates (vehicle_type_id, rate_per_hour, grace_period_minutes, effective_from) VALUES
(1, 3000, 15, '2026-01-01 00:00:00'),
(1, 4000, 15, '2026-09-01 00:00:00'),
(2, 1500, 10, '2026-01-01 00:00:00'),
(3, 6000, 30, '2026-01-01 00:00:00'),
(4, 3500, 15, '2026-01-01 00:00:00');

-- ------------------------------------------------------------
-- 8. HISTORICAL PARKING SESSIONS (Completed with payments)
-- ------------------------------------------------------------
INSERT INTO ParkingSessions (vehicle_id, space_id, entry_time, exit_time, overstay_flag) VALUES
(7,  3,  '2026-10-12 08:05:00', '2026-10-12 11:50:00', FALSE),
(11, 4,  '2026-10-13 09:02:00', '2026-10-13 10:45:00', FALSE),
(3,  5,  '2026-10-14 07:40:00', '2026-10-14 09:55:00', FALSE),
(1,  6,  '2026-10-12 08:30:00', '2026-10-12 15:10:00', FALSE),
(2,  7,  '2026-10-12 09:00:00', '2026-10-12 09:50:00', FALSE),
(4,  8,  '2026-10-13 07:45:00', '2026-10-13 18:20:00', TRUE),
(5,  13, '2026-10-13 10:00:00', '2026-10-13 13:30:00', FALSE),
(6,  14, '2026-10-13 12:00:00', '2026-10-13 14:00:00', FALSE),
(8,  15, '2026-10-14 08:15:00', '2026-10-14 12:00:00', FALSE),
(9,  16, '2026-10-14 08:00:00', '2026-10-14 16:30:00', TRUE),
(10, 17, '2026-10-14 09:00:00', '2026-10-14 11:30:00', FALSE);

-- ------------------------------------------------------------
-- 9. 30 ACTIVE SESSIONS TODAY (Currently parked: exit_time IS NULL)
-- ------------------------------------------------------------
INSERT INTO ParkingSessions (vehicle_id, space_id, entry_time, exit_time, overstay_flag) VALUES
(13, 1,  NOW() - INTERVAL 9 HOUR, NULL, TRUE),  -- Overstayer
(14, 2,  NOW() - INTERVAL 10 HOUR, NULL, TRUE), -- Overstayer
(15, 3,  NOW() - INTERVAL 2 HOUR, NULL, FALSE),
(16, 4,  NOW() - INTERVAL 3 HOUR, NULL, FALSE),
(17, 5,  NOW() - INTERVAL 1 HOUR, NULL, FALSE),
(18, 6,  NOW() - INTERVAL 4 HOUR, NULL, FALSE),
(19, 7,  NOW() - INTERVAL 5 HOUR, NULL, FALSE),
(20, 8,  NOW() - INTERVAL 2 HOUR, NULL, FALSE),
(21, 9,  NOW() - INTERVAL 6 HOUR, NULL, FALSE),
(22, 10, NOW() - INTERVAL 1 HOUR, NULL, FALSE),
(23, 11, NOW() - INTERVAL 3 HOUR, NULL, FALSE),
(24, 12, NOW() - INTERVAL 4 HOUR, NULL, FALSE),
(25, 13, NOW() - INTERVAL 9 HOUR, NULL, TRUE),  -- Overstayer
(26, 14, NOW() - INTERVAL 2 HOUR, NULL, FALSE),
(27, 15, NOW() - INTERVAL 1 HOUR, NULL, FALSE),
(28, 16, NOW() - INTERVAL 5 HOUR, NULL, FALSE),
(29, 17, NOW() - INTERVAL 3 HOUR, NULL, FALSE),
(30, 18, NOW() - INTERVAL 2 HOUR, NULL, FALSE),
(31, 19, NOW() - INTERVAL 4 HOUR, NULL, FALSE),
(32, 20, NOW() - INTERVAL 1 HOUR, NULL, FALSE),
(33, 21, NOW() - INTERVAL 7 HOUR, NULL, FALSE),
(34, 22, NOW() - INTERVAL 2 HOUR, NULL, FALSE),
(35, 23, NOW() - INTERVAL 3 HOUR, NULL, FALSE),
(36, 24, NOW() - INTERVAL 8 HOUR, NULL, FALSE),
(37, 25, NOW() - INTERVAL 1 HOUR, NULL, FALSE),
(38, 26, NOW() - INTERVAL 4 HOUR, NULL, FALSE),
(39, 27, NOW() - INTERVAL 2 HOUR, NULL, FALSE),
(40, 28, NOW() - INTERVAL 3 HOUR, NULL, FALSE),
(41, 29, NOW() - INTERVAL 10 HOUR, NULL, TRUE), -- Overstayer
(42, 30, NOW() - INTERVAL 2 HOUR, NULL, FALSE);

-- ------------------------------------------------------------
-- 10. PAYMENTS (Historical records)
-- ------------------------------------------------------------
INSERT INTO Payments (session_id, amount, payment_method, payment_time, payment_status, processed_by_staff_id) VALUES
(1,  14000, 'Mobile Money', '2026-10-12 11:55:00', 'Success', NULL),
(2,   7000, 'Card',         '2026-10-13 10:50:00', 'Success', NULL),
(3,   8000, 'Cash',         '2026-10-14 09:58:00', 'Success', 3),
(4,  28000, 'Cash',         '2026-10-12 15:15:00', 'Success', NULL),
(5,   1500, 'Cash',         '2026-10-12 09:55:00', 'Success', 4),
(6,  44000, 'Card',         '2026-10-13 18:25:00', 'Failed',  NULL),
(6,  44000, 'Cash',         '2026-10-13 18:40:00', 'Success', 4),
(7,  18000, 'Mobile Money', '2026-10-13 13:35:00', 'Success', NULL),
(8,   8000, 'Cash',         '2026-10-13 14:05:00', 'Success', NULL),
(9,   6000, 'Cash',         '2026-10-14 12:05:00', 'Success', 5),
(10, 36000, 'Card',         '2026-10-14 16:35:00', 'Success', 5),
(11, 12000, 'Mobile Money', '2026-10-14 11:35:00', 'Success', NULL);

-- ------------------------------------------------------------
-- 11. SPACE STATUS LOG
-- ------------------------------------------------------------
INSERT INTO SpaceStatusLog (space_id, status, changed_at, session_id) VALUES
(8, 'Out-of-Service', NOW() - INTERVAL 1 DAY, NULL);
