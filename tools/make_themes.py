#!/usr/bin/env python3
"""Derive the Meniscus themes from the wallpapers.

For every image in themes/wallpapers this writes
  package/effects/meniscus/contents/ui/themes.js      palettes used by the overlay
  package/effects/meniscus/contents/images/<id>.jpg    small previews for the theme picker
  package/color-schemes/Meniscus<Name>.colors          matching Plasma colour scheme

The wallpapers themselves are only read, never rewritten.
Needs Pillow. `--sheet FILE` additionally renders a contact sheet of all palettes.
"""
from __future__ import annotations

import argparse
import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
WALLPAPERS = ROOT / "themes" / "wallpapers"
UI_DIR = ROOT / "package" / "effects" / "meniscus" / "contents" / "ui"
IMAGE_DIR = ROOT / "package" / "effects" / "meniscus" / "contents" / "images"
SCHEME_DIR = ROOT / "package" / "color-schemes"

# Display order in the theme picker.
ORDER = ["amethyst", "tide", "glacier", "aurora", "ember", "canyon",
         "tarn", "dune", "fern", "forest", "mist", "alpine"]

# Set by hand where the picture cannot decide: greyscale photographs carry no hue,
# and plates should follow what the picture is about rather than its shadows.
CURATED = {
    "tide": {"pop_hue": 295, "pop": 0.085},
    "tarn": {"hue": 232},
    "fern": {"hue": 165},
    "forest": {"hue": 200, "body": 0.012, "pop_hue": 190, "pop": 0.065},
    "mist": {"dark": True, "mono": True},
    "alpine": {"mono": True},
}


# ---- OKLab / OKLCH -------------------------------------------------------

def _to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _to_gamma(c: float) -> float:
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def rgb_to_oklab(rgb: tuple[float, float, float]) -> tuple[float, float, float]:
    r, g, b = (_to_linear(c) for c in rgb)
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    return (0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s)


def _oklab_to_linear(L: float, a: float, b: float) -> tuple[float, float, float]:
    l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
    return (4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)


def oklch(L: float, C: float, h: float) -> tuple[int, int, int]:
    """OKLCH to 8-bit sRGB; chroma is reduced until the colour fits the gamut."""
    rad = math.radians(h)
    for _ in range(40):
        lin = _oklab_to_linear(L, C * math.cos(rad), C * math.sin(rad))
        if all(-0.0005 <= c <= 1.0005 for c in lin):
            break
        C *= 0.94
    return tuple(round(255 * _to_gamma(min(1.0, max(0.0, c)))) for c in lin)


def to_lch(rgb: tuple[int, int, int]) -> tuple[float, float, float]:
    L, a, b = rgb_to_oklab(tuple(c / 255 for c in rgb))
    return L, math.hypot(a, b), math.degrees(math.atan2(b, a)) % 360


def hex_of(rgb: tuple[int, int, int]) -> str:
    return "#%02x%02x%02x" % rgb


# ---- palette extraction --------------------------------------------------

def hue_distance(a: float, b: float) -> float:
    d = abs(a - b) % 360
    return min(d, 360 - d)


def analyse(path: Path) -> dict:
    image = Image.open(path).convert("RGB")
    small = image.resize((128, 72), Image.Resampling.LANCZOS)
    data = small.tobytes()
    pixels = [to_lch((data[i], data[i + 1], data[i + 2])) for i in range(0, len(data), 3)]

    lightness = sum(p[0] for p in pixels) / len(pixels)
    chroma = sum(p[1] for p in pixels) / len(pixels)

    bins = 36
    area = [0.0] * bins        # how much of the picture a hue covers
    vivid = [0.0] * bins       # how loudly a hue speaks
    peak = [0.0] * bins
    for L, C, h in pixels:
        if C < 0.02:
            continue
        i = int(h / 360 * bins) % bins
        area[i] += C
        vivid[i] += C * C * (0.4 + L)
        peak[i] = max(peak[i], C)

    def smooth(values: list[float]) -> list[float]:
        return [0.25 * values[i - 1] + 0.5 * values[i] + 0.25 * values[(i + 1) % bins]
                for i in range(bins)]

    def centre(values: list[float], i: int) -> float:
        # Weighted mean hue of the peak and its neighbours.
        x = y = 0.0
        for j in (i - 1, i, i + 1):
            angle = math.radians((j % bins + 0.5) * 360 / bins)
            x += values[j % bins] * math.cos(angle)
            y += values[j % bins] * math.sin(angle)
        return math.degrees(math.atan2(y, x)) % 360

    area_s, vivid_s = smooth(area), smooth(vivid)
    if max(area_s) <= 0:
        return {"lightness": lightness, "chroma": chroma, "primary": 250.0, "secondary": 250.0, "pop": 0.0}

    first = max(range(bins), key=lambda i: area_s[i])
    primary = centre(area_s, first)
    rivals = [i for i in range(bins) if hue_distance((i + 0.5) * 360 / bins, primary) > 55]
    second = max(rivals, key=lambda i: vivid_s[i])
    if vivid_s[second] >= 0.10 * max(vivid_s):
        secondary, pop = centre(vivid_s, second), max(peak[second], peak[second - 1], peak[(second + 1) % bins])
    else:
        best = max(range(bins), key=lambda i: vivid_s[i])
        secondary, pop = centre(vivid_s, best), peak[best]
    return {"lightness": lightness, "chroma": chroma, "primary": primary, "secondary": secondary, "pop": pop}


def build_theme(theme_id: str, stats: dict) -> dict:
    hand = CURATED.get(theme_id, {})
    dark = hand.get("dark", stats["lightness"] < 0.60)
    hue = hand.get("hue", stats["primary"])
    pop_hue = hand.get("pop_hue", stats["secondary"])
    body = hand.get("body", min(0.045, 0.012 + stats["chroma"] * 0.45))
    pop = hand.get("pop", min(0.17, max(0.085, stats["pop"] * 1.05)))
    if hand.get("mono"):
        # No colour at all: the accent is simply the far end of the grey scale.
        body, pop, pop_hue = 0.004, 0.006, hue
    if dark:
        plate = oklch(0.23, body, hue)
        ink = oklch(0.965, 0.008, hue)
        accent = oklch(0.90 if hand.get("mono") else 0.80, pop, pop_hue)
        accent_ink = oklch(0.20, min(0.03, pop), pop_hue)
    else:
        plate = oklch(0.955, body * 0.45, hue)
        ink = oklch(0.22, 0.02, hue)
        accent = oklch(0.34 if hand.get("mono") else 0.52, pop, pop_hue)
        accent_ink = oklch(0.985, 0.005, pop_hue)
    return {
        "id": theme_id,
        "name": theme_id.capitalize(),
        "dark": dark,
        "hue": hue,
        "body": body,
        "popHue": pop_hue,
        "plate": plate,
        "ink": ink,
        "accent": accent,
        "accentInk": accent_ink,
    }


# ---- Plasma colour scheme ------------------------------------------------

def scheme_text(theme: dict) -> str:
    hue, body, accent = theme["hue"], theme["body"], theme["accent"]
    if theme["dark"]:
        levels = {"View": 0.185, "Window": 0.225, "Button": 0.275, "Header": 0.205,
                  "Tooltip": 0.25, "Complementary": 0.165}
        step, text_l, dim_l = 0.022, 0.955, 0.70
        signal = {"Link": (0.78, 0.11, 245), "Visited": (0.76, 0.11, 310), "Negative": (0.70, 0.17, 25),
                  "Neutral": (0.80, 0.13, 75), "Positive": (0.78, 0.15, 150)}
    else:
        levels = {"View": 0.99, "Window": 0.955, "Button": 0.975, "Header": 0.93,
                  "Tooltip": 0.985, "Complementary": 0.26}
        step, text_l, dim_l = -0.02, 0.24, 0.50
        signal = {"Link": (0.48, 0.14, 250), "Visited": (0.46, 0.14, 310), "Negative": (0.52, 0.19, 27),
                  "Neutral": (0.58, 0.13, 65), "Positive": (0.52, 0.14, 150)}

    def rgb(color: tuple[int, int, int]) -> str:
        return "%d,%d,%d" % color

    def group(name: str, background, alternate, text, dim) -> list[str]:
        lines = [f"[Colors:{name}]",
                 f"BackgroundAlternate={rgb(alternate)}",
                 f"BackgroundNormal={rgb(background)}",
                 f"DecorationFocus={rgb(accent)}",
                 f"DecorationHover={rgb(accent)}",
                 f"ForegroundActive={rgb(accent)}",
                 f"ForegroundInactive={rgb(dim)}"]
        for key in ("Link", "Negative", "Neutral"):
            lines.append(f"Foreground{key}={rgb(oklch(*signal[key]))}")
        lines.append(f"ForegroundNormal={rgb(text)}")
        lines.append(f"ForegroundPositive={rgb(oklch(*signal['Positive']))}")
        lines.append(f"ForegroundVisited={rgb(oklch(*signal['Visited']))}")
        lines.append("")
        return lines

    text, dim = oklch(text_l, 0.008, hue), oklch(dim_l, 0.014, hue)
    out = [
        "[ColorEffects:Disabled]", "Color=56,56,56", "ColorAmount=0", "ColorEffect=0",
        "ContrastAmount=0.65", "ContrastEffect=1", "IntensityAmount=0.1", "IntensityEffect=2", "",
        "[ColorEffects:Inactive]", "ChangeSelectionColor=true", "Color=112,111,110", "ColorAmount=0.025",
        "ColorEffect=2", "ContrastAmount=0.1", "ContrastEffect=2", "Enable=false",
        "IntensityAmount=0", "IntensityEffect=0", "",
    ]
    for name in ("Button", "Complementary", "Header", "Tooltip", "View", "Window"):
        level = levels[name]
        inverted = name == "Complementary" and not theme["dark"]
        group_text = oklch(0.955, 0.008, hue) if inverted else text
        group_dim = oklch(0.70, 0.014, hue) if inverted else dim
        alternate = oklch(level + (0.022 if inverted else step), body, hue)
        out += group(name, oklch(level, body, hue), alternate, group_text, group_dim)
        if name == "Header":
            calm = levels["Window"]
            block = group("Header", oklch(calm, body, hue), oklch(calm + step, body, hue), text, dim)
            block[0] = "[Colors:Header][Inactive]"
            out += block
    selection = group("Selection", accent, oklch(to_lch(accent)[0] - 0.06, to_lch(accent)[1], theme["popHue"]),
                      theme["accentInk"], theme["accentInk"])
    for i, line in enumerate(selection):
        if line.startswith(("ForegroundActive=", "ForegroundLink=", "ForegroundVisited=",
                            "ForegroundNegative=", "ForegroundNeutral=", "ForegroundPositive=")):
            selection[i] = line.split("=")[0] + "=" + rgb(theme["accentInk"])
    out += selection
    title = oklch(levels["Header"], body, hue)
    out += [
        "[General]", f"ColorScheme=Meniscus{theme['name']}", f"Name=Meniscus {theme['name']}",
        "shadeSortColumn=true", "",
        "[KDE]", "contrast=4", "",
        "[WM]",
        f"activeBackground={rgb(title)}", f"activeBlend={rgb(text)}", f"activeForeground={rgb(text)}",
        f"inactiveBackground={rgb(oklch(levels['Window'], body, hue))}", f"inactiveBlend={rgb(dim)}",
        f"inactiveForeground={rgb(dim)}", "",
    ]
    return "\n".join(out)


# ---- output --------------------------------------------------------------

def themes_js(themes: list[dict]) -> str:
    rows = []
    for t in themes:
        rows.append('    { id: "%s", name: "%s", dark: %s, plate: "%s", ink: "%s", accent: "%s", accentInk: "%s" }'
                    % (t["id"], t["name"], "true" if t["dark"] else "false", hex_of(t["plate"]),
                       hex_of(t["ink"]), hex_of(t["accent"]), hex_of(t["accentInk"])))
    return (".pragma library\n\n"
            "// Generated by tools/make_themes.py from themes/wallpapers; do not edit.\n"
            "var list = [\n" + ",\n".join(rows) + "\n]\n\n"
            "function find(id) {\n"
            "    for (let i = 0; i < list.length; ++i) {\n"
            "        if (list[i].id === id)\n"
            "            return list[i]\n"
            "    }\n"
            "    return list[0]\n"
            "}\n")


def contact_sheet(themes: list[dict], target: Path) -> None:
    cell_w, cell_h, cols = 480, 300, 4
    rows = math.ceil(len(themes) / cols)
    sheet = Image.new("RGB", (cols * cell_w, rows * cell_h), (20, 20, 20))
    draw = ImageDraw.Draw(sheet)
    for i, t in enumerate(themes):
        x, y = (i % cols) * cell_w, (i // cols) * cell_h
        thumb = Image.open(WALLPAPERS / f"{t['id']}.jpg").convert("RGB").resize((cell_w, 270))
        sheet.paste(thumb, (x, y))
        draw.rounded_rectangle((x + 60, y + 90, x + 420, y + 190), 24, fill=t["plate"])
        draw.text((x + 84, y + 108), f"{t['name']}  {'dark' if t['dark'] else 'light'}", fill=t["ink"])
        draw.text((x + 84, y + 128), f"plate {hex_of(t['plate'])} accent {hex_of(t['accent'])}", fill=t["ink"])
        draw.rounded_rectangle((x + 84, y + 152, x + 244, y + 176), 12, fill=t["accent"])
        draw.text((x + 100, y + 158), "selected", fill=t["accentInk"])
        draw.rectangle((x, y + 270, x + cell_w // 2, y + cell_h), fill=t["plate"])
        draw.rectangle((x + cell_w // 2, y + 270, x + cell_w, y + cell_h), fill=t["accent"])
    target.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(target, quality=88)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--sheet", type=Path, help="also write a contact sheet of the palettes")
    args = parser.parse_args()

    found = {p.stem: p for p in sorted(WALLPAPERS.glob("*.jpg"))}
    ids = [i for i in ORDER if i in found] + sorted(set(found) - set(ORDER))
    themes = []
    for theme_id in ids:
        stats = analyse(found[theme_id])
        theme = build_theme(theme_id, stats)
        themes.append(theme)
        print("%-9s L=%.2f C=%.3f hue=%3.0f pop=%3.0f (%.3f) %s plate=%s accent=%s"
              % (theme_id, stats["lightness"], stats["chroma"], stats["primary"], stats["secondary"],
                 stats["pop"], "dark " if theme["dark"] else "light", hex_of(theme["plate"]), hex_of(theme["accent"])))

    UI_DIR.mkdir(parents=True, exist_ok=True)
    IMAGE_DIR.mkdir(parents=True, exist_ok=True)
    SCHEME_DIR.mkdir(parents=True, exist_ok=True)
    (UI_DIR / "themes.js").write_text(themes_js(themes), encoding="utf-8", newline="\n")
    for theme in themes:
        preview = Image.open(found[theme["id"]]).convert("RGB").resize((256, 144), Image.Resampling.LANCZOS)
        preview.save(IMAGE_DIR / f"{theme['id']}.jpg", quality=84, optimize=True)
        (SCHEME_DIR / f"Meniscus{theme['name']}.colors").write_text(scheme_text(theme), encoding="utf-8", newline="\n")
    if args.sheet:
        contact_sheet(themes, args.sheet)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
