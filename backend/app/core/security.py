"""
Security Module
HMAC request signing and verification for API authentication.
"""
import hmac
import hashlib
import time
from typing import Optional, Tuple
from app.core.config import settings


class HMACValidator:
    """
    HMAC-SHA256 request signature validation.
    Prevents replay attacks and ensures request integrity.
    """
    
    @staticmethod
    def generate_signature(payload: str, timestamp: str) -> str:
        """
        Generate HMAC-SHA256 signature for request payload.
        
        Args:
            payload: JSON string of request body
            timestamp: Unix timestamp string
        
        Returns:
            Hex-encoded HMAC signature
        """
        message = f"{payload}:{timestamp}"
        signature = hmac.new(
            settings.SECRET_KEY.encode(),
            message.encode(),
            hashlib.sha256
        ).hexdigest()
        return signature
    
    @staticmethod
    def verify_signature(
        payload: str,
        timestamp: str,
        provided_signature: str,
        max_age_seconds: int = 300
    ) -> Tuple[bool, str]:
        """
        Verify HMAC signature and check timestamp freshness.
        
        Args:
            payload: JSON string of request body
            timestamp: Unix timestamp string from request
            provided_signature: Signature from X-Signature header
            max_age_seconds: Maximum allowed age of request (default 5 minutes)
        
        Returns:
            Tuple of (is_valid, reason)
        """
        # Check timestamp freshness (prevent replay attacks)
        try:
            request_time = int(timestamp)
            current_time = int(time.time())
            age = current_time - request_time
            
            if age > max_age_seconds:
                return False, f"Request expired: {age}s old (max {max_age_seconds}s)"
            
            if age < -60:  # Clock skew tolerance: 1 minute
                return False, "Request timestamp is in the future"
        
        except ValueError:
            return False, "Invalid timestamp format"
        
        # Generate expected signature
        expected_signature = HMACValidator.generate_signature(payload, timestamp)
        
        # Constant-time comparison to prevent timing attacks
        if not hmac.compare_digest(expected_signature, provided_signature):
            return False, "Invalid signature"
        
        return True, "Signature verified"
    
    @staticmethod
    def create_signed_request(payload: dict) -> dict:
        """
        Create a signed request with timestamp and signature headers.
        Used for testing and client SDK.
        
        Args:
            payload: Request body dictionary
        
        Returns:
            Dictionary with headers: X-Timestamp, X-Signature
        """
        import json
        timestamp = str(int(time.time()))
        payload_str = json.dumps(payload, sort_keys=True)
        signature = HMACValidator.generate_signature(payload_str, timestamp)
        
        return {
            "X-Timestamp": timestamp,
            "X-Signature": signature
        }


class SecurityGate:
    """
    Combined security validation gate.
    Checks both HMAC signature and sensor fusion data.
    """
    
    @staticmethod
    def validate_payout_request(
        payload: str,
        timestamp: str,
        signature: str,
        sensor_data: dict,
        require_signature: bool = True
    ) -> Tuple[bool, str]:
        """
        Comprehensive security validation for payout requests.
        
        Args:
            payload: JSON request body
            timestamp: Request timestamp
            signature: HMAC signature
            sensor_data: Sensor fusion data
            require_signature: Whether to enforce HMAC (disable for testing)
        
        Returns:
            Tuple of (is_valid, reason)
        """
        from app.services.sensor_svc import SensorFusionAnalyzer
        
        # Step 1: HMAC Validation
        if require_signature:
            is_valid, reason = HMACValidator.verify_signature(
                payload, timestamp, signature
            )
            if not is_valid:
                return False, f"HMAC Validation Failed: {reason}"
        
        # Step 2: Sensor Fusion Validation
        is_valid, reason = SensorFusionAnalyzer.validate_sensor_consistency(
            sensor_data
        )
        if not is_valid:
            return False, f"Sensor Validation Failed: {reason}"
        
        return True, "Security validation passed"
