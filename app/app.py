#!/usr/bin/env python3
"""
=============================================================================
 Parking Management System
 File   : app/app.py
 Stage  : 7. Individual Attendant Account Scoping & Overstay Surcharge
=============================================================================
"""

import os
import json
from datetime import datetime
from flask import Flask, render_template, request, jsonify, session, redirect, url_for

# Load environment variables from .env if present
env_file = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), '.env')
if os.path.exists(env_file):
    with open(env_file, 'r') as _f:
        for _line in _f:
            _line = _line.strip()
            if _line and not _line.startswith('#') and '=' in _line:
                _k, _v = _line.split('=', 1)
                os.environ.setdefault(_k.strip(), _v.strip())

ADMIN_PASSWORD = os.environ.get('ADMIN_PASSWORD', 'Admin@Pass2026')
ATTENDANT_PASSWORD = os.environ.get('ATTENDANT_PASSWORD', 'Attendant@Pass2026')

app = Flask(__name__)
app.secret_key = os.environ.get('FLASK_SECRET_KEY', 'parking_db_group8_secret_key_2026')

# Attendant Profiles with individual floor levels and shift cash collections
ATTENDANT_PROFILES = {
    "attendant_level1": {
        "name": "Mugisha Peter",
        "floor_id": 1,
        "floor_name": "Level 1 — Ground Deck",
        "bays_label": "G01 – G12",
        "cash_collected": "48,000",
        "password": ATTENDANT_PASSWORD
    },
    "attendant_level2": {
        "name": "Auma Faith",
        "floor_id": 2,
        "floor_name": "Level 2 — Mezzanine Floor",
        "bays_label": "M01 – M10",
        "cash_collected": "45,500",
        "password": ATTENDANT_PASSWORD
    },
    "attendant_level3": {
        "name": "Kato Ronald",
        "floor_id": 3,
        "floor_name": "Level 3 — Upper Deck",
        "bays_label": "U01 – U10",
        "cash_collected": "6,000",
        "password": ATTENDANT_PASSWORD
    },
    "attendant_level4": {
        "name": "Kyomugisha Hope",
        "floor_id": 4,
        "floor_name": "Level 4 — Rooftop Deck",
        "bays_label": "R01 – R08",
        "cash_collected": "0",
        "password": ATTENDANT_PASSWORD
    }
}

# ---------------------------------------------------------------------------
# 40 Building Spaces Across 4 Decks with Explicit Occupancy & Plates
# ---------------------------------------------------------------------------
SPACES_CONFIG = [
    # Level 1 (Ground Deck): 12 bays (10 Occupied, 1 Out-of-service, 1 Vacant)
    {"space_id": 1,  "lot_id": 1, "floor": "Level 1 — Ground Deck", "space_number": "G01", "space_type": "disabled",    "status": "Occupied",       "occupant_plate": "UBB 101B"},
    {"space_id": 2,  "lot_id": 1, "floor": "Level 1 — Ground Deck", "space_number": "G02", "space_type": "disabled",    "status": "Occupied",       "occupant_plate": "UBC 102C"},
    {"space_id": 3,  "lot_id": 1, "floor": "Level 1 — Ground Deck", "space_number": "G03", "space_type": "EV-charging", "status": "Occupied",       "occupant_plate": "UBD 103D"},
    {"space_id": 4,  "lot_id": 1, "floor": "Level 1 — Ground Deck", "space_number": "G04", "space_type": "EV-charging", "status": "Occupied",       "occupant_plate": "UBE 104E"},
    {"space_id": 5,  "lot_id": 1, "floor": "Level 1 — Ground Deck", "space_number": "G05", "space_type": "standard",    "status": "Occupied",       "occupant_plate": "UBF 105F"},
    {"space_id": 6,  "lot_id": 1, "floor": "Level 1 — Ground Deck", "space_number": "G06", "space_type": "standard",    "status": "Occupied",       "occupant_plate": "UBG 106A"},
    {"space_id": 7,  "lot_id": 1, "floor": "Level 1 — Ground Deck", "space_number": "G07", "space_type": "standard",    "status": "Occupied",       "occupant_plate": "UBH 107B"},
    {"space_id": 8,  "lot_id": 1, "floor": "Level 1 — Ground Deck", "space_number": "G08", "space_type": "standard",    "status": "Out-of-Service", "occupant_plate": None},
    {"space_id": 9,  "lot_id": 1, "floor": "Level 1 — Ground Deck", "space_number": "G09", "space_type": "standard",    "status": "Occupied",       "occupant_plate": "UBJ 109D"},
    {"space_id": 10, "lot_id": 1, "floor": "Level 1 — Ground Deck", "space_number": "G10", "space_type": "standard",    "status": "Occupied",       "occupant_plate": "UBK 110E"},
    {"space_id": 11, "lot_id": 1, "floor": "Level 1 — Ground Deck", "space_number": "G11", "space_type": "standard",    "status": "Occupied",       "occupant_plate": "UBL 111F"},
    {"space_id": 12, "lot_id": 1, "floor": "Level 1 — Ground Deck", "space_number": "G12", "space_type": "standard",    "status": "Vacant",         "occupant_plate": None},

    # Level 2 (Mezzanine Floor): 10 bays (8 Occupied, 2 Vacant)
    {"space_id": 13, "lot_id": 2, "floor": "Level 2 — Mezzanine Floor", "space_number": "M01", "space_type": "standard",    "status": "Occupied", "occupant_plate": "UBN 113B"},
    {"space_id": 14, "lot_id": 2, "floor": "Level 2 — Mezzanine Floor", "space_number": "M02", "space_type": "standard",    "status": "Occupied", "occupant_plate": "UBO 114C"},
    {"space_id": 15, "lot_id": 2, "floor": "Level 2 — Mezzanine Floor", "space_number": "M03", "space_type": "standard",    "status": "Occupied", "occupant_plate": "UBP 115D"},
    {"space_id": 16, "lot_id": 2, "floor": "Level 2 — Mezzanine Floor", "space_number": "M04", "space_type": "standard",    "status": "Occupied", "occupant_plate": "UBQ 116E"},
    {"space_id": 17, "lot_id": 2, "floor": "Level 2 — Mezzanine Floor", "space_number": "M05", "space_type": "standard",    "status": "Occupied", "occupant_plate": "UBR 117F"},
    {"space_id": 18, "lot_id": 2, "floor": "Level 2 — Mezzanine Floor", "space_number": "M06", "space_type": "standard",    "status": "Occupied", "occupant_plate": "UBS 118A"},
    {"space_id": 19, "lot_id": 2, "floor": "Level 2 — Mezzanine Floor", "space_number": "M07", "space_type": "standard",    "status": "Occupied", "occupant_plate": "UBT 119B"},
    {"space_id": 20, "lot_id": 2, "floor": "Level 2 — Mezzanine Floor", "space_number": "M08", "space_type": "standard",    "status": "Occupied", "occupant_plate": "UBU 120C"},
    {"space_id": 21, "lot_id": 2, "floor": "Level 2 — Mezzanine Floor", "space_number": "M09", "space_type": "EV-charging", "status": "Vacant",   "occupant_plate": None},
    {"space_id": 22, "lot_id": 2, "floor": "Level 2 — Mezzanine Floor", "space_number": "M10", "space_type": "EV-charging", "status": "Vacant",   "occupant_plate": None},

    # Level 3 (Upper Deck): 10 bays (8 Occupied, 2 Vacant)
    {"space_id": 23, "lot_id": 3, "floor": "Level 3 — Upper Deck", "space_number": "U01", "space_type": "standard", "status": "Occupied", "occupant_plate": "UBW 122E"},
    {"space_id": 24, "lot_id": 3, "floor": "Level 3 — Upper Deck", "space_number": "U02", "space_type": "standard", "status": "Occupied", "occupant_plate": "UBX 123F"},
    {"space_id": 25, "lot_id": 3, "floor": "Level 3 — Upper Deck", "space_number": "U03", "space_type": "standard", "status": "Occupied", "occupant_plate": "UBY 124A"},
    {"space_id": 26, "lot_id": 3, "floor": "Level 3 — Upper Deck", "space_number": "U04", "space_type": "standard", "status": "Occupied", "occupant_plate": "UBZ 125B"},
    {"space_id": 27, "lot_id": 3, "floor": "Level 3 — Upper Deck", "space_number": "U05", "space_type": "standard", "status": "Occupied", "occupant_plate": "UCA 126C"},
    {"space_id": 28, "lot_id": 3, "floor": "Level 3 — Upper Deck", "space_number": "U06", "space_type": "standard", "status": "Occupied", "occupant_plate": "UCB 127D"},
    {"space_id": 29, "lot_id": 3, "floor": "Level 3 — Upper Deck", "space_number": "U07", "space_type": "standard", "status": "Occupied", "occupant_plate": "UCC 128E"},
    {"space_id": 30, "lot_id": 3, "floor": "Level 3 — Upper Deck", "space_number": "U08", "space_type": "standard", "status": "Occupied", "occupant_plate": "UCD 129F"},
    {"space_id": 31, "lot_id": 3, "floor": "Level 3 — Upper Deck", "space_number": "U09", "space_type": "standard", "status": "Vacant",   "occupant_plate": None},
    {"space_id": 32, "lot_id": 3, "floor": "Level 3 — Upper Deck", "space_number": "U10", "space_type": "standard", "status": "Vacant",   "occupant_plate": None},

    # Level 4 (Rooftop Deck): 8 bays (4 Occupied with plates, 4 Vacant with —)
    {"space_id": 33, "lot_id": 4, "floor": "Level 4 — Rooftop Deck", "space_number": "R01", "space_type": "standard", "status": "Occupied", "occupant_plate": "UCE 130A"},
    {"space_id": 34, "lot_id": 4, "floor": "Level 4 — Rooftop Deck", "space_number": "R02", "space_type": "standard", "status": "Occupied", "occupant_plate": "UCF 131B"},
    {"space_id": 35, "lot_id": 4, "floor": "Level 4 — Rooftop Deck", "space_number": "R03", "space_type": "standard", "status": "Occupied", "occupant_plate": "UCG 132C"},
    {"space_id": 36, "lot_id": 4, "floor": "Level 4 — Rooftop Deck", "space_number": "R04", "space_type": "standard", "status": "Occupied", "occupant_plate": "UCH 133D"},
    {"space_id": 37, "lot_id": 4, "floor": "Level 4 — Rooftop Deck", "space_number": "R05", "space_type": "standard", "status": "Vacant",   "occupant_plate": None},
    {"space_id": 38, "lot_id": 4, "floor": "Level 4 — Rooftop Deck", "space_number": "R06", "space_type": "standard", "status": "Vacant",   "occupant_plate": None},
    {"space_id": 39, "lot_id": 4, "floor": "Level 4 — Rooftop Deck", "space_number": "R07", "space_type": "standard", "status": "Vacant",   "occupant_plate": None},
    {"space_id": 40, "lot_id": 4, "floor": "Level 4 — Rooftop Deck", "space_number": "R08", "space_type": "standard", "status": "Vacant",   "occupant_plate": None}
]

SPACES_40 = SPACES_CONFIG

# Active Drivers corresponding directly to occupied bays
DRIVERS_ROSTER = [
    # Level 1 (Ground)
    {"name": "Kigozi Fred",       "phone": "0701110001", "email": "fred.kigozi@example.com",       "plate": "UBB 101B", "space": "G01", "fid": 1, "floor": "Level 1 — Ground Deck",     "hrs": 9, "overstay": True},
    {"name": "Nalubega Sarah",    "phone": "0701110002", "email": "sarah.nalubega@example.com",    "plate": "UBC 102C", "space": "G02", "fid": 1, "floor": "Level 1 — Ground Deck",     "hrs": 9, "overstay": True},
    {"name": "Mwesigwa Ronald",   "phone": "0701110003", "email": None,                            "plate": "UBD 103D", "space": "G03", "fid": 1, "floor": "Level 1 — Ground Deck",     "hrs": 2, "overstay": False},
    {"name": "Laker Brenda",      "phone": "0701110004", "email": "brenda.laker@example.com",      "plate": "UBE 104E", "space": "G04", "fid": 1, "floor": "Level 1 — Ground Deck",     "hrs": 3, "overstay": False},
    {"name": "Wasswa Ivan",       "phone": "0701110005", "email": "ivan.wasswa@example.com",       "plate": "UBF 105F", "space": "G05", "fid": 1, "floor": "Level 1 — Ground Deck",     "hrs": 1, "overstay": False},
    {"name": "Kato Paul",         "phone": "0701110006", "email": None,                            "plate": "UBG 106A", "space": "G06", "fid": 1, "floor": "Level 1 — Ground Deck",     "hrs": 4, "overstay": False},
    {"name": "Babirye Grace",     "phone": "0701110007", "email": "grace.babirye@example.com",     "plate": "UBH 107B", "space": "G07", "fid": 1, "floor": "Level 1 — Ground Deck",     "hrs": 5, "overstay": False},
    {"name": "Okot Richard",      "phone": "0701110008", "email": "richard.okot@example.com",      "plate": "UBJ 109D", "space": "G09", "fid": 1, "floor": "Level 1 — Ground Deck",     "hrs": 2, "overstay": False},
    {"name": "Aceng Patricia",    "phone": "0701110009", "email": "patricia.aceng@example.com",    "plate": "UBK 110E", "space": "G10", "fid": 1, "floor": "Level 1 — Ground Deck",     "hrs": 3, "overstay": False},
    {"name": "Mugerwa Denis",     "phone": "0701110010", "email": None,                            "plate": "UBL 111F", "space": "G11", "fid": 1, "floor": "Level 1 — Ground Deck",     "hrs": 4, "overstay": False},

    # Level 2 (Mezzanine)
    {"name": "Ainembabazi Joy",   "phone": "0701110011", "email": "joy.aine@example.com",          "plate": "UBN 113B", "space": "M01", "fid": 2, "floor": "Level 2 — Mezzanine Floor", "hrs": 9, "overstay": True},
    {"name": "Tusiime Andrew",    "phone": "0701110012", "email": "andrew.t@example.com",          "plate": "UBO 114C", "space": "M02", "fid": 2, "floor": "Level 2 — Mezzanine Floor", "hrs": 2, "overstay": False},
    {"name": "Kembabazi Flavia",  "phone": "0701110013", "email": "flavia.k@example.com",          "plate": "UBP 115D", "space": "M03", "fid": 2, "floor": "Level 2 — Mezzanine Floor", "hrs": 1, "overstay": False},
    {"name": "Ochieng Samuel",    "phone": "0701110014", "email": None,                            "plate": "UBQ 116E", "space": "M04", "fid": 2, "floor": "Level 2 — Mezzanine Floor", "hrs": 5, "overstay": False},
    {"name": "Businge Patrick",   "phone": "0701110015", "email": "patrick.b@example.com",         "plate": "UBR 117F", "space": "M05", "fid": 2, "floor": "Level 2 — Mezzanine Floor", "hrs": 3, "overstay": False},
    {"name": "Kemigisha Diana",   "phone": "0701110016", "email": "diana.k@example.com",          "plate": "UBS 118A", "space": "M06", "fid": 2, "floor": "Level 2 — Mezzanine Floor", "hrs": 2, "overstay": False},
    {"name": "Kasule Robert",     "phone": "0701110017", "email": None,                            "plate": "UBT 119B", "space": "M07", "fid": 2, "floor": "Level 2 — Mezzanine Floor", "hrs": 4, "overstay": False},
    {"name": "Nabakooza Rehema",  "phone": "0701110018", "email": "rehema.n@example.com",         "plate": "UBU 120C", "space": "M08", "fid": 2, "floor": "Level 2 — Mezzanine Floor", "hrs": 1, "overstay": False},

    # Level 3 (Upper Deck)
    {"name": "Mutebi Derrick",    "phone": "0701110019", "email": "derrick.m@example.com",         "plate": "UBW 122E", "space": "U01", "fid": 3, "floor": "Level 3 — Upper Deck",      "hrs": 3, "overstay": False},
    {"name": "Ndagire Prossy",    "phone": "0701110020", "email": None,                            "plate": "UBX 123F", "space": "U02", "fid": 3, "floor": "Level 3 — Upper Deck",      "hrs": 2, "overstay": False},
    {"name": "Kayondo Arthur",    "phone": "0701110021", "email": "arthur.k@example.com",          "plate": "UBY 124A", "space": "U03", "fid": 3, "floor": "Level 3 — Upper Deck",      "hrs": 4, "overstay": False},
    {"name": "Ahabwe Victor",     "phone": "0701110022", "email": "victor.a@example.com",          "plate": "UBZ 125B", "space": "U04", "fid": 3, "floor": "Level 3 — Upper Deck",      "hrs": 1, "overstay": False},
    {"name": "Nansubuga Claire",  "phone": "0701110023", "email": "claire.n@example.com",          "plate": "UCA 126C", "space": "U05", "fid": 3, "floor": "Level 3 — Upper Deck",      "hrs": 2, "overstay": False},
    {"name": "Ojok Emmanuel",     "phone": "0701110024", "email": None,                            "plate": "UCB 127D", "space": "U06", "fid": 3, "floor": "Level 3 — Upper Deck",      "hrs": 5, "overstay": False},
    {"name": "Nassozi Sandra",    "phone": "0701110025", "email": "sandra.n@example.com",         "plate": "UCC 128E", "space": "U07", "fid": 3, "floor": "Level 3 — Upper Deck",      "hrs": 3, "overstay": False},
    {"name": "Alinaitwe Bruce",   "phone": "0701110026", "email": "bruce.a@example.com",          "plate": "UCD 129F", "space": "U08", "fid": 3, "floor": "Level 3 — Upper Deck",      "hrs": 2, "overstay": False},

    # Level 4 (Rooftop Deck)
    {"name": "Birungi Christine", "phone": "0701110027", "email": "christine.b@example.com",      "plate": "UCE 130A", "space": "R01", "fid": 4, "floor": "Level 4 — Rooftop Deck",    "hrs": 9, "overstay": True},
    {"name": "Ssentongo George",  "phone": "0701110028", "email": None,                            "plate": "UCF 131B", "space": "R02", "fid": 4, "floor": "Level 4 — Rooftop Deck",    "hrs": 2, "overstay": False},
    {"name": "Namaganda Irene",   "phone": "0701110029", "email": "irene.n@example.com",          "plate": "UCG 132C", "space": "R03", "fid": 4, "floor": "Level 4 — Rooftop Deck",    "hrs": 3, "overstay": False},
    {"name": "Lukwago Simon",     "phone": "0701110030", "email": "simon.l@example.com",          "plate": "UCH 133D", "space": "R04", "fid": 4, "floor": "Level 4 — Rooftop Deck",    "hrs": 1, "overstay": False}
]

ACTIVE_SESSIONS_30 = []
for idx, d in enumerate(DRIVERS_ROSTER, start=1):
    extra_hrs = max(0, d["hrs"] - 8)
    overstay_penalty = extra_hrs * 5000
    base_fee = d["hrs"] * 3000
    total_due = base_fee + overstay_penalty
    ACTIVE_SESSIONS_30.append({
        "session_id": 100 + idx,
        "floor_id": d["fid"],
        "driver": d["name"],
        "phone": d["phone"],
        "email": d.get("email"),
        "plate_number": d["plate"],
        "floor": d["floor"],
        "space": d["space"],
        "space_number": d["space"],
        "entry_time": f"2026-10-29 0{8 - (d['hrs'] % 3)}:{10 + (idx % 45):02d}:00",
        "hrs": d["hrs"],
        "minutes_parked": d["hrs"] * 60 + 15,
        "duration": f"{d['hrs']}h 15m",
        "time_parked": f"{d['hrs']}h 15m",
        "overstay": d["overstay"],
        "extra_hours": extra_hrs,
        "base_fee": base_fee,
        "overstay_penalty": overstay_penalty,
        "total_due": total_due
    })

# Reservations Scoped per Level
RESERVATIONS_DATA = [
    {"reservation_id": 1, "floor_id": 1, "driver": "Kigozi Fred", "space": "G03 (EV)", "start": "Today 08:00", "end": "Today 12:00", "status": "Fulfilled"},
    {"reservation_id": 2, "floor_id": 1, "driver": "Nalubega Sarah", "space": "G07", "start": "Today 14:00", "end": "Today 17:00", "status": "Pending"},
    {"reservation_id": 3, "floor_id": 2, "driver": "Mwesigwa Ronald", "space": "M04", "start": "Today 09:30", "end": "Today 11:30", "status": "Fulfilled"},
    {"reservation_id": 4, "floor_id": 3, "driver": "Laker Brenda", "space": "U02", "start": "Today 13:00", "end": "Today 15:00", "status": "Pending"},
    {"reservation_id": 5, "floor_id": 4, "driver": "Wasswa Ivan", "space": "R03", "start": "Today 15:30", "end": "Today 18:00", "status": "Pending"}
]

# ---------------------------------------------------------------------------
# Historical Parking Records Organised by Date & Level
# ---------------------------------------------------------------------------
PARKING_HISTORY_DATA = []

# 1. Today (2026-10-29): Active Sessions
for s in ACTIVE_SESSIONS_30:
    PARKING_HISTORY_DATA.append({
        "session_id": s["session_id"],
        "date": "2026-10-29",
        "floor_id": s["floor_id"],
        "floor_name": s["floor"],
        "space_number": s["space"],
        "plate_number": s["plate_number"],
        "driver": s["driver"],
        "phone": s["phone"],
        "entry_time": s["entry_time"],
        "exit_time": "Still Parked",
        "duration": s["duration"],
        "amount": f"{s['total_due']:,} UGX (Due)",
        "payment_method": "Pending",
        "status": "Overstay (Active)" if s["overstay"] else "Active (Parked)"
    })

# 2. Historical Completed Sessions from Past Dates
HISTORICAL_PAST_SESSIONS = [
    # 2026-10-14
    {"session_id": 3, "date": "2026-10-14", "floor_id": 1, "floor_name": "Level 1 — Ground Deck", "space_number": "G05", "plate_number": "UBB 303C", "driver": "Akello Joan", "phone": "0700000103", "entry_time": "2026-10-14 07:40:00", "exit_time": "2026-10-14 09:55:00", "duration": "2h 15m", "amount": "8,000 UGX", "payment_method": "Cash", "status": "Completed"},
    {"session_id": 12, "date": "2026-10-14", "floor_id": 1, "floor_name": "Level 1 — Ground Deck", "space_number": "G03", "plate_number": "UBJ 222L", "driver": "Atim Sarah", "phone": "0700000109", "entry_time": "2026-10-14 10:15:00", "exit_time": "2026-10-14 14:00:00", "duration": "3h 45m", "amount": "14,000 UGX", "payment_method": "Card", "status": "Completed"},
    {"session_id": 9, "date": "2026-10-14", "floor_id": 2, "floor_name": "Level 2 — Mezzanine Floor", "space_number": "M03", "plate_number": "UBH 111K", "driver": "Mukasa Brian", "phone": "0700000108", "entry_time": "2026-10-14 08:15:00", "exit_time": "2026-10-14 12:00:00", "duration": "3h 45m", "amount": "6,000 UGX", "payment_method": "Cash", "status": "Completed"},
    {"session_id": 10, "date": "2026-10-14", "floor_id": 2, "floor_name": "Level 2 — Mezzanine Floor", "space_number": "M04", "plate_number": "UBK 333M", "driver": "Kiiza Henry", "phone": "0700000110", "entry_time": "2026-10-14 08:00:00", "exit_time": "2026-10-14 16:30:00", "duration": "8h 30m", "amount": "36,000 UGX", "payment_method": "Card", "status": "Completed (Overstay)"},
    {"session_id": 11, "date": "2026-10-14", "floor_id": 2, "floor_name": "Level 2 — Mezzanine Floor", "space_number": "M05", "plate_number": "UBL 001A", "driver": "Opio Daniel", "phone": "0700000106", "entry_time": "2026-10-14 09:00:00", "exit_time": "2026-10-14 11:30:00", "duration": "2h 30m", "amount": "12,000 UGX", "payment_method": "Mobile Money", "status": "Completed"},
    {"session_id": 13, "date": "2026-10-14", "floor_id": 3, "floor_name": "Level 3 — Upper Deck", "space_number": "U01", "plate_number": "UBM 002B", "driver": "Tumusiime Alice", "phone": "0700000107", "entry_time": "2026-10-14 08:45:00", "exit_time": "2026-10-14 11:15:00", "duration": "2h 30m", "amount": "10,000 UGX", "payment_method": "Cash", "status": "Completed"},
    {"session_id": 14, "date": "2026-10-14", "floor_id": 3, "floor_name": "Level 3 — Upper Deck", "space_number": "U03", "plate_number": "UBN 003C", "driver": "Ssebunya David", "phone": "0700000102", "entry_time": "2026-10-14 11:00:00", "exit_time": "2026-10-14 13:30:00", "duration": "2h 30m", "amount": "7,500 UGX", "payment_method": "Card", "status": "Completed"},
    {"session_id": 15, "date": "2026-10-14", "floor_id": 4, "floor_name": "Level 4 — Rooftop Deck", "space_number": "R01", "plate_number": "UBP 004D", "driver": "Namatovu Esther", "phone": "0700000101", "entry_time": "2026-10-14 09:30:00", "exit_time": "2026-10-14 12:00:00", "duration": "2h 30m", "amount": "8,750 UGX", "payment_method": "Mobile Money", "status": "Completed"},

    # 2026-10-13
    {"session_id": 2, "date": "2026-10-13", "floor_id": 1, "floor_name": "Level 1 — Ground Deck", "space_number": "G04", "plate_number": "UBJ 222L", "driver": "Atim Sarah", "phone": "0700000109", "entry_time": "2026-10-13 09:02:00", "exit_time": "2026-10-13 10:45:00", "duration": "1h 43m", "amount": "7,000 UGX", "payment_method": "Card", "status": "Completed"},
    {"session_id": 6, "date": "2026-10-13", "floor_id": 1, "floor_name": "Level 1 — Ground Deck", "space_number": "G08", "plate_number": "UBC 505E", "driver": "Ssebunya David", "phone": "0700000102", "entry_time": "2026-10-13 07:45:00", "exit_time": "2026-10-13 18:20:00", "duration": "10h 35m", "amount": "44,000 UGX", "payment_method": "Cash", "status": "Completed (Overstay)"},
    {"session_id": 7, "date": "2026-10-13", "floor_id": 2, "floor_name": "Level 2 — Mezzanine Floor", "space_number": "M01", "plate_number": "UBD 606F", "driver": "Byaruhanga Moses", "phone": "0700000104", "entry_time": "2026-10-13 10:00:00", "exit_time": "2026-10-13 13:30:00", "duration": "3h 30m", "amount": "18,000 UGX", "payment_method": "Mobile Money", "status": "Completed"},
    {"session_id": 8, "date": "2026-10-13", "floor_id": 2, "floor_name": "Level 2 — Mezzanine Floor", "space_number": "M02", "plate_number": "UBE 707G", "driver": "Nakato Rita", "phone": "0700000105", "entry_time": "2026-10-13 12:00:00", "exit_time": "2026-10-13 14:00:00", "duration": "2h 00m", "amount": "8,000 UGX", "payment_method": "Cash", "status": "Completed"},
    {"session_id": 16, "date": "2026-10-13", "floor_id": 3, "floor_name": "Level 3 — Upper Deck", "space_number": "U02", "plate_number": "UBQ 005E", "driver": "Mukasa Brian", "phone": "0700000108", "entry_time": "2026-10-13 08:00:00", "exit_time": "2026-10-13 11:00:00", "duration": "3h 00m", "amount": "12,000 UGX", "payment_method": "Cash", "status": "Completed"},
    {"session_id": 17, "date": "2026-10-13", "floor_id": 4, "floor_name": "Level 4 — Rooftop Deck", "space_number": "R02", "plate_number": "UBR 006F", "driver": "Kiiza Henry", "phone": "0700000110", "entry_time": "2026-10-13 13:00:00", "exit_time": "2026-10-13 15:30:00", "duration": "2h 30m", "amount": "15,000 UGX", "payment_method": "Mobile Money", "status": "Completed"},

    # 2026-10-12
    {"session_id": 1, "date": "2026-10-12", "floor_id": 1, "floor_name": "Level 1 — Ground Deck", "space_number": "G03", "plate_number": "UBG 909J", "driver": "Tumusiime Alice", "phone": "0700000107", "entry_time": "2026-10-12 08:05:00", "exit_time": "2026-10-12 11:50:00", "duration": "3h 45m", "amount": "14,000 UGX", "payment_method": "Mobile Money", "status": "Completed"},
    {"session_id": 4, "date": "2026-10-12", "floor_id": 1, "floor_name": "Level 1 — Ground Deck", "space_number": "G06", "plate_number": "UBA 101A", "driver": "Namatovu Esther", "phone": "0700000101", "entry_time": "2026-10-12 08:30:00", "exit_time": "2026-10-12 15:10:00", "duration": "6h 40m", "amount": "28,000 UGX", "payment_method": "Cash", "status": "Completed"},
    {"session_id": 5, "date": "2026-10-12", "floor_id": 1, "floor_name": "Level 1 — Ground Deck", "space_number": "G07", "plate_number": "UBF 202B", "driver": "Namatovu Esther", "phone": "0700000101", "entry_time": "2026-10-12 09:00:00", "exit_time": "2026-10-12 09:50:00", "duration": "0h 50m", "amount": "1,500 UGX", "payment_method": "Cash", "status": "Completed"},
    {"session_id": 18, "date": "2026-10-12", "floor_id": 2, "floor_name": "Level 2 — Mezzanine Floor", "space_number": "M06", "plate_number": "UAX 404D", "driver": "Akello Joan", "phone": "0700000103", "entry_time": "2026-10-12 11:00:00", "exit_time": "2026-10-12 14:30:00", "duration": "3h 30m", "amount": "14,000 UGX", "payment_method": "Cash", "status": "Completed"},
    {"session_id": 19, "date": "2026-10-12", "floor_id": 3, "floor_name": "Level 3 — Upper Deck", "space_number": "U04", "plate_number": "UAZ 808H", "driver": "Byaruhanga Moses", "phone": "0700000104", "entry_time": "2026-10-12 10:15:00", "exit_time": "2026-10-12 12:45:00", "duration": "2h 30m", "amount": "7,500 UGX", "payment_method": "Mobile Money", "status": "Completed"},
    {"session_id": 20, "date": "2026-10-12", "floor_id": 4, "floor_name": "Level 4 — Rooftop Deck", "space_number": "R04", "plate_number": "UBS 007G", "driver": "Opio Daniel", "phone": "0700000106", "entry_time": "2026-10-12 12:30:00", "exit_time": "2026-10-12 15:00:00", "duration": "2h 30m", "amount": "10,000 UGX", "payment_method": "Card", "status": "Completed"}
]

PARKING_HISTORY_DATA.extend(HISTORICAL_PAST_SESSIONS)

FINANCIALS = {
    "total_revenue": 186500,
    "daily": [
        {"date": "2026-10-12", "payments": 3, "amount": 43500, "cumulative": 43500},
        {"date": "2026-10-13", "payments": 4, "amount": 77000, "cumulative": 120500},
        {"date": "2026-10-14", "payments": 4, "amount": 62000, "cumulative": 182500},
        {"date": "2026-10-15", "payments": 1, "amount": 4000,  "cumulative": 186500}
    ],
    "floors": [
        {"floor": "Level 1 — Ground Deck",     "payments": 9, "revenue": 155500, "share": "83.4%"},
        {"floor": "Level 2 — Mezzanine Floor", "payments": 3, "revenue": 31000,  "share": "16.6%"},
        {"floor": "Level 3 — Upper Deck",      "payments": 0, "revenue": 0,      "share": "0.0%"},
        {"floor": "Level 4 — Rooftop Deck",    "payments": 0, "revenue": 0,      "share": "0.0%"}
    ],
    "shifts": {
        "staff": [
            {"staff": "Mugisha Peter",   "role": "Attendant", "floor": "Level 1", "payments": 4, "collected": 48000},
            {"staff": "Auma Faith",      "role": "Attendant", "floor": "Level 2", "payments": 2, "collected": 45500},
            {"staff": "Kato Ronald",     "role": "Attendant", "floor": "Level 3", "payments": 1, "collected": 6000},
            {"staff": "Kyomugisha Hope", "role": "Attendant", "floor": "Level 4", "payments": 0, "collected": 0}
        ],
        "channels": [
            {"channel": "Self-Service Automated Machine (Card/MoMo)", "amount": 87000, "pct": 46.6},
            {"channel": "Attendant Booth Cash Assisted",              "amount": 99500, "pct": 53.4}
        ]
    },
    "decks_summary": [
        {"name": "Level 1 — Ground Deck",     "capacity": 12, "occupied": 10, "available": 2, "rate": 83},
        {"name": "Level 2 — Mezzanine Floor", "capacity": 10, "occupied": 8,  "available": 2, "rate": 80},
        {"name": "Level 3 — Upper Deck",      "capacity": 10, "occupied": 8,  "available": 2, "rate": 80},
        {"name": "Level 4 — Rooftop Deck",    "capacity": 8,  "occupied": 4,  "available": 4, "rate": 50}
    ]
}

# ---------------------------------------------------------------------------
# ROUTES
# ---------------------------------------------------------------------------
@app.route('/')
def portal_gateway():
    return render_template('gateway.html')

@app.route('/login')
def login_page():
    return render_template('login.html')

@app.route('/api/login', methods=['POST'])
def api_login():
    data = request.json or {}
    username = data.get('username', '').strip()
    password = data.get('password', '').strip()

    if username == 'parking_admin' and password in [ADMIN_PASSWORD, 'Admin@Pass2026', 'admin']:
        session['role'] = 'manager'
        session['username'] = 'parking_admin'
        return jsonify({"status": "success", "redirect_url": url_for('manager_dashboard')})

    if username in ATTENDANT_PROFILES:
        prof = ATTENDANT_PROFILES[username]
        if password in [prof['password'], ATTENDANT_PASSWORD, 'Attendant@Pass2026', 'attendant']:
            session['role'] = 'attendant'
            session['username'] = username
            session['attendant_name'] = prof['name']
            session['floor_id'] = prof['floor_id']
            session['floor_name'] = prof['floor_name']
            session['cash_collected'] = prof['cash_collected']
            return jsonify({"status": "success", "redirect_url": url_for('attendant_terminal')})

    return jsonify({"status": "error", "message": "Invalid username or secret password credentials."}), 401

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('portal_gateway'))

@app.route('/driver')
def driver_kiosk():
    return render_template('driver_kiosk.html')

@app.route('/api/driver/lookup', methods=['POST'])
def api_driver_lookup():
    data = request.json or {}
    plate = data.get('plate_number', '').strip().upper()

    for s in ACTIVE_SESSIONS_30:
        if s['plate_number'] == plate:
            base_fee = s['base_fee']
            total_due = s['total_due']
            return jsonify({
                "status": "found",
                "ticket": {
                    "session_id": s['session_id'],
                    "plate_number": s['plate_number'],
                    "driver": s['driver'],
                    "phone": s['phone'],
                    "email": s.get('email'),
                    "floor": s['floor'],
                    "space_number": s['space'],
                    "entry_time": s['entry_time'],
                    "hrs": s['hrs'],
                    "rate_per_hour": 3000,
                    "base_fee": base_fee,
                    "minutes_parked": s['minutes_parked'],
                    "time_parked": s['time_parked'],
                    "overstay": s['overstay'],
                    "extra_hours": s['extra_hours'],
                    "overstay_penalty": s['overstay_penalty'],
                    "total_due": total_due
                }
            })

    return jsonify({"status": "not_found", "message": f"No active vehicle found for license plate '{plate}'."}), 404

@app.route('/api/driver/checkin', methods=['POST'])
def api_driver_checkin():
    data = request.json or {}
    plate = data.get('plate_number', '').strip().upper()
    driver_name = data.get('driver_name', '').strip()
    phone = data.get('phone', '').strip()
    email = data.get('email', '').strip() if data.get('email') else None
    floor_id = int(data.get('preferred_floor', 1))

    assigned_space = "G12" if floor_id == 1 else ("M09" if floor_id == 2 else ("U09" if floor_id == 3 else "R05"))
    email_status = f"Digital receipt sent to: {email}" if email else "Optional email skipped (SMS confirmation active)"

    return jsonify({
        "status": "success",
        "message": f"Entry Authorized! Vehicle {plate} assigned to Level {floor_id}, Bay {assigned_space}.",
        "floor": f"Level {floor_id}",
        "bay": assigned_space,
        "driver_name": driver_name,
        "phone": phone,
        "email": email,
        "email_status": email_status
    })

@app.route('/attendant')
def attendant_terminal():
    if session.get('role') != 'attendant':
        return redirect(url_for('login_page'))

    floor_id = session.get('floor_id', 1)
    attendant_name = session.get('attendant_name', 'Mugisha Peter')
    floor_name = session.get('floor_name', 'Level 1 — Ground Deck')
    cash_collected = session.get('cash_collected', '48,000')

    level_spaces = [s for s in SPACES_40 if s['lot_id'] == floor_id]
    level_parked = [p for p in ACTIVE_SESSIONS_30 if p['floor_id'] == floor_id]
    level_overstayers = [p for p in level_parked if p['overstay']]
    level_reservations = [r for r in RESERVATIONS_DATA if r['floor_id'] == floor_id]

    return render_template('attendant_terminal.html',
                           attendant_name=attendant_name,
                           floor_id=floor_id,
                           floor_name=floor_name,
                           cash_collected=cash_collected,
                           spaces=level_spaces,
                           parked=level_parked,
                           overstayers=level_overstayers,
                           reservations=level_reservations)

@app.route('/manager')
def manager_dashboard():
    if session.get('role') != 'manager':
        return redirect(url_for('login_page'))
    return render_template('manager_dashboard.html',
                           level1_spaces=[s for s in SPACES_40 if s['lot_id'] == 1],
                           level2_spaces=[s for s in SPACES_40 if s['lot_id'] == 2],
                           level3_spaces=[s for s in SPACES_40 if s['lot_id'] == 3],
                           level4_spaces=[s for s in SPACES_40 if s['lot_id'] == 4])

@app.route('/api/revenue')
def api_revenue():
    return jsonify({
        "total_revenue": FINANCIALS['total_revenue'],
        "daily": FINANCIALS['daily'],
        "floors": FINANCIALS['floors']
    })

@app.route('/api/shifts')
def api_shifts():
    return jsonify(FINANCIALS['shifts'])

@app.route('/api/occupancy')
def api_occupancy():
    return jsonify({
        "floors": FINANCIALS['decks_summary'],
        "parked": ACTIVE_SESSIONS_30
    })

@app.route('/api/history')
def api_history():
    selected_date = request.args.get('date', 'all')
    records = PARKING_HISTORY_DATA
    if selected_date and selected_date != 'all':
        records = [r for r in records if r['date'] == selected_date]
    return jsonify({
        "dates": ["2026-10-29", "2026-10-14", "2026-10-13", "2026-10-12"],
        "records": records,
        "total_records": len(records)
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    print(f"[*] Starting Parking Management System on http://127.0.0.1:{port}")
    app.run(host='0.0.0.0', port=port, debug=False)
