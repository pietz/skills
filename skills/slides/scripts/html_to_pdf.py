# /// script
# dependencies = ["playwright"]
# requires-python = ">=3.12"
# ///

"""
Convert HTML files to PDF using Playwright headless Chromium.
Produces native vector PDF output — text stays sharp and selectable at any zoom.

Usage:
    uv run html_to_pdf.py input.html
    uv run html_to_pdf.py input.html --format slides
    uv run html_to_pdf.py input.html --format a4 --output flyer.pdf

Formats:
    slides           16:9 presentation (1280x720)
    slides-4x3       4:3 presentation (1024x768)
    a4               A4 portrait (210x297mm)
    a4-landscape     A4 landscape (297x210mm)
    letter           US Letter portrait (216x279mm)
    letter-landscape US Letter landscape (279x216mm)
    a3               A3 portrait (297x420mm)
    tabloid          Tabloid (279x432mm)
    custom           Use @page size from the HTML/CSS (default)

First run installs Chromium automatically (~300 MB).
"""

import argparse
import subprocess
import sys
from pathlib import Path

FORMATS: dict[str, dict] = {
    "slides":           {"width": "1280px",  "height": "720px",  "vw": 1280, "vh": 720},
    "slides-4x3":       {"width": "1024px",  "height": "768px",  "vw": 1024, "vh": 768},
    "a4":               {"width": "210mm",   "height": "297mm",  "vw": 794,  "vh": 1123},
    "a4-landscape":     {"width": "297mm",   "height": "210mm",  "vw": 1123, "vh": 794},
    "letter":           {"width": "216mm",   "height": "279mm",  "vw": 816,  "vh": 1056},
    "letter-landscape": {"width": "279mm",   "height": "216mm",  "vw": 1056, "vh": 816},
    "a3":               {"width": "297mm",   "height": "420mm",  "vw": 1123, "vh": 1587},
    "tabloid":          {"width": "279mm",   "height": "432mm",  "vw": 1056, "vh": 1632},
    "custom":           {},
}

PRINT_OVERRIDES = """
[style*="backdrop-filter"] {
    backdrop-filter: none !important;
    -webkit-backdrop-filter: none !important;
}
* {
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
}
"""


def convert(html_path: Path, output_path: Path, fmt: str) -> None:
    # Install Chromium if needed (silent on subsequent runs)
    subprocess.run(
        [sys.executable, "-m", "playwright", "install", "chromium"],
        check=True, capture_output=True,
    )

    from playwright.sync_api import sync_playwright

    config = FORMATS[fmt]

    with sync_playwright() as p:
        browser = p.chromium.launch()

        page_opts: dict = {}
        if config.get("vw"):
            page_opts["viewport"] = {"width": config["vw"], "height": config["vh"]}

        page = browser.new_page(**page_opts)
        page.goto(html_path.absolute().as_uri())
        page.wait_for_load_state("networkidle")
        page.evaluate("document.fonts.ready")
        page.add_style_tag(content=PRINT_OVERRIDES)

        pdf_opts: dict = {
            "path": str(output_path),
            "print_background": True,
            "margin": {"top": "0", "right": "0", "bottom": "0", "left": "0"},
        }

        if fmt == "custom":
            pdf_opts["prefer_css_page_size"] = True
        else:
            pdf_opts["width"] = config["width"]
            pdf_opts["height"] = config["height"]

        page.pdf(**pdf_opts)
        browser.close()

    size_kb = output_path.stat().st_size / 1024
    print(f"PDF saved: {output_path}  ({size_kb:.0f} KB, format: {fmt})")


def main() -> None:
    parser = argparse.ArgumentParser(description="Convert HTML to PDF via Playwright")
    parser.add_argument("input", type=Path, help="Input HTML file")
    parser.add_argument("--format", choices=list(FORMATS), default="custom",
                        help="Page format (default: custom — uses @page from CSS)")
    parser.add_argument("--output", type=Path, help="Output PDF path (default: <input>.pdf)")
    args = parser.parse_args()

    if not args.input.exists():
        print(f"Error: {args.input} not found", file=sys.stderr)
        sys.exit(1)

    output = args.output or args.input.with_suffix(".pdf")
    convert(args.input, output, args.format)


if __name__ == "__main__":
    main()
