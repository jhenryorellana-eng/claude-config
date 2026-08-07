# Motion Recipes — Disruptive Landing Patterns

Recetas reusables, probadas en proyectos reales (Olivar 2026).

## 1. Hero pin con scrub deformation
```js
const mm = gsap.matchMedia();
mm.add('(min-width: 768px)', () => {
  gsap.to([eyebrow, wordmark, headline, bottom], {
    scrollTrigger: {
      trigger: heroRoot,
      start: 'top top',
      end: '+=80%',
      pin: true,
      scrub: 0.6,
    },
    yPercent: -8,
    opacity: 0,
    scale: 0.94,
    ease: 'none',
  });
});
```
Mobile: skip pin, simple opacity fade.

## 2. SplitType + GSAP stagger chars
```js
const split = new SplitType(el, { types: 'lines,words,chars', tagName: 'span' });
gsap.set(split.chars, { yPercent: 110, opacity: 0 });
gsap.to(split.chars, {
  yPercent: 0, opacity: 1,
  duration: 0.9, stagger: 0.025, ease: 'power3.out',
  scrollTrigger: { trigger: el, start: 'top 80%' }
});
```
Necesita CSS:
```css
.split-word, .word { display: inline-block; overflow: hidden; vertical-align: top; }
.split-char, .char { display: inline-block; will-change: transform, opacity; }
```

## 3. Horizontal scroll pinned (Space)
```js
const mm = gsap.matchMedia();
mm.add('(min-width: 768px) and (prefers-reduced-motion: no-preference)', () => {
  const calc = () => Math.max(0, track.scrollWidth - gallery.clientWidth);
  const tl = gsap.to(track, {
    x: () => -calc(),
    ease: 'none',
    scrollTrigger: {
      trigger: gallery, start: 'top top',
      end: () => `+=${calc()}`,
      pin: true, scrub: 0.6,
      invalidateOnRefresh: true,
    },
  });
  // Per-card highlight via containerAnimation
  cards.forEach((card) => {
    gsap.to(card, {
      scale: 1.04,
      ease: 'none',
      scrollTrigger: {
        trigger: card, containerAnimation: tl,
        start: 'left center', end: 'right center',
        scrub: true,
      },
    });
  });
});
```

## 4. Clip-path reveal (de abajo hacia arriba)
```js
gsap.set(el, { clipPath: 'inset(100% 0% 0% 0%)', opacity: 0 });
gsap.to(el, {
  clipPath: 'inset(0% 0% 0% 0%)',
  opacity: 1,
  duration: 1.1, ease: 'power3.out',
  scrollTrigger: { trigger: el, start: 'top 85%' }
});
```

## 5. Circular reveal (map)
```js
gsap.set(el, { clipPath: 'circle(0% at 50% 50%)' });
gsap.to(el, {
  clipPath: 'circle(100% at 50% 50%)',
  duration: 1.6, ease: 'power3.out',
  scrollTrigger: { trigger: el, start: 'top 80%' }
});
```

## 6. SVG line drawing en scroll
```js
const len = path.getTotalLength();
gsap.set(path, { strokeDasharray: len, strokeDashoffset: len });
gsap.to(path, {
  strokeDashoffset: 0, ease: 'none',
  scrollTrigger: { trigger: parent, start: 'top 60%', end: 'bottom 30%', scrub: 1 }
});
// Ellipses: perim = π * (3*(rx+ry) - sqrt((3*rx+ry)*(rx+3*ry)))
```

## 7. Mask reveal left-to-right (Wines)
```js
gsap.set([name, origin, cepa], { clipPath: 'inset(0% 100% 0% 0%)', opacity: 0 });
const tl = gsap.timeline({ scrollTrigger: { trigger: row, start: 'top 88%' } });
tl.to(name,   { clipPath: 'inset(0% 0% 0% 0%)', opacity: 1, duration: 1.1 })
  .to(origin, { clipPath: 'inset(0% 0% 0% 0%)', opacity: 1, duration: 0.7 }, '-=0.7')
  .to(cepa,   { clipPath: 'inset(0% 0% 0% 0%)', opacity: 1, duration: 0.9 }, '-=0.5');
```

## 8. Counter-up animation
```js
const counter = { value: 0 };
const totalMin = h * 60 + m;
gsap.to(counter, {
  value: totalMin,
  duration: 1.4, ease: 'power2.out',
  scrollTrigger: { trigger: el, start: 'top 85%' },
  onUpdate: () => {
    const hh = Math.floor(counter.value / 60);
    const mm = Math.floor(counter.value % 60);
    el.textContent = `${pad(hh)}:${pad(mm)}`;
  },
  onComplete: () => { el.textContent = `${pad(h)}:${pad(m)}`; }
});
```

## 9. Marquee scroll-velocity-aware
```js
let scrollVelocity = 0;
lenis.on('scroll', (e) => {
  scrollVelocity = Math.min(8, Math.abs(e.velocity || 0));
});

const tick = () => {
  scrollVelocity *= 0.95; // decay
  tracks.forEach((track) => {
    const base = speeds.get(track);  // 0.5 * dir
    const dir = base >= 0 ? 1 : -1;
    const speed = base + scrollVelocity * 0.6 * dir;
    let pos = (positions.get(track) || 0) - speed;
    const half = track.scrollWidth / 2;
    if (pos <= -half) pos += half;
    if (pos > 0) pos -= half;
    positions.set(track, pos);
    track.style.transform = `translate3d(${pos}px, 0, 0)`;
  });
  requestAnimationFrame(tick);
};
requestAnimationFrame(tick);
```
Track HTML: render content TWICE side-by-side for infinite wrap.
CSS:
```css
.marquee { overflow:hidden; mask-image:linear-gradient(90deg, transparent, #000 8%, #000 92%, transparent); }
.marquee__track { display:inline-flex; will-change:transform; }
```

## 10. Tilt 3D card (hover)
```js
card.addEventListener('mousemove', (e) => {
  const rect = card.getBoundingClientRect();
  const x = (e.clientX - rect.left) / rect.width;   // 0..1
  const y = (e.clientY - rect.top) / rect.height;
  const rotY = (x - 0.5) * 12;
  const rotX = (0.5 - y) * 8;
  gsap.to(inner, {
    rotateX: rotX, rotateY: rotY,
    scale: 1.02, duration: 0.5,
    ease: 'power2.out', transformPerspective: 800,
  });
});
card.addEventListener('mouseleave', () => {
  gsap.to(inner, { rotateX: 0, rotateY: 0, scale: 1, duration: 0.7, ease: 'power3.out' });
});
```
Only `(hover: hover) and (pointer: fine)`.

## 11. Magnetic CTA
```js
el.addEventListener('mousemove', (e) => {
  const rect = el.getBoundingClientRect();
  const x = e.clientX - rect.left - rect.width / 2;
  const y = e.clientY - rect.top - rect.height / 2;
  gsap.to(el, { x: x * 0.18, y: y * 0.18, duration: 0.5, ease: 'power3.out' });
});
el.addEventListener('mouseleave', () => {
  gsap.to(el, { x: 0, y: 0, duration: 0.7, ease: 'elastic.out(1, 0.4)' });
});
```

## 12. Pulse CTA cuando form está lleno
```js
let pulseTween = null;
const startPulse = () => {
  if (pulseTween || reduced) return;
  pulseTween = gsap.to(submitBtn, {
    scale: 1.025, duration: 1.2,
    ease: 'sine.inOut', repeat: -1, yoyo: true,
  });
};
const stopPulse = () => {
  if (!pulseTween) return;
  pulseTween.kill();
  pulseTween = null;
  gsap.to(submitBtn, { scale: 1, duration: 0.3 });
};
form.addEventListener('input', () => allFilled() ? startPulse() : stopPulse());
```

## 13. Footer wordmark scroll-grow
```js
gsap.set(wordmark, { scale: 0.7, opacity: 0.4, y: 60, transformOrigin: '50% 100%' });
gsap.to(wordmark, {
  scale: 1, opacity: 1, y: 0,
  ease: 'none',
  scrollTrigger: { trigger: wrap, start: 'top 90%', end: 'bottom bottom', scrub: 0.8 }
});
```

## 14. Canvas particles (resumen)
- IntersectionObserver para pausar fuera de viewport
- document visibilitychange para pausar en tab oculta
- DPR cap 1.5
- 35 mobile / 80 desktop
- Mouse repel solo desktop (no isMobile)
- reduced-motion: drawStatic() una vez, no rAF
- Cleanup function return: stop rAF + disconnect IO + remove listeners
