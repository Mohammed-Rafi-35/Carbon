# CARBON MOBILE APPLICATION: UPDATED FRONTEND SPECIFICATION (V2.0)

This document provides the synchronized technical specification for the **Carbon Flutter Application**, aligned with the production-grade **FastAPI Backend** architecture. The application serves as a high-performance, sensor-integrated client for delivery workers in the gig economy.

## 1. CORE ARCHITECTURE & STATE MANAGEMENT

To ensure "Ultimate State Management" and performance, Carbon utilizes the **BLoC (Business Logic Component)** pattern with **HydratedBLoC** for persistent state across app restarts.

- **Persistence Layer**: `flutter_secure_storage` is used to store the `worker_id` and `auth_token`. Upon app launch, a `SplashGuard` checks for the presence of a stored ID; if found, the user is automatically navigated to the Home Screen.
- **Network Layer**: A centralized `ApiClient` using the `dio` package implements a custom `InterceptorsWrapper`. This interceptor automatically injects the **HMAC-SHA256** signature and `X-Timestamp` into every payout request header to satisfy the backend's security requirements.
- **Data Synchronization**: The app uses a "Pull-to-Refresh" and "Auto-Sync" strategy. When the app returns to the foreground, it pings `GET /api/v1/workers/{worker_id}` to refresh the wallet balance and ride statistics.

## 2. SCREEN-BY-SCREEN FUNCTIONAL SPECIFICATION

### 2.1 Onboarding & Authentication (Login/Signup)
- **Responsibility**: Authenticate users via phone number and establish the permanent worker profile.
- **UI Flow**: 
    - **Signup**: Captures phone, zone, and vehicle type. Calls `POST /api/v1/workers/register`.
    - **Login**: Captures phone. Calls `GET /api/v1/workers/phone/{phone}`. If the worker exists, the `worker_id` is persisted.
- **Backend Sync**: Upon successful registration or login, the app stores the returned Worker JSON in the local BLoC state to minimize redundant API calls.

### 2.2 Live Radar Dashboard (Home)
- **Responsibility**: Display real-time coverage status and current financial health.
- [cite_start]**UI Flow**: High-visibility metric cards show the `wallet_balance` and `weekly_rides_completed`[cite: 480]. A "Shield Status" indicator turns green if a policy is `is_active = true`.
- **Backend Sync**: Streams data from `GET /api/v1/workers/{id}`. If the wallet balance increases due to an automated payout, the UI triggers a celebratory overlay.

### 3.3 Active Order & Weather Synthesis
- **Responsibility**: Process incoming delivery orders and display parametric weather risks.
- **UI Flow**: When an order is accepted, the app captures the current GPS coordinates and calls `POST /api/v1/orders/receive`. 
- **Display**: The UI renders the synthesized weather data (Rain, Wind, Temp). If `meets_threshold` is true, the UI displays the `threshold_reason` (e.g., "Heavy Rain Detected").
- **System Design**: Uses **Lazy Loading**; weather details are only fetched via `GET /api/v1/orders/weather/{order_id}` if the user expands the order card.

### 3.4 Payout Trigger & Sensor Fusion
- **Responsibility**: Validate physical movement and initiate the income protection payout.
- **UI Flow**: A "Claim Protection" button becomes active only when weather thresholds are met. 
- [cite_start]**Sensor Collection**: The app utilizes `geolocator` for `gps_speed_kmh` and `sensors_plus` to calculate `accelerometer_variance` over a 3-second window[cite: 467, 504].
- **Backend Sync**: Calls `POST /api/v1/payout/trigger`. The request payload includes the sensor fusion data and is signed with an HMAC signature.
- **Security Check**: The app performs a local "Sanity Check" (e.g., ensuring speed isn't $>120$ km/h) before even hitting the API to reduce server load.

### 3.5 Transaction History & Wallet
- **Responsibility**: Provide a transparent audit trail of all financial movements.
- **UI Flow**: A vertical list showing all payout events.
- **Backend Sync**: Calls `GET /api/v1/payout/history/{worker_id}`. The UI filters and displays the `amount`, `reason`, and `timestamp` for every approved transaction.

## 3. TECHNICAL IMPLEMENTATION & SENSOR FUSION LOGIC



To maintain production-grade quality (SQM), the Flutter application implements a **Kinematic Verification Service**:
1. [cite_start]**Sampling**: The app samples the 3-axis accelerometer at 50Hz for 3 seconds[cite: 504, 505].
2. **Calculation**: It computes the variance (standard deviation squared) of the magnitude.
3. **Dispatch**: This variance is sent alongside the `gps_speed_kmh` to the backend. The backend validates that if the worker is moving ($>10$ km/h), the physical vibration (variance) is $>0.5$. If this correlation fails, the backend rejects the claim as GPS Spoofing.

## 4. INTEGRATION & DEPLOYMENT PLAN

- **API Base URL**: Configured via `.env` to point to the **Render.com** hosted backend instance.
- **State Persistence**: Uses the `hydrated_bloc` library to ensure that once a worker is logged in, they bypass the auth screen until an explicit `LOGOUT` event is triggered.
- [cite_start]**UI Uniformity**: All screens utilize the centralized `CarbonMaterialTheme` providing high-contrast components and standardized text styles for outdoor gig-worker environments[cite: 474, 489].
- **Quality Assurance**: Adheres to the 100% test coverage target of the backend by implementing unit tests for every BLoC state transition and integration tests for all API service calls.