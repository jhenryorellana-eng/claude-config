# Free Asset Sources

Every source below is **free for commercial use** (verify per-asset license before final publish — most are CC0 / Pexels License / Pixabay License / Unsplash License, all of which allow commercial use with no attribution required).

The key concept: **you always want the direct file URL**, not the page where the asset lives. The LLM ingesting the spec needs an `https://...mp4` or `https://...webp` URL it can drop into a `<video src>` or `<img src>` tag.

---

## VIDEOS

### Pexels Videos (best overall)

- **Base URL**: `https://www.pexels.com/videos/`
- **License**: Pexels License — free for commercial use, no attribution required
- **How to search**: `web_search` for `site:pexels.com videos [topic]` or browse `https://www.pexels.com/search/videos/[topic]/`
- **Getting the direct URL**: from any video page, the download endpoint exposes URLs like:
  - `https://videos.pexels.com/video-files/[VIDEO-ID]/[VIDEO-ID]-hd_1920_1080_30fps.mp4`
  - `https://videos.pexels.com/video-files/[VIDEO-ID]/[VIDEO-ID]-uhd_2560_1440_30fps.mp4`
- **Resolution strategy**: prefer `hd_1920_1080` for hero videos (fast loading); use `uhd_2560_1440` only when truly needed
- **Tip**: `web_fetch` the page, look for `<video>` or `<source>` tags or the JSON-LD payload to extract the .mp4 URL.

### Coverr (curated, cinematic)

- **Base URL**: `https://coverr.co/`
- **License**: Coverr License — free, no attribution
- **Strengths**: hand-picked, cinematic, often better-tasted than Pexels for hero usage
- **Direct URL pattern**: `https://images.coverr.co/[VIDEO-SLUG].mp4?...`
- **Categories**: aerial, business, food, lifestyle, nature, technology, urban
- **Tip**: this is your first stop for "cinematic" briefs.

### Mixkit (broad library)

- **Base URL**: `https://mixkit.co/free-stock-video/`
- **License**: Mixkit License — free, no attribution, no AI-training reuse
- **Direct URL pattern**: `https://assets.mixkit.co/videos/[ID]/[ID]-[res].mp4`

### Pixabay Videos (deep catalog)

- **Base URL**: `https://pixabay.com/videos/`
- **License**: Pixabay Content License — free for commercial, no attribution
- **Direct URL pattern**: `https://cdn.pixabay.com/video/[YEAR]/[MM]/[DD]/[ID].mp4`

### Videvo Free (cinematic 4K)

- **Base URL**: `https://www.videvo.net/`
- **License**: mixed — filter by "Free" tag only. Free assets require no attribution.
- **Best for**: drone shots, slow motion, abstract

### Mazwai (curated cinematic shorts)

- **Base URL**: `https://mazwai.com/`
- **License**: free, attribution sometimes required — check each file
- **Best for**: dreamy, atmospheric, art-film aesthetic

---

## IMAGES (static)

### Unsplash (gold standard)

- **Base URL**: `https://unsplash.com/`
- **License**: Unsplash License — free for commercial, no attribution required
- **Direct URL pattern**: `https://images.unsplash.com/photo-[PHOTO-ID]?ixlib=rb-4.0.3&auto=format&fit=crop&w=2400&q=80`
- **Sizing parameters**:
  - `w=1280` (good default for cards)
  - `w=2400` (hero / large backgrounds)
  - `auto=format` (serves WebP/AVIF where supported)
  - `q=80` (good quality/size balance)
- **Tip**: pass `&fit=crop` and add `&h=` for an exact aspect ratio.

### Pexels Photos

- **Base URL**: `https://www.pexels.com/`
- **License**: same as Pexels Videos
- **Direct URL pattern**: `https://images.pexels.com/photos/[ID]/pexels-photo-[ID].jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1`

### Pixabay Photos

- **Base URL**: `https://pixabay.com/photos/`
- **License**: Pixabay Content License
- **Direct URL pattern**: `https://cdn.pixabay.com/photo/[YEAR]/[MM]/[DD]/[ID]_1280.jpg`

### Lummi (AI-generated, free)

- **Base URL**: `https://www.lummi.ai/`
- **License**: free for personal & commercial
- **Best for**: when you want stylized / abstract imagery that doesn't look stock
- **Caution**: AI-generated — note this if the brand explicitly forbids AI imagery

---

## ANIMATED GIFs

### Giphy

- **Base URL**: `https://giphy.com/`
- **License**: complicated — Giphy itself is free to embed but underlying GIFs may have studio copyrights. Only use Giphy GIFs from "Original" / artist-uploaded accounts.
- **Direct URL pattern**: `https://media.giphy.com/media/[ID]/giphy.gif` or `.webp`
- **Tip**: prefer `.webp` over `.gif` — smaller, faster.

### Tenor

- **Base URL**: `https://tenor.com/`
- **Same caveats as Giphy.**

**For most cinematic landings, prefer short looping MP4s over GIFs** — they're smaller and higher quality.

---

## 3D / INTERACTIVE EMBEDS

### Spline Community (premium 3D, free embed)

- **Base URL**: `https://spline.design/community`
- **License**: Spline Community License — free to use and remix
- **Embed pattern**:
  ```html
  <iframe src='https://my.spline.design/[SCENE-ID]/' frameborder='0' width='100%' height='100%'></iframe>
  ```
- **Or via React**:
  ```jsx
  import Spline from '@splinetool/react-spline';
  <Spline scene="https://prod.spline.design/[SCENE-ID]/scene.splinecode" />
  ```
- **Best for**: abstract floating objects, hero centerpieces, interactive 3D elements

### Sketchfab (3D model embeds)

- **Base URL**: `https://sketchfab.com/`
- **License**: filter by "Downloadable" + "Creative Commons" for safe commercial use
- **Embed pattern**:
  ```html
  <iframe src="https://sketchfab.com/models/[MODEL-ID]/embed?autostart=1&ui_controls=0&ui_infos=0" frameborder="0"></iframe>
  ```

### Three.js scenes (hand-coded)

- For full custom 3D, write inline Three.js code. Common premium-feeling examples:
  - Particle field reacting to mouse
  - Slow-rotating wireframe geometry
  - Animated gradient sphere
- Reference: `https://threejs.org/examples/`

---

## LOTTIE ANIMATIONS

### LottieFiles (free tier)

- **Base URL**: `https://lottiefiles.com/`
- **License**: per-asset (filter by "Free" — most are free under Lottie Simple License)
- **Direct URL pattern**: `https://assets-v2.lottiefiles.com/a/[ID]/animations/[FILE].json`
- **React usage**:
  ```jsx
  import Lottie from "lottie-react";
  <Lottie animationData={data} loop autoplay />
  ```
  Or for URL-based:
  ```jsx
  <DotLottieReact src="https://lottie.host/[ID].lottie" autoplay loop />
  ```
- **Best for**: small icons-with-motion, loading states, decorative accents (don't use as hero — they're not heavy enough)

### IconScout Lottie (free section)

- **Base URL**: `https://iconscout.com/free-lottie-animations`
- **License**: per-asset

---

## ICONS

### Lucide (preferred default)

- **Install**: `lucide-react` (or use the CDN script for raw HTML)
- **License**: ISC — fully free
- **Usage**: `import { ArrowRight, Check, Globe } from "lucide-react"`
- **Catalog**: 1500+ icons. Browse at `https://lucide.dev/icons/`
- **Why preferred**: consistent stroke width, great selection, used by all the reference prompts

### Heroicons

- **Base URL**: `https://heroicons.com/`
- **License**: MIT
- **Usage**: `import { ArrowRightIcon } from "@heroicons/react/24/outline"` or copy/paste SVG

### Phosphor Icons

- **Base URL**: `https://phosphoricons.com/`
- **License**: MIT
- **Strengths**: 6 weight variants per icon (thin, light, regular, bold, fill, duotone)

### Material Icons (when SVG paths are needed inline)

- **Base URL**: `https://fonts.google.com/icons`
- **License**: Apache 2.0
- **Usage**: copy the SVG path string directly into a `<path d="..."/>` (this is what the Aetheris/Space Voyage prompt does)

---

## FONTS

### Google Fonts (always free)

- **Base URL**: `https://fonts.google.com/`
- **License**: Open Font License or Apache — free everywhere
- **Embed pattern** (in `<head>`):
  ```html
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=Inter:wght@300;400;500;600&display=swap" rel="stylesheet">
  ```

**Display fonts that look premium** (use italic in headlines):
- Instrument Serif (the cinematic favorite)
- Cormorant Garamond
- Playfair Display
- Bodoni Moda
- DM Serif Display
- Fraunces (with optical sizing)

**Body fonts that pair well**:
- Inter (most reliable)
- Manrope
- Almarai
- Barlow
- Karla
- Plus Jakarta Sans

**Bold display fonts** (for portfolio / impact headlines):
- Kanit (the Jack 3D Creator pick)
- Anton
- Boldonse
- Bowlby One

### Fontsource (NPM-installable Google Fonts)

- For Vite + TS projects, prefer `@fontsource/inter` over `<link>` tags

---

## NOISE / TEXTURE / GRADIENTS

### Inline SVG noise (zero-bandwidth, infinite quality)

Use `feTurbulence`. See `design-vocabularies.md` for the two recipes (heavy and subtle).

### Hero Patterns (SVG patterns library)

- **Base URL**: `https://heropatterns.com/`
- **License**: CC BY 4.0 — free, requires attribution
- **Usage**: paste the SVG data URI as a `background-image`

### SVG Backgrounds (more variety)

- **Base URL**: `https://www.svgbackgrounds.com/`
- **License**: free with attribution

### Mesh Gradients (modern color blobs)

- **Generator**: `https://meshgradient.com/`
- **Approach**: generate, export as SVG, paste inline
- **License**: generated content is yours

---

## ASSET SEARCH WORKFLOW

For each visual element in the section plan, follow this exact sequence:

1. **Identify the asset role**: "Hero background video, slow cinematic, evoking [adjective]"
2. **Pick 2 sources from above** (e.g., Pexels Videos primary, Coverr backup)
3. **Search**: `web_search` for `site:pexels.com [keywords] video`
4. **Open the most promising result** with `web_fetch`
5. **Extract the direct file URL** from the page (look for `<video>`, `<source>`, JSON-LD, or download buttons)
6. **Verify** by fetching the URL itself — if it returns a video MIME type or proper file, it's good
7. **Record in spec** as a hardcoded constant

### Example flow (real)

**Brief**: cinematic hero for "Aether — a luxury private jet club"

**Asset needed**: hero video, slow aerial shot or interior of a private jet, ~10-30 seconds, looping-friendly

**Search 1**: `web_search` `site:pexels.com private jet aerial slow motion video`
**Result**: page like `https://www.pexels.com/video/aerial-view-of-airplane-2330708/`
**Fetch**: `web_fetch` that URL, look for the direct mp4
**Direct URL found**: `https://videos.pexels.com/video-files/2330708/2330708-hd_1920_1080_30fps.mp4`
**Record in spec**:
```
Background video URL: https://videos.pexels.com/video-files/2330708/2330708-hd_1920_1080_30fps.mp4
```

---

## LICENSING QUICK-REFERENCE

| Source | Commercial OK? | Attribution required? | AI-training restrictions? |
|--------|---------------|----------------------|--------------------------|
| Pexels | ✅ | No | No |
| Coverr | ✅ | No | No |
| Mixkit | ✅ | No | Yes (no AI training reuse) |
| Pixabay | ✅ | No | No |
| Unsplash | ✅ | No | No |
| Lummi | ✅ | No | Note: AI-generated |
| Spline Community | ✅ | Per-scene | Per-scene |
| Sketchfab CC | Filter required | Often required (BY) | No |
| LottieFiles | Free tier OK | Per-asset | No |
| Lucide | ✅ | No | No |
| Heroicons | ✅ | No | No |
| Google Fonts | ✅ | No | No |

When in doubt, default to Pexels + Unsplash + Lucide + Google Fonts — the safest combo.

---

## ANTI-PATTERNS

- **Don't hotlink from random websites.** Their URLs change or block hotlinking.
- **Don't use motionsites.ai's CloudFront URLs.** Even though they work, they're someone else's CDN and could be revoked at any time. Plus, the user wanted free open-web replacements.
- **Don't use Shutterstock / Getty / Adobe Stock previews.** They have watermarks and are not licensed for use.
- **Don't use Google Image search results directly.** Most are copyrighted; the URLs are unstable.
- **Don't use a "free trial" CDN service.** It will lapse.
- **Don't include an asset URL you haven't verified actually loads.**

The only acceptable URLs in the final spec are:
1. Verified direct file URLs from the sources above
2. Inline SVG / CSS
3. CDN-hosted libraries from official sources (Google Fonts, unpkg, cdnjs for code)
