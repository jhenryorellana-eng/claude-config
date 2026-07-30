# Slide Blueprints Reference — v2

This file contains **16 layout primitives** plus composition principles. There is NO default recipe. The Direction Brief from Step 3 tells you which stance and grid the deck commits to; your job here is to pick 4-6 layouts that serve that brief, ensuring no two consecutive slides share the same primitive.

The previous version of this file specified 5 layouts (A-E) and 8 recipes — and the very first recipe (A→B→C→D→E) was the implicit default. Every deck used it. This version makes the implicit explicit and removes the default.

---

## How to use this file

1. **Read the Direction Brief first.** The grid, stance, chrome, and pivotal slide tell you what kind of layouts fit.
2. **Pick 4-6 primitives** from the 16 below. Sequence them so the pivotal slide gets the biggest layout.
3. **Never place two consecutive slides with the same primitive.** Even slight variation isn't enough — pick a structurally different layout each transition.
4. **Compose**, don't fill. Each primitive is a starting structure, not a finished slide. Adapt the proportions, accent placement, and shared-element morph to the topic.

---

## The 16 primitives

Each primitive has:
- **Role**: what story beat it serves
- **Best with**: which grids/stances pair well
- **Shared elements**: which DOM nodes morph in/out
- **Anti-pattern**: when NOT to use it

---

### 1 — `hero-centered-massive`

The classic title reveal. Massive title (160-200px) centered, subtitle below in accent color, hero image either off-screen below or fading in at low opacity.

- **Role**: opening, when the topic deserves a stage all to itself
- **Best with**: `rule-of-thirds`, `centered-radial` grids; `minimal-poetic`, `dense-editorial` stances
- **Shared elements**: `#title`, `#hero` (off-screen)
- **Anti-pattern**: avoid if the topic isn't worth a full-screen title moment (technical decks rarely need this)

### 2 — `hero-offset-left-overlap`

Title sits in the left 40% of the canvas; hero image fills the right 60% but overlaps the title's right edge (z-layered so the title is *in front* of the image but partially obscured by it).

- **Role**: opening with intimacy — the subject and title share space
- **Best with**: `asymmetric-L`, `diagonal-split` grids; `fashion-bold`, `dense-editorial` stances
- **Shared elements**: `#title`, `#hero`
- **Anti-pattern**: avoid for centered/symmetric subjects (flags, faces, symbols)

### 3 — `hero-fullbleed-text-overlay`

Hero image fills the entire canvas. Text is overlaid in a corner with a semi-transparent backing or directly on the image (with shadow if needed for legibility).

- **Role**: immersive opening or pivotal mid-deck moment
- **Best with**: `fullbleed-with-cutout` grid; `fashion-bold`, `minimal-poetic` stances
- **Shared elements**: `#hero` (fullbleed), `#title` (corner overlay)
- **Anti-pattern**: avoid if the image lacks dead space for text legibility

### 4 — `hero-split-vertical-asymmetric`

Canvas split vertically into ~35/65 or ~65/35. One side is full-bleed hero, the other carries the title and a short paragraph stacked vertically.

- **Role**: opening with editorial breathing room
- **Best with**: `magazine-spread`, `rule-of-thirds` grids; `dense-editorial`, `soft-watercolor` stances
- **Shared elements**: `#title`, `#hero`
- **Anti-pattern**: avoid if the hero image doesn't crop well to a tall narrow rectangle

### 5 — `hero-diagonal-cut`

Hero image clipped with a diagonal `clip-path` — the v1 default. Title sits in the negative space opposite the diagonal.

- **Role**: travel/cultural opening with motion-graphics energy
- **Best with**: `diagonal-split` grid only
- **Shared elements**: `#title`, `#hero`
- **Anti-pattern**: **avoid if `paris-eiffel.html` already used this and the topic isn't specifically French/travel**. This is the most overfit primitive — use sparingly.

### 6 — `hero-cutout-circle`

Hero image masked into a circle (or oval) sitting at 30% or 70% of the horizontal axis. Title beside it, often wrapping.

- **Role**: opening with portrait-like intimacy
- **Best with**: `rule-of-thirds` grid; `minimal-poetic`, `soft-watercolor` stances
- **Shared elements**: `#title`, `#hero`
- **Anti-pattern**: avoid for landscape-dominant images that get cropped badly by a circle mask

### 7 — `hero-tunnel-perspective`

Hero image scaled to ~140% with perspective transform applied (`transform: perspective(1000px) rotateY(-12deg) scale(1.4)`) so it feels like you're looking down a tunnel or into a vanishing point. Title centered close.

- **Role**: opening or pivotal slide for topics about depth, exploration, going inside
- **Best with**: `off-canvas-peek` grid; `fashion-bold`, `brutalist-asymmetric` stances
- **Shared elements**: `#title`, `#hero` with perspective
- **Anti-pattern**: avoid for flat subjects (logos, charts, faces head-on)

### 8 — `detail-magazine-spread`

Two-column layout. Left column: 72px section title at top, 18-20px body paragraph below, CTA pill at bottom. Right column: hero image (now visible, not off-screen).

- **Role**: the explainer slide that introduces the subject after the hero reveal
- **Best with**: `magazine-spread`, `rule-of-thirds` grids; `dense-editorial`, `soft-watercolor` stances
- **Shared elements**: `#title` (shrunk and relocated from slide 1), `#hero` (now visible)
- **Anti-pattern**: avoid if there's no real paragraph to write — empty editorial space reads as filler

### 9 — `detail-card-stack`

Three cards stacked vertically (or in a 3-column row) each holding a sub-topic, an icon, a one-line description, and an optional "Más →" link. Hero shrinks to a small frame at the top.

- **Role**: showing the three pillars / three aspects / three options of the topic
- **Best with**: `asymmetric-L`, `vertical-thirds` grids; `technical-blueprint`, `dense-editorial` stances
- **Shared elements**: `#hero` (shrunk), `#title` (corner)
- **Anti-pattern**: avoid if the topic only has 2 aspects or more than 4 — adapt the layout, don't force 3

### 10 — `stats-orbital-ring`

Hero centered, thin ring (`<svg>` circle) surrounds it, 3-4 plus-icons positioned around the ring's circumference with stat callouts extending outward. The ring rotates slowly after appearing.

- **Role**: the "wow" stats moment for topics with a central object and orbiting data
- **Best with**: `centered-radial` grid only; `dense-editorial`, `technical-blueprint` stances
- **Shared elements**: `#hero`, `#ring`, `.stat-N`
- **Anti-pattern**: **this is the v1 default for stats slides — banned if used in the last 2 decks (memory.json)**. Pick a different stats primitive.

### 11 — `stats-grid-2x2-magazine`

Four stat callouts arranged in a 2×2 grid. Each cell has a big number (72-96px), label, and a tiny icon. Optional thin divider lines between cells.

- **Role**: stats moment for topics with parallel quantitative facts (not orbiting a center)
- **Best with**: `magazine-spread`, `rule-of-thirds` grids; `dense-editorial`, `technical-blueprint` stances
- **Shared elements**: `#title` (top), individual `.stat-N`
- **Anti-pattern**: avoid for 3 or 5 stats (use a different primitive); avoid for narratives where stats build on each other

### 12 — `stats-vertical-cascade`

Stats stacked vertically, left-aligned, each one larger than the next as the eye scrolls down. The biggest stat at the bottom is the load-bearing one (from Q2 of critical-thinking.md).

- **Role**: stats moment with editorial drama — building up to the biggest number
- **Best with**: `vertical-thirds`, `magazine-spread` grids; `dense-editorial`, `fashion-bold` stances
- **Shared elements**: `#title` (top corner), individual `.stat-N`
- **Anti-pattern**: avoid if all stats are equal-weight — this primitive needs a clear winner

### 13 — `stats-radial-arc-quarter`

A quarter-circle arc occupies one corner of the canvas. Three stats sit along the arc at evenly-spaced points. Hero sits in the opposite corner, small.

- **Role**: stats moment with elegant restraint — alternative to the full orbital ring
- **Best with**: `asymmetric-L`, `centered-radial` grids; `soft-watercolor`, `minimal-poetic` stances
- **Shared elements**: `#hero` (corner, small), arc SVG, individual `.stat-N`
- **Anti-pattern**: avoid for >3 stats; the arc geometry doesn't support 4+

### 14 — `media-showcase-tablet` (the iPad mockup)

Hero and previous stats shift to the left side, compacted. From the right slides in an iPad/tablet/laptop frame carrying a video preview, scenic photo, or product screenshot with optional Ken Burns animation.

- **Role**: breaking abstract data with concrete media — a moment of "look, here it is in real life"
- **Best with**: any grid; `dense-editorial`, `documentary-warm` stances
- **Shared elements**: `#hero` (compacted left), `#mediaDevice` (new, slides in)
- **Anti-pattern**: avoid if there's no real media to show — empty device mockup is worse than skipping this primitive

### 15 — `closing-quote-overlay`

Hero scales up to fill the canvas at low opacity (~0.22). A single quote rises from the bottom in 36-48px serif. Quote attribution in small caps below.

- **Role**: final hero composition with editorial weight
- **Best with**: any grid; any stance except brutalist
- **Shared elements**: `#hero` (full bleed, low opacity), `#title` (could be present or hidden), quote text (new)
- **Anti-pattern**: **avoid for the pivotal slide** — this is a *closing* primitive. Avoid if you can't find/write a real quote (don't invent quotes).

### 16 — `closing-tunnel-zoom`

Hero scales beyond 100% and zooms into a single detail until that detail fills the screen. A short final CTA or thought appears as the zoom completes.

- **Role**: final slide for topics where "going deeper" is the message
- **Best with**: `off-canvas-peek`, `fullbleed-with-cutout` grids; `fashion-bold`, `cinematic-build` motion
- **Shared elements**: `#hero` (zoom into detail), closing text (new)
- **Anti-pattern**: avoid if the hero image has no interesting detail to zoom into

---

## Interactive primitives (use sparingly)

These three are blueprints F, G, H from the v1 — they remain useful but require explicit purpose. Don't add interactivity for its own sake.

### I.1 — `interactive-radial-menu`
Central hub + 6-8 satellites with click-triggers opening detail panels. See `references/interactions.md` §4.

### I.2 — `interactive-tab-navigation`
Numbered pills swap content panels in place. See `references/interactions.md` §3.2.

### I.3 — `interactive-zoom-portal`
Clickable element scales up to fill the canvas, revealing a hidden world behind it. See `references/interactions.md` §3.3. **Max 2 per deck.**

---

## Composition principles (replaces the old "recipes")

There are no recipes. There are principles.

### Principle 1 — The pivotal slide gets the biggest layout

From Q4 of critical-thinking.md, you identified which slide is pivotal. That slide gets the most generous primitive: `hero-fullbleed-text-overlay`, `interactive-zoom-portal`, `stats-vertical-cascade` (with the load-bearing stat at the bottom), or `hero-tunnel-perspective`. The non-pivotal slides get smaller primitives.

### Principle 2 — No two consecutive slides share a primitive

This is Hard Rule 17 from SKILL.md. Even if `stats-grid-2x2` and `stats-vertical-cascade` are both stats slides, they're different primitives — you can use both, but not adjacent to the same primitive. Force structural variation.

### Principle 3 — Sequence the emotional arc

The emotional contract from Q3 of critical-thinking.md determines the order:

- **Asombro arc**: build up slowly (`hero-centered-massive` → `detail-magazine-spread` → `stats-vertical-cascade` → `closing-quote-overlay`). Restraint then payoff.
- **Urgencia arc**: open in medias res (`hero-fullbleed-text-overlay` with shocking stat already visible) → `stats-grid-2x2-magazine` → `detail-card-stack` → `closing-tunnel-zoom`. No slow build.
- **Confianza arc**: balanced and symmetric (`hero-split-vertical-asymmetric` → `detail-magazine-spread` → `stats-orbital-ring` or alternative → `media-showcase-tablet` → `closing-quote-overlay`). Reassurance through structure.
- **Curiosidad arc**: open with question (`hero-centered-massive` with question as title) → `interactive-radial-menu` → sub-flows → `closing-quote-overlay`. Exploration.
- **FOMO arc**: open with stat that hurts (`stats-vertical-cascade` with the urgency number) → `hero-fullbleed-text-overlay` → `detail-card-stack` → CTA closing. Tension throughout.
- **Indignación arc**: brutalist sequence with very few slides (3-4). Each one a punch. `hero-fullbleed-text-overlay` → `stats-grid-2x2` → `closing-quote-overlay` with the victim's name.
- **Nostalgia arc**: archival feel. `hero-cutout-circle` (portrait) → `detail-magazine-spread` → `stats-radial-arc-quarter` → `closing-quote-overlay`.
- **Calma arc**: minimal sequence. `hero-fullbleed-text-overlay` (with silence) → `stats-vertical-cascade` (slowly) → `closing-quote-overlay`. 3 slides is enough.

### Principle 4 — Slide count follows the emotional arc, not a default

The v1 said "5 is the sweet spot." That's wrong as a default. Calma arcs work in 3 slides; dense editorial decks need 6. Pick the count from the arc.

| Arc | Recommended count |
|---|---|
| Calma, Indignación | 3-4 |
| Asombro, Confianza, Nostalgia | 4-5 |
| Curiosidad, Dense editorial | 5-6 |
| FOMO, Urgencia | 3-5 (no slow build) |

### Principle 5 — Mode declaration per slide

Each slide must carry `data-mode="linear"` or `data-mode="interactive"`. The boilerplate's click handler reads this to decide whether to advance or wait for explicit triggers.

```html
<div class="slide current" data-mode="linear" id="slide-1">...</div>
<div class="slide" data-mode="interactive" id="slide-3">...</div>
```

---

## Coherence checklist (before composing)

- [ ] Have I read the Direction Brief from Step 3?
- [ ] Do I know which slide is pivotal (from Q4)?
- [ ] Is the pivotal slide getting the biggest primitive?
- [ ] Are any two consecutive slides using the same primitive? (If yes, swap one.)
- [ ] Is the slide count appropriate for the emotional arc?
- [ ] Have I checked memory.json — is any primitive forbidden because it appeared in the last 2 decks?
- [ ] Am I about to use `hero-diagonal-cut` + `stats-orbital-ring`? (If yes, justify why this isn't the v1 default sneaking back in.)

If any answer is "I'm not sure", go back to the Direction Brief and verify.
