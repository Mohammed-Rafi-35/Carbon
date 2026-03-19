import pytest
from app.services.sensor_svc import SensorFusionAnalyzer


class TestSensorFusionAnalyzer:
    def test_valid_motion_data(self):
        """Test valid GPS and accelerometer correlation"""
        is_valid, reason = SensorFusionAnalyzer.analyze_motion_data(
            gps_speed_kmh=25.0,
            accelerometer_variance=1.2
        )
        
        assert is_valid is True
        assert "validated" in reason.lower()
    
    def test_gps_spoofing_detection(self):
        """Test GPS spoofing: High speed with low accelerometer variance"""
        is_valid, reason = SensorFusionAnalyzer.analyze_motion_data(
            gps_speed_kmh=15.0,
            accelerometer_variance=0.3  # Too low for 15 km/h
        )
        
        assert is_valid is False
        assert "GPS Spoofing" in reason
        assert "15.0" in reason
        assert "0.3" in reason
    
    def test_exact_threshold_boundary(self):
        """Test exact threshold boundary (10 km/h, 0.5 variance)"""
        # Just above threshold - should fail
        is_valid, reason = SensorFusionAnalyzer.analyze_motion_data(
            gps_speed_kmh=10.1,
            accelerometer_variance=0.49
        )
        assert is_valid is False
        
        # Just below threshold - should pass
        is_valid, reason = SensorFusionAnalyzer.analyze_motion_data(
            gps_speed_kmh=9.9,
            accelerometer_variance=0.49
        )
        assert is_valid is True
    
    def test_stationary_vibration_detection(self):
        """Test stationary device with artificial vibration"""
        is_valid, reason = SensorFusionAnalyzer.analyze_motion_data(
            gps_speed_kmh=0.5,
            accelerometer_variance=2.5  # High variance while stationary
        )
        
        assert is_valid is False
        assert "Stationary Vibration" in reason
    
    def test_unrealistic_speed(self):
        """Test unrealistic speed for delivery vehicles"""
        is_valid, reason = SensorFusionAnalyzer.analyze_motion_data(
            gps_speed_kmh=150.0,
            accelerometer_variance=2.0
        )
        
        assert is_valid is False
        assert "Unrealistic Speed" in reason
        assert "150.0" in reason
    
    def test_negative_variance(self):
        """Test invalid negative accelerometer variance"""
        is_valid, reason = SensorFusionAnalyzer.analyze_motion_data(
            gps_speed_kmh=20.0,
            accelerometer_variance=-0.5
        )
        
        assert is_valid is False
        assert "Invalid Sensor Data" in reason
        assert "Negative" in reason
    
    def test_gyroscope_validation(self):
        """Test enhanced gyroscope validation"""
        is_valid, reason = SensorFusionAnalyzer.analyze_motion_data(
            gps_speed_kmh=30.0,
            accelerometer_variance=1.5,
            gyroscope_variance=0.2  # Too low for 30 km/h
        )
        
        assert is_valid is False
        assert "Gyroscope Anomaly" in reason
    
    def test_calculate_expected_variance(self):
        """Test expected variance calculation for different speeds"""
        # Very low speed
        variance = SensorFusionAnalyzer.calculate_expected_variance(3.0)
        assert variance == 0.1
        
        # Low speed
        variance = SensorFusionAnalyzer.calculate_expected_variance(15.0)
        assert variance == 0.5
        
        # Medium speed
        variance = SensorFusionAnalyzer.calculate_expected_variance(35.0)
        assert variance == 1.0
        
        # High speed
        variance = SensorFusionAnalyzer.calculate_expected_variance(60.0)
        assert variance == 1.5
    
    def test_validate_sensor_consistency_with_timestamp(self):
        """Test comprehensive sensor validation with timestamp"""
        sensor_data = {
            "gps_speed_kmh": 25.0,
            "accelerometer_variance": 1.2,
            "timestamp_diff_ms": 1000  # 1 second old
        }
        
        is_valid, reason = SensorFusionAnalyzer.validate_sensor_consistency(sensor_data)
        
        assert is_valid is True
        assert "passed" in reason.lower()
    
    def test_stale_sensor_data(self):
        """Test rejection of stale sensor data"""
        sensor_data = {
            "gps_speed_kmh": 25.0,
            "accelerometer_variance": 1.2,
            "timestamp_diff_ms": 6000  # 6 seconds old (> 5 second threshold)
        }
        
        is_valid, reason = SensorFusionAnalyzer.validate_sensor_consistency(sensor_data)
        
        assert is_valid is False
        assert "Stale Sensor Data" in reason
        assert "6000" in reason
    
    def test_variance_mismatch_detection(self):
        """Test detection of variance mismatch for given speed"""
        sensor_data = {
            "gps_speed_kmh": 50.0,  # High speed
            "accelerometer_variance": 0.3,  # Too low for 50 km/h
            "timestamp_diff_ms": 1000
        }
        
        is_valid, reason = SensorFusionAnalyzer.validate_sensor_consistency(sensor_data)
        
        assert is_valid is False
        assert "Variance Mismatch" in reason or "GPS Spoofing" in reason
    
    def test_low_speed_low_variance_valid(self):
        """Test that low speed with low variance is valid"""
        is_valid, reason = SensorFusionAnalyzer.analyze_motion_data(
            gps_speed_kmh=5.0,
            accelerometer_variance=0.2
        )
        
        assert is_valid is True
    
    def test_high_speed_high_variance_valid(self):
        """Test that high speed with high variance is valid"""
        is_valid, reason = SensorFusionAnalyzer.analyze_motion_data(
            gps_speed_kmh=60.0,
            accelerometer_variance=2.5
        )
        
        assert is_valid is True
    
    def test_edge_case_zero_speed(self):
        """Test zero speed with minimal variance"""
        is_valid, reason = SensorFusionAnalyzer.analyze_motion_data(
            gps_speed_kmh=0.0,
            accelerometer_variance=0.1
        )
        
        assert is_valid is True
    
    def test_multiple_sensor_failures(self):
        """Test scenario with multiple sensor anomalies"""
        sensor_data = {
            "gps_speed_kmh": 150.0,  # Unrealistic speed
            "accelerometer_variance": 0.2,  # Too low
            "gyroscope_variance": 0.1,  # Too low
            "timestamp_diff_ms": 7000  # Stale
        }
        
        is_valid, reason = SensorFusionAnalyzer.validate_sensor_consistency(sensor_data)
        
        assert is_valid is False
        # Should catch the first failure (stale data or unrealistic speed)
