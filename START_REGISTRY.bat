@echo off
title Ark Citizen Registry Server
color 0A
echo.
echo  ============================================
echo   ARK CITIZEN REGISTRY SERVER  (port 5000)
echo  ============================================
echo.
echo  Press Ctrl+C to stop.
echo.
cd /d "%~dp0"
python server.py
echo.
echo  Server stopped.
pause
