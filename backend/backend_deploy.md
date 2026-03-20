To ensure the **Carbon** platform remains functional during a live review where local network conditions (IP addresses) are unpredictable, you must move beyond static `.env` files for the mobile client. In a production-grade system, the client should either discover the server or allow for manual override without re-compiling the application.
---

### 1. Solving the Dynamic IP Challenge in Flutter

Since you cannot modify a `.env` file once the Flutter app is installed on a physical device, you must implement a **Dynamic Configuration Layer**.

**The Developer Settings Override (Recommended)**
Instead of hardcoding the `BASE_URL` from the `.env` file into your API client, treat the `.env` value as a "Default Fallback." Use a persistent storage library like `shared_preferences` or `flutter_secure_storage` to allow manual IP updates within the app.
* **Implementation**: Create a hidden "Network Settings" screen (accessible via a long-press on the login logo).
* **Logic**: The app checks local storage for an `OVERRIDE_URL`. If found, it uses that; otherwise, it defaults to the `.env` value.
* **Review Benefit**: If your laptop's IP changes during the demo, you simply type the new IP into the app's settings and hit "Save." The BLoC will re-initialize the `ApiClient` with the new base URL instantly.

**Network Discovery (mDNS/Bonjour)**
For high-innovation scores, you can implement **Multicast DNS (mDNS)**. This allows the Flutter app to search the local Wi-Fi for a service named `carbon-backend.local` instead of a numerical IP address.
* **Backend**: Configure the Docker container to announce its presence using an Avahi or Bonjour daemon.
* **Frontend**: Use a Flutter package like `nsd` (Network Service Discovery) to resolve `carbon-backend.local` to the current IP address of your laptop automatically.

---

### 2. Dockerized Backend & Dynamic IP Binding

Containerizing the **Carbon** backend ensures environment parity, but the container needs to know the host's IP to handle certain "Rule-Based" logic correctly.

**The IP Binding Script**
You can use a shell script (entrypoint) inside your Docker container to detect the host's IP and inject it into the FastAPI environment variables at runtime.
* **The Script**: `export HOST_IP=$(hostname -I | awk '{print $1}')`
* **The Command**: Run `uvicorn main:app --host 0.0.0.0 --port 8000` to ensure the container listens to all incoming Wi-Fi traffic mapped from the host.
* **Docker Compose Configuration**: Use a `docker-compose.yml` file to map your laptop's port 8000 to the container's port 8000. This ensures that any device hitting `http://<YOUR_LAPTOP_IP>:8000` is routed to the FastAPI engine.

---

### 3. Wi-Fi Management & Infrastructure SQM

To maintain Software Quality Management (SQM) and reliability during the review, the local network must be treated as a production environment.

* **Static DHCP Lease**: If you have access to the Wi-Fi router settings, reserve a static IP for your laptop's MAC address. This prevents the IP from changing even if the laptop reboots.
* **Windows Firewall Automation**: Since you are using a Windows machine with 8GB RAM, create a PowerShell script to automatically open Port 8000 for "Private" networks only. This ensures the Wi-Fi bridge remains secure but functional.
* **Connection Health Check**: Implement a "Pulse" indicator in the Flutter app. If the app cannot reach the `BASE_URL`, change the "Shield Status" to a gray "Disconnected" state. This informs the user (the judge) of a network issue rather than a software crash.

---

### 4. Implementation Roadmap for Zeroth Review

Follow this phase-based plan to complete the infrastructure today:

**Phase 1: Local Persistence (Flutter)**
Implement the `shared_preferences` logic in your `ApiClient`. Ensure the app can persist a custom IP address across restarts.

**Phase 2: The Network Settings UI**
Build a clean, minimal "Settings" page in Flutter. This allows the judge to see that you have planned for "Production Deployment Flexibility" where server endpoints might change.

**Phase 3: Dockerization & Environment Mapping**
Finalize the `Dockerfile`. Ensure all secrets from your `.env` (Supabase keys, Firebase config) are passed into the container via the `--env-file` flag.

**Phase 4: End-to-End Wi-Fi Test**
Install the release APK on your physical device. Turn off the laptop's mobile data and connect both to the same Wi-Fi. Trigger a "Simulated Rainstorm" from the laptop and verify the payout arrives on the phone wirelessly.



By implementing a manual IP override and a robust Dockerized backend, you demonstrate to the judges that **Carbon** is not just a hardcoded prototype, but a flexible, production-ready system capable of operating in dynamic real-world environments.
