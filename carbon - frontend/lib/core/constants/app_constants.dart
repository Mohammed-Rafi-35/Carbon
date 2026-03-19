/// App-wide constants
class AppConstants {
  // App Info
  static const String appName = 'Carbon';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Parametric Insurance for Delivery Workers';
  
  // Validation
  static const int phoneNumberLength = 10;
  static const double maxSpeedKmh = 120.0;
  static const double minVarianceIfMoving = 0.1;
  static const double movingSpeedThreshold = 10.0;
  
  // Sensor Collection
  static const int accelerometerSamplingDuration = 3; // seconds
  static const int accelerometerSamplingFrequency = 50; // Hz
  static const int targetSamples = 150; // 3 seconds * 50 Hz
  
  // Weather Thresholds (default values)
  static const double defaultRainThreshold = 5.0; // mm
  static const double defaultWindThreshold = 30.0; // km/h
  static const double defaultTempThreshold = 35.0; // °C
  
  // UI
  static const double defaultPadding = 20.0;
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 2.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);
  static const Duration celebrationDuration = Duration(seconds: 3);
  
  // Timeouts
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration errorSnackbarDuration = Duration(seconds: 4);
  
  // Zones
  static const List<String> zones = [
    'North',
    'South',
    'East',
    'West',
    'Central',
  ];
  
  // Vehicle Types
  static const List<String> vehicleTypes = [
    'bike',
    'scooter',
    'bicycle',
  ];
  
  // Status
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusPending = 'pending';
  static const String statusActive = 'active';
  
  // Error Messages
  static const String errorNoInternet = 'No internet connection. Please check your network.';
  static const String errorTimeout = 'Connection timeout. Please try again.';
  static const String errorServerError = 'Server error. Please try again later.';
  static const String errorUnknown = 'Something went wrong. Please try again.';
  static const String errorLocationPermission = 'Location permission denied. Please enable it in settings.';
  static const String errorLocationDisabled = 'Location services are disabled. Please enable them.';
  static const String errorSensorCollection = 'Failed to collect sensor data. Please try again.';
  
  // Success Messages
  static const String successOrderCreated = 'Order received successfully!';
  static const String successPayoutApproved = 'Payout approved! Amount credited to your wallet.';
  static const String successLogout = 'Logged out successfully';
  
  // Empty State Messages
  static const String emptyOrders = 'No active orders';
  static const String emptyHistory = 'No transactions yet';
  static const String emptyHistoryDescription = 'Your transaction history will appear here once you claim protection.';
}
