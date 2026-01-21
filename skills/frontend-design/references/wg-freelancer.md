# Freelancer App Design Language

Visual design reference for the WorkGenius Freelancer application (app.workgenius.com/freelancer). Tailwind CSS classes provided.

---

## Visual Style

**Glassmorphism theme**: Translucent surfaces with backdrop blur, layered transparencies. Softer, more organic feel compared to admin.

---

## Colors

### Primary

| Usage | Tailwind | Hex |
|-------|----------|-----|
| Primary action | `slate-700` | #334155 |
| Primary hover | `slate-600` | #475569 |
| Translucent surface | `white/40` | rgba(255,255,255,0.4) |
| Translucent hover | `white/60` | rgba(255,255,255,0.6) |
| Solid surface | `white` | #ffffff |
| Accent (AI features) | `blue-600` | #2563eb |

### Semantic

| Meaning | Background | Text |
|---------|------------|------|
| Success | `emerald-50` | `emerald-700` |
| Warning | `amber-50` | `amber-700` |
| Error | `red-50` | `red-700` |
| Info | `sky-50` | `sky-700` |

### Neutrals

| Purpose | Tailwind |
|---------|----------|
| Page background | `slate-300` with radial gradient |
| Card surface (outer) | `white/40` + `backdrop-blur-2xl` |
| Card surface (nested) | `slate-50/50` |
| Primary text | `slate-700` |
| Secondary text | `slate-500` |
| Body text (muted) | `slate-600` |
| Placeholder | `slate-400` |
| Borders | `slate-200` / `slate-300` |

---

## Page Background

Radial gradient anchored at bottom center:

```css
bg-slate-300 bg-radial-[at_50%_100%] from-[#C8DBFF] from-0% to-[var(--color-slate-300)] to-65%
```

- Base: `slate-300` (#cbd5e1)
- Gradient start: `#C8DBFF` (soft blue) at center-bottom
- Gradient end: `slate-300` at 65%

---

## CSS Custom Properties

```css
--header-height: 5rem;           /* 80px */
--main-area-padding-y: 0.625rem; /* 10px */
--logo-size-sm: 2rem;            /* 32px - mobile logo */
--sidebar-width: 13.75rem;       /* 220px */
--container-padding: 1.063rem;   /* ~17px */
--app-col-gap: 0.75rem;          /* 12px */
--nav-item-height: 3rem;         /* 48px */
--onboarding-max-width: 100%;
```

**2xl breakpoint overrides** (implied from code patterns):
- Sidebar width: ~300px
- Nav item height: ~56px
- Container padding: ~20px
- Column gap: ~16px

---

## Typography

| Element | Classes | Notes |
|---------|---------|-------|
| Page title | `text-2xl font-bold` | 24px |
| Section/Card title | `text-lg text-slate-500` | 18px, muted |
| Body text | `text-sm/5` or `text-base/6` | 14px or 16px with line-height |
| Nav item text | `text-sm/5 font-medium text-slate-700` | 14px, medium weight |
| Empty state title | `text-base font-semibold text-slate-700` | 16px, semibold |
| Empty state body | `text-slate-600 text-sm` | 14px, muted |
| Meta/caption | `text-sm text-slate-500` | 14px, secondary |
| Breadcrumb (current) | `text-slate-500 truncate` | Muted, truncated |

**2xl breakpoint**: Nav and body text upgrade to `text-base/6` (16px).

---

## Spacing

| Context | Value |
|---------|-------|
| Container padding | `px-(--container-padding)` (~17px) |
| Column/row gap | `gap-(--app-col-gap)` (12px) |
| Card padding | `p-4 md:p-6` (16px mobile, 24px desktop) |
| Section spacing | `space-y-4 2xl:space-y-6` |
| Nav group heading margin | `mb-2` |
| Main area vertical padding | `py-(--main-area-padding-y)` (10px) |

---

## Buttons

**Shape**: Pill-shaped (`rounded-full`).

### Variants

| Variant | Background | Hover | Text | Border |
|---------|------------|-------|------|--------|
| Primary | `slate-700` | `slate-600` | white | — |
| Default | white | — | `slate-700` | `slate-200` |
| Faded/Ghost | `white/40` | `white/60` | `slate-700` | — |
| Icon button | `white/40` | `white/60` | `slate-700` | `slate-200` |

### Button Sizing

| Type | Classes |
|------|---------|
| Standard | `px-8 py-2 text-base font-medium` |
| Small/Ghost | `p-2` |
| Icon button (square) | `size-10` or `size-9` |

### States

```css
/* Disabled */
disabled:opacity-60 disabled:cursor-not-allowed disabled:bg-transparent
```

---

## Form Elements

**Text inputs**: 
- Height: 48px (`h-12`)
- Background: white
- Border: 1px `slate-300`
- Radius: 12px (`rounded-xl`)
- Focus: 1px `slate-800` ring
- Invalid: `red-300` border

**Checkboxes**: 20×20px, `rounded-sm`, `sky-700` when checked.

**Radio buttons**: 16×16px circle, `slate-700` fill when selected (5px border), `slate-300` border unselected.

**Select**: Same as input, placeholder `text-slate-400`.

---

## Layout

### Container

```html
<div class="px-(--container-padding)">
  <div class="2xl:max-w-[120rem] 2xl:mx-auto relative">
    <!-- content -->
  </div>
</div>
```

### Grid (Dashboard)

```html
<div class="grid 2xl:grid-cols-2 gap-(--app-col-gap)">
  <!-- Two-column on 2xl, single column below -->
</div>
```

### Sidebar

- Width: `w-(--sidebar-width)` (220px)
- Position: `sticky top-0`
- Structure: Flex column, full height
- Contains: Logo, nav sections, AI recruiter card, profile link

### Nav Items

```html
<!-- Active -->
<a class="rounded-2xl h-(--nav-item-height) px-4 flex items-center gap-x-2 
          text-sm/5 font-medium text-slate-700 bg-white">
  
<!-- Inactive -->
<a class="rounded-2xl h-(--nav-item-height) px-4 flex items-center gap-x-2 
          text-sm/5 font-medium text-slate-700 bg-white/40 hover:bg-white">
```

### Nav Section Headers

```html
<h2 class="2xl:text-base/6 text-sm/5 text-slate-500 mb-2">Section Name</h2>
<div class="space-y-1">
  <!-- nav items -->
</div>
```

### Header

- Height: `h-(--header-height)` (80px)
- Layout: Flex with gap, space-between on mobile
- Contains: Logo (mobile), breadcrumbs, profile button (desktop), menu button (mobile)

---

## Cards

### Outer Card (Glassmorphism)

```html
<div class="block p-4 md:p-6 relative">
  <div class="absolute inset-0 z-0 bg-white/40 backdrop-blur-2xl" 
       style="border-radius: 24px;"></div>
  <div class="relative z-10 flex flex-col gap-2 w-full h-full">
    <!-- content -->
  </div>
</div>
```

- Background layer: `bg-white/40 backdrop-blur-2xl`
- Border radius: 24px (`rounded-3xl`)
- Padding: `p-4 md:p-6`
- Z-index layering for blur effect

### Nested Card (Inner Content)

```html
<div class="block p-4 md:p-6 relative">
  <div class="absolute inset-0 z-0 bg-slate-50/50" 
       style="border-radius: 16px;"></div>
  <div class="relative z-10">
    <!-- content -->
  </div>
</div>
```

- Background: `bg-slate-50/50` (not white/70)
- Border radius: 16px (`rounded-2xl`)

### Card Header

```html
<div class="flex justify-between items-center gap-4">
  <h2 class="text-lg text-slate-500">Title</h2>
  <!-- optional action button -->
</div>
```

### Card Link Button (Arrow)

```html
<span class="size-10 rounded-full bg-white/40 border border-slate-200 
             text-slate-700 text-sm flex items-center justify-center 
             group-hover:bg-white/60 transition-colors">
  <!-- arrow icon -->
</span>
```

---

## Empty States

```html
<div class="flex flex-col text-center md:py-14 items-center justify-center 
            max-w-lg mx-auto gap-2 relative z-10">
  <svg class="block mx-auto mb-2 text-slate-400 fa-3x"><!-- icon --></svg>
  <h2 class="text-base font-semibold text-slate-700">Title</h2>
  <p class="text-slate-600 text-sm whitespace-pre-line">Description</p>
</div>
```

- Icon: `text-slate-400`, 3x size (48px)
- Title: `text-base font-semibold text-slate-700`
- Description: `text-slate-600 text-sm`
- Desktop padding: `md:py-14`

---

## List Items (Job Listings)

### Container

```html
<ul class="flex flex-col w-full divide-y divide-slate-300">
```

### Item Structure

```html
<li class="w-full">
  <a class="p-4 relative block group cursor-pointer">
    <div class="absolute inset-0 z-0 bg-slate-50/50 group-hover:bg-slate-50 
                transition-colors" style="border-radius: 16px;"></div>
    <div class="flex w-full flex-col gap-4 relative z-10">
      <!-- Title row -->
      <span class="text-slate-700 text-base font-medium">Title</span>
      <!-- Meta row -->
      <span class="flex flex-wrap items-center gap-x-4 xl:gap-x-6 gap-y-2">
        <!-- meta items -->
      </span>
    </div>
  </a>
</li>
```

### Meta Item

```html
<span class="flex items-center gap-1.5 text-sm text-slate-700 
             [&>svg]:h-4 [&>svg]:text-slate-500 truncate font-medium">
  <svg><!-- icon --></svg>
  <span>Value</span>
</span>
```

### Date (Right-aligned)

```html
<span class="hidden md:block ms-auto text-sm text-slate-500">26 Nov 2025</span>
```

---

## Stats Cards

```html
<div class="flex flex-wrap gap-2">
  <div class="p-4 md:p-6 relative grow py-6 px-4 flex items-center">
    <div class="absolute inset-0 z-0 bg-slate-50/50" 
         style="border-radius: 16px;"></div>
    <div class="relative z-10 flex flex-col gap-2 w-full h-full">
      <div class="flex gap-(--app-col-gap) h-full items-center justify-between">
        <span class="text-sm/5 text-slate-500">Label</span>
        <span class="text-lg/7 text-slate-700">Value</span>
      </div>
    </div>
  </div>
</div>
```

---

## AI Recruiter Card (Sidebar)

```html
<div class="bg-white/40 p-6 rounded-2xl flex flex-col items-center text-center 
            2xl:text-base/6 text-sm/5 mt-4">
  <span class="flex justify-center text-base text-blue-600 mb-6">
    <svg class="fa-sparkles fa-2x"><!-- sparkles icon --></svg>
  </span>
  <span class="font-bold text-slate-700 text-center mb-4">Talk to Ai Recruiter</span>
  <ul class="flex flex-col gap-1 w-full text-center">
    <li>
      <button class="rounded-full flex w-full justify-center items-center p-2 
                     text-slate-700 bg-white/40 hover:bg-white/60 transition-colors 
                     disabled:opacity-60 disabled:cursor-not-allowed disabled:bg-transparent">
        Button Text
      </button>
    </li>
  </ul>
</div>
```

- Accent icon: `text-blue-600`
- Title: `font-bold text-slate-700`
- Button list gap: `gap-1`

---

## Profile/User Button

```html
<a class="bg-white/40 rounded-full hover:bg-white/60 transition-colors block p-0.5">
  <div class="min-w-0 flex items-center justify-between gap-x-3">
    <img class="rounded-full inline-block size-9" src="...">
    <span class="text-slate-700 text-sm/5">User Name</span>
    <div class="size-9 flex items-center justify-center bg-white/40 rounded-full">
      <svg class="fa-gear text-xs"><!-- gear icon --></svg>
    </div>
  </div>
</a>
```

- Container: `bg-white/40 rounded-full p-0.5`
- Avatar: `size-9 rounded-full`
- Name: `text-slate-700 text-sm/5`
- Settings button: `size-9 bg-white/40 rounded-full`

---

## Mobile Menu Button

```html
<button class="size-(--logo-size-sm) bg-white/40 rounded-full 
               hover:bg-white/60 transition-colors flex items-center justify-center">
  <svg class="fa-bars"><!-- hamburger icon --></svg>
</button>
```

---

## Modals

- Backdrop: `slate-800/40` with `backdrop-blur-sm`
- Panel: `bg-white/70`, 24px radius (`rounded-3xl`), 24px padding
- Max-width: 896px (`max-w-4xl`)
- Close button: Faded pill button with X icon
- Animation: Fade + scale (0.95 to 1)

---

## Alerts

- Border radius: 32px (`rounded-[2rem]`)
- Padding: 16px left, 8px right/vertical
- Icon + content layout
- Uses semantic color variants

---

## Tabs

**Pill tabs**:
- Container: `bg-white/40 rounded-full`
- Active indicator: `bg-white rounded-full`, animated position
- Tab text: 14px, `slate-700`, selected `slate-800`
- Animation: Indicator slides to active tab

---

## Motion

Heavy use of Motion (Framer Motion):
- **Layout animations**: Cards use inline `style` with animated `opacity` and `border-radius`
- **Stagger**: Form fields and list items reveal with staggered delay
- **Page transitions**: Fade + slide animations
- **Timings**: 200-300ms ease-out typical

---

## Icons

**Font Awesome Pro** with three styles:

| Style | Usage | Example |
|-------|-------|---------|
| Duotone (`fad`) | Navigation icons | `fa-duotone fa-grid-2` |
| Regular (`far`) | Action/meta icons | `fa-regular fa-gear` |
| Solid (`fas`) | Decorative/accent | `fa-solid fa-sparkles` |

**Sizing**:
- Navigation: Default (~16px)
- Meta icons: `h-4` (16px) via `[&>svg]:h-4`
- Large decorative: `fa-2x`, `fa-3x`
- Small icons: `text-xs`

---

## Transitions

Standard transition class used throughout:

```css
transition-colors
```

Applied to: buttons, nav items, cards with hover states.

---

## Responsive Breakpoints

| Breakpoint | Key Changes |
|------------|-------------|
| Default (mobile) | Single column, compact nav, hamburger menu |
| `md` | Card padding increases (`p-6`), date shows in listings |
| `lg` | Sidebar visible, desktop nav, profile in header |
| `xl` | Meta item gap increases (`gap-x-6`) |
| `2xl` | Two-column dashboard, larger typography, max-width container |

---

## Design Principles

1. **Glassmorphism** — Translucent `white/40` surfaces with `backdrop-blur-2xl`
2. **Layered backgrounds** — Absolute positioned blur layers with relative z-10 content
3. **Organic shapes** — Pill buttons (`rounded-full`), large radii (16px, 24px)
4. **Subtle nested cards** — `slate-50/50` inner cards within glass outer cards
5. **Muted palette** — Slate grays (`slate-500`, `slate-700`) over pure blacks
6. **Consistent spacing** — CSS custom properties for responsive sizing
7. **Smooth transitions** — `transition-colors` on interactive elements
8. **Mobile-first** — Progressive enhancement with `md:`, `lg:`, `2xl:` breakpoints