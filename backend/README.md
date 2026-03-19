# Carbon Backend - Parametric Insurance API

Production-grade FastAPI backend for the Carbon parametric insurance platform.

## 🚀 Quick Start

### 1. Setup Virtual Environment
```bash
setup_venv.bat
```

This will:
- Create a Python virtual environment
- Install all dependencies from requirements.txt
- Prepare the development environment

### 2. Configure Environment Variables
Copy `.env.example` to `.env` and fill in your credentials:
```bash
copy .env.example .env
```

Required variables:
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_KEY` - Your Supabase API key
- `DATABASE_URL` - PostgreSQL connection string
- `SECRET_KEY` - Secret key for HMAC signing
- `ENVIRONMENT` - `development` or `production`

### 3. Run Tests
```bash
run_tests.bat
```

### 4. Start Server
```bash
run_server.bat
```

Server will be available at:
- API: http://127.0.0.1:8000
- Interactive Docs: http://127.0.0.1:8000/docs
- Health Check: http://127.0.0.1:8000/health

## 📁 Project Structure

```
backend/
├── app/
│   ├── api/v1/          # API route controllers
│   │   ├── worker.py    # Worker registration & profiles
│   │   ├── order.py     # Order reception & weather synthesis
│   │   └── payout.py    # Payout trigger & history (NEW)
│   ├── core/            # Configuration & constants
│   │   ├── config.py    # Pydantic settings
│   │   ├── constants.py # Parametric thresholds
│   │   └── security.py  # HMAC validation & security gate (NEW)
│   ├── db/              # Database layer
│   │   ├── session.py   # Async session management
│   │   ├── models.py    # SQLAlchemy ORM models
│   │   └── repository.py # CRUD operations
│   ├── schemas/         # Pydantic validation schemas
│   │   └── models.py    # Request/response DTOs
│   ├── services/        # Business logic
│   │   ├── weather_svc.py # Weather synthesizer
│   │   ├── sensor_svc.py  # Sensor fusion analyzer (NEW)
│   │   └── payout_svc.py  # Payout calculation (NEW)
│   └── main.py          # FastAPI application entry point
├── tests/               # Unit & integration tests
│   ├── test_database.py # Database CRUD tests
│   ├── test_weather.py  # Weather synthesizer tests
│   ├── test_sensor.py   # Sensor fusion tests (NEW)
│   ├── test_security.py # HMAC security tests (NEW)
│   ├── test_payout.py   # Payout service tests (NEW)
│   └── test_api.py      # API integration tests
├── venv/                # Virtual environment (auto-generated)
├── .env                 # Environment variables (create from .env.example)
├── requirements.txt     # Python dependencies
└── pytest.ini           # Test configuration
```

## 🧪 Testing

### Run All Tests
```bash
run_tests.bat
```

### Run Specific Test File
```bash
call venv\Scripts\activate.bat
pytest tests/test_weather.py -v
```

### Run with Coverage
```bash
call venv\Scripts\activate.bat
pytest tests/ --cov=app --cov-report=html
```

## 🔧 Development

### Manual Virtual Environment Activation
```bash
activate.bat
```

### Start Server with Auto-Reload
```bash
call venv\Scripts\activate.bat
uvicorn app.main:app --reload
```

### Database Migrations (Future)
```bash
# Alembic migrations will be added in Phase 4
```

## 📊 API Endpoints

### Health Check
```http
GET /health
```

### Worker Management
```http
POST /api/v1/workers/register
GET /api/v1/workers/{worker_id}
GET /api/v1/workers/phone/{phone}
```

### Order & Weather
```http
POST /api/v1/orders/receive
GET /api/v1/orders/weather/{order_id}
```

### Payout (NEW)
```http
POST /api/v1/payout/trigger
GET /api/v1/payout/history/{worker_id}
```

## 🏗️ Architecture

### Layered Pattern
- **API Layer**: Route controllers (FastAPI)
- **Service Layer**: Business logic (Weather Synthesizer, Sensor Fusion)
- **Repository Layer**: Data access (SQLAlchemy)
- **Model Layer**: Database schemas (ORM models)

### Key Features
- **Async I/O**: Non-blocking database and API operations
- **Type Safety**: Strict type hints with Pydantic validation
- **Cross-Database**: Works with PostgreSQL (production) and SQLite (testing)
- **Fail-Safe**: Graceful error handling and validation

## 🔐 Security

- Environment variables for sensitive data
- HMAC-SHA256 request signing (NEW)
- Sensor fusion anti-fraud gates (NEW)
- GPS spoofing detection (NEW)
- Replay attack prevention (NEW)
- Input validation with Pydantic
- SQL injection prevention via ORM
- Constant-time signature comparison (NEW)

## 📈 Performance

- Connection pooling (10 connections, 20 overflow)
- Async database operations
- Lazy loading for weather data
- Efficient indexing on frequently queried fields

## 🐛 Troubleshooting

### Virtual Environment Not Found
```bash
# Delete venv folder and run setup again
rmdir /s venv
setup_venv.bat
```

### Database Connection Error
- Verify DATABASE_URL in .env
- Check PostgreSQL is running
- For testing, SQLite is used automatically

### Import Errors
```bash
# Ensure you're in the backend directory
cd backend
call venv\Scripts\activate.bat
```

## 📝 Phase Completion Status

- ✅ Phase 1: Persistence & Core Engine (Complete)
- ✅ Phase 2: Weather Synthesizer & Parametric Logic (Complete)
- ✅ Phase 3: Security Architecture (Sensor Fusion) (Complete)
- ⏳ Phase 4: Flutter Application (Frontend) - Next
- ⏳ Phase 5: Real-Time Sync & Admin Dashboard
- ⏳ Phase 6: Refactoring & SQM Enforcement

## 🤝 Contributing

1. Create feature branch
2. Write tests first (TDD)
3. Implement feature
4. Run `run_tests.bat` to verify
5. Submit pull request

## 📄 License

Proprietary - Carbon Parametric Insurance Platform
