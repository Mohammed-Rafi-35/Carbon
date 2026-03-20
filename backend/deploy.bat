@echo off
echo ========================================
echo Carbon Backend - Docker Deployment
echo ========================================
echo.

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running. Please start Docker Desktop.
    pause
    exit /b 1
)

REM Get host IP address
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set HOST_IP=%%a
    goto :found_ip
)
:found_ip
set HOST_IP=%HOST_IP:~1%

echo.
echo Network Configuration:
echo    Host IP: %HOST_IP%
echo    Backend URL: http://%HOST_IP%:8000
echo.

REM Check if .env file exists
if not exist .env (
    echo [WARNING] No .env file found. Creating from template...
    copy .env.docker .env
    echo [SUCCESS] Created .env file
)

REM Build and start containers
echo.
echo Building Docker images...
docker-compose build

echo.
echo Starting containers...
docker-compose up -d

echo.
echo Waiting for services to start...
timeout /t 10 /nobreak >nul

REM Check if containers are running
docker-compose ps | findstr "Up" >nul
if errorlevel 1 (
    echo.
    echo [ERROR] Failed to start services. Check logs:
    echo    docker-compose logs
    pause
    exit /b 1
)

echo.
echo ========================================
echo [SUCCESS] Carbon Backend is running!
echo ========================================
echo.
echo Access Points:
echo    API Docs:    http://%HOST_IP%:8000/docs
echo    Health:      http://%HOST_IP%:8000/health
echo    Database:    localhost:5432
echo.
echo Mobile App Configuration:
echo    1. Open Carbon app
echo    2. Long-press logo on login screen
echo    3. Enter: http://%HOST_IP%:8000
echo    4. Test connection and save
echo.
echo Commands:
echo    View logs:   docker-compose logs -f
echo    Stop:        docker-compose down
echo    Restart:     docker-compose restart
echo.
pause
