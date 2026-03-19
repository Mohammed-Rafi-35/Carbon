@echo off
echo Activating Carbon Backend Virtual Environment...
call venv\Scripts\activate.bat
echo.
echo Virtual environment activated!
echo.
echo Available commands:
echo   pytest tests/ -v          - Run all tests
echo   uvicorn app.main:app --reload  - Start server
echo   python                    - Python shell
echo.
cmd /k
