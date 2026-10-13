#!/usr/bin/env python3
"""Generate PWA PNG icons without third-party deps."""

from __future__ import annotations

import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "public"


def png(width: int, height: int, pixels: bytes) -> bytes:
    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    raw = b""
    stride = width * 4
    for y in range(height):
        raw += b"\x00" + pixels[y * stride : (y + 1) * stride]
    return b"".join(
        [
            b"\x89PNG\r\n\x1a\n",
            chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)),
            chunk(b"IDAT", zlib.compress(raw, 9)),
            chunk(b"IEND", b""),
        ]
    )


def clamp(v: int) -> int:
    return 0 if v < 0 else 255 if v > 255 else v


def draw(size: int) -> bytes:
    bg = (200, 240, 77, 255)
    ink = (18, 20, 16, 255)
    px = bytearray(size * size * 4)
    r = size * 0.22
    bolt = [
        (0.58, 0.16),
        (0.32, 0.48),
        (0.50, 0.48),
        (0.40, 0.84),
        (0.70, 0.50),
        (0.52, 0.50),
    ]

    def inside_bolt(x: float, y: float) -> bool:
        pts = [(p[0] * size, p[1] * size) for p in bolt]
        odd = False
        j = len(pts) - 1
        for i, (xi, yi) in enumerate(pts):
            xj, yj = pts[j]
            if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi + 1e-9) + xi:
                odd = not odd
            j = i
        return odd

    for y in range(size):
        for x in range(size):
            i = (y * size + x) * 4
            corner = min(x, y, size - 1 - x, size - 1 - y)
            if corner < r * 0.15 and (x < r or y < r or x > size - r or y > size - r):
                # rounded corners via distance to inner rect
                cx = r if x < r else size - r if x > size - r else x
                cy = r if y < r else size - r if y > size - r else y
                dist = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
                if dist > r:
                    px[i : i + 4] = b"\x00\x00\x00\x00"
                    continue
            color = ink if inside_bolt(x + 0.5, y + 0.5) else bg
            px[i : i + 4] = bytes(color)
    return bytes(px)


def main() -> None:
    ROOT.mkdir(exist_ok=True)
    for name, size in [("pwa-192.png", 192), ("pwa-512.png", 512), ("apple-touch-icon.png", 180)]:
        (ROOT / name).write_bytes(png(size, size, draw(size)))
        print("wrote", name)


if __name__ == "__main__":
    main()
