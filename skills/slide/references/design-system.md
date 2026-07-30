# Design System Reference

The visual language for Asombro presentations. Read this before generating any HTML.

---

## 1. Palette construction

A palette has **exactly 4 roles**:

| Role | Purpose | Examples |
|---|---|---|
| `--bg` | Dominant background, fills 60–70% of every slide | Navy, ink-black, lapis blue, jungle green |
| `--accent` | The "energy" color. Used for the diagonal flag bars, the orbital ring, the active nav dot, the CTA button, the location pin | Coral, vermilion, gold, neon cyan |
| `--text` | Body text, headlines, the brand mark | Usually white, cream, bone, washi paper |
| `--muted` | Secondary text, the inactive nav dots, soft outlines | A 40–60% opacity of `--text` |

**Rules:**
- `--bg` and `--text` must have at least 7:1 contrast (WCAG AAA).
- `--accent` must pop against `--bg` — desaturated accents look weak.
- Never use more than 4 colors. No gradient palettes, no rainbow accents.

### Topic → palette table (expanded)

| Topic | `--bg` | `--accent` | `--text` | `--muted` |
|---|---|---|---|---|
| Paris / France | `#1a2332` | `#ef4a3c` | `#f5f5f0` | `#7c8794` |
| Tokyo / Japan | `#0e0e0e` | `#c8102e` | `#f4ede1` | `#7a7068` |
| Kyoto / temples | `#2b1d14` | `#d96c3a` | `#f0e4d2` | `#8a7560` |
| New York / urban | `#111111` | `#ffb300` | `#f5f5f5` | `#888888` |
| London / royal | `#1c1c2e` | `#b8324a` | `#e8e4d8` | `#7d7a85` |
| Egypt / desert | `#1d3557` | `#e6b85c` | `#f1e4c3` | `#8a8270` |
| Iceland / arctic | `#0a1828` | `#88c0d0` | `#eceff4` | `#6c7a89` |
| Brazil / tropical | `#0b3d2e` | `#ffd400` | `#f7f2e8` | `#7a8a7a` |
| Mexico / vibrant | `#2b1638` | `#ff4d6d` | `#f8e7c1` | `#8a6f7a` |
| Greece / coastal | `#0f3d5c` | `#f5f5f0` | `#fef9e7` | `#6c8a9c` |
| Tech / SaaS | `#0d1117` | `#7dd3fc` | `#e6edf3` | `#6e7681` |
| Fintech / banking | `#0a1d3a` | `#22c55e` | `#f5f7fa` | `#6b7280` |
| Health / clinical | `#0f2a3f` | `#06b6d4` | `#f0f7fb` | `#6a8a9c` |
| Luxury / fashion | `#1a1a1a` | `#c9a96e` | `#f4f1eb` | `#807870` |
| Sports / athletic | `#0d0d0d` | `#ff4500` | `#ffffff` | `#7c7c7c` |
| Food / culinary | `#2b1810` | `#e85a3c` | `#f5e8d0` | `#8a7060` |
| Music / nightlife | `#0a0014` | `#ff00aa` | `#f0e8ff` | `#6a5a7a` |
| Space / cosmic | `#050816` | `#a78bfa` | `#e9e4ff` | `#5a5a7a` |
| Nature / forest | `#0d1f0d` | `#84cc16` | `#f0f5ec` | `#6a7a6a` |
| Generic fallback | `#1f1f23` | `#ff5a4c` | `#f4f1eb` | `#7a7670` |

If the topic isn't in this table, **derive** a palette: think of the most iconic color associated with the place/concept/brand, make that the accent, pair it with a deep complementary background.

---

## 2. Typography pairings

Always pair a **distinctive display font** with a **clean body font**. Never use the same font for both. Always pull from Google Fonts via `<link>` in the `<head>`.

| Topic family | Display font | Body font |
|---|---|---|
| Travel / editorial | **Fraunces** (700, soft variant) | **Manrope** (400, 500) |
| Modern tech | **Space Grotesk** (700) — *use sparingly, common* | **DM Sans** (400) |
| Luxury / premium | **Playfair Display** (900) | **Cormorant Garamond** (400) |
| Bold / impact | **Bebas Neue** (regular) | **Inter** (400) — body only |
| Editorial magazine | **PP Editorial New** *(use Crimson Pro as free alternative, 700)* | **Söhne** *(use Manrope as free alternative)* |
| Asian/Japanese | **Shippori Mincho** (700) | **Noto Sans JP** (400) |
| Brutalist / raw | **Archivo Black** | **Archivo** (400) |
| Soft / friendly | **Fraunces** (600, soft) | **Nunito** (400) |
| Cinematic / dramatic | **Bodoni Moda** (900) | **Inter** (400) |
| Geometric / clean | **Syne** (800) | **Outfit** (400) |
| Retro / 70s | **Abril Fatface** | **Karla** (400) |
| Default rotation | **Fraunces** (700) | **Manrope** (500) |

**How to import:**
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:opsz,wght@9..144,600;9..144,700;9..144,900&family=Manrope:wght@400;500;700&display=swap" rel="stylesheet">
```

**Size scale (1280×720 canvas):**
- Hero title: 160–200px, font-weight 700–900, letter-spacing 0 to -2px
- Section title: 72–96px
- Big stat number: 64–88px
- Body: 18–22px, line-height 1.5
- Micro label: 12–14px, letter-spacing 1–2px, uppercase

---

## 3. The persistent UI chrome

Every slide carries these 4 elements in the same positions. They give the deck identity and provide anchors for micro-interactions.

### 3.1 Brand mark (top-left)

Paper-plane SVG icon + horizontal bar. Both in `--text` color.

```html
<div class="brand">
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
    <path d="M22 2L11 13M22 2l-7 20-4-9-9-4 20-7z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
  </svg>
  <div class="brand-bar"></div>
</div>
```

```css
.brand {
  position: absolute; top: 32px; left: 40px;
  display: flex; align-items: center; gap: 12px;
  color: var(--text); z-index: 20;
}
.brand-bar { width: 36px; height: 2px; background: var(--text); border-radius: 1px; }
```

### 3.2 Nav dots (left-center)

Vertical column of 5 dots. The active one is larger and filled with `--text`; the others are smaller and `--muted`.

```html
<div class="nav-dots">
  <span class="dot"></span>
  <span class="dot"></span>
  <span class="dot active"></span>
  <span class="dot"></span>
  <span class="dot"></span>
</div>
```

```css
.nav-dots {
  position: absolute; left: 40px; top: 50%; transform: translateY(-50%);
  display: flex; flex-direction: column; gap: 16px; z-index: 20;
}
.dot { width: 6px; height: 6px; border-radius: 50%; background: var(--muted); transition: all .4s ease; }
.dot.active { width: 12px; height: 12px; background: var(--text); }
```

The active dot **moves** as slides advance (use GSAP to add/remove the `.active` class on each scene).

### 3.3 Location pin tag (bottom-left)

Pin icon + topic-specific label (e.g. "Encontrar Agenda", "Explorar Tour", "Reservar Visita").

```html
<div class="pin-tag">
  <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
    <path d="M12 22s8-7 8-13a8 8 0 1 0-16 0c0 6 8 13 8 13z M12 11a2 2 0 1 0 0-4 2 2 0 0 0 0 4z" fill="currentColor"/>
  </svg>
  <span>Encontrar Agenda</span>
</div>
```

Color: `--accent`. The pin itself pulses subtly (see micro-interaction catalog).

### 3.4 Flag bars (right side, diagonal)

Two diagonal bars in the lower-right: one in `--text` (the "white" stripe) and one in `--accent` (the "color" stripe), rotated ~25°. These echo a national-flag motif. **They are not always literally a country flag** — for non-travel topics, treat them as pure graphic decoration in palette colors.

```html
<div class="flag-bars">
  <div class="bar bar-light"></div>
  <div class="bar bar-accent"></div>
</div>
```

```css
.flag-bars {
  position: absolute; right: -80px; top: -100px; bottom: -100px;
  width: 400px; pointer-events: none; z-index: 1; overflow: visible;
}
.bar {
  position: absolute; width: 80px; height: 1400px;
  transform: rotate(25deg); transform-origin: top center;
}
.bar-light { background: var(--text); right: 180px; opacity: .95; }
.bar-accent { background: var(--accent); right: 60px; }
```

The bars **slide and shift** between slides — that's a signature morph move.

---

## 4. Spatial composition rules

- **Canvas**: 1280×720 (16:9). Build for this exact size, then add a CSS transform scale wrapper for responsive.
- **Safe margins**: 40px from any edge for content; chrome elements can hug the edges.
- **Asymmetry over symmetry**: never center everything. Hero subjects sit at 30% or 70% of the horizontal axis, not 50%.
- **Diagonal flow**: the flag bars create a 25° diagonal that other elements should respect — orbital rings, image clip-paths, and stat positions should feel like they belong to that diagonal.
- **Generous negative space** on the hero slide. Density only on stat slides.

---

## 5. The orbital ring (signature element)

On the stats slide, the hero subject is enclosed by a thin coral ring (`--accent`, 1px or 2px stroke) with 3–4 plus-icons positioned around its circumference. Each plus is the anchor for a stat callout.

```html
<svg class="orbital-ring" viewBox="0 0 600 600">
  <circle cx="300" cy="300" r="280" fill="none" stroke="var(--accent)" stroke-width="2" />
</svg>
```

The plus-icons are small filled circles (16px diameter) with a `+` inside, also in `--accent`. They pulse (see micro-interactions). The ring itself slowly rotates (60s per revolution) once it appears.

---

## 6. Buttons & CTAs

Single primary button style — a pill in `--accent`, white text. Optional hover micro-interaction: slight scale + shift.

```css
.btn {
  display: inline-flex; align-items: center; padding: 10px 28px;
  background: var(--accent); color: var(--text);
  border-radius: 999px; font-weight: 600; font-size: 16px;
  cursor: pointer; transition: transform .2s ease;
}
.btn:hover { transform: translateY(-2px) scale(1.03); }
```

Label is usually one word: "Más", "Explorar", "Reservar", "Comenzar".
