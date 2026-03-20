# CARBON: PRODUCTION-GRADE PARAMETRIC INSURANCE INFRASTRUCTURE
**Technical Blueprint & Integration Guide v2.0**

## 1. PROBLEM STATEMENT AND CORE IDEATION
[cite_start]The Indian gig economy relies on delivery partners who face a 20-30% loss of monthly earnings due to uncontrollable external disruptions such as hazardous weather, extreme pollution, and social unrest[cite: 7, 10]. [cite_start]Carbon is an AI-enabled parametric insurance platform designed to provide rapid income protection through automated payouts triggered by objective environmental data[cite: 14, 15]. [cite_start]The platform strictly adheres to the "Loss of Income" constraint, excluding health, life, and vehicle repair coverage, and operates on a weekly pricing model aligned with gig worker earnings cycles[cite: 17, 18, 83, 85].

## 2. SYSTEM ARCHITECTURE AND DATA FLOW
Carbon utilizes a decoupled micro-architecture designed for high availability and strict data integrity. The system leverages polyglot persistence, using Supabase (PostgreSQL) for transactional and financial records and Firebase Realtime Database for high-frequency "hot" data such as live driver location pings and status updates.



### 2.1 Backend Micro-Architecture
[cite_start]The backend is built with FastAPI to utilize asynchronous I/O, allowing it to handle thousands of concurrent requests from active drivers[cite: 418]. It serves as the central brain, executing parametric logic and security gates.
- [cite_start]**Parametric Engine**: Monitors real-time environmental triggers (Rain ≥ 5.0mm, Wind ≥ 40.0 km/h)[cite: 122].
- **Weather Synthesizer**: A proprietary middleware that generates deterministic, meteorologically consistent weather data for 100+ geographic zones.
- **Audit Ledger**: Every transaction is logged with a unique ID and a human-readable reason to ensure transparency.

### 2.2 Frontend Client Architecture
The Carbon mobile application is built with Flutter using a Feature-First Clean Architecture and the BLoC pattern for state management.
- [cite_start]**High-Contrast UI**: Designed for outdoor visibility with minimal interaction requirements[cite: 474].
- **Lazy Loading**: Weather and route data are only fetched when an active order is viewed, minimizing data consumption for the worker.
- **Persistence**: Auth tokens and worker IDs are stored securely, ensuring a seamless experience across app restarts.

## 3. PHASE 1: DATA PERSISTENCE AND INFRASTRUCTURE
The cold data layer is managed via Supabase to ensure ACID compliance for all financial movements.

- **Workers Table**: Stores profile data, zone, vehicle type, and current wallet balance.
- **Policies Table**: Tracks active weekly insurance coverage for each worker.
- **Transactions Table**: A permanent audit trail of all premium payments and automated payouts.
- [cite_start]**RouteWeather Table**: Stores synthesized weather snapshots for every delivery order to provide a historical basis for claims[cite: 441, 457].

## 4. PHASE 2: PARAMETRIC LOGIC AND WEATHER SYNTHESIZER
The parametric engine automates the claims process by replacing manual adjudication with rule-based code execution.

- [cite_start]**Weather Synthesis**: When an order is received via `POST /api/v1/orders/receive`, the system auto-detects weather for both pickup and drop-off coordinates[cite: 418, 441, 443].
- **Consistency Filtering**: The synthesizer enforces physical laws (e.g., high rain requires high humidity) to ensure the data remains plausible during simulation.
- [cite_start]**Trigger Logic**: If the synthesized data crosses predefined thresholds (e.g., 2.0mm rain), the order is flagged as "Meets Threshold," enabling a potential payout[cite: 453, 465].

## 5. PHASE 3: SENSOR FUSION AND TRUTHFULNESS GATE
[cite_start]To prevent fraud, Carbon implements a multi-layered security architecture that moves beyond single data points[cite: 413, 497].



- [cite_start]**Kinematic Analysis**: During a payout request, the backend cross-references OS-level GPS speed with hardware accelerometer variance[cite: 461, 504]. 
- [cite_start]**The Fraud Gate**: If GPS speed exceeds 10 km/h but accelerometer variance is below 0.5 (indicating a perfectly still device), the system flags a "GPS Spoofing" attack and rejects the claim[cite: 468, 505].
- [cite_start]**HMAC Signing**: All payout requests are signed with an HMAC-SHA256 hash using a shared secret key and a unique timestamp to prevent replay attacks[cite: 502].

## 6. PHASE 4: REVENUE MODEL AND CORPUS STRATEGY
The platform balances company profitability with gig worker economic development through an innovative pricing structure.

- **Front-Loading Strategy**: During the initial month, premiums are temporarily increased (7-5-3% tier) to generate a ₹55.5 Crore "Disaster Ready" seed fund.
- **Ride-Based Premium**: After the corpus build, rates scale based on activity:
    - 100+ Weekly Rides: 5% of income.
    - 70-99 Weekly Rides: 4% of income.
    - < 70 Weekly Rides: 3% of income.
- **Payout Scaling**: Automated payouts are calculated as 20% of the worker's projected weekly income, providing substantial relief during disruptions.

## 7. PHASE 5: REAL-TIME SYNC AND ADMIN COMMAND CENTER
The admin dashboard provides a high-level "Financial Pulse" and real-time operational visibility.

- [cite_start]**Live Disruption Map**: Visualizes active geofences and the real-time location of insured drivers via Firebase[cite: 492].
- [cite_start]**Anomaly Detection**: A "Fraud Quarantine Queue" highlights claims flagged by the sensor fusion gate for manual review[cite: 496].
- [cite_start]**Diagnostic Analytics**: Compares total payouts against disruption intensity to monitor loss ratios and fund health[cite: 491].

## 8. PHASE 6: INTEGRATION AND WI-FI NETWORK BRIDGE
To transition the application from an emulator to a physical device using a local server infra, follow these technical steps.



### 8.1 Backend Wi-Fi Configuration
- **Network Identification**: Identify the host machine's IPv4 address (e.g., 192.168.1.15) using `ipconfig`.
- **IP Binding**: Bind the FastAPI server to the 0.0.0.0 interface to listen on all network adapters.
    - **Command**: `python -m uvicorn main:app --host 0.0.0.0 --port 8000`
- **Firewall Authorization**: Create an inbound rule in Windows Firewall to allow TCP traffic on Port 8000 for private networks.

### 8.2 Frontend Mobile Integration
- **Dynamic URL Configuration**: Implement a hidden "Network Settings" screen in the Flutter app using `shared_preferences` to override the default backend URL.
- **Wireless Connection**: Connect the physical mobile device and the server laptop to the same Wi-Fi SSID.
- **Service Access**: Point the Flutter app to `http://192.168.1.15:8000/api/v1`. The app will now interact wirelessly with the local FastAPI engine.

### 8.3 Containerized Local Deployment
- **Dockerization**: Create a Dockerfile in the backend directory that installs dependencies and runs the uvicorn server on host 0.0.0.0.
- **Runtime Injection**: Use `docker run -p 8000:8000 --env-file .env carbon-backend` to map the host port to the container and inject Supabase/Firebase credentials. This ensures the backend logic is isolated while remaining accessible over the local Wi-Fi.

## 9. SOFTWARE QUALITY MANAGEMENT (SQM)
Carbon adheres to high-level SQM standards to ensure the prototype is production-ready.
- **Modularity**: Separation of concerns between API routers, parametric services, and database repositories.
- **Reliability**: Asynchronous error handling and graceful degradation during network instability.
- **Scalability**: Stateless backend design allowing for horizontal scaling via Docker orchestration.
- **Verification**: 100% test coverage for core weather synthesis and sensor fusion logic.