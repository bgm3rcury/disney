#!/usr/bin/env python3
"""Best-effort Disneyland Paris metadata scraper.

The live Disneyland Paris site may redirect to Queue-it. When reachable, this script
prints candidate attraction links/images for manual review. The app uses the curated
AttractionMetadata.json fallback so builds do not depend on this scraper succeeding.
"""
import re
import sys
import urllib.request

URL = "https://www.disneylandparis.com/en-int/attractions/"

request = urllib.request.Request(URL, headers={"User-Agent": "Mozilla/5.0"})
try:
    with urllib.request.urlopen(request, timeout=30) as response:
        html = response.read().decode("utf-8", errors="replace")
except Exception as exc:
    print(f"Could not fetch Disneyland Paris attractions page: {exc}", file=sys.stderr)
    sys.exit(0)

if "waitingroom.disneylandparis.com" in html or "Queue-it" in html:
    print("Disneyland Paris returned the waiting room; using curated fallback metadata.")
    sys.exit(0)

for match in re.finditer(r'href="([^"]*/attractions/[^"]+)"', html):
    print(match.group(1))
