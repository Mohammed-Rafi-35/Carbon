@echo off
echo ========================================
echo CARBON BACKEND - FASTAPI SERVER
echo ========================================
echo.

REM Activate virtual environment
if not exist venv (
    echo ERROR: Virtual environment not found!
    echo Please run setup_venv.bat first
    exit /b 1
)

call venv\Scripts\activate.bat

echo Starting FastAPI server...
echo.
echo Server will be available at:
echo   http://127.0.0.1:8000
echo.
echo API Documentation:
echo   http://127.0.0.1:8000/docs
echo.
echo Health Check:
echo   http://127.0.0.1:8000/health
echo.
echo Press CTRL+C to stop the server
echo ========================================
echo.

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
