"""
Parametric Insurance Constants & Thresholds
"""

# Premium Rate Tiers (Weekly Cycle)
PREMIUM_TIERS = {
    "TIER_1": {"min_rides": 100, "rate": 0.05},  # 5% for high earners
    "TIER_2": {"min_rides": 70, "rate": 0.04},   # 4% for medium earners
    "TIER_3": {"min_rides": 0, "rate": 0.03},    # 3% for low earners
}

# Front-Loading Corpus Strategy (Month 1)
FRONT_LOAD_TIERS = {
    "TIER_1": 0.07,
    "TIER_2": 0.05,
    "TIER_3": 0.03,
}

# Weather Payout Thresholds
WEATHER_THRESHOLDS = {
    "RAIN_MM": 5.0,
    "WIND_SPEED_KMH": 40.0,
    "TEMPERATURE_MIN": 5.0,
    "TEMPERATURE_MAX": 42.0,
}

# Sensor Fusion Anti-Fraud Gates
SENSOR_FUSION_THRESHOLDS = {
    "MIN_SPEED_KMH": 10.0,
    "MAX_ACCELEROMETER_VARIANCE": 0.5,
}

# Payout Multipliers
BASE_PAYOUT_PERCENTAGE = 0.20  # 20% of weekly projected income
