#!/usr/bin/env python3
"""Generate AppIcon.appiconset PNGs for Find My Friends (map + people motif)."""
from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Assets.xcassets" / "AppIcon.appiconset"

SIZES = [
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-1024x1024@1x.png", 1024),
]


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def render(size: int) -> Image.Image:
    s = float(size)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = img.load()
    cx, cy = s * 0.5, s * 0.52
    for y in range(size):
        for x in range(size):
            dx = (x + 0.5 - cx) / (s * 0.65)
            dy = (y + 0.5 - cy) / (s * 0.65)
            r = math.hypot(dx, dy)
            t = min(1.0, r * 1.05)
            # Deep space → accent blue
            rr = int(lerp(11, 90, t))
            gg = int(lerp(15, 140, t))
            bb = int(lerp(27, 255, t))
            px[x, y] = (rr, gg, bb, 255)

    d = ImageDraw.Draw(img)
    # Soft vignette
    for y in range(size):
        for x in range(size):
            dx = (x + 0.5) / s - 0.5
            dy = (y + 0.5) / s - 0.5
            v = 1.0 - 0.22 * (dx * dx + dy * dy) * 4
            r, g, b, a = px[x, y]
            px[x, y] = (int(r * v), int(g * v), int(b * v), a)

    scale = s / 1024.0
    # Map pin (white)
    pin_cx = s * 0.48
    pin_top = s * 0.28
    pin_w = s * 0.22
    pin_h = s * 0.34
    head_r = pin_w * 0.38
    head_cy = pin_top + head_r * 0.9
    d.ellipse(
        (
            pin_cx - head_r,
            head_cy - head_r,
            pin_cx + head_r,
            head_cy + head_r,
        ),
        fill=(255, 255, 255, 255),
    )
    tip_y = pin_top + pin_h
    d.polygon(
        [
            (pin_cx - head_r * 0.55, head_cy + head_r * 0.35),
            (pin_cx + head_r * 0.55, head_cy + head_r * 0.35),
            (pin_cx, tip_y),
        ],
        fill=(255, 255, 255, 255),
    )
    # Inner dot on pin
    inner = head_r * 0.42
    d.ellipse(
        (
            pin_cx - inner,
            head_cy - inner,
            pin_cx + inner,
            head_cy + inner,
        ),
        fill=(60, 120, 255, 255),
    )

    # Two "friend" circles
    def person(px_off: float, py_off: float, rad: float, fill: tuple[int, int, int, int]) -> None:
        d.ellipse(
            (
                pin_cx + px_off - rad,
                head_cy + py_off - rad,
                pin_cx + px_off + rad,
                head_cy + py_off + rad,
            ),
            fill=fill,
        )

    pr = max(3.0, 28 * scale)
    person(s * 0.26, s * 0.08, pr, (255, 255, 255, 230))
    person(s * 0.34, -s * 0.02, pr * 0.92, (180, 230, 255, 240))

    return img


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, dim in SIZES:
        render(dim).save(OUT / name, "PNG")
    contents = {
        "images": [
            {"size": "20x20", "idiom": "iphone", "filename": "Icon-App-20x20@2x.png", "scale": "2x"},
            {"size": "20x20", "idiom": "iphone", "filename": "Icon-App-20x20@3x.png", "scale": "3x"},
            {"size": "29x29", "idiom": "iphone", "filename": "Icon-App-29x29@2x.png", "scale": "2x"},
            {"size": "29x29", "idiom": "iphone", "filename": "Icon-App-29x29@3x.png", "scale": "3x"},
            {"size": "40x40", "idiom": "iphone", "filename": "Icon-App-40x40@2x.png", "scale": "2x"},
            {"size": "40x40", "idiom": "iphone", "filename": "Icon-App-40x40@3x.png", "scale": "3x"},
            {"size": "60x60", "idiom": "iphone", "filename": "Icon-App-60x60@2x.png", "scale": "2x"},
            {"size": "60x60", "idiom": "iphone", "filename": "Icon-App-60x60@3x.png", "scale": "3x"},
            {"size": "1024x1024", "idiom": "ios-marketing", "filename": "Icon-App-1024x1024@1x.png", "scale": "1x"},
        ],
        "info": {"version": 1, "author": "findmyfriends"},
    }
    (OUT / "Contents.json").write_text(json.dumps(contents, indent=2), encoding="utf-8")
    (ROOT / "Assets.xcassets" / "Contents.json").write_text(
        json.dumps({"info": {"version": 1, "author": "findmyfriends"}}, indent=2),
        encoding="utf-8",
    )
    print("Wrote", OUT)


if __name__ == "__main__":
    main()
