# Worked example — vague idea → dense build prompt

> **Read this as a GUIDE, not a template.** It exists to show *how* a loose idea becomes a
> spec-dense prompt — the reasoning that turns "make it cool" into exact hex, classes, and
> algorithms. **Do not copy its values.** Every real brief has a different subject, stack,
> aesthetic, palette, interaction, and copy. Study the *moves* (pin the decision, kill the default;
> write the mechanic as an algorithm; end with verifiable acceptance criteria), then invent your own.
> The subject below (a coffee roaster) is deliberately different from the motionsites references so
> you practice adapting, not repeating.

---

## 1. The vague input (what the person said)

> "Quiero una landing brutal para mi marca de café de especialidad. Algo oscuro, premium, con una
> animación que enganche apenas entras. Que se vea caro."

Everything important is unspecified: brand name, exact aesthetic, fonts, colors, the "animación que
engancha", stack, sections, copy. Left as-is, an agent would default to Inter, a generic dark theme,
and four identical cards. So we **interview, then lock**.

## 2. Decisions locked (after a one-message interview)

- **What / who**: *Bruma*, a specialty coffee roaster; page sells single-origin subscriptions to
  design-literate home-brewers. Single job: **drive "Start a subscription"**.
- **Aesthetic**: luxury-dark, warm-cinematic — near-black `#0B0A08`, warm amber accent `#E4A548`,
  bone text `#EDE6D8`. One risk: a **cursor-following warm glow** that "heats" the dark scene.
- **Signature interaction**: the warm glow (radial gradient trailing the cursor) + a scroll-linked
  marquee of origin names + a blur-rise entrance on load.
- **Stack**: React 18 + TS + Vite + Tailwind + Framer Motion + lucide-react.
- **Sections (v1)**: Hero → Origins marquee. (Rest deferred to SDD mode if it grows.)
- **Fonts**: display *Fraunces* (italic, opsz-high), body *Inter*.

## 3. The resulting build prompt (what you'd hand off)

```markdown
# Bruma — dark, warm-cinematic hero + origins marquee for a specialty coffee roaster

## Role
You are a senior front-end engineer expert in React 18 + TypeScript + Vite + Tailwind CSS +
Framer Motion + lucide-react and premium motion design. You ship award-winning, 60fps interfaces and
follow this spec to the letter — no improvised colors, fonts, or layout.

## Context
- **What & who**: Bruma — a specialty coffee roaster selling single-origin subscriptions to
  design-literate home-brewers.
- **Goal of the page**: one job — drive clicks on "Start a subscription".
- **Where it lives**: standalone Vite app (shareable). Page `<title>`: "Bruma — Single-Origin Coffee".
- **Must respect**: 60fps, mobile-first, prefers-reduced-motion, visible focus states.

## Task
Build a full-screen dark hero + a scroll-linked origins marquee for **Bruma** using
**React 18 + TypeScript + Vite + Tailwind CSS + Framer Motion + lucide-react**. Aesthetic direction:
**luxury-dark warm-cinematic** — near-black scene warmed by a cursor-following amber glow; the one
risk is that glow as the signature moment. Match every detail below exactly.

## Constraints — Global setup
- **Fonts** — add to the top of `src/index.css` before `@tailwind` layers:
  ```css
  @import url('https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght@1,9..144,400;1,9..144,600&family=Inter:wght@300;400;500;600&display=swap');
  * { font-family: 'Inter', sans-serif; }
  .font-display { font-family: 'Fraunces', serif; font-optical-sizing: auto; }
  ```
- **Color tokens** (every color must be one of these):
  `--bg #0B0A08` · `--fg #EDE6D8` · `--fg-dim rgba(237,230,216,0.7)` · `--accent #E4A548` · `--surface #14110C`
- **Type scale**: hero heading `clamp(3rem, 9vw, 8.5rem)`; body `clamp(0.9rem, 1.3vw, 1.1rem)`.
- **Motion defaults**: easing `cubic-bezier(0.16,1,0.3,1)`; default duration `1s`.
- **Root wrapper**: `min-h-screen bg-[#0B0A08] text-[#EDE6D8] overflow-x-clip tracking-[-0.01em]`.

## Constraints — Section 1: Hero
- **Container**: `<section className="relative w-full overflow-hidden bg-[#0B0A08]">`, inline
  `style={{ height: '100dvh' }}`. Layers by z-index:
  1. `z-10` warm-glow layer (the signature mechanic — see below), `absolute inset-0 pointer-events-none`.
  2. `z-20` grain overlay: `absolute inset-0 opacity-[0.06] pointer-events-none` with an inline SVG
     `feTurbulence baseFrequency='0.85'` noise as background.
  3. `z-40` content: `relative flex flex-col justify-center h-full px-6 md:px-14 max-w-6xl`.
- **Copy** (verbatim):
  - Eyebrow: "SINGLE-ORIGIN · ROASTED WEEKLY" — `text-xs tracking-[0.35em] text-[#E4A548] mb-6`.
  - Heading (`<h1 className="font-display italic font-normal leading-[0.9] text-[#EDE6D8]">`),
    two block spans: "Coffee that" then "remembers where it grew" —
    `text-[clamp(3rem,9vw,8.5rem)]`, second line `text-[#E4A548]`.
  - Sub: "We ship a different farm every month — traceable to the exact lot, roasted three days
    before it reaches you." — `max-w-md mt-8 text-[#EDE6D8]/70`.
  - CTA: "Start a subscription" — `mt-10 inline-flex items-center gap-2 bg-[#E4A548] text-[#0B0A08]
    font-medium px-8 py-3.5 rounded-full transition-all hover:scale-[1.03] active:scale-95
    hover:shadow-lg hover:shadow-[#E4A548]/30` with a lucide `ArrowRight` (size 18).
- **Entrance animation**: eyebrow → `hero-fade` delay `0.15s`; heading line 1 → `hero-rise` `0.3s`;
  line 2 → `hero-rise` `0.45s`; sub → `hero-fade` `0.65s`; CTA → `hero-fade` `0.8s`.

## Constraints — Signature interaction: cursor warm glow (core mechanic)
Write it as an algorithm so it's reproducible:
- **Refs / state**: `mouse` (raw `{x,y}`), `smooth` (eased, init center), `rafRef`; state `glow` = `{x,y}`.
- **Listeners**: `mousemove` on the section stores raw `e.clientX/clientY` (relative to the section rect).
- **Loop / math**: RAF lerps `smooth.x += (mouse.x - smooth.x) * 0.12` (same for y); `setGlow(smooth)`.
- **Apply**: the glow layer's `background = radial-gradient(600px circle at ${glow.x}px ${glow.y}px,
  rgba(228,165,72,0.22), rgba(228,165,72,0.06) 40%, transparent 70%)`. On touch devices skip the
  listener and render a static centered glow.
- **Cleanup**: remove listener + `cancelAnimationFrame` on unmount.

## Constraints — Section 2: Origins marquee (scroll-linked)
- Two rows of origin chips drifting opposite directions with scroll. `bg-[#0B0A08] py-24`.
- Origins (verbatim, chips): "ETHIOPIA · Guji", "COLOMBIA · Huila", "KENYA · Nyeri",
  "GUATEMALA · Huehue", "RWANDA · Nyamasheke", "PERU · Cajamarca" — triple the set for seamless loop.
- Chip: `px-6 py-3 rounded-full border border-[#EDE6D8]/15 text-[#EDE6D8]/80 whitespace-nowrap font-display italic`.
- Compute `offset = (scrollY - sectionTop + innerHeight) * 0.3`. Row 1 `translateX(offset - 200)`,
  row 2 `translateX(-(offset - 200))`. `willChange:'transform'`, passive scroll listener, `gap-4`.

## Constraints — Motion & entrance animations
```css
@keyframes heroRise { 0%{opacity:0;transform:translateY(26px);filter:blur(10px)} 100%{opacity:1;transform:translateY(0);filter:blur(0)} }
@keyframes heroFade { 0%{opacity:0;transform:translateY(16px)} 100%{opacity:1;transform:translateY(0)} }
.hero-anim{opacity:0;animation-fill-mode:forwards;animation-timing-function:cubic-bezier(0.16,1,0.3,1)}
.hero-rise{animation-name:heroRise;animation-duration:1.1s}
.hero-fade{animation-name:heroFade;animation-duration:1s}
@media (prefers-reduced-motion: reduce){ .hero-anim{animation:none;opacity:1;transform:none} }
```
Apply `hero-anim` + the named class to each element with the per-element `animationDelay` above.

## Constraints — Reusable components
- **GlowLayer**: `absolute inset-0 z-10 pointer-events-none`; receives `x,y`; sets the radial-gradient
  background per frame; static fallback on touch.
- **CtaButton**: the amber pill above; props `label`, `onClick`; always renders the `ArrowRight` icon.

## Constraints — Responsiveness
- Breakpoints: Tailwind defaults (sm 640 / md 768 / lg 1024), mobile-first.
- Heading scales via `clamp()`; hero padding `px-6` → `md:px-14`. Use `100dvh` to avoid mobile chrome
  clip. Marquee chips shrink to `text-sm` below `md`. Glow is static (centered) on touch.

## Dependencies (exact)
react ^18.3.1, react-dom ^18.3.1, framer-motion ^12.x, lucide-react ^0.344.0,
tailwindcss ^3.4.x, vite, typescript.

## Format & acceptance criteria (build is "done" only when all pass)
- [ ] Fraunces italic renders on the heading; Inter elsewhere; all colors are the defined tokens.
- [ ] The warm glow follows the cursor smoothly (lerp 0.12), 600px radius, amber; static on touch.
- [ ] Entrance animations fire with the specified stagger; nothing pops in un-animated.
- [ ] Marquee rows drift opposite directions on scroll and loop seamlessly.
- [ ] Layout holds at 375px / 768px / 1440px with no overflow or clipping (100dvh hero).
- [ ] `prefers-reduced-motion` disables entrance + glow; keyboard focus is visible on eyebrow CTA.

Match every detail above exactly.
```

## 4. What to notice (the moves you're learning)

- **Every vague word got pinned.** "Oscuro premium" → `#0B0A08` + `#E4A548` + Fraunces italic.
  "Una animación que engancha" → a named mechanic written as refs + lerp math + apply + cleanup.
- **The signature interaction is an algorithm, not an adjective** — that's what makes it reproducible
  across agents. Copy *that discipline*, not the specific glow.
- **Acceptance criteria are verifiable** ("no overflow at 375px", "lerp 0.12"), never "looks premium".
- **Structure is [Role][Context][Task][Constraints][Format]** — the agent knows who to be, why, what,
  the exact constraints, and how "done" is checked, before a single line of code.
- **Now throw these values away.** Your brand isn't Bruma; your accent isn't amber; your mechanic
  might be sticky-stacking cards or a WebGL hero. Reuse the *shape*, invent the *substance*.
