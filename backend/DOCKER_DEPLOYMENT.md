# Carbon Backend - Docker Deployment Guide

## 🚀 Quick Start

### Prerequisites
- Docker Desktop installed and running
- 4GB RAM available
- Ports 8000 and 5432 available

### One-Command Deployment

**Windows:**
```bash
deploy.bat
```

**Linux/Mac:**
```bash
chmod +x deploy.sh
./deploy.sh
```

The script will:
1. ✅ Check Docker installation
2. ✅ Detect your host IP address
3. ✅ Create .env file if missing
4. ✅ Build Docker images
5. ✅ Start PostgreSQL and Backend
6. ✅ Display access URLs

---

## 📱 Mobile App Configuration

After deployment, configure the Flutter app:

1. **Open Carbon App**
2. **Long-press** the logo on login screen (2 seconds)
3. **Enter URL**: `http://<YOUR_IP>:8000` (shown in deployment output)
4. **Test Connection** → Should show green checkmark
5. **Save URL**

The app will now communicate with your Docker backend!

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│         Docker Compose Stack            │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────┐   ┌───────────────┐  │
│  │  PostgreSQL  │   │    Backend    │  │
│  │   Database   │◄──│   FastAPI     │  │
│  │   Port 5432  │   │   Port 8000   │  │
│  └──────────────┘   └───────────────┘  │
│         │                    │          │
│         │                    │          │
│    [Volume]            [Health Check]   │
│  postgres_data              │          │
│                             │          │
└─────────────────────────────┼──────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │   Flutter App    │
                    │  (Same Wi-Fi)    │
                    └──────────────────┘
```

---

## 🔧 Configuration

### Environment Variables (.env)

```bash
# Database
POSTGRES_USER=carbon
POSTGRES_PASSWORD=carbon_secure_password_2024
POSTGRES_DB=carbon_db

# Security
SECRET_KEY=production-secret-key-change-this

# Server
HOST=0.0.0.0
PORT=8000
WORKERS=4
LOG_LEVEL=info

# Weather Thresholds
RAIN_THRESHOLD_MM=5.0
WIND_THRESHOLD_KMH=30.0
TEMP_THRESHOLD_C=35.0

# Payout
BASE_PAYOUT_AMOUNT=50.0
MAX_PAYOUT_AMOUNT=200.0
```

---

## 📊 Database Schema

### Workers Table
```sql
CREATE TABLE workers (
    id UUID PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(15) UNIQUE NOT NULL,
    zone VARCHAR(100) NOT NULL,
    vehicle_type VARCHAR(50) NOT NULL,
    wallet_balance NUMERIC(10,2) DEFAULT 0.0,
    weekly_rides_completed INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### Transactions Table
```sql
CREATE TABLE transactions (
    id UUID PRIMARY KEY,
    worker_id UUID REFERENCES workers(id),
    amount NUMERIC(10,2) NOT NULL,
    type VARCHAR(50) NOT NULL,
    reason VARCHAR(500),
    timestamp TIMESTAMP DEFAULT NOW()
);
```

### Route Weather Table
```sql
CREATE TABLE route_weather (
    id UUID PRIMARY KEY,
    worker_id UUID REFERENCES workers(id),
    order_id VARCHAR(100) NOT NULL,
    pickup_lat FLOAT NOT NULL,
    pickup_lon FLOAT NOT NULL,
    dropoff_lat FLOAT NOT NULL,
    dropoff_lon FLOAT NOT NULL,
    weather_data TEXT NOT NULL,
    meets_threshold BOOLEAN DEFAULT FALSE,
    threshold_reason VARCHAR(500),
    timestamp TIMESTAMP DEFAULT NOW()
);
```

---

## 🧪 Testing the Deployment

### 1. Health Check
```bash
curl http://localhost:8000/health
```

**Expected Response:**
```json
{
  "status": "healthy",
  "environment": "production",
  "version": "2.0.0"
}
```

### 2. API Documentation
Open in browser: `http://localhost:8000/docs`

### 3. Register Worker
```bash
curl -X POST http://localhost:8000/api/v1/workers/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "phone": "9876543210",
    "zone": "North",
    "vehicle_type": "bike"
  }'
```

### 4. Check Database
```bash
docker-compose exec postgres psql -U carbon -d carbon_db -c "SELECT * FROM workers;"
```

---

## 📝 Common Commands

### View Logs
```bash
# All services
docker-compose logs -f

# Backend only
docker-compose logs -f backend

# PostgreSQL only
docker-compose logs -f postgres
```

### Restart Services
```bash
# Restart all
docker-compose restart

# Restart backend only
docker-compose restart backend
```

### Stop Services
```bash
docker-compose down
```

### Stop and Remove Data
```bash
docker-compose down -v
```

### Rebuild Images
```bash
docker-compose build --no-cache
docker-compose up -d
```

---

## 🔍 Troubleshooting

### Issue: Port 8000 already in use
**Solution:**
```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:8000 | xargs kill -9
```

### Issue: Port 5432 already in use
**Solution:**
```bash
# Stop local PostgreSQL
# Windows: Services → PostgreSQL → Stop
# Linux: sudo systemctl stop postgresql
# Mac: brew services stop postgresql
```

### Issue: Cannot connect from mobile app
**Solution:**
1. Ensure phone and laptop on same Wi-Fi
2. Check firewall allows port 8000
3. Verify IP address: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
4. Test from phone browser: `http://<IP>:8000/health`

### Issue: Database connection failed
**Solution:**
```bash
# Check PostgreSQL is running
docker-compose ps

# Check logs
docker-compose logs postgres

# Restart PostgreSQL
docker-compose restart postgres
```

---

## 🚀 Production Deployment

### Render.com Deployment

1. **Create Render Account**
2. **New Web Service**
3. **Connect GitHub Repository**
4. **Configure:**
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
5. **Add Environment Variables** (from .env)
6. **Deploy**

### Environment Variables for Render
```
DATABASE_URL=<render_postgres_url>
SECRET_KEY=<strong_random_key>
ENVIRONMENT=production
LOG_LEVEL=info
```

---

## 📊 Performance Tuning

### Increase Workers
Edit `.env`:
```bash
WORKERS=8  # For 4-core CPU
```

### Database Connection Pool
Edit `app/db/session.py`:
```python
engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=20,
    max_overflow=10,
)
```

### Enable Caching
Add Redis to `docker-compose.yml`:
```yaml
redis:
  image: redis:7-alpine
  ports:
    - "6379:6379"
```

---

## 🔐 Security Checklist

- [ ] Change default SECRET_KEY
- [ ] Change default POSTGRES_PASSWORD
- [ ] Enable HTTPS in production
- [ ] Restrict CORS origins
- [ ] Enable rate limiting
- [ ] Regular security updates
- [ ] Backup database regularly

---

## 📈 Monitoring

### Health Check Endpoint
```bash
curl http://localhost:8000/health
```

### Database Stats
```bash
docker-compose exec postgres psql -U carbon -d carbon_db -c "
  SELECT 
    schemaname,
    tablename,
    n_live_tup as row_count
  FROM pg_stat_user_tables
  ORDER BY n_live_tup DESC;
"
```

### Container Stats
```bash
docker stats
```

---

## 🎯 Next Steps

1. ✅ Deploy backend with Docker
2. ✅ Configure mobile app with IP
3. ✅ Test complete user journey
4. ✅ Monitor logs and performance
5. ✅ Backup database regularly
6. ✅ Plan production deployment

---

## 📞 Support

For issues or questions:
1. Check logs: `docker-compose logs -f`
2. Review troubleshooting section
3. Check API docs: `http://localhost:8000/docs`

---

**Version:** 2.0.0  
**Last Updated:** December 2024  
**Docker Compose Version:** 3.8  
**PostgreSQL Version:** 15  
**Python Version:** 3.11
