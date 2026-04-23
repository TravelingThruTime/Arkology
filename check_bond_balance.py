"""Check BCH balance for the Ark Bond Fund wallet."""
import urllib.request, json

ADDR = "bitcoincash:qqd0ywgg5s94lxmxjad7hju3adqy6356nvy6szarp6"

try:
    req = urllib.request.Request(
        f"https://blockchair.com/bitcoin-cash/dashboards/address/{ADDR}?limit=1",
        headers={"User-Agent": "ArkBonds/1.0"})
    with urllib.request.urlopen(req, timeout=15) as r:
        data = json.loads(r.read())
    info = data.get("data", {}).get(ADDR, {}).get("address", {})
    bal = info.get("balance", 0) / 1e8
    txns = info.get("transaction_count", 0)
except Exception as e:
    print(f"  [!] Blockchair error: {e}")
    bal, txns = 0, "?"

try:
    req2 = urllib.request.Request(
        "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin-cash&vs_currencies=usd",
        headers={"User-Agent": "ArkBonds/1.0"})
    with urllib.request.urlopen(req2, timeout=10) as r2:
        rate = json.loads(r2.read()).get("bitcoin-cash", {}).get("usd", 0)
except:
    rate = 0

print()
print(f"  Balance : {bal:.8f} BCH")
if rate:
    print(f"  BCH/USD : ${rate:,.2f}")
    print(f"  Value   : ${bal * rate:,.2f} USD")
else:
    print(f"  BCH/USD : (unavailable)")
print(f"  Txns    : {txns}")
print()
