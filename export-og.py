#!/usr/bin/env python3
import os, subprocess, tempfile, shutil
from PIL import Image

W, H = 1280, 640


def find_browser():
    for p in (
        "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
        "C:/Program Files/Google/Chrome/Application/chrome.exe",
    ):
        if os.path.exists(p):
            return p
    return shutil.which("msedge") or shutil.which("chrome")


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    browser = find_browser()
    if not browser:
        raise SystemExit("Edge/Chrome not found.")
    html = "file:///" + os.path.join(here, "index.html").replace("\\", "/")
    big = os.path.join(here, "og-image-2x.png")
    out = os.path.join(here, "og-image.png")
    prof = os.path.join(tempfile.gettempdir(), "og-shot-profile")
    args = [
        browser, "--headless=new", "--disable-gpu", "--hide-scrollbars",
        "--no-first-run", "--force-device-scale-factor=2",
        "--window-size=%d,%d" % (W, H), "--virtual-time-budget=8000",
        "--user-data-dir=" + prof, "--screenshot=" + big, html,
    ]
    subprocess.run(args, check=True)
    with Image.open(big) as src:
        src.resize((W, H), Image.LANCZOS).save(out)
    os.remove(big)
    kb = os.path.getsize(out) / 1024
    if os.path.getsize(out) >= 1024 * 1024:
        print("WARNING: %.0fKB over GitHub 1MB limit" % kb)
    print("Exported: %s (%.0fKB, %dx%d)" % (out, kb, W, H))


if __name__ == "__main__":
    main()

