@echo off
cd /d "%~dp0"
echo.
echo  ==========================================
echo   ARK UBI SENDER — DRY RUN PREVIEW
echo  ==========================================
echo.
echo  This shows who will be paid and how much.
echo  No transactions will be sent.
echo.
python send_ubi.py
echo.
pause
