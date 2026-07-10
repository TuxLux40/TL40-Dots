#!/usr/bin/env python3
"""Write G915 profile effects to volatile write buffers. Run after Solaar starts."""
import os, time, select, sys

HIDRAW = "/dev/hidraw14"

def send_recv(fd, feat, fn_byte, data=b"", timeout=8):
    msg = bytearray(20)
    msg[0] = 0x11; msg[1] = 0xFF; msg[2] = feat; msg[3] = fn_byte
    for i, b in enumerate(data):
        if 4 + i < 20: msg[4 + i] = b
    os.write(fd, bytes(msg))
    deadline = time.time() + timeout
    while time.time() < deadline:
        ready = select.select([fd], [], [], 0.3)
        if not ready[0]: continue
        r = os.read(fd, 64)
        if len(r) < 4: continue
        if r[0] == 0x11 and r[2] == feat: return r, 0
        if len(r) >= 5 and r[0] == 0x11 and r[2] == 0xFF and r[3] == feat: return r, 0
        if r[0] == 0x10 and r[3] == feat and r[2] == 0x8F: return r, r[5]
    return None, 0xFF

def write_sector(fd, sector, led_slot0, led_slot1):
    p = bytearray(254)
    p[0:16]  = bytes.fromhex('01000000000000000000000000ffffff')
    p[16:32] = bytes.fromhex('ffffffffffffffffffffffff3c002c01')
    if sector == 1:
        p[32:48] = bytes.fromhex('8002003a8002003b8002003c8002003d')
        p[48:64] = bytes.fromhex('8002003e900dff01900dff02900dff03')
    else:
        p[32:48] = bytes.fromhex('8002001e8002001f8002002080020021')
        p[48:64] = bytes.fromhex('80020022900dff01900dff02900dff03')
    for i in range(64, 160):  p[i] = 0xFF
    for i in range(160, 208): p[i] = 0x00
    p[208:219] = led_slot0
    p[219:230] = led_slot1

    FEAT_OBP = 0x15
    r, err = send_recv(fd, FEAT_OBP, 0x60, bytes([0, sector, 0, 0, len(p)>>8, len(p)&0xFF]))
    if err: print(f"  StartWrite ERR {err:#04x}"); return False
    for off in range(0, len(p), 16):
        r, err = send_recv(fd, FEAT_OBP, 0x70, bytes(p[off:off+16]))
        if err: print(f"  WriteData @{off} ERR"); return False
    r, err = send_recv(fd, FEAT_OBP, 0x80, timeout=20)
    print(f"  Commit: {'OK' if not err else f'ERR {err:#04x}'}")
    return not err

WHITE  = bytes([0x01, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
ICY_BREATHE = bytes([0x02, 0x00, 0xBC, 0xFF, 0x00, 0x00, 0xB8, 0x0B, 0x64, 0x00, 0x00])

fd = os.open(HIDRAW, os.O_RDWR)
FEAT_OBP = 0x15

print("Profile 1 → white static...")
write_sector(fd, 1, WHITE, WHITE)

print("Profile 2 → icy breathe...")
write_sector(fd, 2, ICY_BREATHE, ICY_BREATHE)

# Activate profile 1
send_recv(fd, FEAT_OBP, 0x30, bytes([0, 1]))
print("Done — profile 1 active")
os.close(fd)
