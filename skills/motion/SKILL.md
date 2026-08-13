---
name: motion
description: >
  Construye landings y hero sections cinemáticos con la metodología motionsites:
  research del nicho, dirección creativa, curaduría de assets libres con URL
  directa verificada, spec de transcripción técnica total (cada texto literal,
  cada delay numérico, cada URL hardcodeada) y build final. Usa cuando se pida
  "landing cinemática", "hero con video de fondo", "motion-rich", "sticky
  stacking cards", "scroll-driven", "marquee scroll", "liquid glass",
  "glassmorphism", "portfolio que se vea caro", o al pegar un spec estilo
  motionsites para adaptar. NO es micro-interacciones de un producto existente
  (/impeccable:animate) ni elección de paleta (design-system).
---

# Motionsites Architect

A skill for building cinematic, motion-rich web pages following the methodology pioneered by **motionsites.ai** — but adapted to use **only free, openly-available assets** found via web research instead of a paid CDN library.

## Cuando corres dentro del pipeline UI

Si esta skill se invoca dentro del pipeline UI del equipo, la paleta la valida `ui-designer` antes de cerrar la dirección creativa (Phase 2).

El build lo lidera `frontend-builder`: si él está a cargo, entrégale el spec de Phase 4 y no ejecutes Phase 5.

Lee el `CLAUDE.md` del directorio de trabajo para el contexto específico del proyecto.

---

## What this skill does

It takes a user's brief (even a vague one) and produces, in order:

1. **Deep topic research** — to understand the brand, audience, niche, visual codes
2. **Creative direction** — mood, palette, typography, sections, motion vocabulary
3. **Asset curation** — exact URLs to free videos, images, GIFs, 3D, Lottie animations from open sources (Pexels, Coverr, Unsplash, LottieFiles, Sketchfab, etc.)
4. **A motionsites-style technical spec** — the kind of hyperdetailed system prompt that, when fed to any code-generating LLM (Claude Artifacts, Gemini AI Studio, Lovable, v0.dev, Bolt, Cursor), reproduces the page faithfully
5. **Final build** — the actual React/HTML code, rendered as a working preview

## The core insight

The "magic" of motionsites.ai pages is **not** that the LLM is creative. It's that someone wrote a **complete technical transcription** of a pre-designed page — every pixel, every delay, every URL hardcoded. The LLM only acts as a code assembler.

This skill applies that same principle but **replaces motionsites.ai's paid CDN with free, openly-licensed assets** that any user can reuse legally.

## Workflow

Walk through these five phases sequentially. Don't skip any. At the end of each phase, summarize for the user before moving on — they can redirect at any point.

---

### PHASE 1 — Discovery & Research

**Goal**: understand the project deeply enough to make every creative decision afterward grounded in real context, not generic AI-template thinking.

**Step 1a — Gather the brief**

Ask the user up to 3 questions max (use `AskUserQuestion` — it's far easier than typing answers). Cover:

1. **The topic/brand** — what is this page for? (e.g., a private jet service, a film studio, a portfolio for a 3D artist, a fintech SaaS, a wellness brand)
2. **The mood / aesthetic preference** — one of: dark cinematic, warm cream cinematic, futuristic glass, minimal brutalist, organic earthy, neon retro, editorial print, or "surprise me"
3. **The scope** — single hero section, full landing (3-5 sections), or portfolio-style (5+ sections with case studies)

If the user already gave a brief, skip the interview and just confirm your reading of it.

**Step 1b — Research the topic on the web**

Use `WebSearch` to ground the page in the real domain. Search at least 3 angles:

- The topic itself — to capture accurate terminology, key offerings, audience pains, common claims ("private jet service offerings 2026", "film studio portfolio sections", etc.)
- Visual references — search `site:awwwards.com [topic]`, `site:godly.website [topic]`, `site:landings.dev [topic]`, or generic queries like "best [topic] landing pages 2026"
- Typography & design trends in that niche — luxury verticals prefer serif headlines, dev tools prefer mono accents, wellness uses warm palettes, etc.

Read 2-4 of the most relevant search results in full with `WebFetch` to capture nuance. Do NOT just read snippets.

**Step 1c — Summarize findings to the user**

Give a brief paragraph: "Based on research, this niche has these visual codes: [X]. The audience expects [Y]. Competitors emphasize [Z]. I'll lean into [angle] to differentiate." Get a thumbs up before proceeding.

---

### PHASE 2 — Creative Direction

**Goal**: lock every creative decision before writing a single line of spec, so Phase 4 is pure transcription.

Decide and present to the user:

**1. Mood board (in words)** — 3-5 sentences describing the visual feel ("Imagine: matte-black inset cards floating over a slow-motion clip of clouds at golden hour. Text is a thin warm-cream serif with subtle character-by-character reveal on scroll. Liquid glass chrome floats above the video. No emojis, no purple — feels like a Rolex ad from 2030.")

**2. Color system** — exact hex codes for:
- Background (usually `#000000`, `#0C0C0C`, `#070612`, `#101010`, or a warm dark)
- Primary text (cream, white, or warm white — never pure `#FFFFFF` for cinematic feel; prefer `#DEDBC8`, `#E1E0CC`, `#D7E2EA`)
- Secondary text (gray-400 / gray-500 / `#6F6F6F`)
- Accent (only if there's a CTA gradient — usually subtle)
- Card surfaces if any (`#101010`, `#212121`, `#1a1a1a`)

**3. Typography pairing** — pick from Google Fonts:

| Mood | Display | Body |
|------|---------|------|
| Cinematic luxury | Instrument Serif (italic) | Inter / Almarai / Barlow |
| Editorial / artist | Kanit / Anton | Inter / Manrope |
| Futuristic / SaaS | Inter (bold) | Inter |
| Warm / wellness | Cormorant Garamond | Lora / Karla |
| Brutalist | Space Grotesk | JetBrains Mono |
| Bold portfolio | Boldonse / Bowlby One | Inter |

Always italicize Instrument Serif when used for display — it's the secret sauce.

Para tipografía fuera de estos moods consulta la skill `design-system`; su blacklist manda.

**4. Section structure** — propose 1-6 sections. Common patterns from the references:

- `Hero` (always)
- `Marquee / logo strip / preview scroll` (optional)
- `About / Manifesto` (with character-by-character reveal)
- `Services / Capabilities` (3-4 card grid, often with glass)
- `Projects / Work showcase` (sticky stacking cards)
- `Features` (mixed grid: video card + content cards)
- `Pricing` / `FAQ` / `Footer with CTA`

**5. Motion vocabulary** — pick which effects from the catalog (see `references/design-vocabularies.md`). Common motion-rich stacks:

- Liquid glass chrome + FadingVideo + BlurText pull-up + entrance fade
- Marquee scroll + sticky stacking + character reveal + magnetic hover
- Glass nav + gradient text headline + scroll-linked opacity + word pull-up

**6. Reusable components needed** — list them so Phase 4 knows what to define:

- `FadingVideo` (custom rAF crossfade loop)
- `BlurText` / `WordsPullUp` (entrance text animation)
- `AnimatedText` (scroll-linked character opacity)
- `Magnet` (mouse-following magnetic hover)
- `FadeIn` (whileInView wrapper)
- `StackingCards` (sticky + useTransform scale)
- `Marquee` (scroll-driven horizontal pan)

**7. Target tool / stack** — ask the user OR infer:

- **CDN-only React + Babel + Tailwind** → for Claude Artifacts, Gemini AI Studio, ChatGPT Canvas, or any "paste-and-preview" tool. Single HTML file output.
- **Vite + React + TypeScript + Tailwind** → for Lovable, v0.dev, Bolt.new, Cursor. Multi-file project output.

Default to CDN-only unless the user mentions Lovable/v0/Bolt/Cursor or asks for a "real project".

---

### PHASE 3 — Asset Curation (free assets only)

**Goal**: replace motionsites.ai's paid CDN with verified free assets the user can actually use.

For every visual element in the section plan, source it from the free libraries catalogued in `references/asset-sources.md`. Read that file before starting Phase 3 — it has the search patterns, URL formats, and license notes for each source.

**Universal rule**: every asset URL must be a **direct file URL** (ends in `.mp4`, `.webp`, `.jpg`, `.gif`, `.json` for Lottie, or is an embeddable iframe URL for 3D). Never reference a "page where the asset lives" — the LLM can't extract from that.

**Search strategy per asset type:**

| Asset type | Primary source | Backup |
|------------|---------------|--------|
| Hero video (cinematic, looping) | Pexels Videos, Coverr | Mixkit, Pixabay Videos |
| Decorative images | Unsplash, Pexels | Pixabay |
| Animated GIFs | Giphy (carefully — license check) | Tenor |
| 3D models / scenes | Spline Community embeds | Sketchfab iframe embeds |
| Lottie animations | LottieFiles (free tier) | IconScout free |
| Icons | Lucide React (built-in) | Heroicons, Phosphor |
| Noise / texture | Inline SVG with `feTurbulence` filter | Hero Patterns |
| Fonts | Google Fonts | Fontsource (NPM) |

**Validation step (critical)**: after picking a URL, fetch it with `WebFetch` (or a HEAD-like check). If the URL returns 404 or is not a direct file URL, search again. Never include unverified URLs in the spec — that's the #1 reason these pages break.

**Example flow for the hero video:**
1. The mood is "cinematic luxury for private jet brand"
2. Search Pexels: `WebSearch` for `site:pexels.com private jet aerial video free download`
3. Find a result like `https://www.pexels.com/video/aerial-view-of-airplane-2330708/`
4. Use `WebFetch` to load the page and extract the direct download URL (Pexels exposes a `https://videos.pexels.com/video-files/2330708/2330708-hd_1920_1080_30fps.mp4` pattern)
5. Verify the .mp4 URL loads
6. Note it in the spec

Repeat for every section's background, every decorative image, every Lottie, every 3D embed.

---

### PHASE 4 — Spec Generation

**Goal**: write a hyperdetailed spec prompt — the kind from the motionsites.ai library — that, fed to any code-generating LLM, reproduces the page faithfully.

Read `references/spec-template.md` for the exact structure. The template has fillable blocks for:

- Intro line (page purpose + stack)
- Fonts block (Google Fonts URL + CSS family declarations)
- Color system (exact hex)
- Custom CSS utilities (paste-verbatim CSS for glass, noise, gradients)
- Per-section breakdown:
  - Layout (Tailwind classes, exact)
  - Background asset (direct URL hardcoded)
  - Navbar / content blocks (every text in quotes)
  - Animation parameters (every delay/duration/easing as numbers)
- Reusable components (full pseudocode for each, with named props)
- Responsive breakpoints
- Tech stack pinned (exact versions)

**Critical writing rules** for the spec:

1. **Quote every text literally** — no "headline about innovation"; instead `"We Build Tomorrow Today"`.
2. **Hardcode every URL** — no "[insert hero video]"; the actual `.mp4` URL.
3. **Numbers, not adjectives** — no "slow fade"; instead `duration: 1.2s, ease: [0.16, 1, 0.3, 1]`.
4. **CSS pasted verbatim inside backtick blocks** — no "make it glass"; paste the full `.liquid-glass { background: ...; backdrop-filter: ...; }`.
5. **SVG paths included as strings** when needed for custom icons (Lucide React covers most cases).
6. **Tailwind classes spelled out completely** — `text-6xl md:text-7xl lg:text-[5.5rem]` not "responsive large text".
7. **Component contracts** — each reusable component shows props, behavior, animation params.

After writing the spec, save it in the current project directory as `<project-name>-spec.md` so the user can copy it elsewhere if they want.

Show it to the user with a brief framing: "Here's the spec. If you want to feed this to Lovable/v0/Gemini yourself, copy that file. Otherwise I'll build it now."

---

### PHASE 5 — Build & Render

**Goal**: execute the spec — produce the actual code and deliver a working preview.

**For CDN-only target (default):**

1. Create a single `index.html` in the current project directory containing:
   - All Google Fonts links in `<head>`
   - All custom CSS in a `<style>` block
   - All React components as `<script type="text/babel">` blocks
   - The mount: `ReactDOM.createRoot(document.getElementById('root')).render(<App />)`
2. The HTML must be self-contained — no build step needed.
3. Test mentally: read through the file; every URL, every text, every animation parameter from the spec is present.
4. Escribe los archivos y reporta las rutas.

**For Vite + TypeScript target:**

1. Create the project layout in `<project>/` inside the current project directory:
   ```
   src/
     components/
       Hero.tsx
       About.tsx
       ...
       shared/
         FadingVideo.tsx
         BlurText.tsx
         ...
     App.tsx
     main.tsx
     index.css
   index.html
   package.json
   tailwind.config.js
   vite.config.ts
   tsconfig.json
   ```
2. Provide a README with `npm install && npm run dev` to launch.
3. Escribe los archivos y reporta las rutas (al menos las de los archivos más importantes).

**Either way — render an Artifact preview** if the chat interface supports it (claude.ai does). This gives the user an immediate live view of the page.

**Quality check before presenting:**

- [ ] All asset URLs verified as direct file URLs
- [ ] All text matches the spec exactly
- [ ] All animations use Framer Motion (or vanilla if specified) — never plain CSS transitions for the "wow" effects
- [ ] Liquid glass + noise CSS pasted verbatim, not paraphrased
- [ ] Responsive breakpoints applied at sm/md/lg/xl
- [ ] No purple, no rainbow gradients (unless explicitly requested) — cinematic palettes only
- [ ] No emojis in the page unless the spec calls for them

---

## When asset sources fail

If a hunted-for asset (e.g., a very specific video like "drone shot of Sahara at dusk") doesn't exist on free sources:

1. **Pivot the mood, not the page** — search for a related concept that does exist. "Drone shot of dunes" → "slow camera over sand texture" is often available.
2. **Use a Spline community embed** as a fallback for any "abstract 3D shape" need — they're free, embeddable, and look premium.
3. **Generate inline SVG** for noise, grain, gradients — `feTurbulence` covers a lot.
4. **As a last resort**, fall back to a tasteful animated gradient (CSS `@keyframes` on `background-position`) — never to a paid CDN URL.

Never include an unverified URL in the final spec. Better to swap the asset than ship a broken page.

---

## When the user just pastes a motionsites-style spec

If the user pastes one of the 6 reference prompts (or a similar one) and says "build this" or "adapt this for [topic]":

1. **Skip Phase 1 research** — they already know what they want.
2. **Identify the assets**: are the URLs CloudFront-hosted (motionsites.ai paid library)? If yes, the user probably needs free replacements. Ask: "Want me to swap the videos/images for free open-web equivalents that match the mood?"
3. **If yes** → run Phase 3 (asset curation) with the existing spec's mood as the target.
4. **Generate a new spec** with the replaced URLs (Phase 4 lite).
5. **Build** (Phase 5).

---

## Quick examples of how to trigger

- *"Make me a landing page for my friend who's a 3D artist"* → full 5-phase flow
- *"Build a hero section for a private jet company"* → focused single-section flow
- *"Here's a prompt from motionsites.ai, adapt it for a fintech startup"* → spec-conversion flow
- *"I want a portfolio that looks like Aetheris Voyage"* → use the reference patterns
- *"Design a cinematic landing for a meditation app"* → wellness aesthetic flow

---

## Reference files

Always read these before working:

- **`references/design-vocabularies.md`** — catalog of every animation/effect/component used in the reference prompts, with code snippets. Read in Phase 2 (when picking motion vocabulary) and Phase 4 (when writing spec).
- **`references/asset-sources.md`** — every free asset library with search patterns and direct-URL formats. Read at the start of Phase 3.
- **`references/spec-template.md`** — the exact fillable template for the spec prompt. Read at the start of Phase 4.
- **`references/reference-prompts.md`** — notes on the 6 source prompts that inspired this skill (Aetheris/Space Voyage, Jack 3D Creator, Prisma, Asme, SkyElite, Aethera, VEX). Read whenever you need a concrete pattern to mirror.

---

## Pitfalls to avoid

1. **Don't be vague in the spec.** "A nice fade-in" is useless. `duration: 0.8, ease: [0.16, 1, 0.3, 1], delay: 0.5` is what works.
2. **Don't skip research.** A landing page for a deep-sea exploration company should not look like a generic SaaS hero. Phase 1 grounds the visuals.
3. **Don't use stock-cliché videos.** "Generic blue waves" or "team meeting handshake" are off-brand for almost everything. Pick assets with intent.
4. **Don't paraphrase CSS.** Paste it verbatim. The LLM will hallucinate `backdrop-filter` values otherwise.
5. **Don't use emojis as decoration.** Use Lucide icons instead.
6. **Don't ship purple gradients** unless the brand specifically calls for them. They're the visual hallmark of "AI-generated slop."
7. **Don't forget mobile.** Every Tailwind class needs an sm/md/lg variant or a `clamp()` fluid value.
