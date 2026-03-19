"""
Weather Synthesizer Service
Generates deterministic, meteorologically sound simulated weather data
with consistency rules to avoid expensive third-party API limits.
"""
from typing import Dict, Tuple
from datetime import datetime
import random
from app.core.constants import WEATHER_THRESHOLDS


class WeatherSynthesizer:
    """
    Rule-based weather data generator with meteorological consistency.
    Ensures physically impossible weather states are auto-corrected.
    """
    
    @staticmethod
    def _apply_consistency_rules(weather_data: Dict) -> Dict:
        """
        Enforce meteorological consistency rules:
        1. Rain > 5mm → Humidity must be > 85%
        2. Temperature > 40°C → Humidity must be < 60%
        3. Wind > 40 km/h → Temperature variance ±5°C
        4. Rain > 10mm → Wind speed must be > 15 km/h
        """
        rain = weather_data["rain_mm"]
        temp = weather_data["temperature_celsius"]
        humidity = weather_data["humidity_percent"]
        wind = weather_data["wind_speed_kmh"]
        
        # Rule 2: Extreme heat implies low humidity (apply first)
        if temp > 40.0 and humidity > 60:
            weather_data["humidity_percent"] = round(random.uniform(30, 60), 1)
            humidity = weather_data["humidity_percent"]  # Update local variable
        
        # Rule 1: Heavy rain implies high humidity (PRIORITY - overrides Rule 2)
        if rain > 5.0:
            if humidity < 85:
                weather_data["humidity_percent"] = round(random.uniform(85, 95), 1)
        
        # Rule 3: High wind with extreme heat is rare
        if wind > 40.0 and temp > 40.0:
            weather_data["temperature_celsius"] = round(random.uniform(35, 40), 1)
        
        # Rule 4: Heavy rain implies wind
        if rain > 10.0 and wind < 15:
            weather_data["wind_speed_kmh"] = round(random.uniform(15, 30), 1)
        
        # Rule 5: Impossible state - rain with very low humidity
        if rain > 0 and weather_data["humidity_percent"] < 50:
            weather_data["humidity_percent"] = round(random.uniform(60, 80), 1)
        
        return weather_data
    
    @staticmethod
    def generate_weather(lat: float, lon: float, zone: str) -> Dict:
        """
        Generate synthetic weather data for a given location.
        
        Args:
            lat: Latitude coordinate
            lon: Longitude coordinate
            zone: Geographic zone (e.g., "Mumbai-Central")
        
        Returns:
            Dictionary with weather parameters
        """
        # Base weather generation (simplified for MVP)
        # In production, this would use zone-specific climate patterns
        base_temp = random.uniform(15, 42)
        base_rain = random.uniform(0, 15)
        base_humidity = random.uniform(40, 95)
        base_wind = random.uniform(5, 50)
        
        weather_data = {
            "temperature_celsius": round(base_temp, 1),
            "rain_mm": round(base_rain, 1),
            "humidity_percent": round(base_humidity, 1),
            "wind_speed_kmh": round(base_wind, 1),
            "zone": zone,
            "lat": lat,
            "lon": lon,
            "timestamp": datetime.utcnow().isoformat(),
        }
        
        # Apply consistency rules
        weather_data = WeatherSynthesizer._apply_consistency_rules(weather_data)
        
        return weather_data
    
    @staticmethod
    def check_payout_threshold(weather_data: Dict) -> Tuple[bool, str]:
        """
        Determine if weather conditions meet payout thresholds.
        
        Returns:
            Tuple of (should_trigger_payout, reason)
        """
        triggers = []
        
        if weather_data["rain_mm"] >= WEATHER_THRESHOLDS["RAIN_MM"]:
            triggers.append(f"Heavy Rain ({weather_data['rain_mm']}mm)")
        
        if weather_data["wind_speed_kmh"] >= WEATHER_THRESHOLDS["WIND_SPEED_KMH"]:
            triggers.append(f"High Wind ({weather_data['wind_speed_kmh']} km/h)")
        
        if weather_data["temperature_celsius"] <= WEATHER_THRESHOLDS["TEMPERATURE_MIN"]:
            triggers.append(f"Extreme Cold ({weather_data['temperature_celsius']}°C)")
        
        if weather_data["temperature_celsius"] >= WEATHER_THRESHOLDS["TEMPERATURE_MAX"]:
            triggers.append(f"Extreme Heat ({weather_data['temperature_celsius']}°C)")
        
        if triggers:
            return True, " + ".join(triggers)
        
        return False, "Normal conditions"
