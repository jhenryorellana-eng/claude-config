# Reference Prompts

The 6 motionsites.ai-style prompts that inspired this skill, with notes on what to learn from each. When a user's brief resembles one of these, mirror that prompt's structure and adapt.

---

## 1. Aetheris / Space Voyage

**Brand**: cinematic space-travel SaaS
**Mood**: dark cosmic, liquid-glass over moving abstract video
**Sections**: Hero + Capabilities (2 sections)
**Stack**: CDN-only React + Babel + Tailwind + Framer Motion

**Signature elements**:
- `.liquid-glass` and `.liquid-glass-strong` (both variants)
- Two background videos (.mp4) — one liquid-blob abstract, one moss-with-crystals
- `FadingVideo` component with custom rAF crossfade (FADE_MS=500, FADE_OUT_LEAD=0.55s)
- `BlurText` with 3-stage keyframes (blur(10) → blur(5) → blur(0), opacity 0 → 0.5 → 1, y 50 → -5 → 0)
- Instrument Serif italic for hero headline, Barlow for body
- "Maiden Voyage 2026" badge with white pill chip
- Two stats cards with cream icons and big serif numbers
- Partners strip at hero bottom: 5 brand names in serif italic

**Pattern to mirror when**: the brief is a SaaS, fintech, AI tool, or cinematic product launch wanting "Apple-event-style" gravitas with video backgrounds.

**Free-asset replacements**:
- Hero abstract video → search Pexels: "abstract liquid metal slow motion" or "iridescent bubble"
- Capabilities video → Pexels: "moss crystal close up" or "forest macro"

---

## 2. Jack — 3D Creator Portfolio

**Brand**: solo 3D artist portfolio
**Mood**: bold typographic with magnetic centerpiece, dark + cream
**Sections**: Hero + Marquee + About + Services + Projects (5 sections)
**Stack**: Vite + TypeScript + React + Tailwind + Framer Motion + Lucide

**Signature elements**:
- Massive serif headline: `text-[14vw]` to `text-[17.5vw]` "HI, I'M JACK"
- Gradient text `linear-gradient(180deg, #646973 → #BBCCD7)` with `-webkit-background-clip: text`
- `Magnet` component on portrait image (padding=150, strength=3)
- Marquee section: 21 GIFs in two rows scrolling opposite directions via scroll listener
- Sticky stacking cards in Projects section (3 cards, scale formula = 1 - (total - 1 - index) * 0.03)
- Magenta-orange gradient CTA button
- White section that "lifts up" from below with rounded-t-[60px]
- Kanit font (weights 300-900)

**Pattern to mirror when**: portfolio, personal site, creative agency, art director, freelancer.

**Free-asset replacements**:
- Portrait image → upload user's own photo, or use Unsplash portraits
- Marquee GIFs → use the user's actual work, or pull from Coverr / Pexels short loops
- Project images → Unsplash with consistent style filter

---

## 3. Prisma — Visual Arts Collective

**Brand**: filmmaker collective / creative studio
**Mood**: warm cream cinematic, inset hero card with grain
**Sections**: Hero + About + Features (3 sections)
**Stack**: Vite + TypeScript + Tailwind + Framer Motion

**Signature elements**:
- Inset hero: `p-4 md:p-6` on the section + `rounded-2xl md:rounded-[2rem] overflow-hidden` on inner
- Noise overlay: `.noise-overlay opacity-[0.7] mix-blend-overlay`
- "Prisma" word-by-word pull-up with asterisk on the final "a"
- `WordsPullUpMultiStyle` — mixes Almarai with Instrument Serif italic in same heading
- Scroll-linked character opacity reveal (`useScroll` + per-char `useTransform`)
- 4-column features grid: 1 video card + 3 content cards
- "Join the lab" pill button with black circle + ArrowRight inside (gap expands on hover)
- Almarai (300/400/700/800) + Instrument Serif italic
- Subtle `.bg-noise` (opacity 0.15) in Features section

**Pattern to mirror when**: film studio, creative agency, photo collective, branding agency, artist directory.

**Free-asset replacements**:
- Hero video → Coverr cinematic clips (atmospheric, slow)
- Features card video → short looping clip
- Feature icons → render as small Unsplash thumbnails, or use Lucide icons styled as cards

---

## 4. Asme — No-code AI App Builder

**Brand**: AI SaaS for building no-code apps
**Mood**: dark futuristic minimal, single hero with email capture
**Sections**: Hero only (1 section)
**Stack**: Vite + Tailwind v4 + Motion + hls.js + Lucide

**Signature elements**:
- HLS video stream from Mux (.m3u8) — requires `hls.js` for non-Safari
- Glass nav pill: `.liquid-glass rounded-full max-w-5xl mx-auto`
- Globe icon + "Asme" wordmark
- "BUILD A NO-CODE AI APP IN MINUTES" tagline in micro-caps tracking-[0.2em]
- Instrument Serif headline with `bg-gradient-to-b from-white via-white/95 to-white/70 bg-clip-text text-transparent`
- AnimatePresence email-form toggle: button click → expands into email input with typewriter placeholder
- Placeholder types char-by-char at 60ms intervals
- After 4s, resets back to button state

**Pattern to mirror when**: AI tool, dev tool, launch teaser, waitlist hero, single-screen marketing page.

**Free-asset replacements**:
- Mux HLS video → Pexels MP4 (skip hls.js entirely)
- Or generate a Spline community scene for an abstract background

---

## 5. SkyElite — Private Jet Service

**Brand**: luxury private jet club
**Mood**: clean modern light/gray with full video bg
**Sections**: Hero only (1 section)
**Stack**: React + TypeScript + Tailwind + Lucide

**Signature elements**:
- Full-bleed video, no overlay
- Inter font globally
- Light/neutral palette: text-gray-900, bg-gray-50, text-gray-500, text-gray-600
- Two-line headline with overlap: "Premium." in gray-500 + "Accessible." in #202A36 with `-mt-3` for overlap
- Mobile menu with hamburger (Lucide Menu/X) toggling state
- Brand-dark CTA: `bg-[#202A36]` hover `#1a2229`
- Hero pulled up with `-mt-80`

**Pattern to mirror when**: luxury services, hospitality, real estate, premium consumer brands. Clean rather than cinematic.

**Free-asset replacements**:
- Hero video → Pexels: "private jet" or "luxury aviation" search

---

## 6. Aethera — Digital Havens

**Brand**: creative community / "digital workspace for makers"
**Mood**: clean white background with subtle video, editorial serif
**Sections**: Hero only (1 section)
**Stack**: React + Vite + Tailwind + TypeScript

**Signature elements**:
- White background with video positioned at `top: 300px` (so it shows below the headline)
- Custom rAF fade-in/fade-out loop on video (0.5s in, 0.5s out before end)
- Gradient overlay: `bg-gradient-to-b from-background via-transparent to-background`
- Aethera® wordmark with registered trademark superscript
- Mixed italic emphasis in headline: "Beyond silence, we build the eternal." — italicized words ("silence," "the eternal.") are in #6F6F6F
- Instrument Serif 5xl → 8xl, line-height 0.95, letter-spacing -2.46px
- Black rounded-full pill CTA with hover scale-1.03
- CSS keyframe animations (`animate-fade-rise`, with `-delay` and `-delay-2` variants)
- Body copy in #6F6F6F (warm gray, not cool gray)

**Pattern to mirror when**: editorial brand, lifestyle, wellness, manifesto-style hero, "thoughtful product" launch.

**Free-asset replacements**:
- Background video → Coverr "calm" or "minimal" categories

---

## Cross-reference matrix — pick a pattern

| User brief sounds like... | Mirror prompt |
|--------------------------|---------------|
| Apple-event SaaS launch | Aetheris (Space Voyage) |
| Personal portfolio with impact | Jack (3D Creator) |
| Film studio / creative collective | Prisma |
| AI tool / dev tool waitlist | Asme |
| Luxury service / consumer premium | SkyElite |
| Editorial / wellness / manifesto | Aethera |

---

## Common DNA across all 6

These elements appear in 4+ of the references — they're the "house style":

1. **Video as hero background** — every single reference
2. **Glass surfaces** (liquid-glass class) — Aetheris, Asme, VEX, Aethera
3. **Serif italic display font** (Instrument Serif) — Aetheris, Prisma, Asme, Aethera
4. **Lucide icons** — every reference using icons uses Lucide
5. **Framer Motion** for all animations
6. **Tailwind for layout** with `clamp()` for fluid typography in display headings
7. **Warm cream text** (`#E1E0CC`, `#DEDBC8`, `#D7E2EA`) instead of pure white — softens against dark
8. **No purple, no neon** — palette is dark + cream + sometimes one accent
9. **Mobile-first responsive** — `sm:`, `md:`, `lg:` variants everywhere
10. **Easing `[0.16, 1, 0.3, 1]`** — the signature smooth-out curve

When in doubt, default to this DNA.

---

## What NOT to take from these references

- **The CloudFront URLs** — those are motionsites.ai's paid CDN. Replace with free assets.
- **The user_id in the URLs** (`user_38xzZboKViGWJOttwIXH07lWA1P`) — that's the motionsites.ai creator's Hailuo account. Don't reuse.
- **The Higgs AI proxy** (`images.higgs.ai/?url=...`) — that's their image optimizer. Use Unsplash's native sizing params or another open optimizer (or just serve the original).
- **The Figma site hotlinks** (`shrug-person-78902957.figma.site/...`) — that's their free CDN hack. Build/host your own assets.
