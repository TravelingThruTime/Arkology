@echo off
title Ark — Caddy HTTPS Server
color 0B
echo.
echo  ============================================
echo   ARK — Caddy HTTPS Proxy for arkology.org
echo  ============================================
echo.
echo  Press Ctrl+C in this window to stop.
echo  ============================================
echo.
cd /d "%~dp0"
caddy run --config Caddyfile
echo.
echo  Caddy stopped.
pause
