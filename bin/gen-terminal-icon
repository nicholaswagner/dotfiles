#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pillow"]
# ///
"""
gen-terminal-icon — generates a custom Ghostty app icon from THEME_* variables.

Reads THEME_* from the environment (set at shell startup by sourcing $DOTFILES/.env).
Falls back to parsing $DOTFILES/.env directly if vars aren't present.

Configurable via environment variables:
  TERMINAL_ICON                 Text to render on the icon       (default: ">_")
  TERMINAL_ICON_CORNER_RADIUS   Corner radius as 0.0–1.0 fraction of canvas size
                                                                 (default: 0.22)
  TERMINAL_ICON_COLOR           Hex color for the text           (default: THEME_ACCENT_9)
  TERMINAL_ICON_BG1_COLOR       Hex color for gradient start     (default: THEME_ACCENT_1)
  TERMINAL_ICON_BG2_COLOR       Hex color for gradient end       (default: THEME_ACCENT_2)
  TERMINAL_ICON_GLOSS_ALPHA     Gloss overlay max opacity 0.0–1.0 (default: 0.6)
  TERMINAL_ICON_GLOSS_SIZE      Gloss rect size as fraction of canvas (default: 0.85)
  TERMINAL_ICON_SHEEN_ALPHA     Text sheen visibility 0.0–1.0       (default: 1.0)

Usage:
  gen-terminal-icon                  # write to ~/.config/ghostty/Ghostty.icns
  gen-terminal-icon --stdout         # write icns bytes to stdout
  gen-terminal-icon --preview /tmp   # write a single 512x512 PNG for quick preview
  build-theme --accent violet && gen-terminal-icon
"""

import os
import sys
import shutil
import subprocess
import tempfile
import argparse
from pathlib import Path


import math
from PIL import Image, ImageChops, ImageDraw, ImageFont


# ---------------------------------------------------------------------------
# Load theme vars
# ---------------------------------------------------------------------------

def load_theme() -> dict[str, str]:
    """Return THEME_* vars from the environment, parsing $DOTFILES/.env if needed."""
    env = os.environ

    if any(k.startswith("THEME_") for k in env):
        return {k: v for k, v in env.items() if k.startswith("THEME_")}

    dotfiles = env.get("DOTFILES", os.path.expanduser("~/.dotfiles"))
    env_path = os.path.join(dotfiles, ".env")

    theme: dict[str, str] = {}
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if not line.startswith("THEME_"):
                continue
            key, _, val = line.partition("=")
            theme[key] = val.strip().strip('"').strip("'")
    return theme


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def hex_to_rgb(hex_color: str) -> tuple[int, int, int]:
    h = hex_color.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def lerp_color(c1: tuple, c2: tuple, t: float) -> tuple[int, int, int]:
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))


def find_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    """Return the best available font at the given pixel size, preferring Nerd Font for glyph coverage."""
    candidates = [
        # Nerd Font variants (glyph coverage for icons)
        os.path.expanduser("~/Library/Fonts/DankMonoNerdFont-Regular.otf"),
        os.path.expanduser("~/Library/Fonts/DankMonoNerdFont-Italic.otf"),
        # System monospace fallbacks
        "/System/Library/Fonts/SFNSMono.ttf",
        "/System/Library/Fonts/Menlo.ttc",
    ]
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()


# ---------------------------------------------------------------------------
# Icon rendering
# ---------------------------------------------------------------------------

ICON_SIZES = [16, 32, 64, 128, 256, 512, 1024]


def render(
    text: str,
    bg_start: tuple[int, int, int],
    bg_end: tuple[int, int, int],
    text_color: tuple[int, int, int],
    corner_radius: float,
    margin_fraction: float = 0.15,
    gloss_start: tuple[int, int, int] = (255, 255, 255),
    gloss_end: tuple[int, int, int] = (255, 255, 255),
    gloss_alpha: float = 0.6,
    gloss_size: float = 0.85,
    stroke_color: tuple[int, int, int] = (0, 0, 0),
    stroke_width: int = 0,
    sheen_start: tuple[int, int, int] = (255, 255, 255),
    sheen_end: tuple[int, int, int] = (128, 128, 128),
    sheen_alpha: float = 1.0,
    size: int = 1024,
) -> Image.Image:
    """Render a single square icon at `size` x `size`."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # --- Gradient background (top → bottom) --------------------------------
    for y in range(size):
        t = y / max(size - 1, 1)
        color = lerp_color(bg_start, bg_end, t) + (255,)
        draw.line([(0, y), (size - 1, y)], fill=color)

    # --- Rounded-rectangle mask --------------------------------------------
    radius = max(1, int(corner_radius * size))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [(0, 0), (size - 1, size - 1)], radius=radius, fill=255
    )
    img.putalpha(mask)

    # --- Aqua gloss overlay ------------------------------------------------
    # Classic aqua: highlight covers only the top ~45% of the inset rect,
    # giving a "light source from above" look. Alpha uses a quadratic ease-out
    # so it starts bright and drops off quickly. Screen blending lightens the
    # underlying colors rather than overwriting them.
    gloss_w = int(size * gloss_size)
    gloss_h = int(size * gloss_size * 0.45)   # top portion only
    ox = (size - gloss_w) // 2
    oy = (size - int(size * gloss_size)) // 2  # align to top of inset area

    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    max_a = int(gloss_alpha * 255)
    for gy in range(gloss_h):
        t = gy / max(gloss_h - 1, 1)
        r, g, b = lerp_color(gloss_start, gloss_end, t)
        a = int(max_a * (1.0 - t) ** 2)       # quadratic ease-out
        overlay_draw.line([(ox, oy + gy), (ox + gloss_w - 1, oy + gy)], fill=(r, g, b, a))

    gloss_mask = Image.new("L", (size, size), 0)
    gloss_radius = max(1, int(corner_radius * gloss_w))
    ImageDraw.Draw(gloss_mask).rounded_rectangle(
        [(ox, oy), (ox + gloss_w - 1, oy + gloss_h - 1)], radius=gloss_radius, fill=255
    )
    overlay.putalpha(ImageChops.multiply(overlay.getchannel("A"), gloss_mask))

    # Screen blend: 1-(1-a)(1-b) — lightens without overriding base colors
    img_rgb  = img.convert("RGB")
    over_rgb = overlay.convert("RGB")
    screened = ImageChops.screen(img_rgb, over_rgb)
    img      = Image.composite(screened.convert("RGBA"), img, overlay.getchannel("A"))

    # --- Text --------------------------------------------------------------
    # Fit text to the available space inside the margin.
    # Probe at full available size, then scale so the constraining
    # dimension (max of width/height) exactly fills the available area.
    margin = int(size * margin_fraction)
    available = size - 2 * margin
    probe = find_font(available)
    pbbox = probe.getbbox(text)
    ptw, pth = pbbox[2] - pbbox[0], pbbox[3] - pbbox[1]
    font_size = max(8, int(available * available / max(ptw, pth, 1)))
    font = find_font(font_size)

    # Measure and center
    bbox = font.getbbox(text)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (size - tw) // 2 - bbox[0]
    y = (size - th) // 2 - bbox[1]

    # Draw stroke + text onto a separate layer so we can mask the sheen to its shape
    text_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    text_draw = ImageDraw.Draw(text_layer)

    if stroke_width > 0:
        steps = max(16, stroke_width * 4)
        for i in range(steps):
            angle = 2 * math.pi * i / steps
            dx = int(round(stroke_width * math.cos(angle)))
            dy = int(round(stroke_width * math.sin(angle)))
            text_draw.text((x + dx, y + dy), text, font=font, fill=stroke_color + (255,))

    text_draw.text((x, y), text, font=font, fill=text_color + (255,))

    # --- Text sheen (soft_light gradient masked to text shape) ---------------
    text_mask = text_layer.getchannel("A")

    sheen = Image.new("RGB", (size, size))
    sheen_draw = ImageDraw.Draw(sheen)
    for sy in range(size):
        t = sy / max(size - 1, 1)
        sheen_draw.line([(0, sy), (size - 1, sy)], fill=lerp_color(sheen_start, sheen_end, t))

    softlit = ImageChops.overlay(text_layer.convert("RGB"), sheen)
    softlit_rgba = softlit.convert("RGBA")
    softlit_rgba.putalpha(text_mask)
    # blend between original text colors and soft-lit colors — text stays fully opaque
    softlit_rgba = Image.blend(text_layer, softlit_rgba, sheen_alpha)

    img = Image.alpha_composite(img, softlit_rgba)

    return img


# ---------------------------------------------------------------------------
# icns packaging
# ---------------------------------------------------------------------------

def build_icns(base_img: Image.Image, out_path: str) -> None:
    """Resize base_img to all required sizes and pack into an .icns file."""
    with tempfile.TemporaryDirectory(suffix=".iconset") as iconset:
        iconset_path = Path(iconset)

        for logical_size in [16, 32, 128, 256, 512]:
            for scale in [1, 2]:
                pixel_size = logical_size * scale
                suffix = f"@{scale}x" if scale == 2 else ""
                fname = f"icon_{logical_size}x{logical_size}{suffix}.png"
                resized = base_img.resize((pixel_size, pixel_size), Image.LANCZOS)
                resized.save(iconset_path / fname, "PNG")

        result = subprocess.run(
            ["iconutil", "-c", "icns", str(iconset_path), "-o", out_path],
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            print(f"gen-terminal-icon: iconutil error: {result.stderr}", file=sys.stderr)
            sys.exit(1)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate Ghostty.icns from current THEME_* vars."
    )
    parser.add_argument("--stdout", action="store_true",
                        help="Write icns bytes to stdout")
    parser.add_argument("--preview", nargs='?', const='/tmp', metavar="DIR", required=False,
                        help="Write a 512x512 PNG preview to DIR(default to /tmp) instead of building icns")
    args = parser.parse_args()

    t = load_theme()
    if not t:
        print("gen-terminal-icon: error: no THEME_* variables found", file=sys.stderr)
        sys.exit(1)

    # --- Config from env vars with defaults --------------------------------
    text          = os.environ.get("TERMINAL_ICON") or ">_"
    corner_radius = float(os.environ.get("TERMINAL_ICON_CORNER_RADIUS", "0.22"))

    bg_start   = hex_to_rgb(os.environ.get("TERMINAL_ICON_BG1_COLOR", t["THEME_ACCENT_1"]))
    bg_end     = hex_to_rgb(os.environ.get("TERMINAL_ICON_BG2_COLOR", t["THEME_ACCENT_2"]))
    text_color      = hex_to_rgb(os.environ.get("TERMINAL_ICON_COLOR", t["THEME_ACCENT_12"]))
    margin_fraction = float(os.environ.get("TERMINAL_ICON_MARGIN", "0.15"))

    gloss_start = hex_to_rgb(t["THEME_ACCENT_4"])
    gloss_end   = hex_to_rgb(t["THEME_ACCENT_9"])
    gloss_alpha = float(os.environ.get("TERMINAL_ICON_GLOSS_ALPHA", "0.55"))
    gloss_size  = float(os.environ.get("TERMINAL_ICON_GLOSS_SIZE", "0.85"))

    stroke_color = hex_to_rgb(t.get("THEME_ACCENT_2", t["THEME_ACCENT_4"]))
    stroke_width = int(os.environ.get("TERMINAL_ICON_STROKE_WIDTH", "30"))

    sheen_start = hex_to_rgb(t["THEME_ACCENT_12"])
    sheen_end   = hex_to_rgb(t["THEME_ACCENT_9"])
    sheen_alpha = float(os.environ.get("TERMINAL_ICON_SHEEN_ALPHA", "1.0"))

    img = render(text, bg_start, bg_end, text_color, corner_radius,
                 margin_fraction, gloss_start, gloss_end, gloss_alpha, gloss_size,
                 stroke_color, stroke_width, sheen_start, sheen_end, sheen_alpha)

    # --- Preview mode -------------------------------------------------------
    if args.preview:
        preview_path = os.path.join(args.preview, "terminal-icon-preview.png")
        img.resize((512, 512), Image.LANCZOS).save(preview_path, "PNG")
        print(f"[gen-terminal-icon] Preview written to {preview_path}")
        return

    # --- icns to stdout or file --------------------------------------------
    with tempfile.TemporaryDirectory() as tmp:
        icns_path = os.path.join(tmp, "Ghostty.icns")
        build_icns(img, icns_path)

        if args.stdout:
            with open(icns_path, "rb") as f:
                sys.stdout.buffer.write(f.read())
            return

        dest = os.path.expanduser("~/.config/ghostty/Ghostty.icns")
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        shutil.copy2(icns_path, dest)
        print(f"[gen-terminal-icon] Written to {dest}")


if __name__ == "__main__":
    main()
