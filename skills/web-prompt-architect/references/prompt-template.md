# Canonical build-prompt template

Fill every `[BRACKET]`. Delete sections that don't apply. Keep the density: exact values, not
descriptions. The final artifact should read like a spec sheet a contractor could build from
blindfolded. Output it in English by default (coding agents perform best on English build prompts,
and it matches the motionsites format) unless the person asks for their own language.

The template follows the professional prompt structure **[Role] → [Context] → [Task] →
[Constraints] → [Format]**: the target agent gets *who to be*, *why/for whom*, *what to build*, the
*exact constraints* (design system + sections + components + responsiveness + deps), and *how "done"
is verified* (acceptance criteria). The Constraints and Format blocks are where motionsites-grade
density lives.

---

```markdown
# [PROJECT NAME] — [one-line description of what the page is]

## Role
You are a **senior front-end engineer** expert in [EXACT STACK] and premium motion / interaction
design. You ship award-winning, 60fps interfaces and follow the spec below to the letter — no
improvised colors, fonts, or layout, no "sample from the statistical center" defaults.

## Context
- **What & who**: [BRAND/SUBJECT] — a [what it is] for [audience].
- **Goal of the page**: the single job — [sell / showcase / capture sign-ups / portfolio].
- **Where it lives**: [standalone Vite app / Next.js production route / claude.ai artifact].
- **Must respect**: [existing design system / brand rules / perf budget / none].

## Task
Build a [page type: full-screen hero / one-page landing / portfolio / product page] for
[BRAND/SUBJECT] using **[EXACT STACK, e.g. React 18 + TypeScript + Vite + Tailwind CSS +
Framer Motion + lucide-react]**. Aesthetic direction: **[named direction]** — [one sentence
describing the intended feel and the one aesthetic risk being taken]. The signature feature is
**[the memorable interaction]**. Match every detail below exactly.

## Constraints — Global setup
- **Fonts** — add to the top of `src/index.css` (before `@tailwind` layers):
  ```css
  @import url('[EXACT GOOGLE FONTS URL]');
  * { font-family: '[BODY FONT]', sans-serif; }
  .font-display { font-family: '[DISPLAY FONT]', serif; }
  ```
- **Color tokens** (every color used anywhere must be one of these):
  - `--bg [#HEX]`  · `--fg [#HEX]`  · `--accent [#HEX]`  · `--muted [#HEX]`  · [add as needed]
- **Type scale**: headings use `clamp([min], [pref-vw], [max])`; body [size]. [state exact per-section sizes below]
- **Motion defaults**: easing `[cubic-bezier(...)]`, default duration `[Xs]`.
- **Root wrapper**: `[exact classes]`. Page `<title>`: "[TITLE]".

## Assets (use these exact URLs)
- `IMG_1` — [purpose]: `[URL]`
- `IMG_2` — [purpose]: `[URL]`
- [or: "Generate/placeholder images at [dimensions], subject: [description]"]

## Section order
1. [Section] 2. [Section] 3. [Section] …

## Section 1 — [NAME]
- **Container**: `[exact classes]`, height `[e.g. 100dvh]`.
- **Layers by z-index** (when overlapping):
  1. `z-10` [element] — [exact classes / background]
  2. `z-30` [element] — [exact classes]
  3. `z-50` [element] — [exact classes]
- **Copy** (verbatim):
  - Heading: "[EXACT TEXT]" — `[classes, sizes per breakpoint, letter-spacing]`
  - Body: "[EXACT TEXT]" — `[classes]`
  - CTA: "[BUTTON LABEL]" — `[classes incl. hover/active states]`
- **Entrance animation**: [element] → `[keyframe name]`, `animationDelay: [Xs]`; [next] → `[Ys]` (staggered).

[Repeat "## Section N — [NAME]" for each section, same density.]

## Signature interaction — [NAME] (core mechanic)
Explain as an algorithm so it's reproducible:
- **Refs / state**: [list them, with init values].
- **Listeners**: [e.g. `mousemove` stores raw `clientX/clientY`].
- **Loop / math**: [e.g. RAF lerps `smooth.x += (mouse.x - smooth.x) * 0.1`; radius `[R]px`;
  threshold `[N]px`; radial-gradient stops `[list]`].
- **Apply**: [how the computed value drives the DOM — transform, maskImage, canvas, etc.].
- **Cleanup**: remove listeners / cancel RAF on unmount.

## Motion & entrance animations
```css
@keyframes [name] { 0% { [from] } 100% { [to] } }
[.class] { animation: [name] [duration] [easing] forwards; }
@media (prefers-reduced-motion: reduce) {
  [.animated-classes] { animation: none; opacity: 1; transform: none; }
}
```
Per-element delays: [element]=`[Xs]`, [element]=`[Ys]`, …

## Reusable components
- **[ComponentName]**: [exact spec — shape, classes, props with defaults, states, behavior].
- [repeat for each: buttons, magnetic wrapper, fade-in wrapper, animated text, etc.]

## Responsiveness
- Breakpoints: Tailwind defaults (sm 640 / md 768 / lg 1024), mobile-first.
- [what hides below md], [what scales], [what reflows]. Use `100dvh` to avoid mobile chrome clipping.
- Fluid typography via `clamp()` throughout.

## Dependencies (exact)
[react ^18.3.1, framer-motion ^12.x, lucide-react ^0.344.0, tailwindcss ^3.4.x, vite, typescript, …]

## Format & acceptance criteria (build is "done" only when all pass)
- [ ] Fonts load; [display font] renders on headings, [body font] elsewhere.
- [ ] All colors match the defined tokens; no stray defaults.
- [ ] [Signature interaction] behaves as specced (smooth, correct radius/threshold, no jank).
- [ ] Entrance animations fire with the specified stagger; nothing pops in un-animated.
- [ ] Layout holds at 375px, 768px, 1440px with no overflow or clipping.
- [ ] `prefers-reduced-motion` disables non-essential motion.
- [ ] Keyboard focus is visible on all interactive elements.

Match every detail above exactly.
```

---

## Notes on using the template

- **Density scales with fidelity.** If the person wants a pixel-exact clone of a reference, pin
  everything (like the motionsites examples). If they want "in this spirit, but your call on
  specifics", still pin the design system (fonts/colors/motion) and the signature interaction, but
  you may leave secondary layout to the agent — just say so explicitly rather than by omission.
- **Copy matters.** Real copy beats lorem ipsum because it sets rhythm and length. If the person
  has none, write short, on-brand copy and mark it "[draft copy — replace]".
- **Keep the acceptance criteria verifiable.** "Looks premium" is not a criterion; "no overflow at
  375px" is. This is the SDD discipline that turns a wish into a contract.
