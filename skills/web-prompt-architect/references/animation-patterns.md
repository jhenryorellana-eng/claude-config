# Animation & interaction patterns

Use this to (a) pick the right library for the person's signature interaction and (b) hand the
coding agent a spec-dense description of the mechanic. Prompts describe mechanics as algorithms, not
as "add a cool effect".

## Table of contents
1. Library selection (2025–2026 state)
2. Signature-interaction cookbook (spec-ready descriptions)
3. The Awwwards scroll stack (GSAP + ScrollTrigger + Lenis + SplitText)
4. Performance & accessibility rules to bake into every prompt

---

## 1. Library selection (current)

- **GSAP + ScrollTrigger** — the industry standard for scroll-driven, cinematic, timeline-based
  motion. GSAP is **free including its plugins** (ScrollTrigger, SplitText, MorphSVG, DrawSVG,
  ScrollSmoother, Physics2D) — verify the current licensing/plugin status when it matters. Reach for
  this for pinned/scrubbed heroes, parallax, horizontal scroll, complex sequencing.
- **Lenis** — smooth-scroll layer. Native scroll is jerky and desyncs scroll-triggered animation;
  Lenis replaces it with fluid, controlled motion synced to the animation loop. Add it to *any*
  scroll-cinematic build — it's the difference between "premium" and "cheap".
- **anime.js v4** — complete ESM rewrite, TypeScript-native, ~10KB, physics-based easing (spring,
  bounce). Great for **lightweight micro-interactions** (hover springs, staggered UI reveals) where
  GSAP would be overkill. New API: `import { animate } from 'animejs'` → `animate('.el', {...})`.
- **Framer Motion** — component-level animation in React. This is what motionsites prompts lean on:
  `whileInView` fade-ins, `useScroll`/`useTransform` for scroll-linked values, sticky-stacking cards,
  magnetic hovers. Best default for React landing pages that aren't doing heavy WebGL.
- **Three.js / WebGL + GLSL shaders** — 3D heroes, particle fields, blob cursors, shader backgrounds.
  Highest effort; always spec a non-WebGL fallback.

**Rule of thumb**: React landing page → Framer Motion (+ GSAP/Lenis if scroll-cinematic).
Vanilla single file → GSAP + Lenis. Heavy 3D → Three.js driven by GSAP's ticker + Lenis.

---

## 2. Signature-interaction cookbook

Each entry is written the way it should appear in the build prompt — as an implementable algorithm.

### Cursor spotlight reveal (reveals a second image through a soft mask)
- Const `SPOTLIGHT_R = [260]`. Refs: `mouse` (raw), `smooth` (eased), `rafRef`; state `cursorPos`
  init `{x:-999,y:-999}`.
- `mousemove` stores raw `e.clientX/clientY`.
- RAF loop lerps `smooth.x += (mouse.x - smooth.x) * 0.1` (same for y), then `setCursorPos`.
- Reveal layer: a `<div>` with the second image as background; a hidden `<canvas>` sized to the
  viewport builds a radial gradient at `(cursorX, cursorY)`, radius 0→`SPOTLIGHT_R`, stops
  `0:1, 0.4:1, 0.6:0.75, 0.75:0.4, 0.88:0.12, 1:0`; `canvas.toDataURL()` becomes the div's
  `maskImage`/`webkitMaskImage` with `maskSize:'100% 100%'`.
- Cleanup: remove listener + cancel RAF on unmount.

### Magnetic element (button/portrait follows cursor within a radius)
- Track cursor vs. element center; when within `padding` px of the edge, apply
  `translate3d(dx/strength, dy/strength, 0)`. Transition in `0.3s ease-out`, out `0.6s ease-in-out`.
  Use `willChange:'transform'`. Typical: `padding 150, strength 3`.

### Scroll-scrubbed pinned hero (content dissolves as you scroll)
- GSAP timeline with `scrollTrigger:{ trigger:'.hero', start:'top top', scrub:[1–3], pin:true,
  anticipatePin:1 }`. Animate hero content to `{ filter:'blur(40px)', autoAlpha:0, scale:0.5 }`.

### Sticky-stacking cards (cards stack and scale down as you pass)
- Framer Motion `useScroll` + `useTransform`. Each card `sticky top-[X]` inside an `h-[85vh]`
  container; `targetScale = 1 - (totalCards - 1 - index) * 0.03`; offset each by `top: index*28px`.

### Kinetic type — char-by-char scroll reveal
- Split heading into characters (SplitText, SplitType, or manual spans). Each char animates opacity
  `0.2 → 1` based on scroll progress; Framer Motion `useScroll` offset `['start 0.8','end 0.2']`, or
  GSAP + ScrollTrigger scrub. For a "smash" effect, add Physics2D so letters tumble off-screen.

### Scroll-linked marquee (rows drift opposite directions on scroll)
- Compute `offset = (scrollY - sectionTop + innerHeight) * 0.3`. Row 1 `translateX(offset - 200)`,
  row 2 `translateX(-(offset - 200))`. Triple the image set for seamless looping;
  `willChange:'transform'`, passive scroll listener.

### Blur-rise entrance (premium on-load reveal)
```css
@keyframes heroReveal { 0%{opacity:0;transform:translateY(28px);filter:blur(12px)} 100%{opacity:1;transform:translateY(0);filter:blur(0)} }
```
Apply with `cubic-bezier(0.16,1,0.3,1)`, staggered per-element `animationDelay` (e.g. 0.25s, 0.42s).

---

## 3. The Awwwards scroll stack (unified loop)

When the build is scroll-cinematic, spec this exact wiring so ScrollTrigger, Lenis, and (optionally)
a WebGL renderer share one loop:

```js
import Lenis from 'lenis';
import gsap from 'gsap';
import ScrollTrigger from 'gsap/ScrollTrigger';
gsap.registerPlugin(ScrollTrigger);

const lenis = new Lenis({ duration: 1.2 });
lenis.on('scroll', ScrollTrigger.update);
gsap.ticker.add((time) => lenis.raf(time * 1000));
gsap.ticker.lagSmoothing(0);
```

Then build sections with `gsap.timeline({ scrollTrigger: {...} })`. Use `gsap.matchMedia()` to give
mobile a lighter version.

---

## 4. Always bake into the prompt

- **`prefers-reduced-motion`** — disable non-essential motion; never ship without it.
- **Mobile budget** — heavy scroll/WebGL kills low-end phones; spec a reduced or static fallback
  via `gsap.matchMedia()` or a media query.
- **`willChange:'transform'`** on frequently-animated elements; passive scroll listeners.
- **Visible focus states** on every interactive element; don't let animation hide keyboard focus.
- **Cleanup** — remove listeners, cancel RAF, kill ScrollTriggers on unmount (React `useEffect`).
