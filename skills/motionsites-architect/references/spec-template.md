# Spec Template

This is the fillable structure for the technical spec written in Phase 4. The output of Phase 4 should look EXACTLY like one of the 6 reference prompts — pixel-perfect, with every URL, text, color, and animation parameter explicit.

Copy this template, replace every `[BRACKETED]` placeholder, and delete every section that doesn't apply.

---

## Template — CDN-only React variant

(Use this when targeting Claude Artifacts, Gemini AI Studio, ChatGPT Canvas. Output is a single `index.html`.)

````
Build a [single-page landing site / hero section / portfolio page] for "[BRAND-NAME]" — a [one-line description of what the brand does and who it's for]. The aesthetic is [mood description, 2-3 sentences].

# TECH STACK (pinned, CDN-only)

<script src="https://cdn.tailwindcss.com"></script>
<script src="https://unpkg.com/react@18.3.1/umd/react.development.js"></script>
<script src="https://unpkg.com/react-dom@18.3.1/umd/react-dom.development.js"></script>
<script src="https://unpkg.com/@babel/standalone@7.29.0/babel.min.js"></script>
<script src="https://unpkg.com/framer-motion@11.11.17/dist/framer-motion.js"></script>
<script>window.Motion = window.FramerMotion;</script>

The page is a React app mounted on #root. All components are <script type="text/babel"> blocks exporting via window.X = X.
Body background: [#000000 / #0C0C0C / etc.]

# FONTS

Google Fonts (paste this <link> in <head>):
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=[DISPLAY-FONT]:ital@0;1&family=[BODY-FONT]:wght@300;400;500;600&display=swap" rel="stylesheet">

Tailwind config (in <script> before mount):
tailwind.config = {
  theme: {
    extend: {
      fontFamily: {
        heading: ['"[DISPLAY-FONT]"', 'serif'],
        body: ['"[BODY-FONT]"', 'sans-serif'],
      },
      borderRadius: {
        DEFAULT: "9999px",  // optional: bare `rounded` becomes pill
      },
    },
  },
};

# COLOR SYSTEM

Background: [#000000]
Primary text: [#E1E0CC]
Secondary text: [text-gray-400 / text-gray-500 / #6F6F6F]
Card surfaces: [#101010 / #212121]
Accent (used only on [element]): [#FFFFFF or a single accent]

# CUSTOM CSS (paste verbatim in <style> block)

[Paste the .liquid-glass + .liquid-glass-strong CSS from design-vocabularies.md]
[Paste the .noise-overlay and/or .bg-noise CSS]
[Paste any other custom utilities — .hero-heading gradient, etc.]

# REUSABLE COMPONENTS (defined once, used across sections)

## FadingVideo
[Paste the FadingVideo component code from design-vocabularies.md, with FADE_MS=500 and FADE_OUT_LEAD=0.55]

## BlurText (or WordsPullUp, depending on style)
[Paste the chosen text-entrance component code]

## AnimatedText (only if used in About-style sections)
[Paste the scroll-linked character opacity component code]

## FadeIn
[Paste the FadeIn wrapper code]

## [Any other components — Magnet, StickyCard, MarqueeScroll]

# SECTION 1 — [HERO / WHATEVER]

**Layout**: [h-screen / min-h-screen / etc.], [flex column / grid], [overflowX clip / overflow hidden]
**Padding**: [p-4 md:p-6 etc.]

**Background**:
- Video URL: [DIRECT-VIDEO-URL-FROM-PEXELS-OR-COVERR]
- Component: FadingVideo (or simple <video autoPlay loop muted playsInline>)
- Classes: absolute inset-0 w-full h-full object-cover z-0
- Overlay: [.noise-overlay opacity-[0.7] mix-blend-overlay / gradient-overlay / none]

**Navbar** (fixed top, z-50):
- Container: [classes]
- Left: [logo: text "[BRAND]" with class [size + font + color]]
- Center (hidden mobile): [5 nav links: "[Link 1]", "[Link 2]", "[Link 3]", "[Link 4]", "[Link 5]" — class [size + tracking + color], gap [gap-N]]
- Right: [CTA button "[BUTTON-LABEL]" with class [bg + color + radius + padding + icon ArrowUpRight]]

**Hero content** (z-10):
- Layout: [grid 12 col / flex col centered / etc.]
- Padding: [px-N / pt-N]

**Element 1 — Tagline / Badge** (delay 0.2s):
- Component: liquid-glass rounded-full pill OR plain text
- Text: "[EXACT-TAGLINE-TEXT]"
- Classes: [exact Tailwind classes]
- Animation: motion.div initial={opacity:0, y:20}, animate at delay 0.2s, ease easeOut

**Element 2 — Headline** (delay 0.4s):
- Component: BlurText (or WordsPullUp / AnimatedHeading)
- Text: "[EXACT-HEADLINE-TEXT — line break with <br/> if needed]"
- Classes: text-6xl md:text-7xl lg:text-[5.5rem] font-heading italic text-white leading-[0.85] tracking-[-4px] max-w-3xl

**Element 3 — Subheading** (delay 0.6s):
- Tag: <p>
- Text: "[EXACT-SUB-TEXT]"
- Classes: mt-4 text-base md:text-lg text-white/70 max-w-2xl font-body font-light leading-relaxed
- Animation: motion.p with delay 0.6s

**Element 4 — CTAs** (delay 0.8s):
- Layout: flex gap-4 mt-8
- Primary: [.liquid-glass-strong rounded-full px-5 py-2.5 text-white "[CTA-TEXT]" + Lucide ArrowUpRight icon]
- Secondary: [bare text link "[SECONDARY-TEXT]" + Lucide Play icon]

**Element 5 — Stats / Partners / Other accents** (delay 1.0s):
[Describe exactly]

---

# SECTION 2 — [ABOUT / SERVICES / CAPABILITIES / etc.]

[Same structure as Section 1: Layout, Background, Content elements with exact text and animation params]

[Include any decorative elements with their exact image URLs from Unsplash/Pexels and their exact positions and FadeIn delays]

---

# SECTION 3 — [PROJECTS / FEATURES / etc.]

[Same structure]

[If sticky-stacking cards: list each card with number, name, description, image URLs (verified Unsplash/Pexels), and the targetScale formula targetScale = 1 - (totalCards - 1 - index) * 0.03]

---

# RESPONSIVE BREAKPOINTS

All Tailwind defaults: sm:640px md:768px lg:1024px xl:1280px
Heavy use of clamp() for fluid type
Mobile-first: stack vertically; tablet: 2-col where appropriate; desktop: full grid

# NOTES

- All text colors are [warm cream / pure white / etc.] — no pure #FFFFFF unless specified
- No purple, no rainbow gradients (unless brand calls for it)
- No emojis
- All videos: autoplay muted playsInline (required for browser autoplay policies)
- All Framer Motion entrance animations use ease [0.16, 1, 0.3, 1] for hero, [0.22, 1, 0.36, 1] for cards
- Liquid glass surfaces: max 2 per section
````

---

## Template — Vite + TypeScript variant

(Use this when targeting Lovable / v0.dev / Bolt / Cursor. Output is a multi-file project.)

````
Build a React + Vite + TypeScript + Tailwind CSS landing page for "[BRAND-NAME]". The page has [N] sections: [SECTION-NAMES]. Use framer-motion for animations and lucide-react for icons. The design is [mood description].

# DEPENDENCIES

- react ^18.3.1
- react-dom ^18.3.1
- framer-motion ^12.0.0
- lucide-react ^0.344.0
- tailwindcss ^3.4.1
- vite ^5.0.0
- typescript ^5.0.0
[Add hls.js ^1.5.0 only if using Mux/HLS video sources]

# PROJECT STRUCTURE

src/
  components/
    Hero.tsx
    About.tsx
    [Other sections].tsx
    shared/
      FadingVideo.tsx
      BlurText.tsx
      [Other reusables].tsx
  App.tsx
  main.tsx
  index.css
index.html
package.json
tailwind.config.js
vite.config.ts
tsconfig.json

# FONTS

Import in index.html <head>:
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=[DISPLAY]:ital@0;1&family=[BODY]:wght@300;400;500;600&display=swap" rel="stylesheet">

In src/index.css:
* { font-family: '[BODY]', -apple-system, BlinkMacSystemFont, sans-serif; }
[Other globals]

In tailwind.config.js → theme.extend:
colors: {
  primary: '[#HEX]',
  // ...
},
fontFamily: {
  serif: ['"[DISPLAY]"', 'serif'],
}

# COLOR SYSTEM

[Same as CDN variant: list every hex with what it's used for]

# CUSTOM CSS (src/index.css)

[Paste verbatim: .liquid-glass, .noise-overlay, .hero-heading gradient, etc.]

# REUSABLE COMPONENTS (src/components/shared/)

## FadingVideo.tsx
[Full component code]

## BlurText.tsx (or WordsPullUp.tsx)
[Full component code]

## [Others]

# SECTION 1 (src/components/Hero.tsx)

[Same per-element breakdown as CDN variant — layout, background, navbar, content with exact text/classes/animations]

# SECTION 2 (...)
...

# RESPONSIVE BREAKPOINTS
[Same as CDN variant]

# NOTES
[Same as CDN variant]
````

---

## Critical writing checklist for Phase 4

Before declaring the spec complete, verify:

- [ ] **Every text is in quotes** — no "headline about the product"; instead `"Build the Future, Today"`
- [ ] **Every URL is hardcoded** — direct .mp4 / .webp / .jpg from a verified free source
- [ ] **Every animation has numbers** — `delay: 0.4`, `duration: 0.7`, `ease: [0.16, 1, 0.3, 1]`, never "smooth fade"
- [ ] **All Tailwind classes are spelled out** — `text-6xl md:text-7xl lg:text-[5.5rem]`, never "responsive heading"
- [ ] **CSS is pasted verbatim** in code blocks, not paraphrased
- [ ] **SVG paths inlined** when needed (Material Icons, custom shapes)
- [ ] **Reusable components defined** with full code, before sections reference them
- [ ] **Mobile values present** for every responsive value (`sm:` and `md:` variants or `clamp()`)
- [ ] **No "(or similar)" weasel-words** — every choice is committed
- [ ] **License-clean assets only** — Pexels, Unsplash, Coverr, etc.

If any checkbox fails, the LLM consuming this spec will hallucinate a value. Don't ship until all pass.

---

## Anti-patterns in spec writing

**❌ Vague:**
> Add a glass card with a nice background and a cool entrance animation.

**✅ Precise:**
> Card uses `.liquid-glass rounded-[1.25rem] p-6 min-h-[360px] flex flex-col`. Entrance: `motion.div initial={{opacity: 0, scale: 0.95, y: 20}} whileInView={{opacity: 1, scale: 1, y: 0}} viewport={{once: true, margin: "-100px"}} transition={{delay: index * 0.15, duration: 0.8, ease: [0.22, 1, 0.36, 1]}}`.

**❌ Placeholder asset:**
> Hero video: [insert cinematic clip]

**✅ Verified asset:**
> Hero video URL: `https://videos.pexels.com/video-files/2330708/2330708-hd_1920_1080_30fps.mp4` (Pexels License, verified Nov 2026)

**❌ Soft style:**
> Use Inter or another good sans-serif.

**✅ Locked style:**
> Font: Inter, weights 300/400/500/600 from Google Fonts. Apply to `body` via `font-family: 'Inter', sans-serif;`.
