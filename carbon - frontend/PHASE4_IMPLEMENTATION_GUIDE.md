# PHASE 4 IMPLEMENTATION GUIDE - FLUTTER APPLICATION

## ✅ COMPLETED FILES

### 1. Configuration & Theme
- ✅ `pubspec.yaml` - All dependencies added
- ✅ `lib/config/api_config.dart` - Centralized API endpoints
- ✅ `lib/core/theme/app_theme.dart` - High-contrast theme system

### 2. Data Models
- ✅ `lib/data/models/worker.dart` - Worker model with JSON serialization
- ✅ `lib/data/models/weather.dart` - Weather model
- ✅ `lib/data/models/payout.dart` - Payout & SensorData models

## 📋 REMAINING FILES TO CREATE

### 3. Network Layer (Priority: HIGH)

**File: `lib/core/network/api_client.dart`**
```dart
// Dio client with HMAC interceptor
// - Add X-Timestamp header
// - Generate HMAC-SHA256 signature
// - Add X-Signature header
// - Handle errors globally
```

**File: `lib/core/network/hmac_interceptor.dart`**
```dart
// HMAC signature generation
// - Use crypto package
// - Match backend SECRET_KEY
// - Sign payload + timestamp
```

### 4. Data Providers (Priority: HIGH)

**File: `lib/data/providers/worker_provider.dart`**
```dart
// API calls:
// - POST /workers/register
// - GET /workers/{id}
// - GET /workers/phone/{phone}
```

**File: `lib/data/providers/order_provider.dart`**
```dart
// API calls:
// - POST /orders/receive
// - GET /orders/weather/{order_id}
```

**File: `lib/data/providers/payout_provider.dart`**
```dart
// API calls:
// - POST /payout/trigger (with HMAC)
// - GET /payout/history/{worker_id}
```

### 5. Repositories (Priority: HIGH)

**File: `lib/data/repositories/worker_repository.dart`**
```dart
// Business logic layer
// - Handle API responses
// - Error handling
// - Data transformation
```

### 6. BLoC State Management (Priority: HIGH)

**File: `lib/logic/auth/auth_bloc.dart`**
```dart
// States: Initial, Loading, Authenticated, Unauthenticated, Error
// Events: LoginRequested, RegisterRequested, LogoutRequested
// - Store worker_id in secure storage
// - Auto-login on app start
```

**File: `lib/logic/worker/worker_bloc.dart`**
```dart
// States: Initial, Loading, Loaded, Error
// Events: LoadWorker, RefreshWorker, UpdateWallet
// - Fetch worker data
// - Update wallet balance
// - Track rides
```

**File: `lib/logic/payout/payout_bloc.dart`**
```dart
// States: Initial, Loading, Success, Failed
// Events: TriggerPayout, LoadHistory
// - Collect sensor data
// - Trigger payout with HMAC
// - Show success/failure
```

### 7. Sensor Services (Priority: HIGH)

**File: `lib/core/services/sensor_service.dart`**
```dart
// Sensor data collection:
// - GPS speed from geolocator
// - Accelerometer variance from sensors_plus
// - Sample for 3 seconds at 50Hz
// - Calculate variance
```

**File: `lib/core/services/location_service.dart`**
```dart
// Location tracking:
// - Request permissions
// - Get current position
// - Calculate speed
// - Background tracking
```

### 8. Presentation Screens (Priority: MEDIUM)

**File: `lib/presentation/screens/splash_screen.dart`**
```dart
// - Check secure storage for worker_id
// - Auto-navigate to Home if logged in
// - Navigate to Auth if not logged in
```

**File: `lib/presentation/screens/auth/login_screen.dart`**
```dart
// - Phone input field
// - Login button
// - Navigate to Register
// - Call GET /workers/phone/{phone}
```

**File: `lib/presentation/screens/auth/register_screen.dart`**
```dart
// - Phone, zone, vehicle type inputs
// - Projected income input
// - Register button
// - Call POST /workers/register
```

**File: `lib/presentation/screens/home/home_screen.dart`**
```dart
// Live Radar Dashboard:
// - Wallet balance card
// - Weekly rides card
// - Shield status indicator
// - Pull-to-refresh
// - Navigate to payout/history
```

**File: `lib/presentation/screens/payout/payout_screen.dart`**
```dart
// Payout Trigger:
// - Weather display
// - Sensor data collection
// - Claim Protection button
// - Security checks display
// - Success animation
```

**File: `lib/presentation/screens/history/history_screen.dart`**
```dart
// Transaction History:
// - List of payouts
// - Amount, reason, timestamp
// - Pull-to-refresh
```

### 9. Reusable Widgets (Priority: MEDIUM)

**File: `lib/presentation/widgets/metric_card.dart`**
```dart
// High-visibility metric display
// - Large value text
// - Label text
// - Icon
// - Color customization
```

**File: `lib/presentation/widgets/status_badge.dart`**
```dart
// Shield status indicator
// - Active (green)
// - Inactive (gray)
// - Animated
```

**File: `lib/presentation/widgets/weather_card.dart`**
```dart
// Weather display
// - Temperature, rain, wind
// - Threshold indicator
// - Color-coded
```

**File: `lib/presentation/widgets/loading_overlay.dart`**
```dart
// Full-screen loading
// - Shimmer effect
// - Transparent background
```

### 10. Utilities (Priority: LOW)

**File: `lib/core/utils/formatters.dart`**
```dart
// - Currency formatter (₹)
// - Date/time formatter
// - Phone number formatter
```

**File: `lib/core/utils/validators.dart`**
```dart
// - Phone validation
// - Zone validation
// - Input validation
```

**File: `lib/core/constants/app_constants.dart`**
```dart
// - Vehicle types
// - Zones
// - Error messages
```

## 🚀 IMPLEMENTATION PRIORITY

### Phase 4A: Core Infrastructure (Day 1)
1. ✅ Dependencies & Theme
2. ✅ Models
3. Network Layer (API Client + HMAC)
4. Data Providers
5. Repositories

### Phase 4B: State Management (Day 2)
6. Auth BLoC
7. Worker BLoC
8. Payout BLoC
9. Sensor Services

### Phase 4C: UI Implementation (Day 3)
10. Splash Screen
11. Auth Screens (Login/Register)
12. Home Screen (Dashboard)
13. Payout Screen
14. History Screen

### Phase 4D: Polish & Testing (Day 4)
15. Reusable Widgets
16. Error Handling
17. Loading States
18. Animations
19. Testing

## 📝 QUICK START COMMANDS

### Install Dependencies
```bash
cd "carbon - frontend"
flutter pub get
```

### Run App
```bash
flutter run
```

### Build APK
```bash
flutter build apk --release
```

## 🔧 CONFIGURATION CHECKLIST

- [ ] Update `api_config.dart` with production URL
- [ ] Update HMAC secret key to match backend
- [ ] Add app icons
- [ ] Add splash screen assets
- [ ] Configure Android permissions (location, sensors)
- [ ] Configure iOS permissions (location, sensors)
- [ ] Test on physical device (sensors required)

## 📱 SCREEN FLOW

```
Splash Screen
    ↓
[Has worker_id?]
    ├─ Yes → Home Screen
    └─ No → Login Screen
              ↓
         [New User?]
              ├─ Yes → Register Screen → Home Screen
              └─ No → Home Screen

Home Screen
    ├─ Payout Button → Payout Screen → Success/Failure
    ├─ History Button → History Screen
    └─ Logout → Login Screen
```

## 🎨 UI GUIDELINES

### Colors (from CarbonTheme)
- Primary: #00C853 (Bright Green)
- Background: #121212 (Dark)
- Cards: #1E1E1E
- Text: #FFFFFF (Primary), #B0B0B0 (Secondary)
- Error: #D32F2F
- Warning: #FF6D00

### Typography (Google Fonts Inter)
- Display: 32px Bold
- Headline: 20px SemiBold
- Body: 16px Regular
- Metric Value: 36px Bold Green
- Metric Label: 14px Medium Gray

### Spacing
- Card Padding: 16px
- Screen Padding: 20px
- Button Height: 56px
- Border Radius: 12px (buttons), 16px (cards)

## 🔐 SECURITY IMPLEMENTATION

### HMAC Signature Generation
```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

String generateHmacSignature(String payload, String timestamp) {
  final message = '$payload:$timestamp';
  final key = utf8.encode(ApiConfig.hmacSecretKey);
  final bytes = utf8.encode(message);
  final hmac = Hmac(sha256, key);
  final digest = hmac.convert(bytes);
  return digest.toString();
}
```

### Sensor Data Collection
```dart
// Collect accelerometer data for 3 seconds
List<double> samples = [];
Timer.periodic(Duration(milliseconds: 20), (timer) {
  // Sample at 50Hz
  accelerometerEvents.listen((event) {
    double magnitude = sqrt(
      event.x * event.x + 
      event.y * event.y + 
      event.z * event.z
    );
    samples.add(magnitude);
  });
  
  if (samples.length >= 150) { // 3 seconds * 50Hz
    timer.cancel();
    double variance = calculateVariance(samples);
  }
});
```

## ✅ TESTING CHECKLIST

- [ ] Login with existing phone
- [ ] Register new worker
- [ ] View wallet balance
- [ ] Trigger payout (with weather threshold met)
- [ ] View payout history
- [ ] Sensor data collection works
- [ ] HMAC signature generated correctly
- [ ] Error handling works
- [ ] Loading states display
- [ ] Pull-to-refresh works
- [ ] Logout works
- [ ] Auto-login works

## 📊 EXPECTED BEHAVIOR

### Successful Payout Flow
1. User opens app → Auto-login to Home
2. User accepts order → Weather synthesized
3. Weather meets threshold → "Claim Protection" enabled
4. User clicks button → Sensors collect data (3s)
5. App generates HMAC → POST /payout/trigger
6. Backend validates → Payout approved
7. Success animation → Wallet balance updates
8. Transaction appears in history

### Failed Payout Scenarios
- GPS spoofing detected → Error message
- Weather threshold not met → Button disabled
- Duplicate payout → Error message
- No active policy → Error message
- Network error → Retry option

---

**Status**: Phase 4 Core Files Created ✅
**Next**: Implement Network Layer & BLoC
**Estimated Time**: 2-3 days for complete implementation
