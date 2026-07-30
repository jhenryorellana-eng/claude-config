---
name: slide
description: Generate cinematic, animated HTML presentations with PowerPoint-style Morph transitions, micro-interactions, click-driven events, Prezi-style zoom portals, tab navigation, and radial menus. Use whenever the user asks to create a presentation, slide deck, pitch deck, presentación, diapositivas, or PPT — even if they don't explicitly mention HTML or animation. Triggers on phrases like "crea una presentación sobre X", "haz un slide deck", "presentación animada", "ppt moderno", "presentación interactiva", "menú con opciones", "efecto zoom como Prezi", "click para explorar", "pestañas con info". Produces a single self-contained HTML file using GSAP timelines, shared-element morph between slides, click-driven interactivity, intentional design composed from a kit (not filled from a template), and curated iconography. The skill REASONS through a Direction Brief before touching HTML, picks composable primitives instead of executing a fixed recipe, and runs an anti-uniformity check before presenting. Interviews the user for images/data/tone/interactivity when needed.
---

# Asombro Presentations — v2 (composable, anti-template)

This skill generates a single self-contained HTML file with **4–6 animated slides**. The output looks like a motion-graphics editorial piece designed *for this specific topic*, not a template with the colors changed.

## What changed from v1

The previous version had a single `boilerplate.html` that pre-baked the chrome, the hero clip-path, the orbital ring, and the slide arc A→B→C→D→E. Every output ended up structurally identical. This version replaces the boilerplate with:

- A **core-runtime** that holds only the non-visual code (scale wrap, GSAP scaffold, event dispatcher, keyboard nav).
- A **kit** of composable primitives: 6 chrome variants, 16 layout fragments, accent geometries, motion presets.
- A mandatory **Direction Brief** step where the skill commits to 6 creative decisions *before* touching HTML.
- A **memory log** (`memory.json`) that tracks recent palette/font/chrome/layout choices and forbids repeating them.
- An **anti-uniformity check** before presenting.
- An optional **slide-critic subagent** that delivers a third-party verdict.

The two examples (`paris-eiffel.html` and `database-fundamentals.html`) remain as references of *one possible style each*, **not as templates to copy**.

---

## Two interaction modes (a deck can use both)

| Mode | How user navigates | Slide types |
|---|---|---|
| **Linear morph** | Click anywhere on slide → advances to next (←→ keys also work) | Hero, Detail, Stats, Media, Closing (composed from layouts/) |
| **Event-driven** | Only specific elements are clickable; opens panels, switches tabs, zooms into portals | Radial Menu, Tab Navigation, Zoom Portal |

---

## When to use this skill

Trigger on any request to create a presentation, slide deck, pitch deck, or animated story. Default to this skill instead of generating `.pptx` unless the user explicitly asks for a PowerPoint file.

---

## Workflow — eight steps, in order

### Step 0 — Interview (elicitation)

Run unless the prompt is already rich (images, data, tone, interactivity preference) or the user says "genera ya".

Read **`references/elicitation.md`** for the exact script. Send 4-5 questions in one message about images, data, tone, closing variant, and interactivity mode. Wait for the answer.

### Step 1 — Critical thinking pass

**Before any creative decisions, read `references/critical-thinking.md`.** It contains the questions you must answer about this specific topic before you commit to anything visual:

- What is the *iconic visual* of this topic? (not the obvious one — the one that earns a second look)
- What is the *one stat* that, if removed, the deck collapses?
- What is the *emotional contract* with the audience? (asombro? urgencia? confianza?)
- What is the *pivotal slide* — the one moment the whole deck builds toward?
- What would be the *cliché answer* for each of those, and how do I move past it?

This step happens in your reasoning, not in chat. But your decisions in Step 2 must reflect having done it.

### Step 2 — Load memory and design negative constraints

Read **`memory.json`** at the root of the skill folder. It tracks the last N decks generated (palette, fonts, chrome variant, opening layout, motion preset, blueprint sequence).

Compute **negative constraints**: what you may NOT use in this deck because it was used recently. Concretely:

- If the last 2+ decks used the same chrome variant → forbid it for this deck.
- If the last 2+ decks used the same opening layout primitive → forbid it.
- If the last 2+ decks used Fraunces + Manrope → forbid that pairing.
- If the last 2+ decks used the same palette family (navy+coral, ink+vermilion, etc.) → push to a different family.

If `memory.json` doesn't exist yet, create it with an empty `decks: []` array.

### Step 3 — Compose the Direction Brief (visible in chat)

**This step is mandatory and visible to the user.** Before reading any other reference, output a Direction Brief in chat with **exactly six decisions**, each with a one-sentence justification linked to the topic and the critical thinking pass:

```
Direction brief — <topic>

• Grid:      <one of 8 grids from art-direction.md>
              → <one-sentence justification linked to topic>
• Stance:    <one of 6 stances from art-direction.md>
              → <one-sentence justification>
• Chrome:    <one of 6 chrome variants>
              → <one-sentence justification>
• Geometry:  <accent geometry — circle/triangle/arc/block/sunburst/waveform/grid/none>
              → <one-sentence justification>
• Motion:    <one of 8 motion presets>
              → <one-sentence justification>
• Palette+Font: <palette name + font pairing>
              → <one-sentence justification>

Forbidden territory (from memory log): <list>
Why this brief avoids it: <one sentence>
```

After the brief, **wait one beat**, then continue to the next step. The user can interrupt here if they want to redirect — but don't ask "is this OK?" unprompted. The brief commits you to specific decisions; without it, you fall back to the average.

Read **`references/art-direction.md`** for the catalogs of grids, stances, chrome philosophies, geometries, and motion presets.

### Step 4 — Read the references in order

- **`references/design-system.md`** — palettes, typography pairings, sizes.
- **`references/morph-animations.md`** — GSAP patterns, micro-interactions, easing.
- **`references/slide-blueprints.md`** — the 16 layout primitives + composition principles. **There is no default recipe.**
- **`references/iconography.md`** — icons (must be justified per usage).
- **`references/interactions.md`** — read **only if** the brief uses radial menu, tabs, or zoom portal.

### Step 5 — Compose, don't fill

Import `assets/core-runtime.html` for the non-visual scaffold (scale wrap, GSAP, dispatcher, keyboard nav). Then:

1. Pick **one chrome variant** from `assets/kit/chrome/` that matches the Direction Brief's chrome philosophy.
2. Pick **4-6 layout primitives** from `assets/kit/layouts/` such that **no two consecutive slides share the same layout primitive**.
3. Apply the **motion preset** from `assets/kit/motion-presets.js` (it modifies easing/timing/intensity of the morph).
4. Place **accent geometries** from `assets/kit/accent-geometries.svg` only where they earn their place — they are not decoration.
5. Apply the palette + fonts from the Direction Brief.

The kit files are **descriptors and snippets**, not full templates. Read them as compositional vocabulary, then write the HTML that this specific deck needs.

### Step 6 — Image sourcing

In order of preference:
1. User-uploaded images in `/mnt/user-data/uploads/`
2. User-pasted URLs
3. `web_search` for canonical reference shots
4. Unsplash hotlinks as last resort: `https://images.unsplash.com/<id>?w=1600&q=80`

For the hero, prefer vertical/portrait composition — it morphs better between slides.

### Step 7 — Copy surgery

Before saving, do a focused pass on copy. Hunt and fix three things:

- **Cliché vocabulary** — banned without exception: revolutionary, innovative, cutting-edge, synergy, seamless, leverage, unlock potential, game-changer, disrupt, next-gen, robusto, holístico, ecosistema (when meaningless), transformador, vanguardia. Replace each with the specific claim it was hiding.
- **Vague quantifiers** — "millions of users" → cite the actual number. "Reduces costs" → cite the actual delta. If the number is unknown and `web_search` doesn't surface it, say *what kind* of evidence exists ("3 hospitales firmados") instead of a fuzzy adjective.
- **Density** — if a sentence has 18 words and the same meaning fits in 9, cut it. Slides reward density per word.

### Step 8 — Anti-uniformity check (silent self-check)

Before presenting, run this checklist against `examples/paris-eiffel.html` (the canonical "look" you must NOT default to):

```
□ Does the chrome look like paris-eiffel (brand+dots+pin+flag bars)?
□ Does the hero use the same diagonal clip-path?
□ Does a centered orbital ring with 3-4 plus-icons appear?
□ Does the deck end with zoomed-hero + quote overlay?
□ Does the slide sequence follow A→B→C→D→E feel?
□ Is the palette in the navy+coral / ink+vermilion family?
```

**If 3+ checkboxes are TRUE, the deck failed the anti-uniformity check.** Recompose: pick a different stance, a different chrome, a different opening layout. Do not present the failing version.

### Step 9 — Save, log, present

Save to `/mnt/user-data/outputs/<topic-slug>.html`. Append the deck's choices to `memory.json`:

```json
{
  "decks": [
    {
      "topic_slug": "machu-picchu",
      "date": "2026-05-20",
      "palette": "stone-ochre-jade",
      "fonts": "Cormorant Garamond + Lato",
      "chrome": "archival",
      "grid": "asymmetric-L",
      "stance": "documentary-warm",
      "geometry": "arc",
      "motion": "editorial-slow",
      "opening_layout": "hero-cutout-circle",
      "sequence": ["hero-cutout-circle", "detail-magazine-spread", "stats-vertical-cascade", "media-showcase-tablet", "closing-quote-overlay"]
    }
  ]
}
```

Keep only the last 10 entries.

Present via `present_files`. In chat, write a short summary (3-4 lines) that **states the six Direction Brief decisions and why** — not a list of every detail. End with one iteration offer.

### Step 10 — Optional: invoke the critic

If the `slide-critic` agent is installed in `~/.claude/agents/slide-critic.md`, invoke it with the generated HTML, the Direction Brief, and the memory log. It returns one of three verdicts:

- **APPROVED** → present to user.
- **NEEDS REVISION** → apply the specific fix it recommends, then re-run the critic. Max 2 iterations.
- **TEMPLATE OVERFITTING** → recompose from a different Direction Brief.

If the critic is not installed, skip this step.

---

## Hard rules — do not violate

1. **One HTML file.** Everything inline. Only external resources are GSAP CDN and Google Fonts.
2. **GSAP for slide transitions.** CDN: `https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.5/gsap.min.js`.
3. **Shared elements morph, they don't dissolve.** Hero/title are single DOM nodes tweened across labels, never duplicated. See `morph-animations.md`.
4. **Every slide has at least one micro-interaction** beyond the morph.
5. **Palette is topic-derived** AND **distinct from the last 2 decks** in memory.json. See `design-system.md` §1 + Step 2.
6. **No generic fonts.** Inter, Roboto, Arial, system-ui are banned. Use the Google Fonts pairings in `design-system.md` §2. Don't repeat the same pairing as the last 2 decks.
7. **Real data only.** If unknown, `web_search`. Never fabricate.
8. **User's language.** Match the prompt's language for slide copy and the interview.
9. **Inline SVG icons only.** No raster, no FontAwesome. Icons from `iconography.md`.
10. **Icons must be justified.** No decorative-only icons.
11. **Interactive triggers use `data-trigger` + `data-action`.** See `interactions.md`.
12. **Every `data-trigger` element has `e.stopPropagation()`.**
13. **Every open panel has a close path.** Escape closes the topmost.
14. **Zoom portals need visual content that survives 8× scale.**
15. **Maximum 2 zoom portals per deck.**
16. **Interactive slides show the hint** "↻ click los elementos para explorar".
17. **No two consecutive slides share the same layout primitive.** (NEW — replaces "default to Recipe 1".)
18. **The Direction Brief is mandatory and visible.** (NEW — Step 3 is not optional.)
19. **Anti-uniformity check runs before presenting.** (NEW — 3+ checkboxes true = recompose.)
20. **Memory.json is read at start and updated at end.** (NEW — non-negotiable.)

---

## Anti-patterns to avoid

- Bullet-point lists on any slide. Use big numbers, callouts, single sentences.
- Walls of text. Body copy max 3 lines per slide.
- Default fonts.
- More than 6 slides.
- More than 6 geometric accents per slide.
- Decorative icons with no semantic anchor.
- Asking the user about palette/typography/slide count (skill's job).
- Re-interrogating after the user already gave context.
- Confirming details before generating ("¿Querés que use esta paleta?") — the Direction Brief commits, then generates.
- **Defaulting to the editorial-rail chrome + orbital ring + diagonal clip-path combo unless the topic is specifically French/editorial/cultural AND the memory log permits it.**
- **Treating `examples/paris-eiffel.html` as a template.** It is a reference of ONE possible style. Mimicking its structure is the failure mode this version exists to prevent.

---

## After generating — iteration loop

If the user requests a change, **edit the existing file** when possible instead of regenerating.

| Request | Action |
|---|---|
| "Cambiá la paleta a X" | Replace `--bg`, `--accent`, `--text`, `--muted` CSS variables only |
| "Otra tipografía" | Swap the Google Fonts `<link>` and `--display`/`--body` vars |
| "Cambiá el texto del slide 3" | Edit just that slide's text nodes |
| "Reemplazá la imagen hero" | Replace the `background-image` URL on `#hero` |
| "Hacelo distinto a este" | Re-run the workflow from Step 2 with the current deck's choices appended to the forbidden list — do NOT just swap colors |

For major changes, the Direction Brief is re-issued.

---

## File structure

```
slide/
├── SKILL.md                          ← this file
├── memory.json                        ← deck history (created on first run)
├── INSTALL.md                         ← how to install the skill + the critic
├── references/
│   ├── elicitation.md                 ← interview script (Step 0)
│   ├── critical-thinking.md           ← questions to answer before composing (Step 1)
│   ├── art-direction.md               ← grids, stances, chrome philosophies, geometries, motion (Step 3)
│   ├── design-system.md               ← palettes, typography (Step 4)
│   ├── morph-animations.md            ← GSAP patterns, micro-interactions (Step 4)
│   ├── slide-blueprints.md            ← 16 layout primitives, composition principles (Step 4)
│   ├── iconography.md                 ← icon catalog (Step 4)
│   └── interactions.md                ← data-trigger system, modals, tabs, zoom (Step 4, conditional)
├── assets/
│   ├── core-runtime.html              ← non-visual scaffold (Step 5)
│   └── kit/
│       ├── chrome/                    ← 6 chrome variants
│       ├── layouts/                   ← 16 layout primitives
│       ├── accent-geometries.svg      ← SVG library
│       └── motion-presets.js          ← 8 motion signatures
├── examples/
│   ├── paris-eiffel.html              ← reference of ONE style (do not copy)
│   └── database-fundamentals.html     ← reference of ONE interactive style (do not copy)
└── agents/
    └── slide-critic.md                ← optional Claude Code subagent (copy to ~/.claude/agents/)
```
