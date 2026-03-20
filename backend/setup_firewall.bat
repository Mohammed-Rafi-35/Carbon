@echo off
:: Carbon Backend — Windows Firewall Setup
:: Run as Administrator to allow physical devices on the same Wi-Fi to reach the backend.
:: Phase 6: Wi-Fi Network Bridge (ZEROTH_REVIEW_CHECKLIST.md §8.1)

echo ============================================================
echo  Carbon Backend — Windows Firewall Configuration
echo ============================================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This script must be run as Administrator.
    echo Right-click the file and select "Run as administrator".
    pause
    exit /b 1
)

:: Remove any existing Carbon rule to avoid duplicates
netsh advfirewall firewall delete rule name="Carbon Backend API" >nul 2>&1

:: Add inbound TCP rule for port 8000 on private networks
netsh advfirewall firewall add rule ^
    name="Carbon Backend API" ^
    dir=in ^
    action=allow ^
    protocol=TCP ^
    localport=8000 ^
    profile=private ^
    description="Allows Flutter mobile app on same Wi-Fi to reach Carbon FastAPI backend"

if %errorLevel% equ 0 (
    echo [OK] Firewall rule created: TCP port 8000 open on private networks.
) else (
    echo [ERROR] Failed to create firewall rule.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  Next steps:
echo  1. Find your LAN IP:   ipconfig  (look for IPv4 Address)
echo  2. Start backend:      docker-compose up --build
echo  3. In Flutter app:     Profile ^> Network Settings
echo     Set URL to:         http://^<YOUR_LAN_IP^>:8000
echo  4. Connect phone to the same Wi-Fi network.
echo ============================================================
echo.
pause
