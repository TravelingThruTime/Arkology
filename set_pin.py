"""
set_pin.py — Admin utility to set a PIN for any existing resident.
Since PINs are SHA-256 hashed, this is the only way to manually assign one.

Usage:
  python set_pin.py           → interactive prompts
  python set_pin.py 42 1234   → set Res#42's PIN to 1234

The hash is written directly to column C of the Res sheet.
"""
import sys, os, hashlib
EXCEL_FILE = os.path.join(os.path.dirname(__file__), "Ark_Database_v6-1.xlsx")

def hash_pin(p): return hashlib.sha256(p.encode()).hexdigest()

def set_pin(res_id_str, pin_str):
    try:
        import openpyxl
        from openpyxl.styles import Font
    except ImportError:
        print("[ERROR] openpyxl not installed. Run SETUP_FIRST_TIME.bat first.")
        return False

    pin_str = pin_str.strip()
    if not pin_str.isdigit() or len(pin_str) != 4:
        print(f"[ERROR] PIN must be exactly 4 digits. Got: {pin_str!r}")
        return False
    try:
        res_id = int(res_id_str)
    except:
        print(f"[ERROR] Resident ID must be a number. Got: {res_id_str!r}")
        return False

    if not os.path.exists(EXCEL_FILE):
        print(f"[ERROR] Excel file not found: {EXCEL_FILE}")
        return False

    wb = openpyxl.load_workbook(EXCEL_FILE)
    ws = wb["Res"]

    for row in ws.iter_rows(min_row=2):
        db_res = row[1].value  # column B = index 1
        if not isinstance(db_res, (int, float)): continue
        if int(db_res) != res_id: continue
        first = row[5].value or ""   # F
        last  = row[4].value or ""   # E
        alive = row[15].value        # P

        pin_cell = row[91]  # CN = col 92 = index 91  # column C
        old_val = pin_cell.value  # CN hash
        pin_cell.value = hash_pin(pin_str)
        pin_cell.font = Font(name="Arial", size=10)

        try:
            wb.save(EXCEL_FILE)
        except PermissionError:
            print("[ERROR] Close Excel first, then try again.")
            return False

        status = "Active" if alive == 1 else "Inactive"
        print(f"[OK] PIN set for Resident #{res_id} — {first} {last} ({status})")
        print(f"     Old hash : {old_val or '(none)'}")
        print(f"     New hash : {hash_pin(pin_str)[:20]}...  [SHA-256 of {pin_str}]")
        return True

    print(f"[ERROR] Resident #{res_id} not found in database.")
    return False

if __name__ == "__main__":
    print()
    print("=" * 50)
    print("  ARK — Set Resident PIN")
    print("=" * 50)
    print()

    if len(sys.argv) == 3:
        res_id_str = sys.argv[1]
        pin_str    = sys.argv[2]
    else:
        res_id_str = input("  Resident Number : ").strip()
        pin_str    = input("  New 4-digit PIN : ").strip()

    print()
    set_pin(res_id_str, pin_str)
    print()
    input("Press Enter to close...")
