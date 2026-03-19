Deploying **Carbon** to a live environment while simultaneously building a Flutter frontend requires a strategic "Split-Environment" workflow. This ensures that while your backend is being provisioned in the cloud, your mobile development remains unblocked.

Here is the deep-dive, real-world guide to deploying your FastAPI backend on Render and architecting the Flutter connection for your zeroth review tomorrow.

---

### Phase 1: Deploying Carbon to Render.com (Production-Grade)

Render’s free tier is excellent for prototypes, but it requires specific configurations to handle FastAPI’s asynchronous nature and ensure the "Rule-Based" logic works globally.

1.  **Prepare the Repository:** Ensure your `backend/` folder contains a `requirements.txt` file (including `fastapi`, `uvicorn`, `sqlalchemy`, `psycopg2-binary`, and `python-dotenv`) and your `main.py` entry point.
2.  **Environment Variables:** Do **not** commit your `.env` file to GitHub. [cite_start]In the Render Dashboard, go to **Environment** and manually add your `SUPABASE_DATABASE_URL`, `FIREBASE_CONFIG`, and `GNEWS_API_KEY`[cite: 426].
3.  **The Render Blueprint:** Create a new **Web Service** and connect your GitHub repo.
    * **Build Command:** `pip install -r requirements.txt`
    * **Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`
4.  **Database Connection:** Since Render's free PostgreSQL has a 30-day limit, your use of **Supabase** is optimal for maintaining persistent financial records without cost.



### Phase 2: What Your Live Endpoints Will Look Like

Once deployed, Render provides a unique URL (e.g., `https://carbon-backend-xyz.onrender.com`). Your Flutter app will interact with these specific production endpoints:

* **Registration:** `https://carbon-backend-xyz.onrender.com/api/v1/workers/register`
* **Order Reception:** `https://carbon-backend-xyz.onrender.com/api/v1/orders/receive`
* **Security Validation:** `https://carbon-backend-xyz.onrender.com/api/v1/payout/trigger`

> **Note on Free Tier Latency:** Render's free tier "spins down" after 15 minutes of inactivity. The first API call from your Flutter app tomorrow might take 30 seconds to wake the server up. For your demo, ensure you ping the server 5 minutes before your presentation to keep it "warm."

---

### Phase 3: Building Frontend Without Deployment (Local Tunneling)

You do not need to wait for a successful Render build to develop the Flutter app. You can use **Local Reverse Proxying** to make your phone think your laptop is a live cloud server.

1.  **Android Emulator Proxy:** In your Flutter `ApiClient`, use the IP `10.0.2.2:8000` to reach the FastAPI server running on your laptop.
2.  **Physical Device (ngrok):** If testing on a real phone, use **ngrok**. Run `ngrok http 8000` in your terminal. It will give you a temporary public URL like `https://random-id.ngrok-free.app`.
3.  **Mocking via Interceptors:** Use the `Dio` package with an interceptor to return "Fake Success" data if the backend is offline. This allows you to polish the UI even if the internet fails.

---

### Phase 4: Connecting Flutter to the Live Backend (SQM Principles)

To maintain a "Production-Grade" connection, your Flutter network layer must handle authentication and data integrity automatically.

* **Centralized BaseURL:** Use `flutter_dotenv` to store the Render URL. This allows you to switch from `localhost` to `production` by changing a single line in your `.env` file.
* [cite_start]**HMAC Signing Interceptor:** The backend requires an `X-Signature` for payout triggers[cite: 502]. [cite_start]Implement a Dio Interceptor that intercepts every request to `/api/v1/payout/trigger`, generates the HMAC-SHA256 hash using the payload and timestamp, and attaches it to the header[cite: 502, 461].
* **Stateful Reliability:** Use `HydratedBLoC` to store the `worker_id` locally. This ensures that even if the app crashes during a rainstorm, the user remains "Logged In" and the state is restored instantly upon restart.

### Phase 5: Zero-Touch Payout Workflow for the Review

To showcase the **Carbon** innovation to the judges, your implementation should follow this real-time sequence:

1.  **Order Ping:** Flutter app sends `pickup_lat/lon` to Render.
2.  **Parametric Check:** Render synthesizes weather and returns `meets_threshold: true`.
3.  **Sensor Fusion:** Upon "Claim," Flutter sends GPS and Accelerometer data.
4.  **Verification:** Render validates the "Truthfulness" (Kinematic Analysis) and updates the Supabase ledger.
5.  **Notification:** Firebase sends a push alert to the phone confirming the ₹50 deposit.

