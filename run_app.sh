#!/usr/bin/env bash
# ============================================================
# Parking Management System (Group 8)
# Launch Script for Stage 7 UI & Database Connectivity
# ============================================================

cd /home/beatrice/parking_db/app
echo "============================================================"
echo " Starting Group 8 Parking Management System Dashboard..."
echo " Web Interface URL: http://127.0.0.1:5000"
echo " Press Ctrl+C to stop the server."
echo "============================================================"

python3 app.py
