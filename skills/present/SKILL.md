---
name: present
description: Present the result of analysis, research, or a gathered deliverable as a polished, self-contained HTML page instead of a terminal wall of text, then open it in the browser. Use when the user says "present this", "show me nicely", "make it visual", or otherwise wants a pleasant, vivid way to inspect what you found rather than reading a Markdown summary in the terminal.
metadata:
  version: "1.0.0"
---

You just did the work: gathered, analyzed, or produced something. The default
move is to dump a summary into the terminal. Don't. Build an HTML page that
makes the result genuinely pleasant to look at, then open it.

## Why HTML

Thariq Shihipar (Claude Code) made the case in "The Unreasonable Effectiveness
of HTML": we default to Markdown out of habit from the token-scarce GPT-4 days,
but that constraint is gone. HTML lets you drop in SVG diagrams, color-coding,
in-page navigation, side-by-side comparisons, and light interactivity, so the
information becomes something to explore rather than a flat block to scroll. For
a human inspecting a deliverable, that is a far better experience than terminal
text. The cost is that HTML is verbose to generate and noisy in git, so treat
these pages as throwaway artifacts for viewing, not as source you commit.

## What to build

One self-contained `.html` file. Inline all CSS and JavaScript. No CDN links, no
external fonts, no network requests of any kind. The file must render correctly
opened straight from disk, offline.

Let the content choose the form. Some honest defaults:

- Lead with the answer. The headline insight, number, or recommendation goes at
  the top, big and unmissable. Supporting detail follows.
- Use real explanatory prose, not just visuals. The reader should understand
  *what they are looking at* and *why it matters*, not just see a chart. Pair
  every visual with a sentence or two of plain-language interpretation.
- Reach for the right visual: an inline SVG diagram for flows and structure, a
  simple table or bar layout for comparisons, color-coding for severity or
  category, callout boxes for the things that matter most.
- Add in-page navigation (a sticky table of contents or jump links) once the
  page is long enough that scrolling gets tedious.
- Add interactivity only when it earns its place: a slider to explore a
  parameter, tabs to switch between cases, a filterable list. Skip it if static
  content already communicates well. Never add interactivity for decoration.
- Make it look intentional. Generous spacing, a restrained palette, clear type
  hierarchy, responsive width. It should feel designed, not like a default
  browser dump. If a strong visual direction would help, the `frontend-design`
  skill has guidance.

## Procedure

1. Decide the one thing the reader most needs to understand, and structure the
   page around it.
2. Write the file to the system temp directory with a descriptive name, e.g.
   `"$TMPDIR/present-<topic>.html"` (or `/tmp/present-<topic>.html`). Keep it
   out of the user's repos and projects.
3. Open it: `open "$TMPDIR/present-<topic>.html"`.
4. In the terminal, give just a one or two line pointer to what you opened. The
   page is the deliverable; don't re-summarize it all in text.

## Keep it proportional

Match the effort to the result. A small finding gets a clean, simple page, not
an over-engineered dashboard. Don't let polishing the HTML delay getting the
actual answer in front of the user.
