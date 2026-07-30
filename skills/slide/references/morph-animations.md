# Morph Animations Reference

Exact GSAP patterns for the Asombro presentation effect. Read this when building the timeline.

---

## 1. The core principle: shared-element morph

PowerPoint's Morph effect works because the **same logical object** moves between slides — not because two different objects fade in/out. We replicate this with **a single DOM element tweened across multiple timeline labels**.

**Wrong (don't do this):**
```html
<!-- Slide 2 -->
<img class="hero hero-slide2" src="tower.jpg">
<!-- Slide 3 -->
<img class="hero hero-slide3" src="tower.jpg">
```
Then fading one out and the other in. This is *not* morph, this is dissolve.

**Right (do this):**
```html
<!-- Single element rendered once, lives in the DOM for the whole deck -->
<img id="hero" src="tower.jpg">
```
```javascript
tl.to("#hero", { x: 400, y: 100, scale: 0.8, duration: 1.2, ease: "power3.inOut" }, "slide3");
tl.to("#hero", { x: -200, y: 50, scale: 1.1, duration: 1.2, ease: "power3.inOut" }, "slide4");
```
The element moves continuously across the deck. That's morph.

---

## 2. Timeline architecture

Single master timeline, paused on load, advanced by click.

```javascript
const tl = gsap.timeline({ paused: true, defaults: { duration: 1, ease: "power3.inOut" } });

// Slide 1 is the static starting state — no tweens needed.

tl.addLabel("slide2")
  .to("#hero",    { /* new state */ }, "slide2")
  .to("#title",   { /* new state */ }, "slide2")
  .to(".dot:nth-child(2)", { width: 12, height: 12, backgroundColor: "var(--text)" }, "slide2");

tl.addLabel("slide3")
  .to("#hero",    { /* new state */ }, "slide3")
  .to("#ring",    { scale: 1, opacity: 1 }, "slide3+=0.2")
  .to(".stat",    { opacity: 1, x: 0, stagger: 0.15 }, "slide3+=0.4");

// Click handler
const labels = ["slide2", "slide3", "slide4", "slide5"];
let i = 0;
container.addEventListener("click", () => {
  if (i < labels.length) {
    tl.tweenTo(labels[i]);
    i++;
  } else {
    tl.tweenTo(0); i = 0;  // loop
  }
});
```

**Why `tweenTo()` and not `play()`**: `tweenTo` lets you skip to a label cleanly even if the user clicks fast or goes backwards. It also auto-reverses if needed.

---

## 3. Easing & duration vocabulary

| Move type | Easing | Duration |
|---|---|---|
| Hero element repositioning | `power3.inOut` | 1.0–1.4s |
| Title shrink + relocate | `power2.inOut` | 0.8–1.0s |
| Element entry from off-screen | `power3.out` | 1.0–1.2s |
| Element exit off-screen | `power3.in` | 0.6–0.8s |
| Scale-from-zero (circles, rings) | `back.out(1.4)` | 0.8–1.0s |
| Stat callout entry | `back.out(1.2)` | 0.6–0.8s |
| Continuous rotation | `none` (linear) | 60s, repeat: -1 |
| Pulse/heartbeat | `sine.inOut` | 1.2s, yoyo: true, repeat: -1 |
| Micro-bounce (letter dot) | `back.out(2)` | 0.4s, yoyo: true, repeat: 1 |

**Never use `linear` for positional moves** — it looks robotic. Reserve `linear` (`none`) for continuous loops only.

---

## 4. Micro-interaction catalog

Each slide must include at least one of these *in addition to* the morph itself.

### 4.1 The letter-dot hop (slide 1 → slide 2 transition)

The dot of an `i` (or any small accent element) separates, hops up, changes color, drops back. Used on the hero slide's title.

```html
<h1 class="title">Par<span class="i-dot">ı</span>s</h1>
<span class="i-dot-mark" id="iDot"></span>  <!-- the visual dot, separate element -->
```

```javascript
tl.to("#iDot", { y: -40, backgroundColor: "var(--accent)", duration: 0.4, ease: "back.out(2)" }, "slide2-=0.3")
  .to("#iDot", { y: 0, duration: 0.5, ease: "bounce.out" }, "slide2+=0.1");
```

Or, simpler — animate it inline as part of the slide-1 idle loop:
```javascript
gsap.to("#iDot", { y: -8, duration: 1.4, ease: "sine.inOut", yoyo: true, repeat: -1 });
```

### 4.2 Flag bars slide (signature transition move)

The diagonal bars shift horizontally between slides. Tiny but instantly recognizable.

```javascript
tl.to(".bar-light", { x: -40, duration: 1.0 }, "slide2");
tl.to(".bar-accent", { x: 60, duration: 1.0 }, "slide2");

tl.to(".bar-light", { x: 20, duration: 1.0 }, "slide3");
tl.to(".bar-accent", { x: -80, duration: 1.0 }, "slide3");
```

### 4.3 Nav-dot relocation

The active nav dot is always the same DOM element — it moves down the column, not a different dot lighting up.

```html
<div class="nav-dots">
  <span class="dot" data-slide="1"></span>
  <span class="dot" data-slide="2"></span>
  <span class="dot active" id="activeDot"></span>  <!-- this one moves -->
  <span class="dot" data-slide="4"></span>
</div>
```

Actually simpler: keep 5 static dots, and animate which one has the `.active` class via GSAP attribute morphing — but morph the position of a separate "active indicator" element that slides up/down behind them.

### 4.4 Orbital ring rotation + plus pulse

Once the ring appears (slide 3), it rotates forever and the plus-icons pulse on a stagger.

```javascript
gsap.to("#ring", { rotation: 360, duration: 60, ease: "none", repeat: -1, transformOrigin: "center" });
gsap.to(".plus-icon", {
  scale: 1.3, opacity: 0.7,
  duration: 1.2, ease: "sine.inOut",
  yoyo: true, repeat: -1, stagger: 0.25
});
```

### 4.5 Stat counter (count-up)

When a stat appears, the number counts up from 0. Use a GSAP object tween + ticker.

```javascript
const counter = { val: 0 };
tl.to(counter, {
  val: 300, duration: 1.2, ease: "power2.out",
  onUpdate: () => document.getElementById("statHeight").textContent = Math.floor(counter.val)
}, "slide3+=0.5");
```

### 4.6 Pin tag pulse

The location pin breathes subtly throughout the whole deck — set this on load, not in the master timeline.

```javascript
gsap.to(".pin-tag svg", { scale: 1.15, duration: 1.4, ease: "sine.inOut", yoyo: true, repeat: -1 });
```

### 4.7 Hero image clip-path morph

The hero image is clipped by a diagonal — this clip-path morphs between slides for a "the world is tilting" feel.

```javascript
tl.to("#hero", {
  clipPath: "polygon(0% 0%, 100% 0%, 100% 100%, 20% 100%)",
  duration: 1.2
}, "slide3");
```

### 4.8 Title shrink-and-relocate

The hero title doesn't disappear — it shrinks and moves to its slide-2 position as a label.

```javascript
tl.to("#title", {
  fontSize: "64px",
  top: "80px", left: "80px", xPercent: 0, yPercent: 0,
  duration: 1.0, ease: "power2.inOut"
}, "slide2");
```

---

## 5. Stagger patterns

Use `stagger` whenever multiple similar elements enter together. Default to `stagger: 0.12`.

```javascript
tl.from(".stat", {
  opacity: 0, y: 30, scale: 0.9,
  duration: 0.6, ease: "back.out(1.2)",
  stagger: 0.15
}, "slide3+=0.6");
```

For more sophisticated patterns:
```javascript
stagger: { each: 0.1, from: "center", grid: "auto" }
```

---

## 6. Common gotchas

### 6.1 `transform-origin` matters

For scaling a circle from a point, set the origin first or it'll grow off-axis:
```javascript
gsap.set("#ring", { transformOrigin: "center center" });
```

### 6.2 `xPercent`/`yPercent` vs `x`/`y`

Use `xPercent: -50, yPercent: -50` for centering — this is relative to the element's own size and survives resize. Use `x`/`y` for pixel offsets.

### 6.3 Don't tween `display`

`display: none` is not animatable. Use `opacity` + `visibility` + `pointer-events`, or set `autoAlpha: 0` (GSAP shortcut that handles both opacity and visibility):
```javascript
tl.to("#thing", { autoAlpha: 0, duration: 0.4 }, "slide4");
```

### 6.4 Pre-set initial states

If an element starts off-screen, set its position with `gsap.set()` *before* the timeline runs, not via CSS. CSS positions can fight GSAP's transform matrix:
```javascript
gsap.set("#iPad", { x: 800, opacity: 0 });
```

### 6.5 Click-during-animation

Use `tl.tweenTo()` (not `tl.play()`), which handles overlapping clicks gracefully.

---

## 7. The whole timeline at a glance (template)

```javascript
const tl = gsap.timeline({ paused: true, defaults: { duration: 1, ease: "power3.inOut" } });

// Pre-state for off-screen elements
gsap.set("#hero", { x: 0, y: 800 });   // starts below
gsap.set("#iPad", { x: 800, opacity: 0 }); // starts right of frame
gsap.set("#ring", { scale: 0, opacity: 0 });

// SLIDE 2: hero rises, title shrinks to corner, first stat appears
tl.addLabel("slide2")
  .to("#hero",   { y: 0 }, "slide2")
  .to("#title",  { fontSize: "64px", top: 80, left: 80, xPercent: 0, yPercent: 0 }, "slide2")
  .to(".stat-1", { opacity: 1, x: 0 }, "slide2+=0.4")
  .to(".bar-light", { x: -30 }, "slide2")
  .to(".bar-accent", { x: 50 }, "slide2");

// SLIDE 3: hero shifts, ring appears, stats orbit
tl.addLabel("slide3")
  .to("#hero",   { scale: 0.85, x: -100 }, "slide3")
  .to("#ring",   { scale: 1, opacity: 1, duration: 1.2, ease: "back.out(1.4)" }, "slide3+=0.2")
  .to(".stat-1, .stat-2, .stat-3", { opacity: 1, x: 0, stagger: 0.15, ease: "back.out(1.2)" }, "slide3+=0.5");

// SLIDE 4: media moment, iPad slides in
tl.addLabel("slide4")
  .to("#hero",   { x: -400, scale: 0.7 }, "slide4")
  .to("#ring",   { x: -400, scale: 0.7 }, "slide4")
  .to(".stat-1, .stat-2, .stat-3", { x: -200 }, "slide4")
  .to("#iPad",   { x: 0, opacity: 1, ease: "power3.out", duration: 1.2 }, "slide4+=0.3");

// SLIDE 5: closing — everything composes into final hero shot or CTA
tl.addLabel("slide5")
  .to("#iPad",   { x: 800, opacity: 0 }, "slide5")
  .to("#hero",   { scale: 1.2, x: 0, y: 0 }, "slide5")
  .to(".cta",    { opacity: 1, y: 0 }, "slide5+=0.4");
```
