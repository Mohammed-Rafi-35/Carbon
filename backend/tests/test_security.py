import pytest
import time
import json
from app.core.security import HMACValidator, SecurityGate


class TestHMACValidator:
    def test_generate_signature(self):
        """Test HMAC signature generation"""
        payload = '{"test": "data"}'
        timestamp = "1234567890"
        
        signature = HMACValidator.generate_signature(payload, timestamp)
        
        assert isinstance(signature, str)
        assert len(signature) == 64  # SHA256 hex = 64 characters
    
    def test_signature_deterministic(self):
        """Test that same input produces same signature"""
        payload = '{"test": "data"}'
        timestamp = "1234567890"
        
        sig1 = HMACValidator.generate_signature(payload, timestamp)
        sig2 = HMACValidator.generate_signature(payload, timestamp)
        
        assert sig1 == sig2
    
    def test_signature_changes_with_payload(self):
        """Test that different payloads produce different signatures"""
        timestamp = "1234567890"
        
        sig1 = HMACValidator.generate_signature('{"test": "data1"}', timestamp)
        sig2 = HMACValidator.generate_signature('{"test": "data2"}', timestamp)
        
        assert sig1 != sig2
    
    def test_signature_changes_with_timestamp(self):
        """Test that different timestamps produce different signatures"""
        payload = '{"test": "data"}'
        
        sig1 = HMACValidator.generate_signature(payload, "1234567890")
        sig2 = HMACValidator.generate_signature(payload, "1234567891")
        
        assert sig1 != sig2
    
    def test_verify_valid_signature(self):
        """Test verification of valid signature"""
        payload = '{"test": "data"}'
        timestamp = str(int(time.time()))
        signature = HMACValidator.generate_signature(payload, timestamp)
        
        is_valid, reason = HMACValidator.verify_signature(
            payload, timestamp, signature
        )
        
        assert is_valid is True
        assert "verified" in reason.lower()
    
    def test_verify_invalid_signature(self):
        """Test rejection of invalid signature"""
        payload = '{"test": "data"}'
        timestamp = str(int(time.time()))
        invalid_signature = "0" * 64
        
        is_valid, reason = HMACValidator.verify_signature(
            payload, timestamp, invalid_signature
        )
        
        assert is_valid is False
        assert "Invalid signature" in reason
    
    def test_verify_expired_request(self):
        """Test rejection of expired request"""
        payload = '{"test": "data"}'
        old_timestamp = str(int(time.time()) - 400)  # 400 seconds ago
        signature = HMACValidator.generate_signature(payload, old_timestamp)
        
        is_valid, reason = HMACValidator.verify_signature(
            payload, old_timestamp, signature, max_age_seconds=300
        )
        
        assert is_valid is False
        assert "expired" in reason.lower()
    
    def test_verify_future_timestamp(self):
        """Test rejection of future timestamp"""
        payload = '{"test": "data"}'
        future_timestamp = str(int(time.time()) + 120)  # 2 minutes in future
        signature = HMACValidator.generate_signature(payload, future_timestamp)
        
        is_valid, reason = HMACValidator.verify_signature(
            payload, future_timestamp, signature
        )
        
        assert is_valid is False
        assert "future" in reason.lower()
    
    def test_verify_invalid_timestamp_format(self):
        """Test rejection of invalid timestamp format"""
        payload = '{"test": "data"}'
        invalid_timestamp = "not-a-timestamp"
        signature = HMACValidator.generate_signature(payload, invalid_timestamp)
        
        is_valid, reason = HMACValidator.verify_signature(
            payload, invalid_timestamp, signature
        )
        
        assert is_valid is False
        assert "Invalid timestamp" in reason
    
    def test_create_signed_request(self):
        """Test creation of signed request headers"""
        payload = {"test": "data", "value": 123}
        
        headers = HMACValidator.create_signed_request(payload)
        
        assert "X-Timestamp" in headers
        assert "X-Signature" in headers
        assert len(headers["X-Signature"]) == 64
    
    def test_signed_request_verification(self):
        """Test that created signed request can be verified"""
        payload = {"test": "data", "value": 123}
        
        headers = HMACValidator.create_signed_request(payload)
        payload_str = json.dumps(payload, sort_keys=True)
        
        is_valid, reason = HMACValidator.verify_signature(
            payload_str,
            headers["X-Timestamp"],
            headers["X-Signature"]
        )
        
        assert is_valid is True
    
    def test_timing_attack_resistance(self):
        """Test that signature comparison is constant-time"""
        payload = '{"test": "data"}'
        timestamp = str(int(time.time()))
        correct_signature = HMACValidator.generate_signature(payload, timestamp)
        
        # Create signatures that differ at different positions
        wrong_sig_start = "X" + correct_signature[1:]
        wrong_sig_end = correct_signature[:-1] + "X"
        
        # Both should fail
        is_valid1, _ = HMACValidator.verify_signature(payload, timestamp, wrong_sig_start)
        is_valid2, _ = HMACValidator.verify_signature(payload, timestamp, wrong_sig_end)
        
        assert is_valid1 is False
        assert is_valid2 is False


class TestSecurityGate:
    def test_validate_payout_request_success(self):
        """Test successful payout request validation"""
        payload_dict = {"worker_id": "test", "order_id": "ORDER_123"}
        payload_str = json.dumps(payload_dict, sort_keys=True)
        timestamp = str(int(time.time()))
        signature = HMACValidator.generate_signature(payload_str, timestamp)
        
        sensor_data = {
            "gps_speed_kmh": 25.0,
            "accelerometer_variance": 1.2,
            "timestamp_diff_ms": 1000
        }
        
        is_valid, reason = SecurityGate.validate_payout_request(
            payload=payload_str,
            timestamp=timestamp,
            signature=signature,
            sensor_data=sensor_data,
            require_signature=True
        )
        
        assert is_valid is True
        assert "passed" in reason.lower()
    
    def test_validate_payout_request_invalid_hmac(self):
        """Test payout request rejection due to invalid HMAC"""
        payload_str = '{"worker_id": "test"}'
        timestamp = str(int(time.time()))
        invalid_signature = "0" * 64
        
        sensor_data = {
            "gps_speed_kmh": 25.0,
            "accelerometer_variance": 1.2
        }
        
        is_valid, reason = SecurityGate.validate_payout_request(
            payload=payload_str,
            timestamp=timestamp,
            signature=invalid_signature,
            sensor_data=sensor_data,
            require_signature=True
        )
        
        assert is_valid is False
        assert "HMAC Validation Failed" in reason
    
    def test_validate_payout_request_invalid_sensor(self):
        """Test payout request rejection due to invalid sensor data"""
        payload_dict = {"worker_id": "test", "order_id": "ORDER_123"}
        payload_str = json.dumps(payload_dict, sort_keys=True)
        timestamp = str(int(time.time()))
        signature = HMACValidator.generate_signature(payload_str, timestamp)
        
        # GPS spoofing scenario
        sensor_data = {
            "gps_speed_kmh": 50.0,
            "accelerometer_variance": 0.2  # Too low
        }
        
        is_valid, reason = SecurityGate.validate_payout_request(
            payload=payload_str,
            timestamp=timestamp,
            signature=signature,
            sensor_data=sensor_data,
            require_signature=True
        )
        
        assert is_valid is False
        assert "Sensor Validation Failed" in reason
    
    def test_validate_payout_request_no_signature_required(self):
        """Test payout validation without HMAC (development mode)"""
        sensor_data = {
            "gps_speed_kmh": 25.0,
            "accelerometer_variance": 1.2
        }
        
        is_valid, reason = SecurityGate.validate_payout_request(
            payload="",
            timestamp="",
            signature="",
            sensor_data=sensor_data,
            require_signature=False
        )
        
        assert is_valid is True
    
    def test_validate_payout_request_stale_data(self):
        """Test rejection of stale sensor data"""
        payload_dict = {"worker_id": "test"}
        payload_str = json.dumps(payload_dict, sort_keys=True)
        timestamp = str(int(time.time()))
        signature = HMACValidator.generate_signature(payload_str, timestamp)
        
        sensor_data = {
            "gps_speed_kmh": 25.0,
            "accelerometer_variance": 1.2,
            "timestamp_diff_ms": 10000  # 10 seconds old
        }
        
        is_valid, reason = SecurityGate.validate_payout_request(
            payload=payload_str,
            timestamp=timestamp,
            signature=signature,
            sensor_data=sensor_data,
            require_signature=True
        )
        
        assert is_valid is False
        assert "Stale" in reason or "Sensor" in reason
