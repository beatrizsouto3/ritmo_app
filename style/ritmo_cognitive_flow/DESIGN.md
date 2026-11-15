---
name: Ritmo Cognitive Flow
colors:
  surface: '#f8f9ff'
  surface-dim: '#c4dcff'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e6eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4ff'
  on-surface: '#001c38'
  on-surface-variant: '#42474f'
  inverse-surface: '#18314e'
  inverse-on-surface: '#eaf1ff'
  outline: '#737780'
  outline-variant: '#c2c6d1'
  surface-tint: '#346095'
  primary: '#002b52'
  on-primary: '#ffffff'
  primary-container: '#0a4174'
  on-primary-container: '#85aee8'
  inverse-primary: '#a3c9ff'
  secondary: '#33628a'
  on-secondary: '#ffffff'
  secondary-container: '#a4d0fe'
  on-secondary-container: '#2a5981'
  tertiary: '#002e39'
  on-tertiary: '#ffffff'
  tertiary-container: '#004656'
  on-tertiary-container: '#75b4c9'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d3e3ff'
  primary-fixed-dim: '#a3c9ff'
  on-primary-fixed: '#001c39'
  on-primary-fixed-variant: '#16487b'
  secondary-fixed: '#cee5ff'
  secondary-fixed-dim: '#9ecbf8'
  on-secondary-fixed: '#001d33'
  on-secondary-fixed-variant: '#164a70'
  tertiary-fixed: '#b3ebff'
  tertiary-fixed-dim: '#90d0e5'
  on-tertiary-fixed: '#001f27'
  on-tertiary-fixed-variant: '#004e5f'
  background: '#f8f9ff'
  on-background: '#001c38'
  surface-variant: '#d3e4ff'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 56px
    fontWeight: '700'
    lineHeight: 64px
    letterSpacing: -0.03em
  display-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.005em
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0em
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: 0em
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.25rem
---

## Brand & Style

This design system is engineered for high-performance learners, medical/bar exam candidates, and deep-work practitioners seeking cognitive endurance and clarity. Grounded in a modern minimalist and neuro-ergonomic aesthetic, it prioritizes visual serenity, low sensory friction, and structured progress tracking across Spaced Repetition (SRS), Pomodoro cycles, and syllabus management.

The brand persona is disciplined, supportive, and methodically precise. Every visual decision avoids anxiety-inducing gamification tropes in favor of composed rhythm and academic confidence. The visual language blends soft tactile elevation with cool, aquatic blue-slate monochromatic tiers inspired directly by cognitive recovery states and atmospheric depth.

## Colors

The palette is derived directly from the deep-to-light slate gradient spectrum, balancing deep nautical tones with ice-tinted surfaces.

### Primary Roles & Functional Hierarchy
- **Deep Navy (`#001D39`):** Represents high-authority text, high-contrast structural headings, active dark mode foundations, and focused session banners.
- **Primary Blue (`#0A4174`):** Primary action color, active tab bar anchors, high-priority timer start buttons, and SRS review cards.
- **Steel Slate Blue (`#49769F`):** Secondary controls, subtle chart lines, active filters, and secondary button fills.
- **Muted Teal/Cyan (`#4E8EA2` and `#6EA2B3`):** Cognitive state accents, memory retention badges, Pomodoro rest intervals, and deck categories.
- **Sky Tint (`#7BBDE8`):** Retention indicators, streak completions, progress ring highlights, and interactive toggles.
- **Ice Blue (`#BDD8E9`):** Subdued card containers, chip backgrounds, SRS interval pill containers, and focus counters.
- **Canvas Neutral (`#F4F8FA`):** Ambient background providing low glare and sustained visual comfort during long reading bouts.

### Contrast & State Logic
- Interactive hover/press states transition downwards along the hue spectrum (e.g., `#0A4174` presses into `#001D39`).
- Status alerts maintain academic restraint: success states utilize `#4E8EA2` and `#7BBDE8`, while warnings use warm slate undertones rather than aggressive pure primaries.

## Typography

Plus Jakarta Sans governs the entire hierarchy. Its clean geometric underpinnings and friendly rounded aperture balance the structural rigors of technical study with warm approachability.

- **Display & Numerical Readouts (`display-lg`):** Reserved for active Pomodoro countdowns and recall retention rates. Numbers use tabular figures (`tnum`) to eliminate layout jitter.
- **Headlines (`headline-lg` through `headline-sm`):** Deliver decisive hierarchical section titles, subject names, and review module headers.
- **Body (`body-lg`, `body-md`):** Formulated with comfortable line heights to facilitate prolonged flashcard reading and markdown summary consumption.
- **Labels (`label-lg` through `label-sm`):** Set with slight tracking expansions (`0.01em` to `0.04em`) to ensure legibility on compact metadata tags, retention intervals (e.g., "1d", "3d", "2w"), and timer mode selectors.

## Layout & Spacing

The interface implements a fluid mobile-first grid bounded by strict padding rhythms. 

- **Canvas & Margins:** Standard mobile canvas maintains an outer gutter margin of `1.25rem` (20px), expanding to `1.5rem` (24px) on tablet split-views.
- **Vertical Flow Rhythm:** Stacked cards and study lists use `space-md` (16px) for item gaps. Sub-elements within cards (question, answer partition, action pills) utilize `space-sm` (8px).
- **Session Modules:** SRS review modes collapse outer padding to allocate maximum surface area for card content while keeping actionable response triggers anchored cleanly in the lower thumb zone.

## Elevation & Depth

Depth in this design system is inspired directly by layered tactile cards with ambient cold-toned shadows, as demonstrated in the visual reference. Rather than flat structural outlines, surfaces float softly above one another.

- **Elevation 0 (Canvas):** Clean `#F4F8FA` neutral tone.
- **Elevation 1 (Surface Cards & Lists):** Pure `#FFFFFF` or `#BDD8E9` tinted surfaces with ambient multi-stop drop shadows: `box-shadow: 0 4px 18px -2px rgba(0, 29, 57, 0.07), 0 2px 6px -1px rgba(0, 29, 57, 0.04)`.
- **Elevation 2 (Floating Action Triggers & Modals):** `box-shadow: 0 10px 30px -4px rgba(0, 29, 57, 0.14), 0 4px 12px -2px rgba(0, 29, 57, 0.06)`.
- **Elevation 3 (Active SRS Flip Card & Bottom Sheets):** `box-shadow: 0 20px 40px -6px rgba(0, 29, 57, 0.22)`.
- **Glass Accents:** Translucent header navigation bars apply `backdrop-filter: blur(16px)` with `background: rgba(244, 248, 250, 0.82)`.

## Shapes

Shape geometry directly mirrors the smooth stadium pills and exaggerated rounded card contours of the reference:

- **Cards & Primary Modules:** Employ `rounded-2xl` (1.5rem / 24px) up to `rounded-3xl` (2rem / 32px) on prominent focus cards.
- **Controls & Buttons:** Fully rounded pill forms (`rounded-full` / 9999px) for primary buttons, timer toggles, and SRS difficulty response buttons.
- **Badges & Chips:** Stadium capsule geometry (`rounded-full`) containing concise metadata.
- **Form Inputs:** Soft unified contours matching `rounded-2xl` (1rem / 16px) to maintain a friendly, calm interaction footprint.

## Components

### Buttons
- **Primary Action (Start Focus / Reveal Answer):** Full pill (`rounded-full`), `#0A4174` background, `#FFFFFF` text. Subtle elevation on default, active press downscales slightly (`scale: 0.98`) to `#001D39`.
- **Secondary Action (Short Break / Skip):** Stadium outline or solid fill in `#49769F` with white typography, or soft-tint variant using `#BDD8E9` background with `#0A4174` text.
- **SRS Answer Grading Quadrant:** 4 stacked or row-aligned pill buttons reflecting SRS difficulty:
  - *Again:* Soft Rose/Navy tint (`#BDD8E9` border + `#001D39` text).
  - *Hard:* `#6EA2B3` fill with white text.
  - *Good:* `#4E8EA2` fill with white text.
  - *Easy:* `#0A4174` fill with white text.

### Chips & Badges
- **Subject & Tag Badges:** Pill geometry (`rounded-full`), height 28px, background `#BDD8E9`, text `#0A4174`, font `label-md`.
- **Retention State Chips:** Capsule with `#4E8EA2` or `#7BBDE8` indicator dot and tabular metrics (e.g., `• 89%`).

### Cards & Deck Containers
- **SRS Flashcard Container:** High-prominence surface with `rounded-3xl` (24px to 32px radius). Crisp `#FFFFFF` surface resting on `#F4F8FA` background with soft ambient navy shadow. Internal divider between prompt and answer rendered in subtle `#BDD8E9` at 50% opacity.
- **Deck Preview Card:** Features stacked layered effect (replicating the overlapping pills from the design reference) where deck mastery is visually represented by slate-to-navy progress fills.

### Pomodoro Timer Display
- **Circular Progress Ring:** Track background `#BDD8E9` with 10px stroke width. Progress arc filled with smooth gradient from `#7BBDE8` through `#0A4174`.
- **Center Readout:** Numeric value in `display-lg` tabular figures, `#001D39`. Subtext in `label-md` indicating phase (`FOCO`, `PAUSA CURTA`, `PAUSA LONGA`).

### Lists & Progress Items
- **Subject Item Rows:** Rounded card rows (`rounded-2xl`), `#FFFFFF` background, featuring horizontal segmented micro-bars colored with `#7BBDE8` and `#4E8EA2` to represent mastery tiers.
- **Form Inputs:** Clean `#FFFFFF` or `#F4F8FA` fields with `#BDD8E9` border stroke, transitioning to a focused 1.5px ring of `#0A4174`. Text typed in `#001D39`.