# Memoria de oficio — frontend-builder
> Máximo 200 líneas cargadas. Curaduría: agent-ops (2026-08-13).
> Fusión original (2026-08-07) de disruptive-landing-builder (motion/GSAP) + ui-builder
> (implementación). El detalle por proyecto vive en los archivos temáticos hermanos.

## Índice de archivos temáticos
- `astro-motion-stack.md` — recetas completas de Astro 5 + GSAP/Lenis/SplitType desde CDN
- `motion-recipes.md` — patrones reusables (clip-path, scrub, marquee, counter-up, tilt, magnetic)
- `frontend-recipes-from-review.md` — recetas salidas de las revisiones de code-reviewer: Astro+CDN, tindivo responsive/tipografía, react-three-fiber (`setFrameloop` resetea el clock), `React.lazy` sin ErrorBoundary, pdf-lib en el navegador, a11y de file inputs, toggles de "revertir" que necesitan snapshot
- `archive-usalatino-frontend.md` — APIs de componentes, boundaries e i18n de usalatino-v2 y tindivo-negocios (detalle por proyecto)

## Preferencias de Mauri/Henry
- Directorios de trabajo: `C:\Users\mauri\Documents\agentes\*` o `C:\Users\mauri\Documents\Trabajos\*`.
- Windows 11, PowerShell y bash disponibles. En bash, rutas con barra normal (`/c/Users/...`) funcionan mejor que backslashes escapados; en PowerShell, `$env:USERPROFILE`.
- Contenido en español (rioplatense), código y docs en inglés.
- La verificación con screenshot de Playwright nunca se omite, ni en landings freelance.

---

## Confirmed CDN URLs (May 2026)
- GSAP 3.12.7: `https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/gsap.min.js` (works)
- ScrollTrigger: `https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/ScrollTrigger.min.js`
- Lenis 1.1.18: `https://cdn.jsdelivr.net/npm/lenis@1.1.18/dist/lenis.min.js` (works)
- SplitType 0.3.4: `https://cdn.jsdelivr.net/npm/split-type@0.3.4/umd/index.min.js` (UMD global `SplitType`)
- Three.js r128: `https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js` (UMD, works)
- Swiper 11: `https://cdn.jsdelivr.net/npm/swiper@11/swiper-bundle.min.js` (works)
- vanilla-tilt 1.8.1: `https://cdnjs.cloudflare.com/ajax/libs/vanilla-tilt/1.8.1/vanilla-tilt.min.js`
- simpleParallax 6.0.0: `https://cdn.jsdelivr.net/npm/simple-parallax-js@6.0.0/dist/vanilla/simpleParallax.min.js` (UMD global `simpleParallax`)
- NOTE: GSAP 3.13.0 SplitText CDN path NOT confirmed on jsdelivr. Use 3.12.7.

## See also (topic files)
- `astro-motion-stack.md` — full recipes para Astro 5 + GSAP/Lenis/SplitType desde CDN
- `motion-recipes.md` — patterns reusables (clip-path, scrub, marquee, counter-up, tilt, magnetic)

## Key Patterns (quick reference)
- Lenis + GSAP sync: `lenis.on('scroll', ScrollTrigger.update)` + `gsap.ticker.add(time => lenis.raf(time*1000))` + `gsap.ticker.lagSmoothing(0)` ← confirmed Context7 darkroomengineering
- SplitType + GSAP: `new SplitType(el, {types:'lines,words,chars', tagName:'span'})` → gsap stagger chars con yPercent:110→0
- IMPORTANT: `.word, .split-word { overflow: hidden; display: inline-block; vertical-align: top }` para que yPercent funcione bien
- Canvas DPR: cap at 1.5 on desktop, reduce particles on mobile (35 vs 80)
- Word-by-word reveal: split text, wrap in .word spans, ScrollTrigger onUpdate with progress
- Magnetic buttons: mousemove offset * 0.18, mouseleave elastic.out(1,.4) reset
- FAQ accordion: gsap.to maxHeight with scrollHeight + padding (avoid animating height — auto trick)
- Custom cursor: dot=direct, ring=GSAP ticker lerp 0.15
- Three.js render via GSAP ticker: `gsap.ticker.add(() => renderer.render(scene, camera))`
- Three.js disable on mobile < 768px entirely for performance
- ScrollTrigger pin: use `gsap.matchMedia()` to enable only desktop + no-preference reduced-motion

## Astro 5 — CDN globals + modular TS (CRITICAL)
- CDN scripts go in `<body>` end with `is:inline` to skip bundler
- Module `<script>` (no `is:inline`) can `import` from `../lib/*.ts` and gets bundled per-page
- Declare globals once in lib file: `declare global { interface Window { gsap: any; ScrollTrigger: any; Lenis: any; SplitType: any; ... } }`
- Each component init pattern: `function waitGsap(cb, retries=60) { if (window.gsap) cb(); else setTimeout(..., 50); }` polls until CDN globals exist
- Components that need motion: write `<script>` block at end, import from `../lib/motion`, call `waitGsap(initMyComponent)`

## Lenis CSS overrides (REQUIRED for proper smooth scroll)
```css
html.lenis, html.lenis body { height: auto; }
.lenis.lenis-smooth { scroll-behavior: auto !important; }
.lenis.lenis-stopped { overflow: hidden; }
.lenis.lenis-scrolling iframe { pointer-events: none; } /* IMPORTANT: maps inside scroll-smooth break without this */
```

## prefers-reduced-motion strategy
- Detect at runtime in each component init
- Skip Lenis init entirely (smooth scroll annoys reduced-motion users)
- Skip pin/scrub; use opacity-only fade-ins
- Render canvas as single static frame, no rAF loop
- CSS @media query also kills scroll-progress, marquee, animations

## Common Mistakes Avoided
- Animating width/height/top/left → use transform/opacity ALWAYS
- Forgetting `gsap.ticker.lagSmoothing(0)` → scrub stutters
- Not refreshing ScrollTrigger after fonts load → wrong positions. Pattern: `document.fonts.ready.then(() => ScrollTrigger.refresh())`
- Pinning on mobile → janky, sometimes scroll breaks. Use matchMedia.
- iframe inside lenis-scrolling block → pointer events trap. CSS fix above.
- SplitType chars sin overflow:hidden en .word → yPercent visible afuera del rect

## Playwright Testing
- Must serve via http-server (no file:// URLs)
- Check port availability - 8765 often in use, use 8799+ as fallback
- Wait 4s after navigation for loader animations
- fullPage screenshots work well for landing pages
- favicon.ico 404 is expected/normal

## Performance Notes
- Single-file HTML with inline CSS/JS loads fastest (but Astro modular OK too)
- IntersectionObserver for lazy canvas init
- Debounce canvas resize at 200ms
- Three.js: `setPixelRatio(Math.min(devicePixelRatio, 1.5))`

## Three.js Food Objects
- Low-poly: SphereGeometry(scaled) body + CylinderGeometry bone + small sphere bumps
- Checkered texture: CanvasTexture with 64x64 canvas, 8x8 grid pattern
- MeshPhongMaterial flatShading:true for stylized look
- PointLight blue + AmbientLight gold = nighttime food scene

## CSS Patterns
- Damero: `repeating-conic-gradient(color 0% 25%, transparent 0% 50%) 0 0/20px 20px`
- Grain: inline SVG feTurbulence data URI, opacity .04-.05
- Glassmorphism: rgba bg + backdrop-filter:blur(12px) + rgba border
- Scroll progress bar: `animation-timeline: scroll(root)` native CSS (no JS) — supported Chrome 115+
- Marquee mask edges: `mask-image: linear-gradient(90deg, transparent 0, #000 8%, #000 92%, transparent 100%)`

## Font Pairings
- Bangers + Nunito 400-800 = fun street-food / youth brand
- Syne 700/800 + Manrope 300-700 = premium agency aesthetic
- Fraunces (opsz + ital variable) + Inter = editorial restaurant / bistró
  - For HUGE display: opsz 144, ital 1, weight 400, letter-spacing -0.04em
  - Fraunces Google Fonts URL with italics: `?family=Fraunces:opsz,ital,wght@9..144,0,400;9..144,0,500;9..144,1,400;9..144,1,500`

## simpleParallax patterns (v6.0+)
- Init: `new simpleParallax(images, { orientation:'up', scale:1.4, delay:0.4, overflow:false })`
- Combina bien con Lenis (Lenis maneja scroll, simpleParallax lee scrollY)
- NO usar simultáneamente con GSAP ScrollTrigger sobre los mismos elementos (doble animación)
- Mobile: bajar scale a 1.2 o desactivar (matchMedia `(max-width: 768px)`) — parallax pierde impacto en pantallas chicas y consume batería
- Para 5+ imágenes: instanciar dentro de IntersectionObserver (solo cuando entran al viewport)
- Industries que funcionan: arquitectura, fotografía, restaurantes con food shots, travel, fashion lookbooks, agency case studies
- NO usar en: fintech, banking, corporate, healthcare/wellness — parallax sugiere "marketing tone" inadecuado para trust-focused brands
- Bug típico: img sin `width/height` HTML attrs → CLS alto. Siempre setear ambos.
- React variant: import default `SimpleParallax` desde `simple-parallax-js`, wrap `<img>` con `<SimpleParallax orientation="up" scale={1.5}>`

## Food Delivery Landing
- WhatsApp cart: encodeURIComponent, asterisks for bold in message
- Menu tabs: data-cat filter, re-render with GSAP stagger
- Peru phone: wa.me/51XXXXXXXXX
- Argentina: wa.me/5491XXXXXXXX

## Restaurant / Bistró Landing (Olivar)
- Editorial cinematic = Fraunces italic huge + dark night bg + terracotta accent
- Effective sections order: Hero pinned → Marquee transición → About clip-paths → Menu asimétrico → Space horizontal → Wines mask reveals → Reservas stagger → Visit radial map → Footer wordmark grow
- WhatsApp reservation form: stub `buildWhatsappMessage` lanza error hasta que user lo implemente → siempre catch con fallback message

