@echo off
echo ========================================
echo CARBON PHASE 2 VALIDATION
echo ========================================
echo.

REM Activate virtual environment
if not exist venv (
    echo ERROR: Virtual environment not found!
    echo Please run setup_venv.bat first
    exit /b 1
)

call venv\Scripts\activate.bat

echo Running Weather Synthesizer Tests...
echo ----------------------------------------
pytest tests/test_weather.py -v --tb=short
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Weather tests failed
    exit /b 1
)

echo.
echo Running Database Tests...
echo ----------------------------------------
pytest tests/test_database.py -v --tb=short
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Database tests failed
    exit /b 1
)

echo.
echo Running API Integration Tests...
echo ----------------------------------------
pytest tests/test_api.py -v --tb=short
if %errorlevel% neq 0 (
    echo.
    echo ERROR: API tests failed
    exit /b 1
)

echo.
echo ========================================
echo ALL TESTS PASSED ✓
echo ========================================
echo.

REM Keep window open
pause
