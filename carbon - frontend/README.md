# CARBON FLUTTER APPLICATION - PHASE 4

## ✅ IMPLEMENTATION STATUS

### Completed Components (Core Foundation)
- ✅ **Dependencies**: All packages added to pubspec.yaml
- ✅ **Theme System**: High-contrast CarbonTheme for outdoor visibility
- ✅ **API Configuration**: Centralized endpoint management
- ✅ **Data Models**: Worker, Weather, Payout models
- ✅ **Network Layer**: API Client with Dio
- ✅ **HMAC Utility**: Request signing implementation
- ✅ **Main App**: Entry point with theme
- ✅ **Splash Screen**: Animated branding screen
- ✅ **Home Screen**: Dashboard with metrics
- ✅ **Reusable Widgets**: MetricCard, StatusBadge

### File Structure Created
```
lib/
├── config/
│   └── api_config.dart ✅
├── core/
│   ├── network/
│   │   └── api_client.dart ✅
│   ├── theme/
│   │   └── app_theme.dart ✅
│   └── utils/
│       └── hmac_util.dart ✅
├── data/
│   ├── models/
│   │   ├── worker.dart ✅
│   │   ├── weather.dart ✅
│   │   └── payout.dart ✅
│   ├── providers/ (empty - ready for implementation)
│   └── repositories/ (empty - ready for implementation)
├── logic/ (empty - ready for BLoC implementation)
├── presentation/
│   ├── screens/
│   │   ├── splash_screen.dart ✅
│   │   └── home/
│   │       └── home_screen.dart ✅
│   └── widgets/
│       ├── metric_card.dart ✅
│       └── status_badge.dart ✅
└── main.dart ✅
```

## 🚀 QUICK START

### 1. Install Dependencies
```bash
cd "carbon - frontend"
flutter pub get
```

### 2. Run Application
```bash
flutter run
```

### 3. Build APK
```bash
flutter build apk --release
```

## 📱 CURRENT FUNCTIONALITY

### Working Features
1. **Splash Screen**
   - Animated Carbon logo
   - Auto-navigation to Home (3 seconds)
   - Fade and scale animations

2. **Home Screen**
   - Wallet balance display (demo data)
   - Weekly rides counter (demo data)
   - Protection status badge
   - Pull-to-refresh gesture
   - Quick action buttons (placeholders)

3. **Theme System**
   - Dark theme optimized for outdoor use
   - High-contrast colors
   - Consistent typography (Google Fonts Inter)
   - Material 3 design

### Demo Data
- Wallet Balance: ₹5,420.50
- Weekly Rides: 47
- Policy Status: Active

## 🔧 CONFIGURATION

### API Endpoints (api_config.dart)
```dart
static const String baseUrl = 'http://127.0.0.1:8000';
```

**Change this to your backend URL:**
- Local: `http://127.0.0.1:8000`
- Production: `https://your-backend.com`

### HMAC Secret Key
```dart
static const String hmacSecretKey = 'test-secret-key-for-testing-only';
```

**Must match backend SECRET_KEY**

## 📋 NEXT IMPLEMENTATION STEPS

### Priority 1: Data Layer (1-2 days)
1. **Create Providers** (`lib/data/providers/`)
   - `worker_provider.dart` - API calls for worker endpoints
   - `order_provider.dart` - API calls for order endpoints
   - `payout_provider.dart` - API calls for payout endpoints

2. **Create Repositories** (`lib/data/repositories/`)
   - `worker_repository.dart` - Business logic for worker data
   - `order_repository.dart` - Business logic for orders
   - `payout_repository.dart` - Business logic for payouts

### Priority 2: State Management (1-2 days)
3. **Implement BLoC** (`lib/logic/`)
   - `auth/auth_bloc.dart` - Authentication state
   - `worker/worker_bloc.dart` - Worker data state
   - `payout/payout_bloc.dart` - Payout state

4. **Add Secure Storage**
   - Store worker_id
   - Auto-login functionality

### Priority 3: Sensor Integration (1 day)
5. **Create Sensor Services** (`lib/core/services/`)
   - `sensor_service.dart` - Accelerometer data collection
   - `location_service.dart` - GPS speed tracking
   - Request permissions

### Priority 4: Complete UI (2-3 days)
6. **Auth Screens**
   - Login screen
   - Register screen

7. **Payout Screen**
   - Weather display
   - Sensor data collection
   - Claim button
   - Success/failure feedback

8. **History Screen**
   - Transaction list
   - Payout details

## 🎨 THEME COLORS

### Primary Colors
- **Primary Green**: `#00C853` - Success, active states
- **Primary Dark**: `#1A1A1A` - Text on green
- **Primary White**: `#FFFFFF` - Primary text

### Background Colors
- **Background Dark**: `#121212` - Main background
- **Background Card**: `#1E1E1E` - Card background
- **Background Light**: `#2C2C2C` - Input fields

### Accent Colors
- **Orange**: `#FF6D00` - Warnings
- **Blue**: `#2196F3` - Info
- **Red**: `#D32F2F` - Errors

### Text Colors
- **Primary**: `#FFFFFF` - Main text
- **Secondary**: `#B0B0B0` - Labels
- **Disabled**: `#757575` - Disabled text

## 📐 DESIGN SPECIFICATIONS

### Typography (Inter Font)
- Display Large: 32px Bold
- Display Medium: 28px Bold
- Headline: 20px SemiBold
- Title: 18px SemiBold
- Body: 16px Regular
- Label: 14px Medium

### Spacing
- Screen Padding: 20px
- Card Padding: 16-20px
- Element Spacing: 8-16px
- Section Spacing: 24-32px

### Border Radius
- Buttons: 12px
- Cards: 16px
- Input Fields: 12px

### Elevation
- Cards: 4dp
- Buttons: 2dp

## 🔐 SECURITY IMPLEMENTATION

### HMAC Signature (Already Implemented)
```dart
// In hmac_util.dart
String generateSignature(String payload, String timestamp) {
  final message = '$payload:$timestamp';
  final key = utf8.encode(ApiConfig.hmacSecretKey);
  final bytes = utf8.encode(message);
  final hmacSha256 = Hmac(sha256, key);
  final digest = hmacSha256.convert(bytes);
  return digest.toString();
}
```

### Usage Example
```dart
final headers = HmacUtil.createSignedHeaders(jsonEncode(payload));
// Returns: {'X-Timestamp': '...', 'X-Signature': '...'}
```

## 📱 SCREEN FLOW

```
Splash Screen (3s)
    ↓
Home Screen
    ├─ Claim Protection → Payout Screen
    ├─ Transaction History → History Screen
    └─ Profile → Profile Screen
```

## 🧪 TESTING

### Run Tests
```bash
flutter test
```

### Test on Device
```bash
flutter run --release
```

### Check for Issues
```bash
flutter analyze
```

## 📦 DEPENDENCIES

### State Management
- `flutter_bloc: ^8.1.3`
- `hydrated_bloc: ^9.1.2`
- `equatable: ^2.0.5`

### Network
- `dio: ^5.4.0`
- `pretty_dio_logger: ^1.3.1`

### Storage
- `flutter_secure_storage: ^9.0.0`
- `path_provider: ^2.1.1`

### Sensors
- `geolocator: ^10.1.0`
- `sensors_plus: ^4.0.2`
- `permission_handler: ^11.1.0`

### UI
- `google_fonts: ^6.1.0`
- `flutter_svg: ^2.0.9`
- `lottie: ^3.0.0`
- `shimmer: ^3.0.0`

### Utils
- `intl: ^0.19.0`
- `crypto: ^3.0.3`
- `uuid: ^4.3.3`

## 🐛 TROUBLESHOOTING

### Issue: Dependencies not installing
```bash
flutter clean
flutter pub get
```

### Issue: Build errors
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: Theme not applying
- Check `main.dart` has `theme: CarbonTheme.darkTheme`
- Restart app completely

### Issue: API not connecting
- Check `api_config.dart` baseUrl
- Ensure backend is running
- Check network permissions in AndroidManifest.xml

## 📝 IMPLEMENTATION CHECKLIST

### Core (Completed ✅)
- [x] Dependencies added
- [x] Theme system created
- [x] API configuration
- [x] Data models
- [x] Network client
- [x] HMAC utility
- [x] Main app structure
- [x] Splash screen
- [x] Home screen
- [x] Reusable widgets

### Data Layer (Pending)
- [ ] Worker provider
- [ ] Order provider
- [ ] Payout provider
- [ ] Worker repository
- [ ] Order repository
- [ ] Payout repository

### State Management (Pending)
- [ ] Auth BLoC
- [ ] Worker BLoC
- [ ] Payout BLoC
- [ ] Secure storage integration

### Sensors (Pending)
- [ ] Location service
- [ ] Sensor service
- [ ] Permission handling

### UI Screens (Pending)
- [ ] Login screen
- [ ] Register screen
- [ ] Payout screen
- [ ] History screen
- [ ] Profile screen

### Testing (Pending)
- [ ] Unit tests
- [ ] Widget tests
- [ ] Integration tests

## 🎯 EXPECTED TIMELINE

- **Day 1**: Data layer (providers, repositories)
- **Day 2**: State management (BLoC, storage)
- **Day 3**: Sensor integration
- **Day 4**: Complete UI screens
- **Day 5**: Testing and polish

## 📞 SUPPORT

For implementation questions, refer to:
- `PHASE4_IMPLEMENTATION_GUIDE.md` - Detailed implementation steps
- `frontend_architecture.md` - Architecture specification
- Backend API docs: `http://127.0.0.1:8000/docs`

---

**Status**: Phase 4 Foundation Complete ✅
**Next**: Implement Data Layer (Providers & Repositories)
**Current Version**: 1.0.0
