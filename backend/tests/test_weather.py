import pytest
from app.services.weather_svc import WeatherSynthesizer


class TestWeatherSynthesizer:
    def test_generate_weather_basic(self):
        """Verify weather generation returns all required fields"""
        weather = WeatherSynthesizer.generate_weather(
            lat=19.0760,
            lon=72.8777,
            zone="Mumbai-Central"
        )
        
        assert "temperature_celsius" in weather
        assert "rain_mm" in weather
        assert "humidity_percent" in weather
        assert "wind_speed_kmh" in weather
        assert weather["zone"] == "Mumbai-Central"
        assert weather["lat"] == 19.0760
        assert weather["lon"] == 72.8777
    
    def test_consistency_rule_rain_humidity(self):
        """Rule 1: Rain > 5mm must result in humidity > 85%"""
        # Generate multiple samples to test consistency
        for _ in range(10):
            weather = WeatherSynthesizer.generate_weather(19.0, 72.0, "Test-Zone")
            
            if weather["rain_mm"] > 5.0:
                assert weather["humidity_percent"] >= 85, \
                    f"Rain {weather['rain_mm']}mm but humidity only {weather['humidity_percent']}%"
    
    def test_consistency_rule_heat_humidity(self):
        """Rule 2: Temperature > 40°C should result in humidity < 60%"""
        for _ in range(10):
            weather = WeatherSynthesizer.generate_weather(19.0, 72.0, "Test-Zone")
            
            if weather["temperature_celsius"] > 40.0:
                assert weather["humidity_percent"] <= 60, \
                    f"Temp {weather['temperature_celsius']}°C but humidity {weather['humidity_percent']}%"
    
    def test_consistency_rule_heavy_rain_wind(self):
        """Rule 4: Rain > 10mm must result in wind > 15 km/h"""
        for _ in range(10):
            weather = WeatherSynthesizer.generate_weather(19.0, 72.0, "Test-Zone")
            
            if weather["rain_mm"] > 10.0:
                assert weather["wind_speed_kmh"] >= 15, \
                    f"Rain {weather['rain_mm']}mm but wind only {weather['wind_speed_kmh']} km/h"
    
    def test_impossible_state_correction(self):
        """Rule 5: Rain with low humidity should be auto-corrected"""
        # Manually create impossible state and verify correction
        impossible_weather = {
            "temperature_celsius": 25.0,
            "rain_mm": 8.0,
            "humidity_percent": 30.0,  # Impossible with rain
            "wind_speed_kmh": 20.0,
        }
        
        corrected = WeatherSynthesizer._apply_consistency_rules(impossible_weather)
        
        assert corrected["humidity_percent"] >= 60, \
            "Rain with low humidity was not corrected"
    
    def test_payout_threshold_heavy_rain(self):
        """Verify payout trigger for heavy rain (>= 5mm)"""
        weather = {
            "rain_mm": 6.5,
            "wind_speed_kmh": 20.0,
            "temperature_celsius": 28.0,
            "humidity_percent": 90.0,
        }
        
        should_trigger, reason = WeatherSynthesizer.check_payout_threshold(weather)
        
        assert should_trigger is True
        assert "Heavy Rain" in reason
        assert "6.5" in reason
    
    def test_payout_threshold_high_wind(self):
        """Verify payout trigger for high wind (>= 40 km/h)"""
        weather = {
            "rain_mm": 0.0,
            "wind_speed_kmh": 45.0,
            "temperature_celsius": 30.0,
            "humidity_percent": 60.0,
        }
        
        should_trigger, reason = WeatherSynthesizer.check_payout_threshold(weather)
        
        assert should_trigger is True
        assert "High Wind" in reason
        assert "45" in reason
    
    def test_payout_threshold_extreme_cold(self):
        """Verify payout trigger for extreme cold (<= 5°C)"""
        weather = {
            "rain_mm": 0.0,
            "wind_speed_kmh": 15.0,
            "temperature_celsius": 3.0,
            "humidity_percent": 50.0,
        }
        
        should_trigger, reason = WeatherSynthesizer.check_payout_threshold(weather)
        
        assert should_trigger is True
        assert "Extreme Cold" in reason
    
    def test_payout_threshold_extreme_heat(self):
        """Verify payout trigger for extreme heat (>= 42°C)"""
        weather = {
            "rain_mm": 0.0,
            "wind_speed_kmh": 10.0,
            "temperature_celsius": 43.0,
            "humidity_percent": 40.0,
        }
        
        should_trigger, reason = WeatherSynthesizer.check_payout_threshold(weather)
        
        assert should_trigger is True
        assert "Extreme Heat" in reason
    
    def test_payout_threshold_multiple_triggers(self):
        """Verify multiple simultaneous triggers are combined"""
        weather = {
            "rain_mm": 8.0,
            "wind_speed_kmh": 50.0,
            "temperature_celsius": 30.0,
            "humidity_percent": 90.0,
        }
        
        should_trigger, reason = WeatherSynthesizer.check_payout_threshold(weather)
        
        assert should_trigger is True
        assert "Heavy Rain" in reason
        assert "High Wind" in reason
        assert "+" in reason  # Multiple triggers joined
    
    def test_payout_threshold_normal_conditions(self):
        """Verify no payout for normal weather"""
        weather = {
            "rain_mm": 2.0,
            "wind_speed_kmh": 20.0,
            "temperature_celsius": 28.0,
            "humidity_percent": 70.0,
        }
        
        should_trigger, reason = WeatherSynthesizer.check_payout_threshold(weather)
        
        assert should_trigger is False
        assert reason == "Normal conditions"
