# Iconography & Visual Elements Reference

Catalog of icons, geometric figures, and decorative elements to weave into slides. Use inline SVG — never raster icons.

---

## 1. Core philosophy

Icons in Asombro decks are **never decorative filler**. Each icon must:
- Reinforce a specific stat or concept (a clock icon next to "1889 — founded")
- Anchor a callout (the `+` icons on the orbital ring)
- Function as UI signage (the location pin, the play button)

If you can't justify why an icon is in a specific spot, remove it.

**Style consistency**: all icons in a single deck must share one stroke weight (default 1.75–2px) and one corner style (rounded ends, `stroke-linecap="round"` and `stroke-linejoin="round"`). Don't mix Feather-style with Material-filled in the same deck.

---

## 2. The icon catalog (inline SVG snippets)

Use 24×24 viewBox, `stroke="currentColor"` so they inherit color, `fill="none"` for outline style. Resize via the wrapping element.

### 2.1 Navigation / brand
```html
<!-- Paper plane (default brand mark) -->
<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M22 2L11 13M22 2l-7 20-4-9-9-4 20-7z"/>
</svg>

<!-- Compass -->
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75">
  <circle cx="12" cy="12" r="10"/>
  <polygon points="16.24 7.76 14.12 14.12 7.76 16.24 9.88 9.88 16.24 7.76"/>
</svg>

<!-- Arrow right (CTA) -->
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <line x1="5" y1="12" x2="19" y2="12"/>
  <polyline points="12 5 19 12 12 19"/>
</svg>
```

### 2.2 Location / travel
```html
<!-- Pin (filled, for pin-tag) -->
<svg viewBox="0 0 24 24" fill="currentColor">
  <path d="M12 22s8-7 8-13a8 8 0 1 0-16 0c0 6 8 13 8 13z"/>
  <circle cx="12" cy="9" r="2.5" fill="var(--bg)"/>
</svg>

<!-- Globe -->
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75">
  <circle cx="12" cy="12" r="10"/>
  <line x1="2" y1="12" x2="22" y2="12"/>
  <path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/>
</svg>

<!-- Mountain (for nature/landscape topics) -->
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linejoin="round">
  <path d="M3 20l5.5-10 4 7 3-5 5.5 8z"/>
  <circle cx="18" cy="6" r="1.5" fill="currentColor"/>
</svg>
```

### 2.3 Data / stats
```html
<!-- Calendar (for years/dates) -->
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75">
  <rect x="3" y="4" width="18" height="18" rx="2"/>
  <line x1="16" y1="2" x2="16" y2="6"/>
  <line x1="8" y1="2" x2="8" y2="6"/>
  <line x1="3" y1="10" x2="21" y2="10"/>
</svg>

<!-- Users (for visitor counts) -->
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75">
  <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/>
  <circle cx="9" cy="7" r="4"/>
  <path d="M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>
</svg>

<!-- Ruler / dimensions (height, length) -->
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75">
  <line x1="12" y1="2" x2="12" y2="22"/>
  <polyline points="6 8 12 2 18 8"/>
  <polyline points="6 16 12 22 18 16"/>
</svg>

<!-- Trending up -->
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <polyline points="23 6 13.5 15.5 8.5 10.5 1 18"/>
  <polyline points="17 6 23 6 23 12"/>
</svg>
```

### 2.4 Media
```html
<!-- Play -->
<svg viewBox="0 0 24 24" fill="currentColor">
  <polygon points="5 3 19 12 5 21 5 3"/>
</svg>

<!-- Camera -->
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75">
  <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/>
  <circle cx="12" cy="13" r="4"/>
</svg>
```

### 2.5 Tech / SaaS
```html
<!-- CPU -->
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75">
  <rect x="4" y="4" width="16" height="16" rx="2"/>
  <rect x="9" y="9" width="6" height="6"/>
  <line x1="9" y1="1" x2="9" y2="4"/><line x1="15" y1="1" x2="15" y2="4"/>
  <line x1="9" y1="20" x2="9" y2="23"/><line x1="15" y1="20" x2="15" y2="23"/>
  <line x1="20" y1="9" x2="23" y2="9"/><line x1="20" y1="14" x2="23" y2="14"/>
  <line x1="1" y1="9" x2="4" y2="9"/><line x1="1" y1="14" x2="4" y2="14"/>
</svg>

<!-- Code brackets -->
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <polyline points="16 18 22 12 16 6"/>
  <polyline points="8 6 2 12 8 18"/>
</svg>
```

### 2.6 Plus / minus / close (orbital anchors)
```html
<!-- Plus (already used on orbital ring) -->
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
  <line x1="12" y1="5" x2="12" y2="19"/>
  <line x1="5" y1="12" x2="19" y2="12"/>
</svg>
```

### 2.7 Icon library fallback

For any icon not in this catalog, use **Lucide** via CDN:
```html
<script src="https://unpkg.com/lucide@latest"></script>
<i data-lucide="leaf"></i>
<script>lucide.createIcons();</script>
```

But prefer inline SVG for production — fewer requests, sharper rendering, easier to style.

---

## 3. Geometric figures (accents)

Small SVG shapes sprinkled as accents. They add texture without filling space. Always in `--accent` color, opacity 0.6–0.85, size 12–24px.

### 3.1 Diamond
```html
<svg width="14" height="14" viewBox="0 0 14 14" fill="var(--accent)">
  <rect x="7" y="0" width="9.9" height="9.9" transform="rotate(45 7 7)"/>
</svg>
```

### 3.2 Asterisk
```html
<svg width="16" height="16" viewBox="0 0 16 16" fill="var(--accent)">
  <rect x="7" y="0" width="2" height="16"/>
  <rect x="0" y="7" width="16" height="2"/>
  <rect x="2.3" y="2.3" width="11.4" height="2" transform="rotate(45 8 8)"/>
  <rect x="2.3" y="2.3" width="11.4" height="2" transform="rotate(-45 8 8)"/>
</svg>
```

### 3.3 Triangle
```html
<svg width="14" height="12" viewBox="0 0 14 12" fill="var(--accent)">
  <polygon points="7,0 14,12 0,12"/>
</svg>
```

### 3.4 Hexagon outline
```html
<svg width="18" height="20" viewBox="0 0 18 20" fill="none" stroke="var(--accent)" stroke-width="1.5">
  <polygon points="9,1 17,6 17,14 9,19 1,14 1,6"/>
</svg>
```

### 3.5 Concentric dots (3 dots in a row)
```html
<svg width="32" height="6" viewBox="0 0 32 6">
  <circle cx="3" cy="3" r="2" fill="var(--accent)"/>
  <circle cx="16" cy="3" r="2" fill="var(--accent)"/>
  <circle cx="29" cy="3" r="2" fill="var(--accent)" opacity="0.4"/>
</svg>
```

**When to use these**: scattered randomly in negative space at low opacity, as bullets next to stat labels, as section dividers between text blocks. Maximum 4–6 per slide. Beyond that they become noise.

---

## 4. Decorative patterns & textures

### 4.1 Dotted grid background

Apply to a slide background for editorial texture. Pure CSS.

```css
.dotted-bg {
  background-image: radial-gradient(circle, var(--muted) 1px, transparent 1px);
  background-size: 24px 24px;
  opacity: 0.15;
}
```

### 4.2 Diagonal hatch lines (data-dense slides)

```css
.hatch-bg {
  background-image: repeating-linear-gradient(
    45deg,
    var(--muted) 0,
    var(--muted) 1px,
    transparent 1px,
    transparent 12px
  );
  opacity: 0.08;
}
```

### 4.3 Noise / grain overlay (cinematic feel)

```css
.grain {
  position: absolute; inset: 0;
  pointer-events: none;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='200' height='200'><filter id='n'><feTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='2'/></filter><rect width='100%' height='100%' filter='url(%23n)' opacity='0.5'/></svg>");
  opacity: 0.06;
  mix-blend-mode: overlay;
  z-index: 16;
}
```

### 4.4 Concentric rings (alternative to orbital ring)

For tech/cosmic topics, multiple thin concentric rings instead of one:
```html
<svg viewBox="0 0 600 600" style="position:absolute; inset:0;">
  <circle cx="300" cy="300" r="290" fill="none" stroke="var(--accent)" stroke-width="1" opacity="0.9"/>
  <circle cx="300" cy="300" r="230" fill="none" stroke="var(--accent)" stroke-width="0.8" opacity="0.5"/>
  <circle cx="300" cy="300" r="180" fill="none" stroke="var(--accent)" stroke-width="0.6" opacity="0.3"/>
</svg>
```

### 4.5 Dashed circle (alternate ring style)

```html
<circle cx="300" cy="300" r="290" fill="none" stroke="var(--accent)" stroke-width="1.5" stroke-dasharray="8 4"/>
```

Animate the `stroke-dashoffset` for a "marching ants" effect:
```javascript
gsap.to("#dashed-ring", { strokeDashoffset: -100, duration: 30, ease: "none", repeat: -1 });
```

### 4.6 Blob (organic background shape)

Soft asymmetric blob in `--accent` at low opacity, behind the hero. Great for editorial/luxury topics.

```html
<svg viewBox="0 0 400 400" style="position:absolute; left: 60%; top: 30%; width: 500px; opacity: 0.15; filter: blur(20px);">
  <path d="M40,180 Q40,80 130,60 Q220,40 290,90 Q360,140 340,230 Q320,320 220,340 Q120,360 70,290 Q20,220 40,180 Z" fill="var(--accent)"/>
</svg>
```

---

## 5. Slide-by-slide guidance — what icons/figures go where

| Slide | Recommended elements |
|---|---|
| **Hero** | Just the brand mark (paper plane). Maybe 2-3 scattered geometric accents (diamond, asterisk) at 50% opacity in negative space. |
| **Detail** | Pin icon next to the CTA pin-tag. A small calendar or compass icon next to the subtitle, in `--accent`. 1-2 geometric accents. |
| **Orbital Stats** | The `+` icons on the ring (already in chrome). Optional: small icon (calendar, users, ruler) inside each plus-circle when it pulses. |
| **Media Showcase** | Play icon overlay on the device (centered, 48×48, white outline). Camera icon in the device's corner as a "frame" indicator. |
| **Closing** | A large opening quote mark (`"`) in `--accent` if quote variant. An arrow-right icon inside the CTA button. |

---

## 6. Visual restraint — the 5-second rule

Stand back 1 meter from the screen and look at any slide for 5 seconds. You should see:
1. **One hero element** (the image or the title)
2. **One supporting layer** (text block, stats, device)
3. **The persistent chrome** (logo, nav, pin, bars)

That's it. If you see more than 3 layers, you're overdecoratiing — remove icons until the composition breathes again.

The decorative elements (geometric accents, patterns, blobs) are **garnish, not main course**. They live at the edges, at low opacity, in negative space. They should not compete with the hero.

---

## 7. Animation on icons

Icons can have their own subtle motion:

- **Pin tag**: gentle scale yoyo (already in chrome)
- **Arrow icons**: nudge right on hover (`gsap.to('.arrow', {x: 4, duration: 0.2, yoyo: true, repeat: -1, ease: 'sine.inOut'})`)
- **Plus icons on ring**: stagger pulse (already in chrome)
- **Geometric accents in negative space**: very slow drift (`gsap.to('.accent-shape', {y: -20, duration: 8, yoyo: true, repeat: -1, ease: 'sine.inOut', stagger: 0.5})`)
- **Quote mark on closing**: scale-in with `back.out(2)` ease on entry

Never animate icons aggressively. They should feel like they're *breathing*, not dancing.
