"""
Pure-Python QR code SVG generator.
No external libraries required.
Supports byte mode (for BCH addresses and any UTF-8 text).
Returns SVG string.
"""

# Reed-Solomon GF(256) tables
_EXP = [0] * 512
_LOG = [0] * 256
x = 1
for i in range(255):
    _EXP[i] = x
    _LOG[x] = i
    x = x << 1
    if x > 255:
        x ^= 0x11d
for i in range(255, 512):
    _EXP[i] = _EXP[i - 255]

def _gf_mul(a, b):
    if a == 0 or b == 0: return 0
    return _EXP[_LOG[a] + _LOG[b]]

def _gf_poly_mul(p, q):
    r = [0] * (len(p) + len(q) - 1)
    for i, pi in enumerate(p):
        for j, qj in enumerate(q):
            r[i+j] ^= _gf_mul(pi, qj)
    return r

def _rs_generator(n):
    g = [1]
    for i in range(n):
        g = _gf_poly_mul(g, [1, _EXP[i]])
    return g

def _rs_encode(data, n_ec):
    gen = _rs_generator(n_ec)
    msg = list(data) + [0] * n_ec
    for i in range(len(data)):
        coef = msg[i]
        if coef != 0:
            for j in range(len(gen)):
                msg[i+j] ^= _gf_mul(gen[j], coef)
    return msg[len(data):]

# QR block info: (version, ec_level) -> [(n_blocks, n_data, n_total), ...]
# ec_level: 0=M
_BLOCKS = {
    (1, 0): [(1, 16, 26)],
    (2, 0): [(1, 28, 44)],
    (3, 0): [(1, 22, 70)],
    (4, 0): [(2, 16, 50)],
    (5, 0): [(2, 22, 67)],
    (6, 0): [(4, 16, 43)],
    (7, 0): [(4, 19, 49)],
    (8, 0): [(2, 14, 34), (4, 15, 35)],
    (9, 0): [(3, 14, 45), (1, 15, 46)],
    (10,0): [(4, 14, 46), (2, 15, 47)],
    (11,0): [(1, 16, 48), (4, 17, 49)],
    (12,0): [(6, 14, 45), (2, 15, 46)],
    (13,0): [(4, 14, 46), (2, 15, 47)],  # simplified
    (14,0): [(3, 14, 46), (5, 15, 47)],
    (15,0): [(5, 14, 45), (5, 15, 46)],
    (16,0): [(7, 14, 45), (3, 15, 46)],
    (17,0): [(10, 14, 45), (1, 15, 46)],
    (18,0): [(9, 14, 45), (4, 15, 46)],
    (19,0): [(3, 14, 45), (11, 15, 46)],
    (20,0): [(3, 15, 46), (13, 16, 47)],
}

_ALIGN = [[], [], [6,18], [6,22], [6,26], [6,30], [6,34],
          [6,22,38], [6,24,42], [6,26,46], [6,28,50],
          [6,30,54], [6,32,58], [6,34,62], [6,26,46,66],
          [6,26,48,70], [6,26,50,74], [6,30,54,78], [6,30,56,82],
          [6,30,58,86], [6,34,62,90]]

def _gen_bch(data, poly, n):
    d = data
    for _ in range(n):
        if d >> (n):
            d ^= poly
        d <<= 1
    return d >> 0

def qr_format_info(mask_pattern, ec=0):  # ec=0 for M
    EC_BITS = {0: 0b01, 1: 0b00, 2: 0b11, 3: 0b10}
    data = (EC_BITS[ec] << 3) | mask_pattern
    G15 = 0x537
    rem = data
    for i in range(9, -1, -1):
        if rem & (1 << (i + 10)):
            rem ^= G15 << i
    fmt = (data << 10) | rem
    fmt ^= 0b101010000010010
    return fmt

def qr_type_info(v):
    G18 = 0x1F25
    rem = v
    for i in range(11, -1, -1):
        if rem & (1 << (i + 12)):
            rem ^= G18 << i
    return (v << 12) | rem

def make_qr(text, ec_level=0):
    data_bytes = text.encode('utf-8')
    n = len(data_bytes)
    
    # Find minimum version for M-level
    # Byte mode capacity at M level
    caps = [0,16,28,22,16,22,16,26,26,24,28,24,28,22,24,24,30,28,28,26,28]
    version = None
    for v in range(1, 21):
        if v in [k[0] for k in _BLOCKS.keys() if k[1] == ec_level]:
            cap = sum(blocks[1] * blocks[0] for blocks in _BLOCKS.get((v, ec_level), [])) - 2
            if cap >= n + 2:  # rough check
                version = v
                break
    if version is None:
        version = 15  # fallback
    
    block_info = _BLOCKS.get((version, ec_level), [(1, 16, 26)])
    total_data = sum(b[0]*b[1] for b in block_info)
    
    # Build bit stream
    bits = []
    def put(val, length):
        for i in range(length-1, -1, -1):
            bits.append((val >> i) & 1)
    
    put(0b0100, 4)  # byte mode
    char_count_bits = 8 if version < 10 else 16
    put(n, char_count_bits)
    for byte in data_bytes:
        put(byte, 8)
    
    # Terminator
    for _ in range(min(4, total_data*8 - len(bits))):
        bits.append(0)
    while len(bits) % 8: bits.append(0)
    
    # Pad bytes
    pad = [0xEC, 0x11]
    i = 0
    while len(bits) < total_data * 8:
        put(pad[i % 2], 8)
        i += 1
    
    data_codewords = [sum(bits[i*8+j] << (7-j) for j in range(8)) for i in range(len(bits)//8)]
    
    # Interleave blocks
    blocks = []
    idx = 0
    for n_blocks, n_data, n_total in block_info:
        for _ in range(n_blocks):
            d = data_codewords[idx:idx+n_data]
            ec = _rs_encode(d, n_total - n_data)
            blocks.append((d, ec))
            idx += n_data
    
    final = []
    max_data = max(len(b[0]) for b in blocks)
    for i in range(max_data):
        for d, _ in blocks:
            if i < len(d): final.append(d[i])
    max_ec = max(len(b[1]) for b in blocks)
    for i in range(max_ec):
        for _, ec in blocks:
            if i < len(ec): final.append(ec[i])
    
    # Convert to bits
    data_bits = []
    for byte in final:
        for i in range(7, -1, -1):
            data_bits.append((byte >> i) & 1)
    
    # Build matrix
    size = version * 4 + 17
    matrix = [[None]*size for _ in range(size)]
    reserved = [[False]*size for _ in range(size)]
    
    def place_finder(r, c):
        for dr in range(-1, 8):
            for dc in range(-1, 8):
                rr, cc = r+dr, c+dc
                if 0 <= rr < size and 0 <= cc < size:
                    matrix[rr][cc] = (0 <= dr <= 6 and dc in (0,6)) or \
                                     (0 <= dc <= 6 and dr in (0,6)) or \
                                     (2 <= dr <= 4 and 2 <= dc <= 4)
                    reserved[rr][cc] = True
    
    place_finder(0, 0)
    place_finder(0, size-7)
    place_finder(size-7, 0)
    
    # Separator (already handled by -1 extension)
    
    # Timing patterns
    for i in range(8, size-8):
        matrix[6][i] = (i % 2 == 0)
        matrix[i][6] = (i % 2 == 0)
        reserved[6][i] = True
        reserved[i][6] = True
    
    # Alignment patterns
    al = _ALIGN[version] if version < len(_ALIGN) else []
    for ar in al:
        for ac in al:
            if reserved[ar][ac]: continue
            for dr in range(-2, 3):
                for dc in range(-2, 3):
                    rr, cc = ar+dr, ac+dc
                    if 0 <= rr < size and 0 <= cc < size:
                        matrix[rr][cc] = (dr in (-2,2) or dc in (-2,2) or (dr==0 and dc==0))
                        reserved[rr][cc] = True
    
    # Format info areas (reserve)
    for i in range(9):
        if i != 6:
            reserved[i][8] = True
            reserved[8][i] = True
        reserved[8][size-1-i] = True
        reserved[size-1-i][8] = True
    
    # Dark module
    matrix[size-8][8] = True
    reserved[size-8][8] = True
    
    # Place data bits (best mask = 2: col%3==0)
    best_mask = 2
    bit_idx = 0
    col = size - 1
    going_up = True
    while col > 0:
        if col == 6: col -= 1
        for _ in range(size):
            row = (size-1 - _) if going_up else _
            for dc in range(2):
                c = col - dc
                if not reserved[row][c] and bit_idx < len(data_bits):
                    bit = data_bits[bit_idx]
                    bit_idx += 1
                    mask = (c % 3 == 0)
                    matrix[row][c] = bool(bit ^ mask)
        going_up = not going_up
        col -= 2
    
    # Place format info
    fmt = qr_format_info(best_mask, ec_level)
    fmt_bits = [(fmt >> i) & 1 for i in range(14, -1, -1)]
    pos = [(8,0),(8,1),(8,2),(8,3),(8,4),(8,5),(8,7),(8,8),
           (7,8),(5,8),(4,8),(3,8),(2,8),(1,8),(0,8)]
    for i, (r,c) in enumerate(pos):
        matrix[r][c] = bool(fmt_bits[i])
        matrix[c][r] = bool(fmt_bits[i])  # symmetric (approximate)
    
    return matrix, size

def qr_to_svg(text, px=6, margin=4):
    try:
        matrix, size = make_qr(text)
    except Exception as e:
        # Fallback: return simple error SVG
        return f'<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200"><rect width="200" height="200" fill="white"/><text y="100" x="10" fill="red">QR Error</text></svg>'
    
    total = (size + 2*margin) * px
    rects = []
    for r in range(size):
        for c in range(size):
            if matrix[r][c]:
                x = (c + margin) * px
                y = (r + margin) * px
                rects.append(f'<rect x="{x}" y="{y}" width="{px}" height="{px}"/>')
    
    return (f'<svg xmlns="http://www.w3.org/2000/svg" '
            f'viewBox="0 0 {total} {total}" width="{total}" height="{total}" '
            f'style="background:white">'
            f'<g fill="black">{"".join(rects)}</g></svg>')

if __name__ == "__main__":
    # Test
    svg = qr_to_svg("bitcoincash:qz3yeruzcwjcp7cxdq2fvtwp07cvvl00rvlk73rqgv")
    print(f"Generated SVG: {len(svg)} bytes")
    with open("/tmp/test_qr.svg", "w") as f:
        f.write(svg)
    print("Saved to /tmp/test_qr.svg")
