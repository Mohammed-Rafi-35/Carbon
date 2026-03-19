"""
Sensor Fusion Service
Cross-references GPS speed with accelerometer variance to detect fraud.
If GPS speed > 10 km/h but accelerometer variance < 0.5, flags as GPS spoofing.
"""
from typing import Tuple, Dict
from app.core.constants import SENSOR_FUSION_THRESHOLDS


class SensorFusionAnalyzer:
    """
    Kinematic analysis for fraud detection.
    Validates that device motion sensors correlate with GPS movement.
    """
    
    @staticmethod
    def analyze_motion_data(
        gps_speed_kmh: float,
        accelerometer_variance: float,
        gyroscope_variance: float = None
    ) -> Tuple[bool, str]:
        """
        Analyze sensor data for fraud indicators.
        
        Args:
            gps_speed_kmh: Speed reported by GPS in km/h
            accelerometer_variance: Variance in accelerometer readings
            gyroscope_variance: Optional gyroscope variance for enhanced detection
        
        Returns:
            Tuple of (is_valid, reason)
        """
        min_speed = SENSOR_FUSION_THRESHOLDS["MIN_SPEED_KMH"]
        max_variance = SENSOR_FUSION_THRESHOLDS["MAX_ACCELEROMETER_VARIANCE"]
        
        # Rule 4: Negative variance (impossible) - Check first
        if accelerometer_variance < 0:
            return False, "Invalid Sensor Data: Negative accelerometer variance"
        
        # Rule 3: Unrealistic speed (> 120 km/h for delivery vehicles)
        if gps_speed_kmh > 120.0:
            return False, (
                f"Unrealistic Speed: {gps_speed_kmh} km/h exceeds maximum "
                f"expected speed for delivery vehicles"
            )
        
        # Rule 1: High GPS speed with low accelerometer variance = GPS spoofing
        if gps_speed_kmh > min_speed and accelerometer_variance < max_variance:
            return False, (
                f"GPS Spoofing Detected: Speed {gps_speed_kmh} km/h but "
                f"accelerometer variance only {accelerometer_variance} "
                f"(expected > {max_variance} for genuine movement)"
            )
        
        # Rule 2: Zero speed with high accelerometer variance = Stationary vibration
        if gps_speed_kmh < 1.0 and accelerometer_variance > 2.0:
            return False, (
                f"Stationary Vibration Detected: GPS shows stationary but "
                f"accelerometer variance {accelerometer_variance} suggests artificial motion"
            )
        
        # Rule 5: Enhanced gyroscope check (if available)
        if gyroscope_variance is not None:
            if gps_speed_kmh > min_speed and gyroscope_variance < 0.3:
                return False, (
                    f"Gyroscope Anomaly: Speed {gps_speed_kmh} km/h but "
                    f"gyroscope variance {gyroscope_variance} too low"
                )
        
        return True, "Sensor data validated"
    
    @staticmethod
    def calculate_expected_variance(gps_speed_kmh: float) -> float:
        """
        Calculate expected accelerometer variance based on GPS speed.
        Used for anomaly detection thresholds.
        
        Args:
            gps_speed_kmh: GPS reported speed
        
        Returns:
            Expected minimum accelerometer variance
        """
        if gps_speed_kmh < 5:
            return 0.1  # Very low speed, minimal variance expected
        elif gps_speed_kmh < 20:
            return 0.5  # Low speed, moderate variance
        elif gps_speed_kmh < 50:
            return 1.0  # Medium speed, higher variance
        else:
            return 1.5  # High speed, significant variance
    
    @staticmethod
    def validate_sensor_consistency(sensor_data: Dict) -> Tuple[bool, str]:
        """
        Comprehensive sensor validation including timestamp checks.
        
        Args:
            sensor_data: Dictionary with keys:
                - gps_speed_kmh
                - accelerometer_variance
                - gyroscope_variance (optional)
                - timestamp_diff_ms (optional)
        
        Returns:
            Tuple of (is_valid, reason)
        """
        gps_speed = sensor_data.get("gps_speed_kmh", 0)
        accel_variance = sensor_data.get("accelerometer_variance", 0)
        gyro_variance = sensor_data.get("gyroscope_variance")
        timestamp_diff = sensor_data.get("timestamp_diff_ms")
        
        # Check timestamp staleness (if provided)
        if timestamp_diff is not None and timestamp_diff > 5000:  # 5 seconds
            return False, f"Stale Sensor Data: {timestamp_diff}ms old"
        
        # Primary motion analysis
        is_valid, reason = SensorFusionAnalyzer.analyze_motion_data(
            gps_speed, accel_variance, gyro_variance
        )
        
        if not is_valid:
            return is_valid, reason
        
        # Check expected variance correlation
        expected_variance = SensorFusionAnalyzer.calculate_expected_variance(gps_speed)
        if accel_variance < expected_variance * 0.5:  # 50% tolerance
            return False, (
                f"Variance Mismatch: Expected {expected_variance:.2f} for "
                f"speed {gps_speed} km/h, got {accel_variance:.2f}"
            )
        
        return True, "All sensor checks passed"
