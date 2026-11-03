#!/usr/bin/env python3
"""
=============================================================================
 Parking Management System (Group 8)
 File   : generate_charts.py
 Cleaned: Removed cluttered reservation donut chart. Focuses on the 3 core
          executive metrics with clear, unclipped labels.
=============================================================================
"""

import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

OUTPUT_DIR = "/home/beatrice/parking_db/reports_charts"
STATIC_DIR = "/home/beatrice/parking_db/app/static/charts"
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(STATIC_DIR, exist_ok=True)

THEME = {
    "bg": "#F8FAFC",
    "card": "#FFFFFF",
    "text": "#0F172A",
    "muted": "#64748B",
    "grid": "#E2E8F0",
    "blue": "#0284C7",
    "blue_light": "#E0F2FE",
    "teal": "#0D9488",
    "teal_light": "#CCFBF1",
    "rose": "#E11D48",
    "purple": "#7C3AED"
}

plt.rcParams.update({
    "font.sans-serif": ["DejaVu Sans", "Helvetica", "Arial"],
    "font.family": "sans-serif",
    "font.size": 11,
    "axes.facecolor": THEME["card"],
    "axes.edgecolor": THEME["grid"],
    "axes.labelcolor": THEME["text"],
    "axes.titlecolor": THEME["text"],
    "xtick.color": THEME["muted"],
    "ytick.color": THEME["muted"],
    "text.color": THEME["text"],
    "grid.color": THEME["grid"],
    "grid.linestyle": ":",
    "figure.facecolor": THEME["bg"]
})

def format_currency(x, pos):
    return f"{int(x):,} UGX"

# 1. Floor Yield
def plot_revenue_by_lot():
    floors = ["Level 1\n(Ground Deck)", "Level 2\n(Mezzanine)", "Level 3\n(Upper Deck)", "Level 4\n(Rooftop)"]
    revenue = [155500, 31000, 0, 0]
    
    fig, ax = plt.subplots(figsize=(8, 4.5), dpi=300)
    bars = ax.bar(floors, revenue, width=0.45, color=THEME["blue"], edgecolor="#0369A1", linewidth=1.2, zorder=3)
    ax.set_ylabel("Gross Revenue (UGX)", fontweight="600")
    ax.set_ylim(0, 185000)
    ax.yaxis.set_major_formatter(matplotlib.ticker.FuncFormatter(format_currency))
    ax.grid(axis="y", zorder=0)

    for bar in bars:
        h = bar.get_height()
        if h > 0:
            ax.annotate(f"{int(h):,} UGX",
                        xy=(bar.get_x() + bar.get_width() / 2, h),
                        xytext=(0, 6), textcoords="offset points",
                        ha="center", va="bottom", fontweight="bold", fontsize=10, color=THEME["blue"])

    plt.title("Financial Revenue Collected by Building Floor Deck", fontsize=12, fontweight="bold", pad=14)
    plt.tight_layout()
    for d in [OUTPUT_DIR, STATIC_DIR]:
        plt.savefig(os.path.join(d, "chart1_revenue_by_lot.png"), bbox_inches="tight")
    plt.close()

# 2. Live Occupancy
def plot_live_occupancy():
    floors = ["Level 1 (Ground)", "Level 2 (Mezzanine)", "Level 3 (Upper)", "Level 4 (Rooftop)"]
    capacities = [12, 10, 10, 8]
    occupied = [10, 8, 8, 4]
    available = [2, 2, 2, 4]

    fig, ax = plt.subplots(figsize=(8.5, 4.5), dpi=300)
    y = np.arange(len(floors))
    h = 0.42

    ax.barh(y, occupied, h, label="Occupied Spaces", color=THEME["rose"], edgecolor="#BE123C", linewidth=1.1, zorder=3)
    ax.barh(y, available, h, left=occupied, label="Available Spaces", color=THEME["teal_light"], edgecolor=THEME["teal"], linewidth=1.1, zorder=3)

    ax.set_yticks(y)
    ax.set_yticklabels(floors, fontweight="600")
    ax.set_xlabel("Parking Bay Capacity Count", fontweight="600")
    ax.set_xlim(0, 14)
    ax.grid(axis="x", zorder=0)

    for i in range(len(floors)):
        pct = (occupied[i] / capacities[i]) * 100
        ax.text(capacities[i] + 0.2, y[i], f"{pct:.0f}% Full ({occupied[i]}/{capacities[i]})",
                va="center", fontweight="bold", fontsize=9.5, color=THEME["text"])

    plt.title("Real-Time Capacity & Allocation Across Building Decks", fontsize=12, fontweight="bold", pad=14)
    ax.legend(loc="lower right", framealpha=0.9, edgecolor=THEME["grid"])
    plt.tight_layout()
    for d in [OUTPUT_DIR, STATIC_DIR]:
        plt.savefig(os.path.join(d, "chart2_live_occupancy.png"), bbox_inches="tight")
    plt.close()

# 3. Daily Trajectory
def plot_daily_revenue():
    dates = ["2026-10-12", "2026-10-13", "2026-10-14", "2026-10-15"]
    daily_rev = [43500, 77000, 62000, 4000]
    running_tot = [43500, 120500, 182500, 186500]

    fig, ax = plt.subplots(figsize=(8.5, 4.5), dpi=300)
    bars = ax.bar(dates, daily_rev, width=0.45, color=THEME["blue_light"], edgecolor=THEME["blue"], linewidth=1.2, label="Daily Revenue (UGX)", zorder=3)
    ax.plot(dates, running_tot, color=THEME["purple"], marker="s", markersize=6, linewidth=2.2, label="Cumulative Total (UGX)", zorder=4)

    ax.set_ylabel("Revenue (UGX)", fontweight="600")
    ax.set_ylim(0, 215000)
    ax.yaxis.set_major_formatter(matplotlib.ticker.FuncFormatter(format_currency))
    ax.grid(axis="y", zorder=0)

    for bar in bars:
        h = bar.get_height()
        ax.annotate(f"{int(h):,}",
                    xy=(bar.get_x() + bar.get_width() / 2, h),
                    xytext=(0, 4), textcoords="offset points",
                    ha="center", va="bottom", fontsize=9, fontweight="bold", color=THEME["blue"])

    plt.title("Daily Collection Intake & Cumulative Growth Curve", fontsize=12, fontweight="bold", pad=14)
    ax.legend(loc="upper left", framealpha=0.9, edgecolor=THEME["grid"])
    plt.tight_layout()
    for d in [OUTPUT_DIR, STATIC_DIR]:
        plt.savefig(os.path.join(d, "chart3_daily_revenue_trend.png"), bbox_inches="tight")
    plt.close()

if __name__ == "__main__":
    plot_revenue_by_lot()
    plot_live_occupancy()
    plot_daily_revenue()
    print("[✓] Regenerated charts 1, 2, 3 without clutter.")
