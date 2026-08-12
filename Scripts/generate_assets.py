#!/usr/bin/env python3
import json
import os
import re
import urllib.request
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "DisneyQueues"
ASSETS = APP / "Assets.xcassets"
METADATA = APP / "AttractionMetadata.json"
ICON_URL = "https://www.vhv.rs/dpng/d/471-4713936_mickeymouse-disney-mickey-disneycastle-silhouette-disney-castle-silhouette.png"

CATEGORY_COLORS = {
    "coasters": ((199, 48, 48), (88, 45, 145)),
    "bigThrills": ((214, 84, 55), (113, 39, 129)),
    "chillRide": ((32, 119, 183), (53, 161, 113)),
    "family": ((37, 132, 138), (62, 151, 89)),
    "walkthrough": ((88, 126, 72), (48, 116, 150)),
    "showsMeetups": ((126, 76, 160), (48, 116, 150)),
    "singleRider": ((122, 122, 122), (70, 70, 70)),
}

APP_ICON_SIZES = [20, 29, 40, 60, 76, 83.5, 1024]

def asset_contents(filename):
    return {
        "images": [
            {"idiom": "universal", "filename": filename, "scale": "1x"}
        ],
        "info": {"author": "xcode", "version": 1}
    }

def safe_font(size):
    for name in ["arial.ttf", "Arial.ttf"]:
        try:
            return ImageFont.truetype(name, size)
        except Exception:
            pass
    return ImageFont.load_default()

def gradient(size, start, end):
    width, height = size
    image = Image.new("RGB", size, start)
    pixels = image.load()
    for y in range(height):
        t = y / max(height - 1, 1)
        row = tuple(int(start[i] * (1 - t) + end[i] * t) for i in range(3))
        for x in range(width):
            pixels[x, y] = row
    return image

def first_color(categories):
    for category in categories:
        if category in CATEGORY_COLORS:
            return CATEGORY_COLORS[category]
    return ((45, 93, 150), (41, 154, 129))

def initials(name):
    words = re.findall(r"[A-Za-z0-9]+", name)
    if not words:
        return "DQ"
    if len(words) == 1:
        return words[0][:2].upper()
    return "".join(word[0] for word in words[:3]).upper()

def write_attraction_asset(item):
    image_name = item["imageName"]
    asset_dir = ASSETS / f"{image_name}.imageset"
    asset_dir.mkdir(parents=True, exist_ok=True)
    filename = f"{image_name}.png"
    path = asset_dir / filename

    start, end = first_color(item.get("simpleCategories", []))
    image = gradient((640, 420), start, end).convert("RGBA")
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((24, 24, 616, 396), radius=34, outline=(255, 255, 255, 92), width=4)
    draw.text((42, 34), item.get("name", image_name), font=safe_font(28), fill=(255, 255, 255, 230))
    mark = initials(item.get("name", image_name))
    bbox = draw.textbbox((0, 0), mark, font=safe_font(96))
    draw.text(((640 - (bbox[2] - bbox[0])) / 2, (420 - (bbox[3] - bbox[1])) / 2), mark, font=safe_font(96), fill=(255, 255, 255, 240))

    if item.get("isCoaster"):
        draw.arc((430, 250, 590, 370), 180, 350, fill=(255, 255, 255, 210), width=7)
        draw.line((430, 330, 590, 330), fill=(255, 255, 255, 170), width=5)

    image.save(path)
    (asset_dir / "Contents.json").write_text(json.dumps(asset_contents(filename), indent=2), encoding="utf-8")

def download_icon_source():
    try:
        request = urllib.request.Request(ICON_URL, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(request, timeout=30) as response:
            return Image.open(response).convert("RGBA")
    except Exception:
        image = Image.new("RGBA", (1024, 1024), (30, 64, 120, 255))
        draw = ImageDraw.Draw(image)
        draw.rounded_rectangle((72, 72, 952, 952), radius=180, fill=(34, 111, 165, 255))
        draw.rectangle((210, 520, 814, 770), fill=(255, 255, 255, 255))
        draw.polygon([(512, 210), (300, 520), (724, 520)], fill=(255, 255, 255, 255))
        draw.rectangle((468, 340, 556, 520), fill=(255, 255, 255, 255))
        return image

def write_app_icons():
    source = download_icon_source()
    icon_dir = ASSETS / "AppIcon.appiconset"
    icon_dir.mkdir(parents=True, exist_ok=True)
    images = []

    for idiom, size, scales in [
        ("iphone", 20, [2, 3]),
        ("iphone", 29, [2, 3]),
        ("iphone", 40, [2, 3]),
        ("iphone", 60, [2, 3]),
        ("ios-marketing", 1024, [1]),
    ]:
        for scale in scales:
            pixels = int(size * scale)
            filename = f"icon-{pixels}.png"
            source.resize((pixels, pixels), Image.LANCZOS).save(icon_dir / filename)
            images.append({"size": f"{size}x{size}", "idiom": idiom, "filename": filename, "scale": f"{scale}x"})

    (icon_dir / "Contents.json").write_text(json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2), encoding="utf-8")

def main():
    ASSETS.mkdir(parents=True, exist_ok=True)
    (ASSETS / "Contents.json").write_text(json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2), encoding="utf-8")
    metadata = json.loads(METADATA.read_text(encoding="utf-8-sig"))
    seen = set()
    for item in metadata:
        if item["imageName"] not in seen:
            write_attraction_asset(item)
            seen.add(item["imageName"])
    write_app_icons()
    print(f"Generated {len(seen)} attraction image assets and app icons")

if __name__ == "__main__":
    main()
