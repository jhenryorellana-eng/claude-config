# Interactions Reference

Beyond the linear click-to-advance and morph transitions, Asombro decks support **event-driven interactions**: click triggers, modal overlays, tab navigation, hotspots, and the signature Prezi-style **zoom portal** effect. This file documents how to implement each pattern.

Read this whenever the user requests:
- A "menu" or "index" slide where each item opens detail
- "Click to reveal", "click para ampliar", "interactivo"
- Tab/pill navigation between subtopics
- A zoom-into-element effect (Prezi-style)
- Hotspots on an image or map
- "Quiero que sea interactivo, no solo lineal"

---

## 1. The interaction model

Every deck has **two complementary modes**:

| Mode | Trigger | Use for |
|---|---|---|
| **Linear morph** | Click anywhere on slide background → advances to next label | Storytelling, narrative arcs (default mode from morph-animations.md) |
| **Event-driven** | Click on specific element → triggers a specific action | Index menus, tabs, hotspots, modals, zoom portals |

The two can coexist in one deck. Slide 1 might be a linear hero, slide 2 a radial menu (event-driven), slides 3-9 the detail destinations (event-driven returns), and slide 10 a linear closing. **Always tell the user how navigation works** at the start (a small "click para explorar" hint).

---

## 2. The unified trigger system

Use **`data-` attributes** on HTML elements to declare interactivity. The boilerplate ships with a global event delegator that reads these attributes and dispatches the right action — no per-element event listeners scattered across the code.

### 2.1 Declarative trigger attributes

```html
<!-- Click opens detail panel by ID -->
<div data-trigger="detail-1" data-action="open">Separación de datos</div>

<!-- Click closes a panel -->
<button data-trigger="detail-1" data-action="close">×</button>

<!-- Click switches active tab -->
<button data-trigger="tab-2" data-action="tab" data-group="users-tabs">2</button>

<!-- Click triggers Prezi-style zoom into element -->
<div data-trigger="zoom-history" data-action="zoom-in">Historia →</div>

<!-- Click reverses the zoom (returns to overview) -->
<button data-trigger="zoom-out" data-action="zoom-out">Volver</button>

<!-- Click toggles a hotspot pulse panel -->
<div data-trigger="hotspot-tower" data-action="toggle">+</div>
```

### 2.2 The global event delegator (in the boilerplate)

```javascript
document.addEventListener('click', (e) => {
  const trigger = e.target.closest('[data-trigger]');
  if (!trigger) return;
  e.stopPropagation();  // prevent slide-advance bubbling

  const id     = trigger.dataset.trigger;
  const action = trigger.dataset.action || 'open';
  const group  = trigger.dataset.group;

  dispatchAction(action, id, trigger, group);
});

function dispatchAction(action, id, source, group) {
  switch (action) {
    case 'open':      openPanel(id, source); break;
    case 'close':     closePanel(id); break;
    case 'toggle':    togglePanel(id); break;
    case 'tab':       switchTab(group, id); break;
    case 'zoom-in':   zoomInto(id, source); break;
    case 'zoom-out':  zoomOut(); break;
    case 'reveal':    revealElement(id); break;
    case 'hide':      hideElement(id); break;
  }
}
```

### 2.3 Why this matters

- **Single source of truth**: all interactions are visible in HTML (the `data-` attrs), not buried in JS event listeners
- **Easy to extend**: add a new action type by adding one case to the switch
- **Survives DOM mutations**: event delegation works for elements added later
- **No conflict with linear-advance**: `stopPropagation()` keeps interactive elements from also advancing the slide

---

## 3. Action implementations

### 3.1 `open` / `close` / `toggle` — panel reveal

Pattern: a hidden panel exists in the DOM (with `opacity: 0; pointer-events: none; transform`), and click reveals it with a GSAP tween.

```javascript
function openPanel(id, source) {
  const panel = document.getElementById(id);
  if (!panel) return;
  
  // Optional: animate FROM the click source for a "growing out" feel
  if (source) {
    const r = source.getBoundingClientRect();
    const wrap = panel.parentElement.getBoundingClientRect();
    gsap.set(panel, {
      transformOrigin: `${r.left + r.width/2 - wrap.left}px ${r.top + r.height/2 - wrap.top}px`
    });
  }

  gsap.set(panel, { pointerEvents: 'auto' });
  gsap.fromTo(panel,
    { opacity: 0, scale: 0.85, y: 20 },
    { opacity: 1, scale: 1, y: 0, duration: 0.55, ease: 'back.out(1.4)' }
  );
}

function closePanel(id) {
  const panel = document.getElementById(id);
  if (!panel) return;
  gsap.to(panel, {
    opacity: 0, scale: 0.92, y: 12,
    duration: 0.3, ease: 'power2.in',
    onComplete: () => gsap.set(panel, { pointerEvents: 'none' })
  });
}

function togglePanel(id) {
  const panel = document.getElementById(id);
  if (!panel) return;
  const isOpen = parseFloat(panel.style.opacity || getComputedStyle(panel).opacity) > 0.5;
  isOpen ? closePanel(id) : openPanel(id);
}
```

**HTML structure:**

```html
<!-- The trigger -->
<div class="menu-item" data-trigger="detail-separation" data-action="open">
  Separación de datos
</div>

<!-- The hidden panel -->
<div id="detail-separation" class="detail-panel" style="opacity: 0; pointer-events: none;">
  <button class="close-btn" data-trigger="detail-separation" data-action="close">×</button>
  <h2>Separación y aislamiento de datos</h2>
  <p>Cada departamento tenía sus propios ficheros separados...</p>
</div>
```

**CSS for the panel:**

```css
.detail-panel {
  position: absolute;
  top: 50%; left: 50%;
  transform: translate(-50%, -50%);
  width: 60%; padding: 48px;
  background: var(--bg);
  border: 1px solid var(--accent);
  border-radius: 16px;
  z-index: 30;
  box-shadow: 0 30px 80px rgba(0,0,0,0.5);
}
```

### 3.2 `tab` — segmented control switching

Multiple buttons share a `data-group` value. Clicking one activates it and deactivates siblings, then shows the matching content panel.

```javascript
const tabState = {};  // { groupName: activeTabId }

function switchTab(group, tabId) {
  if (!group) return;
  const prevId = tabState[group];
  tabState[group] = tabId;

  // Animate visual state of pills
  document.querySelectorAll(`[data-group="${group}"]`).forEach(pill => {
    const isActive = pill.dataset.trigger === tabId;
    gsap.to(pill, {
      backgroundColor: isActive ? 'var(--accent)' : 'transparent',
      color: isActive ? 'var(--text)' : 'var(--muted)',
      scale: isActive ? 1.05 : 1,
      duration: 0.35, ease: 'power2.out'
    });
  });

  // Swap content panels
  if (prevId && prevId !== tabId) {
    gsap.to(`#${prevId}`, { opacity: 0, x: -30, duration: 0.3, ease: 'power2.in',
      onComplete: () => gsap.set(`#${prevId}`, { display: 'none' }) });
  }
  gsap.set(`#${tabId}`, { display: 'block', x: 30, opacity: 0 });
  gsap.to(`#${tabId}`, { opacity: 1, x: 0, duration: 0.5, ease: 'power3.out', delay: 0.2 });
}
```

**HTML structure** (matches your PPTX's "Usuarios de los SGBD" slides 9-12):

```html
<div class="tab-bar">
  <button data-trigger="tab-1" data-action="tab" data-group="users" class="pill active">1</button>
  <button data-trigger="tab-2" data-action="tab" data-group="users" class="pill">2</button>
  <button data-trigger="tab-3" data-action="tab" data-group="users" class="pill">3</button>
  <button data-trigger="tab-4" data-action="tab" data-group="users" class="pill">4</button>
</div>

<div id="tab-1" class="tab-content">
  <h2>Administradores</h2>
  <p>Responsables de configuración…</p>
</div>
<div id="tab-2" class="tab-content" style="display:none;">
  <h2>Diseñadores</h2>
  <p>Realizan el diseño lógico…</p>
</div>
<!-- ... -->
```

### 3.3 `zoom-in` / `zoom-out` — the Prezi portal

The signature move: clicking an element makes it scale up until it fills the viewport, while the surrounding content fades away. When the zoom completes, the element's interior reveals as a "new slide". Click "back" zooms out, reversing the move.

**The math**: you need the element's center coordinates relative to the slide container, then compute the scale factor so it fills 1280×720.

```javascript
let zoomStack = [];  // for nested zooms / back navigation

function zoomInto(targetId, source) {
  const slide = document.getElementById('slide-container');
  const r = source.getBoundingClientRect();
  const s = slide.getBoundingClientRect();
  
  // Center of the clicked element relative to the slide
  const cx = (r.left + r.width/2 - s.left);
  const cy = (r.top + r.height/2 - s.top);
  
  // Scale factor: make the element ~1.5× the slide diagonal so it fully fills
  const scale = Math.max(1280 / r.width, 720 / r.height) * 1.5;

  // Save state for zoom-out
  zoomStack.push({ targetId, sourceEl: source });

  // 1. Scale the clicked element up while pinning its center
  gsap.to(source, {
    scale,
    x: 1280/2 - cx,
    y: 720/2 - cy,
    transformOrigin: 'center center',
    duration: 1.2, ease: 'power2.inOut'
  });

  // 2. Fade out everything else in the current slide
  gsap.to(`#slide-container > *:not(#${source.id || 'NOPE'}):not(#${targetId})`, {
    opacity: 0, duration: 0.6, ease: 'power2.in'
  });

  // 3. Reveal the destination content (which was hidden)
  gsap.set(`#${targetId}`, { display: 'block', opacity: 0, scale: 1.2 });
  gsap.to(`#${targetId}`, {
    opacity: 1, scale: 1,
    duration: 0.8, ease: 'power3.out',
    delay: 0.6
  });
}

function zoomOut() {
  const last = zoomStack.pop();
  if (!last) return;

  // 1. Hide destination content
  gsap.to(`#${last.targetId}`, { opacity: 0, scale: 1.2, duration: 0.4 });

  // 2. Bring source element back to its original position
  gsap.to(last.sourceEl, {
    scale: 1, x: 0, y: 0,
    duration: 1.0, ease: 'power2.inOut', delay: 0.2
  });

  // 3. Restore the other slide elements
  gsap.to(`#slide-container > *`, {
    opacity: 1, duration: 0.5, delay: 0.6, ease: 'power2.out'
  });
}
```

**HTML pattern:**

```html
<!-- The portal trigger (a clickable element that will zoom up) -->
<div id="portal-history" 
     data-trigger="zoom-content-history" 
     data-action="zoom-in"
     style="position: absolute; left: 40%; top: 40%; width: 200px; height: 200px; 
            background-image: url('old-database.jpg'); background-size: cover;
            border-radius: 50%; cursor: zoom-in;">
</div>

<!-- The destination content (hidden initially) -->
<div id="zoom-content-history" style="display: none; position: absolute; inset: 0; padding: 80px;">
  <button data-trigger="zoom-out" data-action="zoom-out" class="back-btn">← Volver</button>
  <h1>Historia de las bases de datos</h1>
  <div class="timeline"><!-- ... --></div>
</div>
```

**Critical for the illusion to feel real:**
- The clicked element should have **visual content** (image, illustration) that makes sense when zoomed — empty circles look weird at 8× scale
- Use `cursor: zoom-in` on triggers and `cursor: zoom-out` on the back button
- Add a subtle scale "anticipation" on hover (`scale: 1.03`) so the user knows it's clickable
- The destination content should **start scaled at 1.2× and zoom down to 1×** while appearing — this echoes the "you're entering" feeling

### 3.4 `reveal` / `hide` — directional element entry

Simpler than panel open/close — animates a single element in or out without modal overlay framing. Used for inline reveals (e.g., click a hotspot → a callout slides in from the side).

```javascript
function revealElement(id) {
  const el = document.getElementById(id);
  if (!el) return;
  const dir = el.dataset.from || 'right';  // right, left, top, bottom
  const offset = { right: { x: 100 }, left: { x: -100 }, top: { y: -50 }, bottom: { y: 50 } }[dir];
  gsap.fromTo(el, { opacity: 0, ...offset }, { opacity: 1, x: 0, y: 0, duration: 0.6, ease: 'back.out(1.2)' });
}

function hideElement(id) {
  gsap.to(`#${id}`, { opacity: 0, duration: 0.4 });
}
```

---

## 4. The radial menu pattern (matches PPTX slide 1)

A central circle (the "topic") surrounded by 6-8 satellite nodes (the subtopics). Each satellite is a click trigger that opens a detail panel.

### 4.1 Geometry

For N satellites around a central point `(cx, cy)` at radius `r`:

```javascript
const N = 7;
const cx = 640, cy = 360, r = 240;
satellites.forEach((sat, i) => {
  const angle = (i / N) * Math.PI * 2 - Math.PI / 2;  // start from top
  sat.x = cx + r * Math.cos(angle);
  sat.y = cy + r * Math.sin(angle);
});
```

Or place them with CSS percentages if you prefer hand-positioned (closer to your PPTX design):
- Top: 50% / 8%
- Top-right: 82% / 22%
- Bottom-right: 88% / 65%
- Bottom: 50% / 88%
- Bottom-left: 12% / 65%
- Top-left: 18% / 22%
- Left/Right midpoints if you need 7-8 items

### 4.2 Entry animation

Satellites enter with a **staggered radial sweep** — each one fades + scales in with a delay based on its angle.

```javascript
gsap.from('.satellite', {
  opacity: 0,
  scale: 0,
  duration: 0.7,
  ease: 'back.out(1.6)',
  stagger: { each: 0.08, from: 'start' }
});

// Central circle pulses gently to invite interaction
gsap.to('#central-hub', {
  scale: 1.04, duration: 1.6, ease: 'sine.inOut', yoyo: true, repeat: -1
});
```

### 4.3 Connecting lines (optional but elegant)

Thin curved or straight lines from the hub to each satellite, drawn with SVG. Animate `stroke-dashoffset` for a "drawing" effect on entry.

```html
<svg class="radial-lines" viewBox="0 0 1280 720" style="position: absolute; inset: 0; pointer-events: none;">
  <line x1="640" y1="360" x2="640" y2="120" stroke="var(--muted)" stroke-width="1" opacity="0.3" 
        stroke-dasharray="200" stroke-dashoffset="200" class="line"/>
  <!-- one line per satellite -->
</svg>

<script>
gsap.to('.line', { strokeDashoffset: 0, duration: 0.8, stagger: 0.08, ease: 'power2.out' });
</script>
```

### 4.4 Satellite hover micro-interaction

Each satellite scales up on hover and pulls its connecting line color to the accent:

```css
.satellite {
  transition: transform 0.3s ease;
  cursor: pointer;
}
.satellite:hover {
  transform: scale(1.08);
}
.satellite:hover .satellite-label {
  color: var(--accent);
}
```

---

## 5. The hotspot pattern

For images or maps with clickable points of interest. Each hotspot is a small pulsing `+` circle; clicking opens an info card next to it.

```html
<div class="hotspot-image">
  <img src="eiffel-tower.jpg">
  <button class="hotspot" data-trigger="hot-1" data-action="toggle" style="top: 20%; left: 50%;">+</button>
  <button class="hotspot" data-trigger="hot-2" data-action="toggle" style="top: 60%; left: 45%;">+</button>
</div>

<div id="hot-1" class="hotspot-card" style="opacity: 0;">
  <h3>Antena superior</h3>
  <p>Añadida en 1957 para transmisión radio…</p>
</div>
```

```css
.hotspot {
  position: absolute;
  width: 32px; height: 32px;
  border-radius: 50%;
  background: var(--accent);
  border: 2px solid var(--text);
  color: var(--text);
  cursor: pointer;
  animation: hotspot-pulse 1.6s ease-in-out infinite;
}
@keyframes hotspot-pulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(239,74,60,0.6); }
  50% { box-shadow: 0 0 0 14px rgba(239,74,60,0); }
}
```

---

## 6. State management

For decks with multiple interactive elements, maintain a single state object:

```javascript
const deckState = {
  currentLabel: null,           // current GSAP timeline label
  openPanels: new Set(),        // which detail panels are currently open
  activeTabs: {},               // { groupName: activeTabId }
  zoomStack: [],                // for nested Prezi zooms
  history: []                   // for back-button support
};

function pushHistory(action, payload) {
  deckState.history.push({ action, payload, timestamp: Date.now() });
}
```

This enables:
- **Escape key closes the topmost open panel** (intuitive UX)
- **Back button (browser or keyboard)** reverses the last interaction
- **Deep linking** via URL hash if you want shareable states (advanced)

```javascript
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    if (deckState.zoomStack.length) { zoomOut(); return; }
    if (deckState.openPanels.size) {
      const last = [...deckState.openPanels].pop();
      closePanel(last);
    }
  }
});
```

---

## 7. Mixing interactive slides with linear morph

Some slides are linear (click anywhere to advance), some are interactive (click only specific elements). Mark them:

```html
<div class="slide" data-mode="interactive" id="slide-menu">...</div>
<div class="slide" data-mode="linear" id="slide-intro">...</div>
```

In the global click handler:

```javascript
const slideEl = document.querySelector('.slide.current');
if (slideEl.dataset.mode === 'linear' && !e.target.closest('[data-trigger]')) {
  advanceTimeline();  // your tl.tweenTo logic
}
// Otherwise: only interactive triggers fire, never auto-advance
```

Always show the user **which mode each slide uses** with a small hint:
- Linear: "→ click para avanzar"
- Interactive: "↻ click los elementos para explorar"

The hint sits at the bottom of the slide in `--muted`, opacity 0.4.

---

## 8. Action catalog summary

| Action | Use case | Animation default |
|---|---|---|
| `open` | Show detail panel from menu item | Scale + fade from source point, `back.out(1.4)` |
| `close` | Dismiss detail panel | Scale + fade down, `power2.in` |
| `toggle` | Hotspot info cards | Same as open/close |
| `tab` | Segmented control switching | Pills color-morph + content slide-swap |
| `zoom-in` | Prezi portal into element | Scale to fill viewport, `power2.inOut`, 1.2s |
| `zoom-out` | Return from portal | Reverse of zoom-in |
| `reveal` | Inline element entry | Slide-in from side, `back.out(1.2)` |
| `hide` | Inline element exit | Fade out, `power2.in` |

---

## 9. Decision rules — when to use what

| User goal | Use |
|---|---|
| "Menú con opciones para explorar" | Radial menu + `open`/`close` panels |
| "Comparación de N elementos" | Tab navigation |
| "Storytelling lineal con sorpresa" | Linear morph + 1-2 click reveals on specific slides |
| "Mapa o imagen con info en puntos" | Hotspot pattern |
| "Sensación de profundidad / capas / 'entrar dentro de'" | Zoom portal (Prezi-style) |
| "Recorrido educativo no lineal" | Radial menu as homepage + linear sub-flows for each topic |
| "Quiero que el usuario controle el ritmo" | Tabs or radial menu (interactive) |
| "Quiero contar una historia con impacto" | Linear morph (default) |

---

## 10. Common bugs and how to avoid them

### 10.1 Click bubbles to slide-advance
**Fix**: always `e.stopPropagation()` in the trigger handler.

### 10.2 Panels appear in wrong place after zoom
**Fix**: panels should be absolutely positioned relative to `#slide-container`, not to a transformed element. Place them as direct children of the slide.

### 10.3 Re-clicking a tab causes content flicker
**Fix**: check `if (prevId === tabId) return;` early in `switchTab`.

### 10.4 Zoom-out doesn't return cleanly because the original element was further transformed
**Fix**: store the **original transform** of the source element in `zoomStack`, restore it explicitly on zoom-out.

### 10.5 Multiple panels open at once cause visual chaos
**Fix**: in `openPanel`, close any currently open panel in the same group first. Or limit to one open panel ever (close all others).

### 10.6 Hotspot pulse animations stack and crash performance
**Fix**: use CSS animation (not JS), and limit to ≤6 visible hotspots per slide.

### 10.7 Tab content panels stack visually when display: none is missing
**Fix**: every non-active tab content must have `display: none` (not just `opacity: 0`), otherwise they accumulate spatially.
