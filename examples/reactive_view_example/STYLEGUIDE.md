# ReactiveView Design System & Style Guide

This document defines the design system for the ReactiveView example application. It provides consistent design tokens, component patterns, and implementation guidelines for developers building with SolidJS and Tailwind CSS.

## Table of Contents

1. [Design Principles](#design-principles)
2. [Color Palette](#color-palette)
3. [Typography](#typography)
4. [Spacing](#spacing)
5. [Components](#components)
6. [Layout Patterns](#layout-patterns)
7. [Icons](#icons)
8. [Accessibility](#accessibility)

---

## Design Principles

1. **Clean & Modern** - Minimal visual noise, generous whitespace, subtle shadows
2. **Consistent** - Unified patterns across all pages and components
3. **Accessible** - Proper contrast ratios, focus states, and semantic markup
4. **Responsive** - Mobile-first approach with thoughtful breakpoints

---

## Color Palette

### Primary Colors

| Name | Tailwind Class | Hex | Usage |
|------|---------------|-----|-------|
| Primary | `blue-600` | `#2563eb` | Primary actions, links, active states |
| Primary Hover | `blue-700` | `#1d4ed8` | Hover state for primary elements |
| Primary Light | `blue-50` | `#eff6ff` | Backgrounds, subtle highlights |
| Primary Border | `blue-200` | `#bfdbfe` | Borders for primary-themed elements |

### Neutral Colors

| Name | Tailwind Class | Hex | Usage |
|------|---------------|-----|-------|
| Text Primary | `gray-900` | `#111827` | Headings, important text |
| Text Secondary | `gray-600` | `#4b5563` | Body text, descriptions |
| Text Muted | `gray-500` | `#6b7280` | Helper text, timestamps |
| Text Placeholder | `gray-400` | `#9ca3af` | Placeholder text, disabled |
| Border | `gray-200` | `#e5e7eb` | Default borders |
| Border Light | `gray-100` | `#f3f4f6` | Subtle dividers |
| Background | `gray-50` | `#f9fafb` | Page backgrounds |
| Surface | `white` | `#ffffff` | Cards, modals |

### Semantic Colors

| Name | Tailwind Class | Hex | Usage |
|------|---------------|-----|-------|
| Success | `emerald-600` | `#059669` | Success states, positive metrics |
| Success Light | `emerald-50` | `#ecfdf5` | Success backgrounds |
| Warning | `amber-600` | `#d97706` | Warning states, caution |
| Warning Light | `amber-50` | `#fffbeb` | Warning backgrounds |
| Error | `red-600` | `#dc2626` | Error states, destructive actions |
| Error Light | `red-50` | `#fef2f2` | Error backgrounds |
| Info | `blue-600` | `#2563eb` | Informational states |
| Info Light | `blue-50` | `#eff6ff` | Info backgrounds |

---

## Typography

### Font Family

```css
font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
```

Tailwind: `font-sans` (default)

### Type Scale

| Name | Tailwind Class | Size | Weight | Usage |
|------|---------------|------|--------|-------|
| Display | `text-4xl font-bold` | 36px | 700 | Page titles |
| Heading 1 | `text-2xl font-bold` | 24px | 700 | Section headings |
| Heading 2 | `text-xl font-semibold` | 20px | 600 | Card titles |
| Heading 3 | `text-lg font-semibold` | 18px | 600 | Subsection headings |
| Body | `text-base` | 16px | 400 | Default body text |
| Body Small | `text-sm` | 14px | 400 | Secondary information |
| Caption | `text-xs` | 12px | 500 | Labels, metadata |
| Overline | `text-xs font-semibold uppercase tracking-wider` | 12px | 600 | Section labels |

### Example Usage

```tsx
// Page title
<h1 class="text-2xl font-bold text-gray-900">Page Title</h1>

// Section heading
<h2 class="text-xl font-semibold text-gray-900">Section Heading</h2>

// Card title
<h3 class="text-lg font-semibold text-gray-900">Card Title</h3>

// Body text
<p class="text-gray-600">Body text content here.</p>

// Overline/label
<span class="text-xs font-semibold text-gray-500 uppercase tracking-wider">
  Label
</span>
```

---

## Spacing

Use Tailwind's default spacing scale consistently:

| Token | Value | Common Usage |
|-------|-------|--------------|
| `1` | 4px | Tight gaps |
| `2` | 8px | Icon gaps, tight padding |
| `3` | 12px | Small padding |
| `4` | 16px | Default padding, card gaps |
| `5` | 20px | Section padding |
| `6` | 24px | Card padding, section gaps |
| `8` | 32px | Large section gaps |
| `10` | 40px | Page section spacing |
| `12` | 48px | Major layout spacing |

### Consistent Patterns

- **Card padding:** `p-6` (24px)
- **Card gap in grids:** `gap-4` or `gap-6`
- **Section spacing:** `space-y-8` or `mb-8`
- **Form field spacing:** `space-y-4`
- **Button group gap:** `gap-2` or `gap-3`

---

## Components

### Buttons

#### Primary Button

```tsx
<button class="inline-flex items-center justify-center px-4 py-2.5 bg-blue-600 text-white text-sm font-medium rounded-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
  Button Text
</button>
```

#### Secondary Button

```tsx
<button class="inline-flex items-center justify-center px-4 py-2.5 bg-white text-gray-700 text-sm font-medium rounded-lg border border-gray-300 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors">
  Button Text
</button>
```

#### Ghost Button

```tsx
<button class="inline-flex items-center justify-center px-4 py-2.5 text-gray-600 text-sm font-medium rounded-lg hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors">
  Button Text
</button>
```

#### Destructive Button

```tsx
<button class="inline-flex items-center justify-center px-4 py-2.5 bg-red-600 text-white text-sm font-medium rounded-lg hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors">
  Delete
</button>
```

#### Destructive Ghost Button

```tsx
<button class="inline-flex items-center justify-center px-4 py-2.5 text-red-600 text-sm font-medium rounded-lg hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-colors">
  Delete
</button>
```

#### Button Sizes

| Size | Classes | Usage |
|------|---------|-------|
| Small | `px-3 py-1.5 text-sm` | Inline actions, table rows |
| Default | `px-4 py-2.5 text-sm` | Standard buttons |
| Large | `px-6 py-3 text-base` | Primary CTAs, hero sections |

---

### Cards

#### Basic Card

```tsx
<div class="bg-white rounded-xl border border-gray-200 p-6">
  <h3 class="text-lg font-semibold text-gray-900 mb-2">Card Title</h3>
  <p class="text-gray-600">Card content goes here.</p>
</div>
```

#### Interactive Card (Clickable)

```tsx
<A
  href="/path"
  class="block bg-white rounded-xl border border-gray-200 p-6 hover:border-blue-200 hover:shadow-md transition-all group"
>
  <h3 class="text-lg font-semibold text-gray-900 group-hover:text-blue-600 mb-2">
    Card Title
  </h3>
  <p class="text-gray-600">Card content goes here.</p>
</A>
```

#### Stat Card

```tsx
<div class="bg-white rounded-xl border border-gray-200 p-6">
  <div class="flex items-center gap-3 mb-3">
    <div class="w-10 h-10 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center">
      {/* Icon */}
    </div>
    <span class="text-sm font-medium text-gray-500">Total Users</span>
  </div>
  <div class="text-3xl font-bold text-gray-900">1,234</div>
  <div class="flex items-center gap-1 mt-2 text-sm text-emerald-600">
    <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18" />
    </svg>
    <span>12% from last month</span>
  </div>
</div>
```

---

### Form Elements

#### Text Input

```tsx
<div class="space-y-1.5">
  <label for="email" class="block text-sm font-medium text-gray-700">
    Email
  </label>
  <input
    type="email"
    id="email"
    name="email"
    class="w-full px-3 py-2.5 bg-white border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-shadow"
    placeholder="you@example.com"
  />
</div>
```

#### Input with Error

```tsx
<div class="space-y-1.5">
  <label for="email" class="block text-sm font-medium text-gray-700">
    Email
  </label>
  <input
    type="email"
    id="email"
    class="w-full px-3 py-2.5 bg-white border border-red-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-transparent"
  />
  <p class="text-sm text-red-600">Please enter a valid email address.</p>
</div>
```

#### Checkbox

```tsx
<label class="flex items-center gap-3 cursor-pointer">
  <input
    type="checkbox"
    class="w-4 h-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 focus:ring-2"
  />
  <span class="text-sm text-gray-700">Remember me</span>
</label>
```

#### Toggle Switch

```tsx
<label class="relative inline-flex items-center cursor-pointer">
  <input type="checkbox" class="sr-only peer" checked={value()} onChange={...} />
  <div class="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-blue-500 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
</label>
```

#### Select

```tsx
<div class="space-y-1.5">
  <label for="country" class="block text-sm font-medium text-gray-700">
    Country
  </label>
  <select
    id="country"
    class="w-full px-3 py-2.5 bg-white border border-gray-300 rounded-lg text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
  >
    <option>United States</option>
    <option>Canada</option>
  </select>
</div>
```

---

### Navigation

#### Main Navigation Item

```tsx
// Default state
<A
  href="/path"
  class="px-4 py-2 text-sm font-medium text-gray-600 rounded-lg hover:bg-gray-100 hover:text-gray-900 transition-colors"
>
  Link
</A>

// Active state
<A
  href="/path"
  class="px-4 py-2 text-sm font-medium text-blue-700 bg-blue-50 rounded-lg"
>
  Active Link
</A>
```

#### Sidebar Navigation Item

```tsx
// Default state
<A
  href="/path"
  class="flex items-center gap-3 px-3 py-2.5 text-sm font-medium text-gray-600 rounded-lg hover:bg-gray-100 hover:text-gray-900 transition-colors"
>
  <IconComponent class="w-5 h-5" />
  Link Text
</A>

// Active state
<A
  href="/path"
  class="flex items-center gap-3 px-3 py-2.5 text-sm font-medium text-blue-700 bg-blue-50 rounded-lg"
>
  <IconComponent class="w-5 h-5" />
  Active Link
</A>
```

---

### Badges & Status

#### Badge

```tsx
// Default
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
  Badge
</span>

// Primary
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
  Primary
</span>

// Success
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-800">
  Success
</span>

// Warning
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-amber-100 text-amber-800">
  Warning
</span>

// Error
<span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
  Error
</span>
```

---

### Alerts & Info Boxes

#### Info Box

```tsx
<div class="bg-blue-50 border border-blue-200 rounded-xl p-4">
  <div class="flex gap-3">
    <svg class="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
    <div>
      <h4 class="text-sm font-semibold text-blue-900">Information</h4>
      <p class="text-sm text-blue-700 mt-1">This is an informational message.</p>
    </div>
  </div>
</div>
```

#### Success Alert

```tsx
<div class="bg-emerald-50 border border-emerald-200 rounded-xl p-4">
  <div class="flex gap-3">
    <svg class="w-5 h-5 text-emerald-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
    </svg>
    <p class="text-sm text-emerald-700">Changes saved successfully!</p>
  </div>
</div>
```

#### Error Alert

```tsx
<div class="bg-red-50 border border-red-200 rounded-xl p-4">
  <div class="flex gap-3">
    <svg class="w-5 h-5 text-red-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
    </svg>
    <p class="text-sm text-red-700">An error occurred. Please try again.</p>
  </div>
</div>
```

#### Warning Alert

```tsx
<div class="bg-amber-50 border border-amber-200 rounded-xl p-4">
  <div class="flex gap-3">
    <svg class="w-5 h-5 text-amber-600 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
    </svg>
    <p class="text-sm text-amber-700">Please review before continuing.</p>
  </div>
</div>
```

---

### Tables

#### Basic Table

```tsx
<div class="bg-white rounded-xl border border-gray-200 overflow-hidden">
  <table class="w-full">
    <thead>
      <tr class="bg-gray-50 border-b border-gray-200">
        <th class="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
          Name
        </th>
        <th class="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
          Status
        </th>
        <th class="px-6 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">
          Actions
        </th>
      </tr>
    </thead>
    <tbody class="divide-y divide-gray-200">
      <tr class="hover:bg-gray-50 transition-colors">
        <td class="px-6 py-4 text-sm text-gray-900">John Doe</td>
        <td class="px-6 py-4">
          <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-100 text-emerald-800">
            Active
          </span>
        </td>
        <td class="px-6 py-4 text-right">
          <button class="text-sm text-blue-600 hover:text-blue-700 font-medium">
            Edit
          </button>
        </td>
      </tr>
    </tbody>
  </table>
</div>
```

#### Simple List Table (No Header)

```tsx
<div class="bg-white rounded-xl border border-gray-200 divide-y divide-gray-200">
  <div class="px-4 py-3 flex items-center justify-between hover:bg-gray-50 transition-colors">
    <span class="text-sm text-gray-900">/dashboard</span>
    <span class="text-sm font-medium text-gray-600">1,234 views</span>
  </div>
  <div class="px-4 py-3 flex items-center justify-between hover:bg-gray-50 transition-colors">
    <span class="text-sm text-gray-900">/users</span>
    <span class="text-sm font-medium text-gray-600">892 views</span>
  </div>
</div>
```

---

### Avatars

#### User Avatar (Initials)

```tsx
// Small
<div class="w-8 h-8 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center text-xs font-semibold">
  AJ
</div>

// Medium
<div class="w-10 h-10 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center text-sm font-semibold">
  AJ
</div>

// Large
<div class="w-12 h-12 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center text-base font-semibold">
  AJ
</div>
```

#### Avatar with Status

```tsx
<div class="relative">
  <div class="w-10 h-10 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center text-sm font-semibold">
    AJ
  </div>
  <span class="absolute bottom-0 right-0 w-3 h-3 bg-emerald-500 border-2 border-white rounded-full"></span>
</div>
```

---

### Code Blocks

```tsx
<pre class="bg-gray-900 text-gray-100 p-4 rounded-xl overflow-x-auto text-sm leading-relaxed">
  <code>{`const [count, setCount] = createSignal(0);`}</code>
</pre>
```

#### Inline Code

```tsx
<code class="px-1.5 py-0.5 bg-gray-100 text-gray-800 rounded text-sm font-mono">
  variable
</code>
```

---

## Layout Patterns

### Page Container

```tsx
<div class="min-h-screen bg-gray-50">
  <Header />
  <main class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    {/* Page content */}
  </main>
</div>
```

### Page Header

```tsx
<div class="mb-8">
  <h1 class="text-2xl font-bold text-gray-900">Page Title</h1>
  <p class="mt-1 text-gray-600">Page description or subtitle.</p>
</div>
```

### Page Header with Actions

```tsx
<div class="flex items-center justify-between mb-8">
  <div>
    <h1 class="text-2xl font-bold text-gray-900">Page Title</h1>
    <p class="mt-1 text-gray-600">Page description.</p>
  </div>
  <div class="flex items-center gap-3">
    <button class="btn-secondary">Secondary</button>
    <button class="btn-primary">Primary Action</button>
  </div>
</div>
```

### Dashboard Layout (Sidebar + Content)

```tsx
<div class="flex min-h-screen bg-gray-50">
  {/* Sidebar */}
  <aside class="w-64 bg-white border-r border-gray-200 flex-shrink-0">
    <div class="p-6">
      <h2 class="text-lg font-semibold text-gray-900 mb-6">Dashboard</h2>
      <nav class="space-y-1">
        {/* Nav items */}
      </nav>
    </div>
  </aside>

  {/* Main content */}
  <div class="flex-1 flex flex-col">
    <header class="bg-white border-b border-gray-200 px-6 py-4">
      {/* Header content */}
    </header>
    <main class="flex-1 p-6">
      {/* Page content */}
    </main>
  </div>
</div>
```

### Grid Layouts

```tsx
// 3-column responsive grid
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  {/* Cards */}
</div>

// 2-column responsive grid
<div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
  {/* Cards */}
</div>
```

---

## Icons

Use inline SVG icons for consistency. Below are commonly used icons:

### Arrow Icons

```tsx
// Arrow Left
<svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
</svg>

// Arrow Right
<svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3" />
</svg>

// Chevron Right
<svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
</svg>

// Arrow Up (for positive metrics)
<svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 10l7-7m0 0l7 7m-7-7v18" />
</svg>

// Arrow Down (for negative metrics)
<svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 14l-7 7m0 0l-7-7m7 7V3" />
</svg>
```

### UI Icons

```tsx
// Check
<svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
</svg>

// X / Close
<svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
</svg>

// Menu / Hamburger
<svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
</svg>

// Settings / Cog
<svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
</svg>

// Users
<svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
</svg>

// Chart Bar
<svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
</svg>

// Home
<svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
</svg>

// Currency Dollar
<svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
</svg>

// Activity / Pulse
<svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
</svg>
```

---

## Accessibility

### Focus States

All interactive elements should have visible focus states:

```css
focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2
```

### Color Contrast

- Text on white backgrounds: minimum `gray-600` for body, `gray-900` for headings
- Text on colored backgrounds: ensure WCAG AA compliance (4.5:1 ratio)

### Semantic HTML

- Use proper heading hierarchy (`h1` > `h2` > `h3`)
- Use `<button>` for actions, `<a>` for navigation
- Use `<label>` elements properly associated with form inputs
- Use `aria-label` for icon-only buttons

### Keyboard Navigation

- All interactive elements should be keyboard accessible
- Use `tabindex` appropriately
- Provide skip links for complex layouts

---

## SolidJS-Specific Patterns

### Conditional Styling

```tsx
<div class={`base-classes ${condition() ? "active-classes" : "inactive-classes"}`}>
```

### Control Flow Components

Always use SolidJS control flow components:

```tsx
// Conditional rendering
<Show when={condition()}>
  <Component />
</Show>

// List rendering
<For each={items()}>
  {(item) => <Component item={item} />}
</For>

// Multiple conditions
<Switch>
  <Match when={condition1()}>
    <Component1 />
  </Match>
  <Match when={condition2()}>
    <Component2 />
  </Match>
</Switch>
```

### Event Handlers

```tsx
// Use e.target (not e.currentTarget in SolidJS)
<input onChange={(e) => setValue(e.target.value)} />
```

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-13 | Initial style guide created |
