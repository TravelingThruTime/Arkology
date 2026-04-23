"""
search_records.py — Search Update Logs and Tax Receipts by keyword, Res#, date, or ID.
Run standalone or via SEARCH_RECORDS.bat
"""
import os, sys, re, glob

BASE   = os.path.dirname(os.path.abspath(__file__))
LOGDIR = os.path.join(BASE, "Update_Information_Logs")
RECDIR = os.path.join(BASE, "Tax_Payment_Receipts")

def search_dir(folder, kind, term):
    files = sorted(glob.glob(os.path.join(folder, "*.txt")))
    hits  = []
    term_lower = term.lower()
    for path in files:
        try:
            with open(path, encoding="utf-8") as f:
                text = f.read()
        except: continue
        if term_lower in text.lower() or term_lower in os.path.basename(path).lower():
            # Pull summary line for display
            fname  = os.path.basename(path)
            id_match = re.search(r'(L-\d{8}-\d+|R-\d{8}-\d+|TXR-[\w-]+)', fname + text)
            uid    = id_match.group(1) if id_match else fname
            res_m  = re.search(r'Resident #\s*:\s*(\S+)', text)
            date_m = re.search(r'Date(?:/Time)?\s*:\s*(\S+ ?\S*)', text)
            name_m = re.search(r'Name\s*:\s*(.+)', text)
            hits.append({
                "file":  fname,
                "path":  path,
                "uid":   uid,
                "res":   res_m.group(1) if res_m else "?",
                "date":  date_m.group(1) if date_m else "?",
                "name":  (name_m.group(1).strip() if name_m else "?")[:28],
                "text":  text,
            })
    return hits

def show_results(hits, kind):
    if not hits:
        print(f"  No {kind} found.")
        return
    print(f"\n  Found {len(hits)} {kind}(s):\n")
    for i, h in enumerate(hits, 1):
        print(f"  [{i}] {h['uid']}")
        print(f"      Res #{h['res']}  |  {h['date']}  |  {h['name']}")
        print(f"      File: {h['file']}")
        print()
    print(f"  Enter a number to view full record, or press Enter to skip: ", end="")
    choice = input().strip()
    if choice.isdigit():
        idx = int(choice) - 1
        if 0 <= idx < len(hits):
            print(f"\n{'='*62}")
            print(hits[idx]["text"])
            print(f"{'='*62}\n")

def main():
    print()
    print("=" * 62)
    print("  ARK RECORDS SEARCH")
    print("  Searches: Update Logs (L#) and Tax Receipts (R#)")
    print("=" * 62)
    print()
    print("  Search by anything: Resident #, name, date, L#/R# ID")
    print("  Examples:  342       Petra       2026-02    L-20260201")
    print()

    args = sys.argv[1:]
    if args:
        term = " ".join(args)
        print(f"  Searching for: {term!r}")
    else:
        term = input("  Search term: ").strip()
    if not term:
        print("  No term given."); input("\nPress Enter to close..."); return

    print()
    print(f"  ── Update Logs ─────────────────────────────────────────")
    log_hits = search_dir(LOGDIR, "update log", term)
    show_results(log_hits, "update log")

    print(f"  ── Tax Receipts ────────────────────────────────────────")
    rec_hits = search_dir(RECDIR, "receipt", term)
    show_results(rec_hits, "receipt")

    total = len(log_hits) + len(rec_hits)
    print(f"  Total results: {total}")
    input("\nPress Enter to close...")

if __name__ == "__main__":
    main()
