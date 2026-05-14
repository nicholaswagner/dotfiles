#!/usr/bin/env python3
"""
build-theme — generates a random dark theme from Radix color scales.

Usage:
  build-theme                        # fully random
  build-theme --accent violet        # fix accent, randomize the rest
  build-theme --stdout               # print to stdout instead of writing .env

Writes theme variables to $DOTFILES/.env in dotenv format (no `export`).
Reload your shell, or `set -a; source "$DOTFILES/.env"; set +a` to apply.
"""

import colorsys
import os
import re
import sys
import random
import argparse

DOTFILES = os.environ.get("DOTFILES", os.path.expanduser("~/.dotfiles"))
sys.path.insert(0, os.path.join(DOTFILES, "config"))

from darkcolors import SCALES, ACCENT_SCALES, NATURAL_PAIRINGS, SEMANTIC_POOLS, DARK_FG_SCALES

_HEX_RE = re.compile(r'^#[0-9a-fA-F]{6}$')


# ---------------------------------------------------------------------------
# Custom hex scale generation
# ---------------------------------------------------------------------------

def _hex_to_hls(hex_color: str) -> tuple[float, float, float]:
    """Return (hue_deg 0–360, lightness 0–1, saturation 0–1)."""
    h = hex_color.lstrip('#')
    r, g, b = (int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
    hue, lum, sat = colorsys.rgb_to_hls(r, g, b)
    return hue * 360, lum, sat


def _hls_to_hex(hue_deg: float, lum: float, sat: float) -> str:
    """Convert HLS back to a hex string, clamping values to [0, 1]."""
    r, g, b = colorsys.hls_to_rgb(
        hue_deg / 360.0,
        max(0.0, min(1.0, lum)),
        max(0.0, min(1.0, sat)),
    )
    return '#{:02x}{:02x}{:02x}'.format(round(r * 255), round(g * 255), round(b * 255))


def _hue_to_grey(hue_deg: float) -> str:
    """Pick the natural Radix grey pairing for a hue (mirrors NATURAL_PAIRINGS logic)."""
    h = hue_deg % 360
    if 200 <= h < 250:          return "SLATE"   # blue / sky / cyan
    if 250 <= h < 345 or h < 15: return "MAUVE"  # violet / purple / pink / red
    if 15 <= h < 65:            return "SAND"    # orange / yellow / amber
    if 65 <= h < 85:            return "OLIVE"   # lime / yellow-green
    if 85 <= h < 175:           return "SAGE"    # green / teal / jade / mint
    if 175 <= h < 200:          return "SLATE"   # cyan-green → slate
    return "GRAY"


def _needs_dark_fg(hex_color: str) -> bool:
    """True when the color is bright enough that step-9 needs dark foreground text."""
    h = hex_color.lstrip('#')
    r, g, b = (int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
    def lin(c): return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    lum = 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
    return lum > 0.35


def generate_dark_scale(hex_color: str) -> dict[int, str]:
    """Build a 12-step Radix-style dark scale from an arbitrary hex color.

    Step roles match theme-notes.md:
      1–2   app / subtle backgrounds
      3–5   component backgrounds (normal / hover / active)
      6–8   borders (subtle / interactive / hover)
      9     solid background — the input color at peak chroma
      10    hovered solid background
      11    low-contrast text
      12    high-contrast text
    """
    h, l9, s9 = _hex_to_hls(hex_color)

    # Steps 1–8: dark backgrounds → border range
    # Lightness grows from 7 % toward (l9 − gap); saturation from ~30 % of s9 upward.
    L_START = 0.07
    S_START = max(0.08, s9 * 0.30)
    L8 = min(l9 - 0.04, max(L_START + 0.25, l9 - 0.08))
    S8 = min(1.0, s9 * 0.85)

    POWER = 1.25  # slight ease-in so steps cluster toward the dark end

    scale: dict[int, str] = {}
    for step in range(1, 9):
        t = ((step - 1) / 7.0) ** POWER
        scale[step] = _hls_to_hex(h, L_START + (L8 - L_START) * t, S_START + (S8 - S_START) * t)

    # Step 9: the input (peak chroma / solid background)
    scale[9] = '#' + hex_color.lstrip('#').lower()

    # Step 10: hover of step 9 — slightly brighter
    scale[10] = _hls_to_hex(h, min(1.0, l9 + 0.06), s9)

    # Step 11: low-contrast text
    l11 = min(0.82, max(0.68, l9 + 0.16))
    scale[11] = _hls_to_hex(h, l11, min(1.0, s9 * 0.90))

    # Step 12: high-contrast text
    l12 = min(0.94, max(0.85, l9 + 0.32))
    scale[12] = _hls_to_hex(h, l12, min(1.0, s9 * 0.65))

    return scale


def pick_semantic(role: str, accent: str) -> str:
    pool = [s for s in SEMANTIC_POOLS[role] if s != accent]
    return random.choice(pool)


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def build_output(
    accent: str,
    grey: str,
    error: str,
    warning: str,
    success: str,
    info: str,
    custom_accent_scale: dict[int, str] | None = None,
    accent_dark_fg: bool = False,
) -> str:
    def scale_lines(prefix: str, scale_name: str, override: dict[int, str] | None = None) -> list[str]:
        data = override if override is not None else SCALES[scale_name]
        return [f'{prefix}_{step}="{data[step]}"' for step in range(1, 13)]

    # Determine which semantic roles need dark foreground text on step 9
    named_scales = {"error": error, "warning": warning, "success": success, "info": info}
    dark_fg_roles = [role for role, scale in named_scales.items() if scale in DARK_FG_SCALES]
    if accent_dark_fg or (custom_accent_scale is None and accent in DARK_FG_SCALES):
        dark_fg_roles.insert(0, "accent")
    dark_fg_str = " ".join(dark_fg_roles)

    blocks = [
        "# Theme Meta",
        f'THEME_TYPE="dark"',
        f'THEME_GREY_SCALE_NAME="{grey.lower()}"',
        f'THEME_ACCENT_SCALE_NAME="{accent.lower()}"',
        f'THEME_ERROR_SCALE_NAME="{error.lower()}"',
        f'THEME_WARNING_SCALE_NAME="{warning.lower()}"',
        f'THEME_SUCCESS_SCALE_NAME="{success.lower()}"',
        f'THEME_INFO_SCALE_NAME="{info.lower()}"',
        f'THEME_USE_DARK="{dark_fg_str}"',
        "",
        "# Theme Accent scale",
        *scale_lines("THEME_ACCENT", accent, override=custom_accent_scale),
        "",
        "# Theme Grey scale",
        *scale_lines("THEME_GREY", grey),
        "",
        "# Theme Error scale",
        *scale_lines("THEME_ERROR", error),
        "",
        "# Theme Warning scale",
        *scale_lines("THEME_WARNING", warning),
        "",
        "# Theme Success scale",
        *scale_lines("THEME_SUCCESS", success),
        "",
        "# Theme Info scale",
        *scale_lines("THEME_INFO", info),
        "",
    ]

    return "\n".join(blocks)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="Generate a random dark shell theme.")
    parser.add_argument("--accent",  help="Fix the accent scale (e.g. violet)")
    parser.add_argument("--grey",    help="Fix the grey scale (e.g. mauve)")
    parser.add_argument("--error",   help="Fix the error scale")
    parser.add_argument("--warning", help="Fix the warning scale")
    parser.add_argument("--success", help="Fix the success scale")
    parser.add_argument("--info",    help="Fix the info scale")
    parser.add_argument("--stdout",  action="store_true",
                        help="Print to stdout instead of writing $DOTFILES/.env")
    args = parser.parse_args()

    raw_accent = args.accent or ""
    custom_accent_scale: dict[int, str] | None = None
    accent_dark_fg = False

    if raw_accent.startswith('#'):
        if not _HEX_RE.match(raw_accent):
            parser.error(f"Invalid hex color {raw_accent!r} — expected #rrggbb")
        accent = raw_accent.lower()
        custom_accent_scale = generate_dark_scale(raw_accent)
        accent_dark_fg = _needs_dark_fg(raw_accent)
        hue_deg, _, _ = _hex_to_hls(raw_accent)
        grey = (args.grey.upper() if args.grey else _hue_to_grey(hue_deg))
    else:
        accent = (raw_accent.upper() if raw_accent else random.choice(ACCENT_SCALES))
        grey   = (args.grey.upper()  if args.grey  else NATURAL_PAIRINGS.get(accent, "GRAY"))

    error   = (args.error.upper()   if args.error   else pick_semantic("ERROR",   accent))
    warning = (args.warning.upper() if args.warning else pick_semantic("WARNING", accent))
    success = (args.success.upper() if args.success else pick_semantic("SUCCESS", accent))
    info    = (args.info.upper()    if args.info    else pick_semantic("INFO",    accent))

    output = build_output(accent, grey, error, warning, success, info,
                          custom_accent_scale=custom_accent_scale,
                          accent_dark_fg=accent_dark_fg)

    if args.stdout:
        print(output)
    else:
        env_path = os.path.join(DOTFILES, ".env")
        with open(env_path, "w") as f:
            f.write(output)
        print(f"[build-theme] Wrote {env_path}", file=sys.stderr)
        print(f'[build-theme] Reload: set -a; source "$DOTFILES/.env"; set +a', file=sys.stderr)


if __name__ == "__main__":
    main()
