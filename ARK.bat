@echo off
title Arkology — Master Control Panel
color 0A

:MENU
cls
echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║            ARKOLOGY — MASTER CONTROL PANEL                  ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.
echo   ── START / STOP ─────────────────────────────────────────────
echo    1  Start Registry Server        (Flask, port 5000) *** MAIN SERVER ***
echo    2  Start Election Server        (Node - NOT NEEDED, elections run in Flask)
echo    3  Start All Servers            (Registry + Caddy only; Node skipped)
echo.
echo   ── MONTHLY WORKFLOW ─────────────────────────────────────────
echo    4  Monthly Workflow             (Balance → Taxes → UBI send)
echo    5  Preview UBI Payments         (dry run, no BCH sent)
echo    6  Check Civic BCH Balance      (wallet + A19 update)
echo    7  Check Bond BCH Balance       (bond wallet only)
echo.
echo   ── ELECTION ─────────────────────────────────────────────────
echo   17  Apply Election               (update Hexarchy + charity ratings)
echo.
echo   ── ADMIN TOOLS ──────────────────────────────────────────────
echo    8  Set Resident Password        (assign Citizen Portal password)
echo    9  Set Resident PIN             (assign PIN to any resident)
echo   10  Search Audit Logs            (logs + receipts)
echo   11  Search Resident Records      (by name, ID, etc.)
echo.
echo   ── SETUP / TROUBLESHOOT ─────────────────────────────────────
echo   12  First-Time Setup             (install Python + openpyxl)
echo   13  Setup Election Portal        (NOT NEEDED - elections run in Flask)
echo   14  Diagnose Election            (NOT NEEDED - use option 1 + browser /admin)
echo   15  Fix Caddy HTTPS              (certificate troubleshooter)
echo   16  Start Caddy HTTPS            (standalone HTTPS proxy)
echo.
echo    0  Exit
echo.
set /p CHOICE=  Enter number: 

if "%CHOICE%"=="1" goto START_REGISTRY
if "%CHOICE%"=="2" goto START_ELECTION
if "%CHOICE%"=="3" goto START_ALL
if "%CHOICE%"=="4" goto MONTHLY
if "%CHOICE%"=="5" goto UBI_PREVIEW
if "%CHOICE%"=="6" goto CHECK_CIVIC_BCH
if "%CHOICE%"=="7" goto CHECK_BOND_BCH
if "%CHOICE%"=="8" goto SET_PASSWORD
if "%CHOICE%"=="9" goto SET_PIN
if "%CHOICE%"=="10" goto SEARCH_LOGS
if "%CHOICE%"=="11" goto SEARCH_RECORDS
if "%CHOICE%"=="12" goto SETUP_FIRST
if "%CHOICE%"=="13" goto SETUP_ELECTION
if "%CHOICE%"=="14" goto DIAGNOSE_ELECTION
if "%CHOICE%"=="15" goto FIX_CADDY
if "%CHOICE%"=="16" goto START_CADDY_STANDALONE
if "%CHOICE%"=="17" goto APPLY_ELECTION
if "%CHOICE%"=="0" exit /b 0
echo.
echo  Invalid choice. Press any key to try again.
pause >nul
goto MENU


:: ═══════════════════════════════════════════════════════════════════════════
:: 1 — START REGISTRY SERVER
:: ═══════════════════════════════════════════════════════════════════════════
:START_REGISTRY
cls
echo.
echo  ============================================
echo   ARK CITIZEN REGISTRY SERVER
echo  ============================================
echo.
echo  Starting server...
echo.
echo  Once started, share this address with citizens:
echo      http://YOUR-PC-IP-ADDRESS:5000
echo.
echo  (To find your IP: ipconfig in another window)
echo  Press Ctrl+C in this window to stop the server.
echo  ============================================
echo.
cd /d "%~dp0"
python server.py
if errorlevel 1 (
    echo.
    echo  [!] Server stopped with an error.
    echo  If Python was not found, run option 11 (First-Time Setup).
    echo.
)
pause
goto MENU


:: ═══════════════════════════════════════════════════════════════════════════
:: 2 — START ELECTION SERVER
:: ═══════════════════════════════════════════════════════════════════════════
:START_ELECTION
cls
echo.
echo  ============================================================
echo   NOTE: The Node.js Election Server is NO LONGER REQUIRED
echo  ============================================================
echo.
echo  Elections now run directly in the Flask registry server.
echo.
echo  To manage elections:
echo    1. Start the Registry Server (option 1)
echo    2. Open http://YOUR-IP:5000/admin in your browser
echo    3. Click "Start Election" to open voting for residents
echo.
echo  The /admin panel lets you start/stop elections and
echo  see all registered charities.
echo.
pause
goto MENU

:START_ELECTION_NODE_LEGACY
cls
echo.
echo  ==========================================
echo   ARKOLOGY ELECTION SERVER  (port 3000) [LEGACY]
echo  ==========================================
echo.

if not exist "%~dp0election" (
    echo  [ERROR] The 'election' folder was not found in:
    echo    %~dp0
    echo  Run option 12 (Setup Election) first.
    echo.
    pause
    goto MENU
)

cd /d "%~dp0election"

where node >nul 2>&1
if %errorlevel% NEQ 0 (
    echo  [ERROR] Node.js not found. Run option 12 (Setup Election) first.
    echo.
    pause
    goto MENU
)

if not exist "node_modules" (
    echo  [ERROR] Dependencies not installed.
    echo  Run option 12 (Setup Election) first.
    echo.
    pause
    goto MENU
)

if not exist "dist\index.html" (
    echo  [ERROR] Frontend not built yet.
    echo  Run option 12 (Setup Election) first.
    echo.
    pause
    goto MENU
)

echo  [OK] Node.js:
node --version
echo.

for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /r "IPv4.*[0-9][0-9]*\.[0-9]"') do (
    set RAW=%%a
    goto :gotip
)
:gotip
set IP=%RAW: =%

echo  -----------------------------------------------
echo   LOCAL:    http://localhost:3000
echo   NETWORK:  http://%IP%:3000
echo   ADMIN:    http://localhost:3000/admin
echo  -----------------------------------------------
echo.
echo  Keep this window open while the election runs.
echo  Press Ctrl+C to stop the server.
echo.

node --experimental-sqlite server.js

echo.
echo  Election server stopped.
pause
goto MENU


:: ═══════════════════════════════════════════════════════════════════════════
:: 3 — START ALL SERVERS
:: ═══════════════════════════════════════════════════════════════════════════
:START_ALL
cls
echo.
echo  ==========================================
echo   ARKOLOGY — Start All Servers
echo  ==========================================
echo.
echo  Starting Citizen Registry (Flask, port 5000)...
start "Ark Registry" cmd /c "%~dp0START_REGISTRY.bat"
timeout /t 3 /nobreak >nul

echo  Starting Election Portal (Node, port 3000)...
if not exist "%~dp0election\dist\" (
    echo  [WARN] Election not built yet. Run option 12 (Setup Election) first.
    echo         Skipping election server.
) else (
    start "Ark Election" cmd /c "%~dp0election\START.bat"
)

echo.
echo  Starting Caddy HTTPS proxy...
where caddy >nul 2>&1
if %errorlevel% NEQ 0 (
    echo  [WARN] Caddy not found in PATH. Skipping HTTPS proxy.
    echo         Install Caddy or run without HTTPS for local dev.
) else (
    start "Ark Caddy" cmd /c "%~dp0START_CADDY.bat"
)

echo.
echo  Servers starting in separate windows.
echo  Close this window or press any key to return to menu.
echo.
pause
goto MENU


:: ═══════════════════════════════════════════════════════════════════════════
:: 4 — MONTHLY WORKFLOW
:: ═══════════════════════════════════════════════════════════════════════════
:MONTHLY
cls
echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║                ARK MONTHLY WORKFLOW                         ║
echo  ║                                                              ║
echo  ║  SCHEDULE:                                                   ║
echo  ║    1st of month — UBI + Charity payments go out              ║
echo  ║    10th of month — Taxes owed are applied                    ║
echo  ║                                                              ║
echo  ║  STEP 1 — CHECK_BCH_BALANCE  (run on the 1st)               ║
echo  ║           Fetches wallet balance + BCH rate, computes A19.   ║
echo  ║           Writes new A19 to the spreadsheet.                 ║
echo  ║                                                              ║
echo  ║  STEP 2 — CHARITY_PAYMENTS  (run on the 1st) *** FIRST ***  ║
echo  ║           Calculates each charity's budget from ratings.     ║
echo  ║           Run BEFORE UBI so charity funds are reserved.      ║
echo  ║                                                              ║
echo  ║  STEP 3 — SEND_UBI_LIVE.bat  (run on the 1st)               ║
echo  ║           Sends BCH to residents with positive net * A19.    ║
echo  ║           Only pays residents with BCH + checked references. ║
echo  ║           This step actually moves money.                    ║
echo  ║                                                              ║
echo  ║  STEP 4 — SEND_UBI_LIVE.bat  (run on the 1st)               ║
echo  ║           Sends live BCH to all eligible residents,          ║
echo  ║           charities, and gov employees. Once per month.      ║
echo  ║                                                              ║
echo  ║  You will be asked to confirm each step before it runs.     ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.
echo  Make sure Ark_Database_v6-1.xlsx is CLOSED in Excel.
echo.

cd /d "%~dp0"

echo  ────────────────────────────────────────────────────────────
echo   STEP 1 / 4 — Check BCH balance and update A19  (1st)
echo  ────────────────────────────────────────────────────────────
set /p C1=  Run Step 1? (Y/N): 
if /I "%C1%"=="Y" (
    echo.
    python CHECK_BCH_BALANCE.py
    echo.
) else (
    echo  Skipped Step 1.
)

echo  ────────────────────────────────────────────────────────────
echo   STEP 2 / 4 — Calculate charity budgets  (1st)  [BEFORE UBI]
echo  ────────────────────────────────────────────────────────────
echo.
echo  Charity funds come from charity taxes collected from residents.
echo  Run this BEFORE sending UBI so the charity budgets are set first.
echo.
set /p C2=  Run Step 2? (Y/N): 
if /I "%C2%"=="Y" (
    echo.
    python CHARITY_PAYMENTS.py
    echo.
) else (
    echo  Skipped Step 2.
)

echo  ────────────────────────────────────────────────────────────
echo   STEP 3 / 4 — Send UBI + Charity + Employee payments  (1st)
echo  ────────────────────────────────────────────────────────────
echo.
echo  First, a DRY RUN preview of who will be paid:
echo.
python send_ubi.py
echo.
echo  *** WARNING: Next step sends REAL BCH. Only run ONCE per month. ***
echo  Make sure Electron Cash is open with your wallet unlocked.
echo.
set /p C3=  Run SEND_UBI_LIVE.bat now? (Y/N): 
if /I "%C3%"=="Y" (
    call SEND_UBI_LIVE.bat
    echo.
) else (
    echo  Skipped Step 3. No BCH sent.
)

echo  ────────────────────────────────────────────────────────────
echo   STEP 4 / 4 — Apply monthly taxes + A19  (10th)
echo  ────────────────────────────────────────────────────────────
echo.
echo  First, a PREVIEW of what will change:
echo.
python monthly_tasks.py
echo.
set /p C4=  Apply these changes? (Y/N): 
if /I "%C4%"=="Y" (
    python monthly_tasks.py --apply
    echo.
) else (
    echo  Skipped Step 4.
)

echo.
echo  Monthly workflow complete.
echo.
pause
goto MENU


:: ═══════════════════════════════════════════════════════════════════════════
:: 5 — UBI PREVIEW
:: ═══════════════════════════════════════════════════════════════════════════
:UBI_PREVIEW
cls
echo.
echo  ==========================================
echo   ARK UBI SENDER — DRY RUN PREVIEW
echo  ==========================================
echo.
echo  This shows who will be paid and how much.
echo  No transactions will be sent.
echo.
cd /d "%~dp0"
python send_ubi.py
echo.
pause
goto MENU


:: ═══════════════════════════════════════════════════════════════════════════
:: 6 — CHECK CIVIC BCH BALANCE
:: ═══════════════════════════════════════════════════════════════════════════
:CHECK_CIVIC_BCH
cls
echo.
echo  ==========================================
echo   ARK CIVIC BCH BALANCE CHECK
echo  ==========================================
echo.
cd /d "%~dp0"
python CHECK_BCH_BALANCE.py
echo.
pause
goto MENU


:: ═══════════════════════════════════════════════════════════════════════════
:: 7 — CHECK BOND BCH BALANCE
:: ═══════════════════════════════════════════════════════════════════════════
:CHECK_BOND_BCH
cls
echo.
echo  ==========================================
echo   ARK BOND WALLET — BCH Balance Check
echo  ==========================================
echo.
echo  Bond BCH Address:
echo    bitcoincash:qqd0ywgg5s94lxmxjad7hju3adqy6356nvy6szarp6
echo.
echo  (Separate from the main civic wallet)
echo.
cd /d "%~dp0"
python check_bond_balance.py
if errorlevel 1 (
    echo.
    echo  [!] Could not check balance. Ensure Python + internet access.
)
echo.
pause
goto MENU


:: ═══════════════════════════════════════════════════════════════════════════
:: 8 — SET PASSWORD
:: ═══════════════════════════════════════════════════════════════════════════
:SET_PASSWORD
cls
echo.
echo  ==========================================
echo   ARK — Set Resident Password (Admin Tool)
echo  ==========================================
echo.
echo  Assign a Citizen Portal password to any existing resident.
echo  Passwords are SHA-256 hashed before storage in column C.
echo.
cd /d "%~dp0"
python set_password.py
echo.
pause
goto MENU


:: ═══════════════════════════════════════════════════════════════════════════
:: 9 — SET PIN
:: ═══════════════════════════════════════════════════════════════════════════
:SET_PIN
cls
echo.
echo  ==========================================
echo   ARK — Set Resident PIN (Admin Tool)
echo  ==========================================
echo.
echo  Assign a PIN to any existing resident.
echo  PINs are SHA-256 hashed.
echo.
cd /d "%~dp0"
python set_pin.py
echo.
pause
goto MENU


:: ═══════════════════════════════════════════════════════════════════════════
:: 9 — SEARCH LOGS
:: ═══════════════════════════════════════════════════════════════════════════
:SEARCH_LOGS
cls
echo.
echo  ==========================================
echo   ARK — Audit Log Search
echo  ==========================================
echo.
echo  Searches Update Information Logs (L#)
echo  and Tax Payment Receipts (R#).
echo.
cd /d "%~dp0"
python search_logs.py
echo.
pause
goto MENU


:: ═══════════════════════════════════════════════════════════════════════════
:: 10 — SEARCH RECORDS
:: ═══════════════════════════════════════════════════════════════════════════
:SEARCH_RECORDS
cls
echo.
echo  ==========================================
echo   ARK — Resident Records Search
echo  ==========================================
echo.
cd /d "%~dp0"
python search_records.py
echo.
pause
goto MENU


:: ═══════════════════════════════════════════════════════════════════════════
:: 12 — FIRST-TIME SETUP
:: ═══════════════════════════════════════════════════════════════════════════
:SETUP_FIRST
cls
echo.
echo  ============================================
echo   ARK CITIZEN REGISTRY — First-Time Setup
echo  ============================================
echo.

python --version >nul 2>&1
if errorlevel 1 (
    echo  [!] Python was not found on this computer.
    echo.
    echo  Please download and install Python from:
    echo    https://www.python.org/downloads/
    echo.
    echo  IMPORTANT: During installation, check the box
    echo  "Add Python to PATH" before clicking Install.
    echo.
    pause
    goto MENU
)

echo  [OK] Python found:
python --version
echo.
echo  Installing required packages...
echo.
pip install openpyxl --quiet
if errorlevel 1 (
    echo  [!] pip install failed. Try: python -m pip install openpyxl
) else (
    echo  [OK] openpyxl installed.
)
echo.
echo  Setup complete! You can now run option 1 to start the server.
echo.
pause
goto MENU


:: ═══════════════════════════════════════════════════════════════════════════
:: 12 — SETUP ELECTION
:: ═══════════════════════════════════════════════════════════════════════════
:SETUP_ELECTION
cls
echo.
echo  ==========================================
echo   ARKOLOGY ELECTION SYSTEM — SETUP
echo  ==========================================
echo.

where node >nul 2>&1
if %errorlevel% EQU 0 goto :SE_NODE_FOUND

echo  Node.js not found. Attempting install via winget...
echo.
winget install OpenJS.NodeJS.LTS --silent --accept-source-agreements --accept-package-agreements
if %errorlevel% EQU 0 (
    echo  [OK] Node.js installed via winget.
    for /f "delims=" %%i in ('powershell -NoProfile -Command "[Environment]::GetEnvironmentVariable(\"PATH\",\"Machine\")"') do set "PATH=%%i;%PATH%"
    goto :SE_NODE_FOUND
)

echo  [!] Could not auto-install Node.js.
echo  Please install from: https://nodejs.org/
echo.
pause
goto MENU

:SE_NODE_FOUND
echo  [OK] Node.js:
node --version
echo.

cd /d "%~dp0election"

echo  Installing npm dependencies...
if exist node_modules (
    echo  node_modules exists, running npm install...
) else (
    echo  Fresh install...
)
call npm install
if errorlevel 1 (
    echo  [!] npm install failed.
    pause
    goto MENU
)
echo  [OK] Dependencies installed.
echo.

echo  Building frontend (clean build)...
if exist dist rmdir /s /q dist
call npm run build
if errorlevel 1 (
    echo  [ERROR] Build failed.
    pause
    goto MENU
)
echo  [OK] Frontend built successfully.
echo.
echo  Election setup complete!
echo  Start with option 2 (Start All Servers).
echo.
pause
goto MENU


:: ═══════════════════════════════════════════════════════════════════════════
:: 13 — DIAGNOSE ELECTION
:: ═══════════════════════════════════════════════════════════════════════════
:DIAGNOSE_ELECTION
cls
echo.
echo  ==========================================
echo   ELECTION PORTAL DIAGNOSTICS
echo  ==========================================
echo.

cd /d "%~dp0election"

echo  [1] Checking Node.js...
where node >nul 2>&1
if %errorlevel% NEQ 0 (
    echo  [FAIL] Node.js not found. Run option 11 first.
) else (
    echo  [OK] Node.js:
    node --version
)
echo.

echo  [2] Checking election\dist\index.html...
if exist dist\index.html (
    echo  [OK] dist\index.html exists.
) else (
    echo  [FAIL] dist\index.html missing! Run option 11 (Setup Election).
)
echo.

echo  [3] Checking if Node server is running on port 3000...
powershell -NoProfile -Command "if((Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue)){Write-Host '  [OK] Port 3000 is listening.'}else{Write-Host '  [FAIL] Port 3000 NOT listening. Start servers first.'}"
echo.

echo  [4] Checking if Flask server is running on port 5000...
powershell -NoProfile -Command "if((Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue)){Write-Host '  [OK] Port 5000 is listening.'}else{Write-Host '  [FAIL] Port 5000 NOT listening. Start servers first.'}"
echo.

echo  [5] Checking election\.env...
if exist .env (
    echo  [OK] .env exists.
    type .env
) else (
    echo  [WARN] No .env file (optional).
)
echo.
pause
goto MENU


:: ═══════════════════════════════════════════════════════════════════════════
:: 14 — FIX CADDY HTTPS
:: ═══════════════════════════════════════════════════════════════════════════
:FIX_CADDY
cls
echo.
echo  ============================================================
echo   CADDY HTTPS CERTIFICATE TROUBLESHOOTER
echo  ============================================================
echo.
echo  The error "HTTP 404 - No such authorization" from Let's Encrypt
echo  means Caddy could not complete the ACME HTTP-01 challenge.
echo.
echo  Common causes:
echo    1. Port 80 is NOT forwarded on your router
echo    2. Port 80 is blocked by Windows Firewall
echo    3. Your DNS A record points to the wrong IP
echo    4. DNS hasn't fully propagated (wait 24 hours)
echo.
echo  ────────────────────────────────────────────────────────────
echo   Your current public IP:
echo  ────────────────────────────────────────────────────────────

cd /d "%~dp0"
powershell -NoProfile -Command "try { (Invoke-WebRequest -Uri 'https://api.ipify.org' -TimeoutSec 5 -UseBasicParsing).Content } catch { 'Could not determine public IP.' }"
echo.
echo.
echo  ────────────────────────────────────────────────────────────
echo   DNS lookup for arkology.org:
echo  ────────────────────────────────────────────────────────────
nslookup arkology.org 2>nul || echo  Could not resolve arkology.org
echo.
echo  If the IP above does NOT match your public IP, update your
echo  DNS A record at your domain registrar.
echo.
echo  ────────────────────────────────────────────────────────────
echo   Port 80 check:
echo  ────────────────────────────────────────────────────────────
powershell -NoProfile -Command "if((Get-NetTCPConnection -LocalPort 80 -ErrorAction SilentlyContinue)){Write-Host '  [OK] Port 80 is listening.'}else{Write-Host '  [WARN] Port 80 is NOT listening.'}"
echo.
pause
goto MENU


:: ═══════════════════════════════════════════════════════════════════════════
:: 15 — START CADDY (standalone)
:: ═══════════════════════════════════════════════════════════════════════════
:START_CADDY_STANDALONE
cls
echo.
echo  ============================================
echo   ARK — Caddy HTTPS Proxy for arkology.org
echo  ============================================
echo.
echo  Press Ctrl+C to stop Caddy.
echo  ============================================
echo.
cd /d "%~dp0"
caddy run --config Caddyfile
echo.
echo  Caddy stopped.
pause
goto MENU


:: ═══════════════════════════════════════════════════════════════════════════
:: 17 — APPLY ELECTION RESULTS
:: ═══════════════════════════════════════════════════════════════════════════
:APPLY_ELECTION
cls
echo.
echo  ╔══════════════════════════════════════════════════════════════╗
echo  ║                APPLY ELECTION RESULTS                       ║
echo  ║                                                              ║
echo  ║  This tool:                                                  ║
echo  ║    • Sets the top 6 Hexarchy candidates in Gov Employees     ║
echo  ║    • Writes charity ratings to the spreadsheet               ║
echo  ║    • Saves results for the "Previous Election" page          ║
echo  ║    • Optionally resets votes for the next cycle              ║
echo  ║                                                              ║
echo  ║  REQUIREMENTS:                                               ║
echo  ║    • Close Ark_Database_v6-1.xlsx in Excel first             ║
echo  ║    • Election server must have been running                  ║
echo  ╚══════════════════════════════════════════════════════════════╝
echo.
echo  Make sure Ark_Database_v6-1.xlsx is CLOSED in Excel before continuing.
echo.
set /p APPLYOK=  Ready? Press Y to continue, N to cancel: 
if /I NOT "%APPLYOK%"=="Y" goto MENU
echo.
cd /d "%~dp0"
python Apply_Election.py
echo.
pause
goto MENU
