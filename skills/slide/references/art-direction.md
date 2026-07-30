# Art Direction Reference

This is the catalog of creative levers the Direction Brief picks from in Step 3. **Read this before reading `design-system.md`** — palette and typography are downstream of these decisions.

The previous version of the skill skipped this layer entirely. The result: every deck ended up with the same grid, the same chrome, the same accent geometry. This file fixes that by making each lever explicit and pickable.

---

## 1. Grids (8 options)

The grid is the underlying skeleton that every slide respects. Pick one per deck; the chosen grid is the *deck's spatial language*.

### 1.1 — `rule-of-thirds`
Content sits on the 1/3 and 2/3 vertical or horizontal lines. Hero subjects at 30% or 70% of the canvas. **Use for:** classical editorial, travel, documentary. **Avoid for:** technical, brutalist, urgent.

### 1.2 — `asymmetric-L`
A heavy block in two adjacent quadrants forming an L, leaving the other two as negative space. **Use for:** architectural, modernist, design-forward topics. **Avoid for:** symmetric subjects (flags, faces, symbols).

### 1.3 — `centered-radial`
Everything orbits a center point. The orbital ring blueprint lives here. **Use for:** topics that genuinely have a center (a solar system, a hub-and-spoke org, a focal artifact). **Avoid for:** narratives with directional flow.

### 1.4 — `fullbleed-with-cutout`
A single image fills the entire slide, and content sits in a small cutout window (top-left or bottom-right). **Use for:** immersive subjects (nature, architecture, products in scene). **Avoid for:** data-heavy decks.

### 1.5 — `diagonal-split`
The canvas is divided by a diagonal line (25°-45°). One side carries the hero, the other carries content. **Use for:** tension, before/after, comparison. **Avoid for:** calm or meditative topics.

### 1.6 — `vertical-thirds`
The canvas is divided into three horizontal bands (top/middle/bottom). Content stacks. **Use for:** layered narratives, hierarchical structures, journeys with altitude (mountains, dives, the atmosphere). **Avoid for:** static facts.

### 1.7 — `magazine-spread`
Two-column with editorial headline / body / pull-quote structure, like an open magazine. **Use for:** long-form analytical, profile, deep-dive. **Avoid for:** product launches, single-message decks.

### 1.8 — `off-canvas-peek`
The hero subject sits mostly outside the canvas, only a portion visible. The eye completes the rest. **Use for:** mysterious, anticipatory, "this is just the beginning" framing. **Avoid for:** decks where you need to deliver the full subject (medical imaging, technical diagrams).

---

## 2. Stances (6 options)

The stance is the *posture* of the deck — how it carries itself. Affects palette intensity, motion preset, copy register, and density.

### 2.1 — `minimal-poetic`
Maximum whitespace. One thought per slide. Type does most of the work. Color used sparingly as accent. Motion is slow and restrained.

**Reference feeling:** Japanese design, Issey Miyake, Apple's 2010s product launch slides.

**Goes with:** any grid, but especially `vertical-thirds`, `fullbleed-with-cutout`, `off-canvas-peek`.

### 2.2 — `dense-editorial`
Rich layouts, multiple text blocks, pull quotes, sidebars. Type hierarchy works hard. Like a New York Times longform.

**Reference feeling:** NYT, The Atlantic, Monocle magazine.

**Goes with:** `magazine-spread`, `rule-of-thirds`.

### 2.3 — `technical-blueprint`
Schematic feel. Thin lines. Labels with leaders. Annotations. Often monochrome plus one accent. Reads like an engineering drawing.

**Reference feeling:** Dieter Rams, Bauhaus technical drawings, Field Notes branding.

**Goes with:** `centered-radial`, `vertical-thirds`, `rule-of-thirds`.

### 2.4 — `fashion-bold`
Oversized type (often pushing the edge of the canvas). High-contrast palette. Confident asymmetry. Often a single dominant image.

**Reference feeling:** Off-White, Balenciaga look book, Vogue Italia covers.

**Goes with:** `diagonal-split`, `asymmetric-L`, `fullbleed-with-cutout`.

### 2.5 — `brutalist-asymmetric`
Raw. Unfinished feel. Type overlaps shapes. Grid is visible but broken. Limited palette (often 2 colors).

**Reference feeling:** Bloomberg Businessweek covers, Wolfgang Tillmans book design, Tumblr-era brutalism.

**Goes with:** `asymmetric-L`, `diagonal-split`, `off-canvas-peek`.

### 2.6 — `soft-watercolor`
Edges blur. Color washes overlap. Type is gentle (serif, regular weight). Motion is fluid.

**Reference feeling:** medical-wellness brands, botanical guides, slow-living publications.

**Goes with:** `magazine-spread`, `vertical-thirds`, `rule-of-thirds`.

---

## 3. Chrome philosophies (6 variants)

Chrome = the persistent UI elements (brand mark, nav, location pin, etc.) that appear on every slide. The previous skill version had ONE chrome (`editorial-rail`) and used it for everything. This version offers six, and **none is the default**.

### 3.1 — `editorial-rail` (the v1 chrome)
- Brand mark (paper-plane SVG) top-left
- Nav dots vertical center-left
- Pin tag bottom-left
- Diagonal flag bars right side

**Use for:** travel, cultural, editorial topics. **Banned for:** anything in the last 2 decks' chrome (memory.json).

### 3.2 — `minimal-rail`
- Only nav dots (vertical, center-left)
- Slide number ("3 / 6") bottom-right in muted

**Use for:** minimal-poetic, technical-blueprint, soft-watercolor stances.

### 3.3 — `archival`
- Outer border frame (1px or 2px) in muted color
- Slide title in the bottom margin in small caps
- Catalog number ("№ 03") top-right corner
- No brand mark

**Use for:** historical, museum, archival topics. **Reference feeling:** library card, passport, antique book.

### 3.4 — `peripheral-data`
- Timecode (top-right): a fake `00:01:23` or `LAT 13.5°S` that increments
- Index of current slide ("S03 / S06") bottom-left
- A live "instrument" reading: wind speed, altitude, depth, temperature
- No brand mark

**Use for:** technical, scientific, documentary, immersive. Treats the chrome as if you're inside a cockpit or research vessel.

### 3.5 — `invisible`
No chrome at all. Just slide content on the canvas.

**Use for:** fashion-bold, brutalist-asymmetric stances. When the subject is so strong it shouldn't compete with UI.

### 3.6 — `instrumental`
The chrome IS the data. Top of slide carries a horizontal progress bar that fills as the deck advances. Left edge carries a vertical bar showing "trust level" or "complexity" or whatever scalar the deck explores. The chrome and the content are the same thing.

**Use for:** decks where the meta-data (progress, scale, intensity) is part of the message.

---

## 4. Accent geometries (7 + none)

The geometric motif that recurs throughout the deck. NOT decoration — the recurrence is what gives the deck visual coherence. Pick one (or `none`).

### 4.1 — `circle`
Circles as orbits, halos, holes, lenses. Goes with `centered-radial` grid. Watch out: this is the v1 default. Use only if topic genuinely calls for it.

### 4.2 — `triangle`
Triangles as direction, tension, mountain, threat, arrows. Goes with `diagonal-split`, `asymmetric-L`.

### 4.3 — `arc`
Quarter circles, segments, the suggestion of a larger circle without closing it. Elegant, restrained. Goes with `vertical-thirds`, `magazine-spread`.

### 4.4 — `block`
Solid rectangles as headers, callouts, plates. Brutalist, confident. Goes with `brutalist-asymmetric`, `fashion-bold`.

### 4.5 — `sunburst`
Lines radiating from a point. High energy. Goes with `centered-radial` when you want urgency or revelation.

### 4.6 — `waveform`
Horizontal wavy lines, sound-wave style. Goes with topics about rhythm, motion, sound, time-series data.

### 4.7 — `grid`
A faint grid of dots or lines underneath everything. Technical, organized. Goes with `technical-blueprint` stance.

### 4.8 — `none`
No geometric accent. The composition itself is the structure. Goes with `minimal-poetic`.

---

## 5. Motion presets (8 signatures)

A motion preset is the deck's *kinetic personality*. It modifies easing curves, durations, and the character of every morph. Each preset is defined in `assets/kit/motion-presets.js` as a config object.

### 5.1 — `editorial-slow`
Long durations (1.4s morph), `power3.inOut`, no bounces. Feels patient, considered.

### 5.2 — `techno-pulse`
Short durations (0.6s morph), `power4.out` (sharp landing), occasional `back.out` overshoots. Feels precise, snappy.

### 5.3 — `documentary-warm`
Medium durations (1.0s morph), `power2.inOut`, gentle Ken Burns drift on hero images. Feels like a documentary cut.

### 5.4 — `fashion-snap`
Very short (0.4s), `power4.in` enter / `power4.out` exit, hard cuts between slides with minimal morph. Feels editorial, magazine-page-turn.

### 5.5 — `watercolor-flow`
Long (1.6s), `sine.inOut`, overlapping fades, no sharp edges. Feels organic, fluid.

### 5.6 — `brutalist-snap`
Short (0.3s), no easing (`none`), hard cuts only. No morph between certain slides — they just *swap*. Feels raw, unpolished, intentional.

### 5.7 — `cinematic-build`
Variable durations — slow on hero reveals (1.8s), fast on cuts to detail (0.5s). `power2.inOut` baseline with `back.out` on key reveals. Feels like a movie trailer.

### 5.8 — `instrumental-tick`
Mechanical, even durations (0.8s), `power1.inOut`, no overshoot. Each transition feels like a watch tick. Goes with `instrumental` chrome.

---

## 6. How to compose the Direction Brief

Picking the six levers is not random. They have natural pairings.

| Stance | Often pairs with grid | Often pairs with chrome | Often pairs with motion |
|---|---|---|---|
| minimal-poetic | vertical-thirds, off-canvas-peek | invisible, minimal-rail | watercolor-flow, editorial-slow |
| dense-editorial | magazine-spread, rule-of-thirds | editorial-rail, archival | documentary-warm, editorial-slow |
| technical-blueprint | centered-radial, vertical-thirds | peripheral-data, instrumental | instrumental-tick, techno-pulse |
| fashion-bold | diagonal-split, asymmetric-L | invisible, minimal-rail | fashion-snap, techno-pulse |
| brutalist-asymmetric | asymmetric-L, off-canvas-peek | invisible, instrumental | brutalist-snap |
| soft-watercolor | magazine-spread, vertical-thirds | minimal-rail, archival | watercolor-flow |

**But pairings are guides, not rules.** Deliberate mismatches create signature decks:
- `minimal-poetic` + `techno-pulse` motion = restrained content with sharp delivery (Apple keynote feel)
- `brutalist-asymmetric` + `watercolor-flow` motion = raw composition softened by motion (the contradiction is the design)
- `dense-editorial` + `invisible` chrome = the content carries everything, no UI competing

When the topic permits, pick the mismatch that's more interesting than the safe pairing.

---

## 7. Negative constraints (from memory.json)

Step 2 of the workflow reads `memory.json` and computes what's forbidden for this deck. The Direction Brief MUST honor these constraints. If the memory log says the last 3 decks used `editorial-rail` chrome, then `editorial-rail` is forbidden for this one — even if the topic seems to call for it. Pick the next-best fit.

The point of negative constraints is not to be perverse — it's to force exploration of the design space. If you keep finding "but editorial-rail really is the best fit", you're not exploring; you're rationalizing.

---

## 8. The forbidden combo

There is one combination that the skill should refuse, period:

> `editorial-rail` chrome + `centered-radial` grid + `circle` geometry + `diagonal` hero clip-path + `editorial-slow` motion + `navy+coral` palette + `Fraunces+Manrope` fonts

This is the `paris-eiffel.html` configuration. Producing this combination for any topic that is not literally Paris is the failure mode this entire version exists to prevent. If you find yourself reaching for it, the anti-uniformity check in Step 8 will catch you anyway — but better to refuse earlier in the Direction Brief.
