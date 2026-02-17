---
name: slides
description: "Create visual documents (presentations, flyers, brochures, posters) by generating HTML/CSS and converting to PDF via headless Chromium. Use this skill when the user wants to create slides, presentations, pitch decks, flyers, brochures, or posters."
---

# Creating Presentations with HTML/CSS

Build presentations as HTML/CSS and export to PDF. Tailwind CSS for styling, Google Fonts for typography, no design ceiling. The same approach works for slides, flyers, brochures, and posters.

## How It Works

Each slide is a fixed-size `<section>` in a single HTML file. The browser renders it, Playwright converts it to a vector PDF (sharp text, selectable, any zoom level). That's the whole pipeline.

The HTML file is self-contained — Tailwind via CDN, Google Fonts via `<link>`, all styles inline. No build step. For images, use base64 data URIs or local file paths (Playwright resolves paths relative to the HTML file).

Here's the skeleton for a 16:9 slide deck:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <script src="https://cdn.tailwindcss.com"></script>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=YOUR+FONTS&display=swap" rel="stylesheet">
  <script>tailwind.config = { theme: { extend: { /* custom colors, fonts */ } } }</script>
  <style>
    @page { size: 1280px 720px; margin: 0; }
    body { margin: 0; }
    * { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    .slide {
      width: 1280px; height: 720px;
      page-break-after: always; overflow: hidden;
      position: relative; box-sizing: border-box;
    }
    .slide:last-child { page-break-after: auto; }
  </style>
</head>
<body>
  <section class="slide"><!-- title slide --></section>
  <section class="slide"><!-- content --></section>
  <section class="slide"><!-- closing --></section>
</body>
</html>
```

For other formats, adjust `@page` size and container dimensions:

| Format | @page size | Container dimensions |
|--------|-----------|----------------------|
| Slides 16:9 | `1280px 720px` | `1280px × 720px` |
| Slides 4:3 | `1024px 768px` | `1024px × 768px` |
| A4 portrait | `A4 portrait` | `210mm × 297mm` |
| A4 landscape | `A4 landscape` | `297mm × 210mm` |
| US Letter | `letter portrait` | `216mm × 279mm` |
| A3 poster | `A3 portrait` | `297mm × 420mm` |

## Tips for Great Results

**Content first.** Draft the slide outline before writing HTML. Each slide title should be an assertion ("Revenue grew 34% YoY"), not a topic label ("Revenue Update"). Reading just the titles in sequence should tell the whole story.

**Establish a design system up front.** Use `tailwind.config` to define your palette, font families, and spacing scale before writing any slides. This keeps the deck consistent — same heading sizes, same card padding, same gaps throughout. Vary layouts across slides, but keep the system uniform. Commit to one visual motif (rounded frames, colored circles, thick borders) and repeat it.

**Use Lucide for icons.** Don't use emoji — they render inconsistently in PDF. Instead, use [Lucide](https://lucide.dev) via CDN: add `<script src="https://unpkg.com/lucide@latest"></script>` in `<head>`, use `<i data-lucide="icon-name"></i>` in your markup, and place `<script>lucide.createIcons();</script>` at the end of `<body>`.

**Keep slides diverse within the system.** A consistent design system doesn't mean every slide looks the same. Mix layout types — a big stat callout, then a two-column text/image split, then a three-card grid, then a full-bleed quote. Use different background shades (dark title slide, light content slides, colored accent slides). The design system gives you the guardrails; variety within those guardrails is what makes a deck feel crafted rather than templated.

**Avoid AI tells.** Purple gradients on white, accent lines under titles, identical layouts on every slide, default system fonts — these scream "AI-generated." Be deliberate.

## PDF Conversion

Convert using the script at `scripts/html_to_pdf.py` (relative to this skill's directory):

```bash
uv run <skill-dir>/scripts/html_to_pdf.py input.html --format slides --output output.pdf
```

The `--format` flag sets page size (`slides`, `slides-4x3`, `a4`, `a4-landscape`, `letter`, `letter-landscape`, `a3`, `tabloid`). Omit for `custom` which reads `@page` from CSS. Omit `--output` to save as `input.pdf`. First run installs Chromium automatically.

## Print Rendering Gotchas

These are the things that will bite you when converting HTML to PDF:

- **Missing backgrounds** — Chromium doesn't print backgrounds by default. The `print-color-adjust: exact` rule and `print_background=True` in the script handle this, but make sure they're present.
- **`backdrop-filter` is broken** — Glassmorphism, blur effects, anything using `backdrop-filter` will not render in PDF. Use solid or semi-transparent backgrounds instead.
- **`vw`/`vh` units are unreliable** — Use `px` or `mm` for all sizing. Viewport units don't behave consistently in print context.
- **Fonts may not load** — The conversion script waits for `document.fonts.ready`, but if fonts fail to load you'll get system fallbacks. Check the output.
- **SVGs using `currentColor`** — This inherits wrong in print. Set explicit `fill` and `stroke` colors.
- **Content overflow** — Slides use `overflow: hidden`, so anything that doesn't fit simply disappears. Watch text length.
- **Emoji rendering** — Emoji render inconsistently across PDF viewers. Use Lucide icons via CDN instead (see Tips above).

## QA

**Assume there are problems. Your job is to find them.**

After converting to PDF, **visually inspect every page**. Open the PDF and look at the actual rendering. Use a subagent for this — you've been staring at the code and will see what you expect, not what's there. Check for:

- Rendering bugs: text overflow, missing backgrounds, font fallback, content cut off
- Design consistency: are font sizes, heading hierarchy, spacing, and card styles uniform across all slides?
- Overall quality: low contrast, generic design, poor visual hierarchy

If you can't read the PDF visually, convert pages to images first: `pdftoppm -jpeg -r 150 output.pdf slide`

Fix issues, re-convert, re-verify. Do not declare success until at least one fix-and-verify cycle.

## Dependencies

- **Playwright + Chromium** — installed automatically on first run via PEP 723
