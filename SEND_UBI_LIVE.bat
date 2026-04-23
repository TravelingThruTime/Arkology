@echo off
cd /d "%~dp0"
echo.
echo  ==========================================
echo   ARK UBI SENDER — LIVE BCH PAYMENTS
echo  ==========================================
echo.
echo  First, a dry-run preview:
echo.
python send_ubi.py
echo.
echo  *** WARNING: Next step sends REAL BCH. ***
echo  *** Only run ONCE per month.           ***
echo  *** Make sure Electron Cash is open.   ***
echo.
set /p CONFIRM=  Type YES to send live payments: 
if /I "%CONFIRM%"=="YES" (
    python send_ubi.py --send
) else (
    echo  Cancelled. No BCH sent.
)
echo.
pause
