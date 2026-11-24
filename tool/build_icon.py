#!/usr/bin/env python3
"""Génère les icônes Android d'ivHelper (même dessin que lib/ui/iv_logo.dart).

Usage : python3 tool/build_icon.py
Écrit tool/android_icons/mipmap-*/ic_launcher.png et assets/logo.png.
"""
import math
from pathlib import Path
from PIL import Image, ImageDraw

YELLOW = (255, 203, 5, 255)
NAVY = (29, 42, 91, 255)
RED = (229, 57, 53, 255)
WHITE = (255, 255, 255, 255)
SS = 4  # suréchantillonnage


def draw(px: int) -> Image.Image:
    n = px * SS
    k = n / 100
    img = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, n - 1, n - 1], radius=22 * k, fill=YELLOW)

    def line(points, w):
        d.line([(x * k, y * k) for x, y in points], fill=NAVY, width=int(w * k), joint="curve")
        for x, y in (points[0], points[-1]):
            r = w / 2 * k
            d.ellipse([x * k - r, y * k - r, x * k + r, y * k + r], fill=NAVY)

    line([(28, 52), (28, 80)], 14)
    line([(46, 50), (62, 80), (78, 50)], 14)
    cx, cy, r = 28 * k, 27 * k, 14 * k
    box = [cx - r, cy - r, cx + r, cy + r]
    d.pieslice(box, 180, 360, fill=RED)
    d.pieslice(box, 0, 180, fill=WHITE)
    lw = int(3.4 * k)
    d.ellipse(box, outline=NAVY, width=lw)
    d.line([cx - r, cy, cx + r, cy], fill=NAVY, width=lw)
    b = r * 0.36
    d.ellipse([cx - b, cy - b, cx + b, cy + b], fill=WHITE, outline=NAVY, width=int(3 * k))
    return img.resize((px, px), Image.LANCZOS)


def main() -> None:
    root = Path(__file__).resolve().parent
    for name, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        out = root / "android_icons" / f"mipmap-{name}"
        out.mkdir(parents=True, exist_ok=True)
        draw(px).save(out / "ic_launcher.png")
    draw(512).save(root.parent / "assets" / "logo.png")


if __name__ == "__main__":
    main()
