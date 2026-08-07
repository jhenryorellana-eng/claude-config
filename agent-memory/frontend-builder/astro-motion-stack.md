# Astro 5 + Motion Stack — CDN Globals Pattern

Receta completa probada en Olivar (May 2026).

## Layout.astro — head + body scripts

```astro
<head>
  <!-- Fonts: preconnect + display=swap -->
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,ital,wght@9..144,0,400;9..144,0,500;9..144,1,400&display=swap" rel="stylesheet" />
</head>
<body>
  <main><slot /></main>

  <!-- CDN globals (is:inline = bypass bundler) -->
  <script is:inline src="https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/gsap.min.js"></script>
  <script is:inline src="https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/ScrollTrigger.min.js"></script>
  <script is:inline src="https://cdn.jsdelivr.net/npm/lenis@1.1.18/dist/lenis.min.js"></script>
  <script is:inline src="https://cdn.jsdelivr.net/npm/split-type@0.3.4/umd/index.min.js"></script>

  <!-- App init (módulo bundled, puede importar TS) -->
  <script>
    import { initMotion, revealOnScroll } from '../lib/motion';

    function waitForMotionLibs(cb, retries = 50) {
      if (window.gsap && window.ScrollTrigger && window.Lenis && window.SplitType) cb();
      else if (retries > 0) setTimeout(() => waitForMotionLibs(cb, retries - 1), 40);
    }

    waitForMotionLibs(() => {
      initMotion();
      revealOnScroll('[data-reveal]', { y: 50 });

      if (document.fonts?.ready) {
        document.fonts.ready.then(() => window.ScrollTrigger?.refresh());
      }
      window.addEventListener('load', () => window.ScrollTrigger?.refresh());
    });
  </script>
</body>
```

## src/lib/motion.ts — central init

```ts
declare global {
  interface Window {
    gsap: any;
    ScrollTrigger: any;
    Lenis: any;
    SplitType: any;
    __olivarLenis?: any;
    __olivarMotionInited?: boolean;
  }
}

export const prefersReducedMotion = () =>
  typeof window !== 'undefined' &&
  window.matchMedia('(prefers-reduced-motion: reduce)').matches;

export function initMotion() {
  if (typeof window === 'undefined' || window.__olivarMotionInited) return;
  const { gsap, ScrollTrigger, Lenis } = window;
  if (!gsap || !ScrollTrigger || !Lenis) { setTimeout(initMotion, 50); return; }

  gsap.registerPlugin(ScrollTrigger);

  if (!prefersReducedMotion()) {
    const lenis = new Lenis({ duration: 1.15, easing: t => Math.min(1, 1.001 - Math.pow(2, -10*t)) });
    lenis.on('scroll', ScrollTrigger.update);
    gsap.ticker.add(time => lenis.raf(time * 1000));
    gsap.ticker.lagSmoothing(0);
    window.__olivarLenis = lenis;
  }

  let t;
  window.addEventListener('resize', () => {
    clearTimeout(t);
    t = setTimeout(() => ScrollTrigger.refresh(), 200);
  });
  window.__olivarMotionInited = true;
}

export function revealOnScroll(selector, options = {}) {
  const { y = 40, stagger = 0.08, duration = 0.9, start = 'top 85%' } = options;
  const els = Array.from(document.querySelectorAll(selector));
  if (!els.length) return;
  if (prefersReducedMotion()) {
    window.gsap.to(els, { opacity: 1, duration: 0.3 });
    return;
  }
  window.gsap.set(els, { opacity: 0, y, willChange: 'transform, opacity' });
  els.forEach((el, i) => {
    window.gsap.to(el, {
      opacity: 1, y: 0, duration, delay: i * stagger, ease: 'power3.out',
      scrollTrigger: { trigger: el, start, toggleActions: 'play none none none' },
      onComplete: () => el.style.willChange = 'auto',
    });
  });
}
```

## Cada componente — pattern de init

```astro
<section data-mycomp-root>
  <h2 data-mycomp-heading>Hello</h2>
</section>

<script>
  import { prefersReducedMotion } from '../lib/motion';

  function waitGsap(cb, retries = 60) {
    if (window.gsap && window.ScrollTrigger && window.SplitType) cb();
    else if (retries > 0) setTimeout(() => waitGsap(cb, retries - 1), 50);
  }

  function init() {
    const root = document.querySelector('[data-mycomp-root]');
    if (!root) return;
    const gsap = window.gsap;
    if (prefersReducedMotion()) { /* fallback */ return; }
    // ... usar gsap, ScrollTrigger, SplitType
  }

  waitGsap(init);
</script>
```

## Lenis CSS overrides (en global.css)

```css
html.lenis, html.lenis body { height: auto; }
.lenis.lenis-smooth { scroll-behavior: auto !important; }
.lenis.lenis-stopped { overflow: hidden; }
.lenis.lenis-scrolling iframe { pointer-events: none; }
```

## Gotchas
1. **`is:inline` para CDN**: sin esto, Astro intenta bundlearlos y rompe.
2. **Bundled `<script>` se ejecuta SOLO en su page**: si tu componente lo usás en otras páginas, el script va con él.
3. **Astro 5 collapses multiple bundled `<script>` per page**: si dos componentes definen `function waitGsap`, no choca porque Astro las scope-aisla por script-module — pero igual usar funciones internas a un IIFE evita potencial colisión global.
4. **TS strict**: `declare global { interface Window { ... } }` en motion.ts. Cada componente puede acceder a `window.gsap` con tipo `any`.
5. **fonts.ready + ScrollTrigger.refresh**: SIEMPRE refresca después de que las webfonts carguen. Si no, las posiciones de pin se calculan con la fuente fallback y al cargar la real se ven raras.

## Build vs Dev
- En dev (`npm run dev`): scripts hot-reload, CDN globals tardan ~100ms en cargar; el waitGsap pattern es robusto.
- En build (`npm run build`): scripts bundled van comprimidos, CDN globals cargan en paralelo. Performance:
  - GSAP+ScrollTrigger ~70KB minified
  - Lenis ~12KB
  - SplitType ~5KB
  - Total ~87KB gzip ≈ 30-40KB
  - LCP target <2.0s viable si fonts swap rápido
