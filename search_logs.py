"""
search_logs.py — Search Update Logs and Tax Receipts
=====================================================
Searches all .txt files in both audit folders.
Can search by: L# ID, R# ID, Resident#, name, date, field, reason, amount.

Usage:
  python search_logs.py                → interactive prompt
  python search_logs.py "L000042"      → find log by ID
  python search_logs.py "res 16"       → find all logs for Resident 16
  python search_logs.py "Marcus"       → find by name
  python search_logs.py "2026-02"      → find by month
"""
import os, sys, re, glob

BASE_DIR    = os.path.dirname(__file__)
LOG_DIR     = os.path.join(BASE_DIR, "Update_Information_Logs")
RECEIPT_DIR = os.path.join(BASE_DIR, "Tax_Payment_Receipts")

SEP = "─" * 60

def search_folder(folder, label, query_lower, show_content=True):
    files = sorted(glob.glob(os.path.join(folder, "*.txt")))
    hits = []
    for fpath in files:
        fname = os.path.basename(fpath)
        try:
            with open(fpath, encoding="utf-8") as f:
                content = f.read()
        except: continue
        # Search filename + content
        if query_lower in fname.lower() or query_lower in content.lower():
            hits.append((fname, fpath, content))
    
    if not hits:
        print(f"  [{label}] No matches.")
        return 0
    
    print(f"\n  [{label}] {len(hits)} match(es):\n")
    for fname, fpath, content in hits:
        print(f"  {'─'*56}")
        print(f"  FILE: {fname}")
        if show_content:
            print()
            for line in content.strip().splitlines():
                print(f"    {line}")
        print()
    return len(hits)

def interactive():
    print()
    print("=" * 60)
    print("  ARK AUDIT SEARCH")
    print("  Searches Update Logs (L#) and Tax Receipts (R#)")
    print("=" * 60)
    print()
    print("  Search tips:")
    print("    L000001          → find specific log by ID")
    print("    R000002          → find specific receipt by ID")
    print("    16               → find all records for Resident #16")
    print("    Sarah            → find by name")
    print("    2026-02          → find records from February 2026")
    print("    address          → find all address change logs")
    print("    wealth           → find all wealth updates")
    print()

    while True:
        try:
            query = input("  Search (or press Enter to exit): ").strip()
        except (KeyboardInterrupt, EOFError):
            break
        if not query:
            break

        q = query.lower()
        print()
        total_logs     = search_folder(LOG_DIR,     "UPDATE LOGS",    q)
        total_receipts = search_folder(RECEIPT_DIR, "TAX RECEIPTS",   q)
        total = total_logs + total_receipts
        print(f"  ── Total: {total} result(s) for '{query}' ──────────────────\n")

    print("\n  Goodbye.\n")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        query = " ".join(sys.argv[1:]).strip()
        print(f"\n  Searching for: '{query}'\n")
        q = query.lower()
        t1 = search_folder(LOG_DIR,     "UPDATE LOGS",  q)
        t2 = search_folder(RECEIPT_DIR, "TAX RECEIPTS", q)
        print(f"\n  Total: {t1+t2} result(s)\n")
    else:
        interactive()
