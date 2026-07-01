# design-md

Capture the design at hand into a `DESIGN.md` file: a semantic design system written in descriptive, designer-friendly language.

Standalone adaptation of Google Labs' Stitch `design-md` skill
(`google-labs-code/stitch-skills`), with all Stitch/MCP coupling removed. Works
directly from whatever is in view: a codebase's styles, an HTML/CSS prototype, a
live URL, or a screenshot.

## Use it

> Capture the design of this codebase into a DESIGN.md.

The output is a single Markdown file meant to serve as the source of truth for
future design work and for prompting other tools to generate screens consistent
with it.

## Structure

```text
design-md/
├── SKILL.md            — core instructions & workflow
├── examples/DESIGN.md  — a sample output
└── README.md           — this file
```
