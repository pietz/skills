# Client App Design Language

Visual design reference for the WorkGenius Client/Organization application (app.workgenius.com/org). Tailwind CSS classes provided.

---

## Visual Style

**Traditional admin panel**: Dark sidebar with light content area. Clean, professional appearance with white cards on slate-100 background.

---

## Colors

### Primary

| Usage | Tailwind | Hex |
|-------|----------|-----|
| Primary action | `sky-600` / `sky-700` | #0284c7 / #0369a1 |
| Sidebar background | `sky-950` | #082f49 |
| Main background | `slate-100` | #f1f5f9 |

### Neutrals

| Purpose | Tailwind |
|---------|----------|
| Card surface | `white` |
| Primary text | `slate-800` |
| Secondary text | `slate-700` |
| Muted text | `slate-500` |
| Borders | `slate-900/10` (10% opacity) |
| Skeleton/placeholder | `slate-100` / `slate-200` |

### Semantic (same as console)

| Meaning | Background | Text |
|---------|------------|------|
| Success | `emerald-50` | `emerald-700` |
| Warning | `amber-50` | `amber-700` |
| Error | `red-50` | `red-700` |
| Info | `sky-50` | `sky-700` |

---

## Typography

| Element | Size | Weight |
|---------|------|--------|
| Page title | 18px (`text-lg`) | Medium |
| Section title | 14px (`text-sm`) | Medium |
| Body text | 14px (`text-sm`) | Normal |
| Small/Caption | 12px (`text-xs`) | Normal/Medium |

**Text colors**: Titles use `slate-800`, body uses `slate-700`, secondary uses `slate-500`.

---

## Spacing

| Context | Value |
|---------|-------|
| Page padding | 16px (`p-4`) |
| Card gap | 16px (`gap-4`) |
| Content padding | 16px, 24px on 2xl (`py-4 2xl:pt-6 px-4`) |
| Sidebar padding | 16px (`px-4`) |

---

## Layout

### Root Layout
- Sidebar: Fixed, 256px width (`lg:w-64`)
- Sidebar background: `sky-950`
- Main area: `slate-100` background
- Main area: Rounded corners on lg+ (`lg:rounded-lg`)
- Container: 16px padding on lg+ (`lg:p-4`)

### Header
- Height: 48px (`h-12`)
- Border: 1px bottom (`border-b border-slate-900/10`)
- Contains breadcrumbs and page-specific actions

### Mobile Header
- Height: 64px
- Fixed top position
- Hamburger menu + logo + avatar

---

## Sidebar Navigation

**Dark variant** (default):
- Text: white inactive, `slate-800` active
- Background: transparent inactive, `slate-100` active
- Hover: `slate-200` background

**Light variant** (settings pages):
- Text: `slate-800`
- Background: transparent inactive, white active

**Nav item traits**:
- Rounded-md (`rounded-md`)
- 8px padding (`px-2 py-2`)
- 14px font (`text-sm`)
- Duotone icons
- Badge: `sky-700` background, white text, rounded-xl

**Nav sections**:
- Section title: 14px, `slate-500`
- Items grouped with 4px gap (`space-y-1`)

---

## Cards

**Standard card**:
- Background: white
- Shadow: `shadow-xs`
- Border radius: 8px on md+ (`md:rounded-lg`)
- Negative margin mobile, normal on desktop (`-mx-4 md:mx-0`)

**Card title**: 18px (`text-lg`), medium weight, `slate-800`.

**Card badge**: 12px, medium, `slate-800` text, `slate-200` background, pill shape.

---

## Page Structure

**Page component**:
- Fade-in animation (opacity 0 to 1, 400ms)
- Flex column layout

**Header bar**:
- 48px height (`h-12`)
- Bottom border
- Breadcrumb navigation

**Breadcrumbs**:
- Home icon + chevron separators
- 14px, `slate-700`
- Hover: 80% opacity

**Back link**:
- Chevron appears on hover (xl+)
- Text transitions to `slate-700` on hover

---

## Surface Components

**Page.Surface**:
- White background
- Rounded corners on xl+ (`xl:rounded-lg`)
- Shadow on xl+ (`xl:shadow-xs`)
- Overflow hidden

---

## Buttons

Uses shared button components from common library (see console.md).

**Create menu button**:
- White background, `slate-700` text
- 32x32px (`w-8 h-8`)
- Rounded-md
- 1px `gray-200` ring

---

## Form Elements

Uses shared input components from common library (see console.md).

---

## Wizard/Stepper

**Wizard header**:
- Title: 18px (`text-lg`), medium, `slate-800`
- Description: 14px (`text-sm`), `slate-500`
- 4px gap between title and description

**Wizard footer**:
- Top border
- Flex layout with right-aligned buttons
- 16px padding

---

## Mobile Menu

- Backdrop: `slate-100/75` (75% opacity)
- Panel: `sky-950` background
- Max-width: 256px (`max-w-64`)
- Slide-in animation (300ms)
- Close button: White pill with gray ring

---

## Motion

- Page transitions: Fade in (400ms ease-in-out)
- Sidebar: Slide in/out (300ms)
- Mobile menu: Slide + fade (300ms)
- Hover states: Color transitions (300ms)

---

## Icons

Font Awesome Pro:
- Navigation: Duotone style (`fa-duotone`)
- Actions: Regular style
- Size: 14-16px typical

---

## Design Principles

1. **Professional aesthetic** - Traditional admin panel look
2. **Dark sidebar** - `sky-950` creates clear visual hierarchy
3. **Light content area** - `slate-100` background with white cards
4. **Subtle shadows** - `shadow-xs` for depth
5. **Consistent spacing** - 16px base unit
6. **Responsive** - Mobile-first with enhanced desktop layouts
7. **Smooth transitions** - 300-400ms for page and menu animations
