# Recruiter Admin Design Language

Visual design reference for the WorkGenius Recruiter Admin application. Tailwind CSS classes provided for convenience.

---

## Colors

### Primary

| Usage | Tailwind | Hex |
|-------|----------|-----|
| Primary action | `sky-600` | #0284c7 |
| Primary hover | `sky-500` | #0ea5e9 |
| Primary light bg | `sky-50` | #f0f9ff |

### Semantic

| Meaning | Background | Text/Icon |
|---------|------------|-----------|
| Success | `green-50` / `emerald-100` | `emerald-600` / `green-800` |
| Warning | `amber-50` | `amber-600` / `amber-800` |
| Error | `red-50` / `rose-50` | `red-600` / `red-800` |
| Info | `sky-50` | `sky-600` / `sky-800` |

### Neutrals

| Purpose | Tailwind |
|---------|----------|
| Page background | `white` |
| Secondary background | `gray-50` |
| Primary text | `gray-900` |
| Secondary text | `gray-500` |
| Muted text | `gray-400` |
| Borders | `gray-200` |
| Input borders | `gray-300` |

---

## Typography

| Element | Size | Weight |
|---------|------|--------|
| Page title | 24px (`text-2xl`) | Semibold |
| Section heading | 18px (`text-lg`) | Semibold/Medium |
| Body text | 14px (`text-sm`) | Normal |
| Small/Caption | 12px (`text-xs`) | Normal/Medium |

**Text colors**: Headings use `gray-800`, body uses `gray-900`, secondary uses `gray-500`, placeholders use `slate-400`.

---

## Spacing

| Context | Value |
|---------|-------|
| Page padding | 16-24px |
| Card/section padding | 16px |
| Form field gap | 24px |
| Inline element gap | 8px |
| Table cell padding | 12px vertical, 8px horizontal |

---

## Buttons

**Sizes**: XS (28px), SM (32px), MD (36px), LG (48px) height

| Variant | Background | Text | Border |
|---------|------------|------|--------|
| Primary | `sky-600` | white | none |
| Default | white | `slate-800` | 1px `gray-200` |
| Danger | white | `red-700` | 1px `gray-200` |
| Success | `emerald-600` | white | none |
| Ghost | transparent | `gray-700` | none |

**Common traits**: 6px radius, medium font weight, subtle shadow (except ghost), 50% opacity when disabled.

---

## Form Elements

**Text inputs**: 36px height, white background, 1px `gray-300` border, 6px radius. Focus: `sky-500` border. Invalid: `red-400` border.

**Checkboxes/Radios**: 16x16px, `sky-600` when checked, white checkmark/dot.

**Toggle switches**: 44x24px track, 20x20px thumb. Off: `gray-200` track. On: `sky-600` track.

**Form layout**: Labels above inputs (14px, medium, `gray-800`). Optional fields show "(Optional)" in smaller gray text. Error messages below in 12px `red-600`.

---

## Layout

### Sidebar
- Width: 256px
- Background: `gray-50` with right border `gray-200`
- Nav items: 14px medium, `gray-500` inactive, white background when active
- Active indicator: 4px right border in `sky-600` or gradient from `sky-50`

### Page Structure
- Header: 48px height, white, sticky, bottom border
- Breadcrumbs: 14px, gray text, slash separators
- Content: 24px vertical padding, 16-24px horizontal, max-width 1280px

---

## Tables

- Header: 12px medium uppercase, `gray-500`, white background
- Rows: White, divided by 1px `gray-200`
- Cells: 14px, 12px vertical / 8px horizontal padding
- First/last columns get extra 16px edge padding

---

## Tags

Inline badges: 12px medium, 4px/10px padding, 6px radius.

| Variant | Background | Text |
|---------|------------|------|
| Gray | `gray-100` | `gray-500` |
| Blue | `sky-50` | `sky-700` |
| Green | `emerald-100` | `emerald-700` |
| Amber | `amber-50` | `amber-700` |
| Red | `rose-50` | `rose-700` |

---

## Overlays

### Modals
- Backdrop: `gray-950` at 60% opacity
- Panel: White, 16px radius, 16px padding, 576px default width
- Close button: Top right, gray X icon

### Drawers
- Slides from right, 896px default width
- Full height, white background with shadow

### Dropdown Menus
- White, 6px radius, subtle shadow, 8px padding
- Items: 14px, 6px/8px padding, `slate-100` hover background

### Tooltips
- White, 8px radius, 16px padding, arrow pointing to trigger

---

## Alerts & Toasts

**Alerts**: 6px radius, 16px padding, icon left + content right. Background and text colors match semantic palette.

**Toasts**: Top center, 384px max width, white with 8px left accent bar in semantic color.

---

## Empty & Loading States

**Empty**: Centered, ~208px illustration, 18px semibold title, 14px gray description, 48px vertical padding.

**Skeleton**: Pulse animation, `slate-200` background, 6px radius, 20px line height.

**Spinner**: Circular spinning icon, inherits color, slight delay before showing.

---

## Tabs

**Underline**: Bottom border container, 32px gap. Active: `gray-900` text with 2px `sky-600` bottom border.

**Pills**: `gray-400/10` container, 36px height. Active: white background, `gray-800` text.

---

## Icons

Font Awesome Pro in Regular (primary), Solid (emphasis), Light (subtle), and Duotone (decorative) weights.

- Nav icons: 16px, `gray-400` inactive / `gray-500` active
- Menu icons: `slate-500`
- Inline: 14px, inherit color

---

## Motion

- Color/opacity: 100-200ms ease-out
- Position changes: 200-300ms ease-out
- Menus/tooltips: Fade + slide up 8px
- Drawers: Slide in 300ms

---

## Design Principles

1. **Subtle shadows** - `shadow-xs` or `shadow-sm` only
2. **Consistent borders** - 1px `gray-200`
3. **Muted defaults** - Gray icons/text; color for active states
4. **Generous whitespace** - Don't crowd elements
5. **Clear hierarchy** - Size and weight distinguish headings
6. **Semantic colors** - Red for errors, green for success
7. **Consistent radii** - 6px standard, 8-16px for cards/modals
