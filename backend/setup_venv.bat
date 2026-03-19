@echo off
echo ========================================
echo CARBON BACKEND - VIRTUAL ENVIRONMENT SETUP
echo ========================================
echo.

REM Check if venv exists
if exist venv (
    echo Virtual environment already exists.
    echo To recreate, delete the 'venv' folder first.
    echo.
) else (
    echo Creating virtual environment...
    python -m venv venv
    if %errorlevel% neq 0 (
        echo ERROR: Failed to create virtual environment
        echo Make sure Python 3.9+ is installed
        exit /b 1
    )
    echo Virtual environment created successfully!
    echo.
)

echo Activating virtual environment...
call venv\Scripts\activate.bat
if %errorlevel% neq 0 (
    echo ERROR: Failed to activate virtual environment
    exit /b 1
)

echo.
echo Installing dependencies from requirements.txt...
python -m pip install --upgrade pip
pip install -r requirements.txt
if %errorlevel% neq 0 (
    echo ERROR: Failed to install dependencies
    exit /b 1
)

echo.
echo ========================================
echo SETUP COMPLETE ✓
echo ========================================
echo.
echo Virtual environment is ready!
echo.
echo To activate manually, run:
echo   venv\Scripts\activate.bat
echo.
echo To run tests:
echo   run_tests.bat
echo.
echo To start the server:
echo   run_server.bat
echo.
