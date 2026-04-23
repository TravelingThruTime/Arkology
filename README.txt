ARK CITIZEN REGISTRY — Setup Guide
====================================

WHAT IS IN THIS FOLDER
-----------------------
  ARK.bat                       Master menu (run this)
  Ark_Database_v6-1.xlsx        Your database (all 13 sheets)
  server.py                     The web server
  templates/index.html          Main page (registration, taxes, 8 buttons)
  templates/bonds.html          Bond purchase + status portal
  templates/calendar.html       Community calendar
  templates/charities.html      Charity viewer
  templates/election_vote.html  Election voting page
  Caddyfile                     HTTPS config for arkology.org
  CHECK_BCH_BALANCE.py          A19 updater (wallet check)
  send_ubi.py                   Live UBI payments
  CHARITY_PAYMENTS.py           Charity budget calculator
  monthly_tasks.py              Tax accumulation
  START_CADDY.bat               Standalone Caddy launcher
  START_REGISTRY.bat            Standalone Flask launcher
  README.txt                    This file


══════════════════════════════════════════════════════
PART 1 — RUNNING ON YOUR LOCAL NETWORK
══════════════════════════════════════════════════════

ONE-TIME SETUP
--------------
1. Double-click SETUP_FIRST_TIME.bat
   - If Python is not installed, it opens the download page.
     IMPORTANT: During Python install, check "Add Python to PATH"
   - Run SETUP_FIRST_TIME.bat again after installing Python.

RUNNING LOCALLY
---------------
1. Double-click START_SERVER.bat — leave the black window open.
2. Same computer:    http://localhost:5000
3. Same Wi-Fi:       Open Command Prompt, type: ipconfig
                     Look for "IPv4 Address" (e.g. 192.168.1.50)
                     Citizens visit: http://192.168.1.50:5000


══════════════════════════════════════════════════════
PART 2 — LAUNCHING ON arkology.org
══════════════════════════════════════════════════════

Four steps to get https://arkology.org working publicly.

STEP A — Find Your Public IP Address
--------------------------------------
Go to: https://whatismyipaddress.com
Write down the IPv4 address shown (e.g. 203.0.113.42).

NOTE: Home internet IPs can change. See Step E to handle this.

STEP B — Point arkology.org DNS to Your Machine
-------------------------------------------------
Log in to wherever you bought arkology.org (Namecheap, GoDaddy, etc.)
Find "DNS Management" and set these records:

  Type: A    Host: @      Value: [your IP from Step A]   TTL: 300
  Type: A    Host: www    Value: [your IP from Step A]   TTL: 300

Check propagation at: https://dnschecker.org
(can take a few minutes to a few hours)

STEP C — Forward Ports on Your Router
---------------------------------------
Your router must send web traffic to your PC.

1. Find your router admin page — usually http://192.168.1.1
   (check the label on your router for the URL and password)
2. Find "Port Forwarding" or "Virtual Servers"
3. Create two rules pointing to your PC's local IP:

   External Port 80  → Internal Port 80  → Your PC's local IP
   External Port 443 → Internal Port 443 → Your PC's local IP

Windows will ask to allow the new server through Firewall — click Allow.

STEP D — Download Caddy and Start It
--------------------------------------
Caddy is a free web server that handles HTTPS automatically,
getting a free security certificate so https:// works.

1. Download: https://caddyserver.com/download
   Choose: Platform = Windows, Architecture = amd64
2. Rename the downloaded file to: caddy.exe
3. Move caddy.exe into this folder (same folder as server.py)

4. Run TWO windows at once:
   Window 1:  START_SERVER.bat        (the Python/Flask app)
   Window 2:  START_HTTPS_CADDY.bat   (the HTTPS front-end)

5. Wait 30-60 seconds for Caddy to get your certificate.
6. Visit https://arkology.org — done!

STEP E (Optional) — Handle Changing IP Addresses
--------------------------------------------------
Home internet IPs often change. If yours does, the site goes down.
The easiest fix is Cloudflare:

1. Sign up free at https://cloudflare.com
2. Add arkology.org to Cloudflare and follow their DNS import steps
3. Enable "Cloudflare Tunnel" (free) — this eliminates port
   forwarding entirely and works even when your IP changes.
   Guide: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/


══════════════════════════════════════════════════════
PART 3 — DATA AND TAX NOTES
══════════════════════════════════════════════════════

WHAT GETS SAVED PER SIGNUP
----------------------------
Each citizen is appended to the Res sheet with:
  Res# (auto, starts at 20, skips multiples of 50)
  Name, email, address, year born, sex
  Password (hashed — not readable)
  Children birth dates (as Excel date serials)
  Sq-ft for up to 2 properties
  Mortgage date and first-home flag
  Net worth in $M
  BCH wallet, jury, deputy, disability, shared housing, spouse ID
  Calculated: Net Tax, Wealth Tax, Wealth Rate, Maternity months, Child count

HOW NET TAX IS CALCULATED
---------------------------
BENEFITS (what community pays you):
  UBI          — under 18: $0 | 18-64: $300 | 65+: $450 /month
  Disability   — $1,200/month (replaces UBI)
  Deputy pay   — $480/month
  Maternity    — $600/month per child under 3 years old
  Mort Assist  — first-home $75k frame rebate spread over 30yr mortgage

TAXES (what you owe):
  Property Tax — Landlord Tax v6 exponential curve
                 Zero below 600 sqft; up to $16,000/mo at 16,000+ sqft
  Child Tax    — 1 child $30 | 2 $60 | 3 $120 | 4 $180 | 5 $240 /month
  Wealth Tax   — Rate = 1 + LOG10(Wealth $M), capped at 22%/yr
                 e.g. $1M=1%/yr, $10M=2%/yr, $100M=3%/yr

Net Tax = Total Taxes - Total Benefits
  Negative = community pays you that amount each month
  Positive = you owe that amount each month

IMPORTANT: Do not have Ark_Database_v6-1.xlsx open in Excel
while someone is signing up. Close it first, or the save
will fail and show an error to the registrant.




══════════════════════════════════════════════════════
PART 4 — MONTHLY WORKFLOW
══════════════════════════════════════════════════════

PAYMENT SCHEDULE
  1st of month  — UBI + Charity payments go out
  10th of month — Taxes owed are applied

Use ARK.bat → option 4 (Monthly Workflow). It walks through
all four steps in order, asking for confirmation at each one.

──────────────────────────────────────────────────────
THE FOUR STEPS (run on the 1st of the month)
──────────────────────────────────────────────────────

STEP 1 — BCH Balance Check + A19 Update  (run on 1st)
  Script: CHECK_BCH_BALANCE.py
  What it does:
    - Fetches the live BCH/USD exchange rate from CoinGecko
    - Checks the Ark community wallet balance via Blockchair
    - Computes A19 (UBI scaling factor) based on wallet capacity
    - A19 can go to 0% if wallet is empty
    - Only counts residents WITH a BCH address
    - Writes the new A19 to cell A19 in the spreadsheet

STEP 2 — Send UBI Payments (Live BCH)  (run on 1st)
  Script: send_ubi.py --live
  What it does:
    - Reads all residents with positive net AND a BCH address
    - SKIPS residents whose references have NOT been checked (col CT≠1)
    - Sends BCH to qualifying residents via Electron Cash CLI
  IMPORTANT: Only run ONCE per month. Electron Cash must be open.

STEP 3 — Charity Budget Payments  (run on 1st)
  Script: CHARITY_PAYMENTS.py
  What it does:
    - Reads charity ratings from the most recent election
    - Calculates: charity_budget = (rating / sum_ratings) * total_market
    - Writes budgets to the Charity sheet
    - Elections determine the charity ratings

STEP 4 — Apply Taxes Owed  (run on 10th)
  Script: monthly_tasks.py --apply
  What it does:
    - Computes each resident's net monthly payment
    - Adds taxes owed to running balance in column CS
    - Prints before/after summary

──────────────────────────────────────────────────────
BEFORE RUNNING
──────────────────────────────────────────────────────
  1. Close Ark_Database_v6-1.xlsx in Excel
  2. Verify Electron Cash is open with the Ark wallet loaded
  3. Run ARK.bat as Administrator (for Caddy HTTPS)


══════════════════════════════════════════════════════
PART 5 — ELECTIONS
══════════════════════════════════════════════════════

Elections determine charity funding. To start an election:
  1. Open Ark_Database_v6-1.xlsx → Elections sheet
  2. Set cell N2 to 1 (activates the election)
  3. Residents vote via the Election button on the main page
  4. When voting is complete, set N2 back to 0
  5. Run CHARITY_PAYMENTS.py to recalculate budgets


══════════════════════════════════════════════════════
TROUBLESHOOTING
══════════════════════════════════════════════════════

"Python not found"                Run ARK.bat option 11 (First-Time Setup)
"Cannot save Excel file"          Close Excel first
"Page not loading locally"        Check Flask is running (ARK.bat option 1)
"arkology.org not loading"        Check DNS, ports forwarded, Caddy running
"Caddy certificate error"         DNS must propagate first — wait a few hours
"Port already in use"             Restart computer and try again
"Caddy window not opening"        Run ARK.bat option 15 (Start Caddy standalone)
