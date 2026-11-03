"""Build splash assets: the whale glyph and the Montserrat brand fonts."""

import pathlib
import re
import shutil

root = pathlib.Path(__file__).resolve().parent
src = root / "brand" / "welcome-brand.svg"

svg = src.read_text(encoding="utf-8")
svg = svg[svg.index("<svg") :]
svg = re.sub(r"<style>.*?</style>", "", svg, flags=re.S)
svg = re.sub(r'fill="var\(--[^"]*\)"', 'fill="#ffffff"', svg)

# The shipped lockup is: 145pt of padding, the whale glyph (x 145.5-168, y 11.5-28),
# the "deepseek" outlines, then a placeholder rectangle. Keep only the whale.
svg = re.sub(r'viewBox="[^"]*"', 'viewBox="144.5 10.5 24.5 19"', svg, count=1)
svg = re.sub(r'\swidth="\d+"', ' width="100%"', svg, count=1)
svg = re.sub(r'\sheight="\d+"', ' height="100%"', svg, count=1)
svg = re.sub(r"\n\s*\n", "\n", svg).strip()
(root / "emblem.svg").write_text(svg, encoding="utf-8")
print(f"emblem.svg: {len(svg)} bytes")

fonts = root / "fonts"
fonts.mkdir(exist_ok=True)
for name in ("montserrat-light.woff2", "montserrat-medium.woff2", "Montserrat-OFL.txt"):
    shutil.copyfile(root / "brand" / name, fonts / name)
print("fonts:", sorted(p.name for p in fonts.iterdir()))
