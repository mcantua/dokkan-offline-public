#!/usr/bin/env python3
"""Generate the original App Installer icon. Python standard library only.

An opaque blue square is masked by iOS. A white download arrow above a tray
keeps the icon legible at small sizes. No external artwork, fonts or telemetry.
Run from any directory; PNG output is written beside this script.
"""
from pathlib import Path
import math
import struct
import zlib

ROOT = Path(__file__).resolve().parent

def png_chunk(kind, content):
    return struct.pack('>I', len(content)) + kind + content + struct.pack('>I', zlib.crc32(kind + content) & 0xffffffff)

def rect_distance(x, y, left, top, right, bottom, radius=0):
    center_x, center_y = (left + right) / 2, (top + bottom) / 2
    half_x, half_y = (right - left) / 2 - radius, (bottom - top) / 2 - radius
    dx, dy = abs(x - center_x) - half_x, abs(y - center_y) - half_y
    return math.hypot(max(dx, 0), max(dy, 0)) + min(max(dx, dy), 0) - radius

def segment_distance(x, y, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    t = max(0, min(1, ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(x - ax - t * dx, y - ay - t * dy)

def draw(size):
    scale = 1024 / size
    rows = bytearray()
    for py in range(size):
        rows.append(0)
        y = (py + 0.5) * scale
        gradient = y / 1024
        background = (round(33 - 15 * gradient), round(130 - 50 * gradient), round(242 - 20 * gradient))
        for px in range(size):
            x = (px + 0.5) * scale
            # Rounded shaft and a triangular arrow head, combined as one mark.
            shaft = rect_distance(x, y, 466, 233, 558, 546, 28)
            # Triangle vertices: (328,470), (696,470), (512,662).
            triangle_inside = 470 <= y <= 662 and abs(x - 512) <= (662 - y) * (184 / 192)
            triangle_edge = min(
                segment_distance(x, y, 328, 470, 696, 470),
                segment_distance(x, y, 696, 470, 512, 662),
                segment_distance(x, y, 512, 662, 328, 470),
            )
            arrow = min(shaft, -triangle_edge if triangle_inside else triangle_edge)
            # Open tray, with a continuous rounded U-shaped stroke.
            tray = min(
                segment_distance(x, y, 292, 656, 292, 758),
                segment_distance(x, y, 292, 758, 732, 758),
                segment_distance(x, y, 732, 758, 732, 656),
            ) - 29
            coverage = max(0, min(1, 0.5 - min(arrow, tray) / scale))
            rows.extend(round(channel + (255 - channel) * coverage) for channel in background)
    header = struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0)
    return b'\x89PNG\r\n\x1a\n' + png_chunk(b'IHDR', header) + png_chunk(b'IDAT', zlib.compress(rows, 9)) + png_chunk(b'IEND', b'')

if __name__ == '__main__':
    for dimension in (120, 180, 1024):
        (ROOT / f'AppIcon{dimension}.png').write_bytes(draw(dimension))
