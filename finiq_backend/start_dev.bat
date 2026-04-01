@echo off
echo ═══════════════════════════════════════
echo  FinIQ Backend — Dev Launcher v4.0
echo ═══════════════════════════════════════

REM Step 1: Setup ADB reverse tunnel
echo [1/3] Setting up ADB reverse tunnel...
adb reverse tcp:5000 tcp:5000
if %ERRORLEVEL% NEQ 0 (
    echo [WARN] ADB not connected — app will use emulator/browser only
) else (
    echo [OK] ADB tunnel active: device:5000 → PC:5000
)

REM Step 2: Activate venv if exists
if exist "venv\Scripts\activate.bat" (
    echo [2/3] Activating virtual environment...
    call venv\Scripts\activate.bat
) else (
    echo [2/3] No venv found — using system Python
)

REM Step 3: Start Flask
echo [3/3] Starting Flask server...
echo.
echo   Local:   http://127.0.0.1:5000
echo   Device:  http://127.0.0.1:5000 (via ADB)
echo   Health:  http://127.0.0.1:5000/ping
echo.
python app.py
