# Design System: WorkGenius Freelancer Dashboard
**Source:** `frontend/src/apps/freelancer/` (UI primitives in `ui/`, layout in `layout/`, tokens in `frontend/src/tailwind.css`).

## 1. Atmosphere

A **light-mode, glassmorphic workspace** — calm, airy, editorial. Frosted-white panels float on a daylight-blue radial gradient. Density is low and *gets more spacious on bigger screens, not denser*. No dark mode anywhere. No shouting accents, no shadows on layout surfaces, no hard chrome. Empty states get full illustrated panels — "nothing here" is treated as legitimate content.

## 2. Color Palette

### Surfaces
- **Sky-Powder Blue** `#C8DBFF` — gradient focal point, anchored bottom-center (`bg-radial-[at_50%_100%] from-[#C8DBFF] to-slate-300 to-65%`).
- **Slate Mist** `slate-300 #CBD5E1` — outer canvas; also the mobile drawer panel color.
- **Translucent Frost** `white/40` + `backdrop-blur-2xl` — workhorse surface for cards, sidebar pills, the "faded" button variant, small icon buttons.
- **Heavy Frost** `white/70` — modal panels.
- **Pure White** — *active* state only: active nav pill, active tab indicator, hover destinations, and the fill of overlay surfaces (tooltip/popover/combobox).
- **Inner Tray** `slate-50/50` — nested wash inside cards (radius 16px) under the outer 24px frost (radius 24px).
- **Modal Scrim** `slate-800/40` + `backdrop-blur-sm`.

### Ink
| Token | Use |
|---|---|
| `slate-800` | Modal/dialog titles, selected tab text, input focus-ring color |
| `slate-700` | Primary text, button labels, primary-button fill |
| `slate-600` | Dialog descriptions, empty-state copy, tab icons |
| `slate-500` | Card titles, section labels, metadata, dates — the "label voice" |
| `slate-400` | Placeholders, unit suffixes, range dashes, duotone-icon decorative paths |
| `slate-300` | Input borders, list dividers, dashed checklist glyphs |
| `slate-200` | Hairline outlines on small icon buttons and outline button variants |

### Accents
**Sky Family** — the **interactive accent**, never branding:
- `sky-700` — checked checkbox / indeterminate / markdown-editor focus.
- `sky-500` — checkbox focus ring.
- `sky-50` — selected combobox option, info-alert background.

### State Colors (Alert + Form errors only)
Always **50/700 pairs** — tinted background, deep matching ink. Never solid red/green chrome.
- info `sky-50 / sky-700`  ·  success `emerald-50 / emerald-700`  ·  warning `amber-50 / amber-700`  ·  error `red-50 / red-700` (form-error tooltip uses `red-100`; invalid input borders shift to `red-300`).

## 3. Typography

**Inter** throughout. No display face, no italics, no uppercase tracking. Sentence case.

| Use | Spec |
|---|---|
| Stepper title (loudest) | `text-2xl font-bold slate-700` |
| Modal title | `text-lg font-medium slate-800` |
| Card titles ("Actions", "Stats") | `text-lg slate-500` regular — *titles whisper; content carries weight* |
| Empty-state headline | `text-base font-semibold slate-700` |
| List item titles | `text-base font-medium slate-700`, `line-clamp-1` |
| Body / metadata | `text-sm/5`, `slate-700` values, `slate-500` labels, `slate-600` descriptions |
| Input text | `text-base slate-700`, `slate-400` placeholder |
| Form label | `text-sm slate-700` |

**Convention:** units and range dashes always render in `slate-400 font-normal`, even inside slate-700 medium-weight values — the *number* is the protagonist.

## 4. Components

### Buttons (pill, `rounded-full px-8 py-2 border font-medium`)
- **Primary** — `bg-slate-700 text-white border-slate-700 hover:bg-slate-600`
- **Default** — `bg-white text-slate-700 border-slate-200 hover:bg-slate-50`
- **Faded** — `bg-white/40 text-slate-700 border-slate-200 hover:bg-slate-50`

Mobile-full-width by default (`w-full md:w-auto`). Disabled = `opacity-70`. **No destructive variant. No loading state. No focus ring on buttons** (focus rings live on inputs).

### Cards (radius **24px**)
`absolute inset-0 z-0 bg-white/40 backdrop-blur-2xl` background div + `relative z-10` content div. No border, no shadow.

### Inner Trays (radius **16px**)
Same pattern, `bg-slate-50/50` fill.

### Sidebar Nav Pill (radius **16px**, height **48px** / **56px** at 2xl)
- Active: `bg-white slate-700` · Resting: `bg-white/40` · Hover: `bg-white`
- Icons: FontAwesome `fa-duotone`, both paths `currentColor` → tints to surrounding text color.

### Inputs / Textarea / Select
`bg-white border border-slate-300 rounded-xl text-slate-700 p-3 h-12 placeholder:text-slate-400`
- **Focus:** `ring-1 ring-slate-800 outline-none` — thin near-black ring.
- **Invalid:** `group-aria-[invalid]:border-red-300`.
- **Disabled:** `bg-slate-50 border-slate-200 text-slate-500` (lightens, doesn't gray out).
- Inputs are **solid white** — they sit *on* the frost, not *as* it.

### Modal / ConfirmDialog
- Scrim: `bg-slate-800/40 backdrop-blur-sm`.
- Panel: `bg-white/70 p-6 rounded-3xl` (Modal `max-w-4xl`, ConfirmDialog `max-w-2xl`). Fade + scale 0.95→1.
- Title `slate-800` · Description `slate-600`.
- Footer buttons forced to **56px** (`[&>button]:h-14`).

### Alert (radius **2rem** / `rounded-4xl`)
Asymmetric `ps-4 pe-2 py-2` — icon left, content+actions right. Four state variants in 50/700 pairs.

### Tabs (pill segmented control)
- Container: `bg-white/40 rounded-full p-0.5`.
- **Sliding white indicator** animates `translate-x` + `width` via CSS variables `--active-tab-left` / `--active-tab-width` — moves under the labels rather than re-rendering.
- Labels `slate-700`, selected `slate-800`.

### Tooltip / Popover / Combobox — Overlay Layer
These break the frosted language entirely:
- **Tooltip:** solid white, `rounded-md`, `shadow-md`, `p-4`, with directional SVG arrow. 150ms fade+scale.
- **Popover:** solid white, `border-slate-300`, `rounded-xl`, `shadow-md`, `p-4`. 150ms `translate-y-2 → 0`.
- **Combobox menu:** same as Popover. Items `rounded-md p-2 font-medium slate-700`. Hover `slate-50`, kbd-highlighted `slate-100`, selected `sky-50`.

> **Frosted = surface. Solid + shadow = overlay.** The two systems coexist by meaning.

### Form
- Layout `flex flex-col gap-6`. Field container is a `group` that sets `aria-invalid="true"` on error.
- **Errors render as a `red-100 / red-700` tooltip *above* the field** — not inline copy below it.

### Stepper
Stacked frosted cards with z-index/scale/opacity offsets per step. Active step gets `relative backdrop-blur-2xl`; inactive ones are `absolute pointer-events-none`. Two nested 24px frost panels — outer for the stack, inner for active content.

## 5. Layout

| Variable | < 2xl | ≥ 2xl |
|---|---|---|
| `--sidebar-width` | 220px | 300px |
| `--app-col-gap` | 12px | 16px |
| `--nav-item-height` | 48px | 56px |
| `--container-padding` | 17px | 20px |
| `--header-height` | 80px | 80px |

- Outer canvas centers at `2xl:max-w-480` (≈1920px).
- Two-column shell: sticky sidebar + main, separated by `--app-col-gap`. Below `lg`, sidebar collapses to a hamburger drawer (`bg-slate-300` over `gray-900/40` backdrop).
- Main grid: `2xl:grid-cols-2`, single-column below.
- Card padding `p-4 md:p-6`, repeated by inner trays.
- **Gap-as-design** — column gap and row gap match. More gradient between cards than density inside them.
- Every card opens with the same header row: `slate-500 text-lg` title left, optional metadata/link/month right.

## 6. Depth & Elevation

**No `box-shadow` on cards, panels, sidebars, or header.** Layout depth comes from:
1. Frost layers (`white/40` + `backdrop-blur-2xl`) lifting off the gradient.
2. Nested tonal steps (`slate-50/50` tray inside a frost card).
3. Surgical hairlines (`divide-slate-300`, `border-slate-200` on small buttons).

The exception is the **overlay layer** — tooltips, popovers, comboboxes use solid white + `shadow-md`. Modals split the difference (`white/70` panel, no panel shadow, but a heavy blurred scrim).

Z-order is built explicitly: every card is a `relative` parent with `absolute inset-0 z-0` background and `relative z-10` content, so background and foreground carry independent radii and opacity.

## 7. Motion

Built on **`motion/react`** (Framer Motion). Restrained, never theatrical.

- **Hover** — `transition-colors` only. Glass gets *clearer* under cursor (`white/40 → white/60 → white`). No scale, no translate. The dominant interaction signal.
- **Mount** — content fades and rises slightly on first paint.
- **Modals** — backdrop fade; panel scale 0.95→1.
- **Tooltips** — opacity + scale (150ms).
- **Popovers / Comboboxes** — `translate-y-2 → 0` (150ms) — menus *settle* in from above.
- **Tabs** — white indicator pill slides under labels via CSS-variable transition.
- **Numbers** — animated via **NumberFlow** (currency + compact formats).

**Absent:** parallax, skeleton-shimmer, spinners, springs, route-level transitions.

## 8. Accessibility & States

- **Focus visibility lives on inputs**, not buttons. Inputs/comboboxes: 1px `slate-800` ring. Checkboxes: 2px `sky-500` ring.
- **Validation is ARIA-driven** — `FormField` sets `aria-invalid="true"`; descendants react via `group-aria-[invalid]:border-red-300`.
- **Disabled posture varies by component:** buttons → `opacity-70` (fill preserved); inputs → `slate-50`/`slate-200` recolor (lightens, doesn't fade); pill quick-actions → `opacity-60` *and* fill removed (dissolves into parent).
- Truncation everywhere: `truncate`, `line-clamp-1`, `min-w-0`.

## 9. Iconography

FontAwesome, three prefixes, color always inherited:
- **`fa-duotone`** — content + nav. Both paths `currentColor`; built-in opacity creates internal hierarchy.
- **`fa-solid`** — accent moments.
- **`fa-regular`** — utility chrome (gear, hamburger, breadcrumb home).

Sized by FontAwesome's own scale (`fa-2x`, `fa-3x`), not Tailwind text-sizes.
