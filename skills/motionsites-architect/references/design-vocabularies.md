# Design Vocabularies

A catalog of every motion effect and reusable component observed in the reference prompts. When the SKILL.md tells you to "pick a motion vocabulary" (Phase 2) or "define reusable components" (Phase 4), look here first. Each entry has when to use it, code, and Tailwind/Framer Motion patterns.

---

## Glass Chrome Effects

### Liquid Glass (subtle)

Used for nav bars, chips, small cards, content tags. Looks like a thin frosted layer with a subtle gradient border. Works over busy video backgrounds.

```css
.liquid-glass {
  background: rgba(255, 255, 255, 0.01);
  background-blend-mode: luminosity;
  backdrop-filter: blur(4px);
  -webkit-backdrop-filter: blur(4px);
  border: none;
  box-shadow: inset 0 1px 1px rgba(255, 255, 255, 0.1);
  position: relative;
  overflow: hidden;
}
.liquid-glass::before {
  content: "";
  position: absolute;
  inset: 0;
  border-radius: inherit;
  padding: 1.4px;
  background: linear-gradient(180deg,
    rgba(255,255,255,0.45) 0%,
    rgba(255,255,255,0.15) 20%,
    rgba(255,255,255,0) 40%,
    rgba(255,255,255,0) 60%,
    rgba(255,255,255,0.15) 80%,
    rgba(255,255,255,0.45) 100%);
  -webkit-mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
  -webkit-mask-composite: xor;
  mask-composite: exclude;
  pointer-events: none;
}
```

### Liquid Glass Strong (heavier)

For primary CTAs, hero cards, prominent surfaces. Use sparingly — usually one per section.

```css
.liquid-glass-strong {
  /* same base as .liquid-glass but: */
  backdrop-filter: blur(50px);
  box-shadow: 4px 4px 4px rgba(0,0,0,0.05), inset 0 1px 1px rgba(255,255,255,0.15);
}
.liquid-glass-strong::before {
  /* same gradient as .liquid-glass::before but stops are: */
  /* 0.5 / 0.2 / 0 / 0 / 0.2 / 0.5 */
}
```

### Glass Pill (alternative — saturated)

For nav links or floating chips when more "color pop" is wanted from the bg.

```css
.glass-pill {
  background: rgba(255, 255, 255, 0.04);
  backdrop-filter: blur(16px) saturate(180%);
  border-radius: 9999px;
  box-shadow: none !important;
}
```

---

## Noise & Texture Overlays

Always inline SVG. Two common variants:

### Heavy noise (over video, makes pages feel filmic)

```css
.noise-overlay {
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg'><filter id='n'><feTurbulence baseFrequency='0.85' numOctaves='3' stitchTiles='stitch'/></filter><rect width='100%25' height='100%25' filter='url(%23n)' opacity='1'/></svg>");
}
```

Apply with: `class="absolute inset-0 noise-overlay opacity-[0.7] mix-blend-overlay pointer-events-none"`

### Subtle noise (background of dark sections, adds film grain)

```css
.bg-noise {
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg'><filter id='n'><feTurbulence baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/></filter><rect width='100%25' height='100%25' filter='url(%23n)' opacity='1'/></svg>");
}
```

Apply with: `class="absolute inset-0 bg-noise opacity-[0.15] pointer-events-none"`

---

## Background Video Patterns

### Pattern A — Simple loop (most common, easiest)

```jsx
<video
  src={videoUrl}
  autoPlay loop muted playsInline
  className="absolute inset-0 w-full h-full object-cover"
/>
```

Pros: simple. Cons: a hard cut at the loop point if the source video doesn't loop seamlessly.

### Pattern B — FadingVideo (custom rAF crossfade)

Use this when the source video has a visible cut at the end. Implements smooth fade-out → reset → fade-in.

```jsx
function FadingVideo({ src, className, style }) {
  const ref = useRef(null);
  const rafRef = useRef(null);
  const fadingOutRef = useRef(false);
  const FADE_MS = 500;
  const FADE_OUT_LEAD = 0.55;

  function fadeTo(target, duration = FADE_MS) {
    if (rafRef.current) cancelAnimationFrame(rafRef.current);
    const video = ref.current;
    const start = performance.now();
    const from = parseFloat(video.style.opacity || "0");
    function step(now) {
      const t = Math.min(1, (now - start) / duration);
      video.style.opacity = String(from + (target - from) * t);
      if (t < 1) rafRef.current = requestAnimationFrame(step);
    }
    rafRef.current = requestAnimationFrame(step);
  }

  useEffect(() => {
    const video = ref.current;
    video.style.opacity = "0";

    const onLoadedData = () => { video.play(); fadeTo(1); };
    const onTimeUpdate = () => {
      const remaining = video.duration - video.currentTime;
      if (!fadingOutRef.current && remaining <= FADE_OUT_LEAD && remaining > 0) {
        fadingOutRef.current = true;
        fadeTo(0);
      }
    };
    const onEnded = () => {
      video.style.opacity = "0";
      setTimeout(() => {
        video.currentTime = 0;
        video.play();
        fadingOutRef.current = false;
        fadeTo(1);
      }, 100);
    };

    video.addEventListener("loadeddata", onLoadedData);
    video.addEventListener("timeupdate", onTimeUpdate);
    video.addEventListener("ended", onEnded);
    return () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
      video.removeEventListener("loadeddata", onLoadedData);
      video.removeEventListener("timeupdate", onTimeUpdate);
      video.removeEventListener("ended", onEnded);
    };
  }, []);

  return <video ref={ref} src={src} autoPlay muted playsInline preload="auto" className={className} style={style} />;
}
```

### Pattern C — HLS streaming video (Mux / .m3u8)

Use when the source is an HLS stream (Mux is most common open service). Requires `hls.js`.

```jsx
useEffect(() => {
  const video = ref.current;
  const url = "https://stream.mux.com/XXXX.m3u8";
  if (video.canPlayType("application/vnd.apple.mpegurl")) {
    video.src = url; // Safari native
  } else {
    const hls = new Hls();
    hls.loadSource(url);
    hls.attachMedia(video);
  }
}, []);
```

---

## Text Entrance Animations

### BlurText (word-by-word blur + opacity entrance)

The Aetheris/Space Voyage signature effect. Words appear with a 3-stage keyframe.

```jsx
function BlurText({ text, className, delay = 0 }) {
  const words = text.split(" ");
  const [inView, setInView] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    const obs = new IntersectionObserver(([e]) => e.isIntersecting && setInView(true), { threshold: 0.1 });
    if (ref.current) obs.observe(ref.current);
    return () => obs.disconnect();
  }, []);

  return (
    <p ref={ref} className={className} style={{ display: "flex", flexWrap: "wrap", justifyContent: "center", rowGap: "0.1em" }}>
      {words.map((w, i) => (
        <motion.span
          key={i}
          initial={{ filter: "blur(10px)", opacity: 0, y: 50 }}
          animate={inView ? {
            filter: ["blur(10px)", "blur(5px)", "blur(0px)"],
            opacity: [0, 0.5, 1],
            y: [50, -5, 0],
          } : {}}
          transition={{ duration: 0.7, times: [0, 0.5, 1], delay: delay + (i * 100) / 1000, ease: "easeOut" }}
          style={{ display: "inline-block", marginRight: "0.28em" }}
        >
          {w}
        </motion.span>
      ))}
    </p>
  );
}
```

### WordsPullUp (word-by-word slide-up)

Cleaner alternative to BlurText. The Prisma signature effect.

```jsx
function WordsPullUp({ text, className, showAsterisk = false }) {
  const ref = useRef(null);
  const inView = useInView(ref, { once: true });
  const words = text.split(" ");

  return (
    <span ref={ref} className={className} style={{ display: "inline-flex", flexWrap: "wrap" }}>
      {words.map((w, i) => (
        <motion.span
          key={i}
          initial={{ y: 20, opacity: 0 }}
          animate={inView ? { y: 0, opacity: 1 } : {}}
          transition={{ delay: i * 0.08, duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
          style={{ display: "inline-block", marginRight: "0.25em" }}
        >
          {w}
          {showAsterisk && i === words.length - 1 && (
            <span className="absolute top-[0.65em] -right-[0.3em] text-[0.31em]">*</span>
          )}
        </motion.span>
      ))}
    </span>
  );
}
```

### AnimatedText (scroll-linked character opacity)

The "About me" effect — characters reveal from 0.2 to 1 opacity as you scroll past.

```jsx
function AnimatedText({ text, className }) {
  const ref = useRef(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start 0.8", "end 0.2"] });
  const chars = text.split("");

  return (
    <p ref={ref} className={className}>
      {chars.map((c, i) => {
        const charProgress = i / chars.length;
        const opacity = useTransform(scrollYProgress, [charProgress - 0.1, charProgress + 0.05], [0.2, 1]);
        return <motion.span key={i} style={{ opacity }}>{c}</motion.span>;
      })}
    </p>
  );
}
```

### AnimatedHeading (character-by-character translate-X entrance)

The VEX hero pattern — each character slides in from -18px.

```jsx
function AnimatedHeading({ text, charDelay = 30, initialDelay = 200 }) {
  const [show, setShow] = useState(false);
  useEffect(() => { setTimeout(() => setShow(true), initialDelay); }, []);
  const lines = text.split("\n");

  return (
    <h1 style={{ letterSpacing: "-0.04em" }}>
      {lines.map((line, li) => (
        <span key={li} style={{ display: "block" }}>
          {line.split("").map((c, ci) => {
            const totalDelay = li * line.length * charDelay + ci * charDelay;
            return (
              <span
                key={ci}
                style={{
                  display: "inline-block",
                  opacity: show ? 1 : 0,
                  transform: show ? "translateX(0)" : "translateX(-18px)",
                  transition: `opacity 500ms ease ${totalDelay}ms, transform 500ms ease ${totalDelay}ms`,
                }}
              >{c === " " ? "\u00A0" : c}</span>
            );
          })}
        </span>
      ))}
    </h1>
  );
}
```

### Typewriter (placeholder text)

The Asme email form effect — placeholder types character by character at 60ms intervals.

```jsx
function useTypewriter(text, interval = 60) {
  const [output, setOutput] = useState("");
  useEffect(() => {
    setOutput("");
    let i = 0;
    const id = setInterval(() => {
      i++;
      setOutput(text.slice(0, i));
      if (i >= text.length) clearInterval(id);
    }, interval);
    return () => clearInterval(id);
  }, [text]);
  return output;
}
```

---

## Hover & Mouse Effects

### Magnet (mouse-following magnetic attraction)

The Jack 3D Creator portrait effect. Element drifts toward the cursor.

```jsx
function Magnet({ children, padding = 100, strength = 3 }) {
  const ref = useRef(null);
  const [active, setActive] = useState(false);
  const [pos, setPos] = useState({ x: 0, y: 0 });

  useEffect(() => {
    const onMove = (e) => {
      const el = ref.current;
      if (!el) return;
      const rect = el.getBoundingClientRect();
      const cx = rect.left + rect.width / 2;
      const cy = rect.top + rect.height / 2;
      const dx = e.clientX - cx;
      const dy = e.clientY - cy;
      const dist = Math.hypot(dx, dy);
      if (dist < rect.width / 2 + padding) {
        setActive(true);
        setPos({ x: dx / strength, y: dy / strength });
      } else {
        setActive(false);
        setPos({ x: 0, y: 0 });
      }
    };
    window.addEventListener("mousemove", onMove);
    return () => window.removeEventListener("mousemove", onMove);
  }, [padding, strength]);

  return (
    <div
      ref={ref}
      style={{
        transform: `translate3d(${pos.x}px, ${pos.y}px, 0)`,
        transition: active ? "transform 0.3s ease-out" : "transform 0.6s ease-in-out",
        willChange: "transform",
      }}
    >
      {children}
    </div>
  );
}
```

---

## Scroll-Driven Patterns

### Marquee (horizontal scroll-driven rows)

Two rows of tiles. Row 1 moves right as you scroll, row 2 moves left. Triplicate the images for seamless wrap.

```jsx
function MarqueeScroll({ images }) {
  const ref = useRef(null);
  const [offset, setOffset] = useState(0);

  useEffect(() => {
    const onScroll = () => {
      const rect = ref.current?.getBoundingClientRect();
      if (!rect) return;
      const sectionTop = rect.top + window.scrollY;
      setOffset((window.scrollY - sectionTop + window.innerHeight) * 0.3);
    };
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const row1 = images.slice(0, Math.ceil(images.length / 2));
  const row2 = images.slice(Math.ceil(images.length / 2));
  const tripled1 = [...row1, ...row1, ...row1];
  const tripled2 = [...row2, ...row2, ...row2];

  return (
    <div ref={ref} className="overflow-hidden flex flex-col gap-3">
      <div className="flex gap-3" style={{ transform: `translateX(${offset - 200}px)`, willChange: "transform" }}>
        {tripled1.map((src, i) => (
          <img key={i} src={src} loading="lazy" className="w-[420px] h-[270px] rounded-2xl object-cover shrink-0" />
        ))}
      </div>
      <div className="flex gap-3" style={{ transform: `translateX(-${offset - 200}px)`, willChange: "transform" }}>
        {tripled2.map((src, i) => (
          <img key={i} src={src} loading="lazy" className="w-[420px] h-[270px] rounded-2xl object-cover shrink-0" />
        ))}
      </div>
    </div>
  );
}
```

### Sticky Stacking Cards (Apple-style)

Each card sticks while the next pushes up, with progressive scale-down on cards being passed.

```jsx
function StickyCard({ index, totalCards, children }) {
  const ref = useRef(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "start start"] });
  const targetScale = 1 - (totalCards - 1 - index) * 0.03;
  const scale = useTransform(scrollYProgress, [0, 1], [1, targetScale]);

  return (
    <div ref={ref} className="h-[85vh] flex items-start justify-center">
      <motion.div
        style={{ scale, top: `${index * 28}px` }}
        className="sticky top-24 md:top-32 w-full"
      >
        {children}
      </motion.div>
    </div>
  );
}
```

---

## Utility Components

### FadeIn (whileInView wrapper)

The workhorse — wrap anything in this for a viewport-triggered entrance.

```jsx
function FadeIn({ children, delay = 0, duration = 0.7, x = 0, y = 30, as = "div" }) {
  const Component = motion[as] || motion.div;
  return (
    <Component
      initial={{ opacity: 0, x, y }}
      whileInView={{ opacity: 1, x: 0, y: 0 }}
      viewport={{ once: true, margin: "50px", amount: 0 }}
      transition={{ delay, duration, ease: [0.25, 0.1, 0.25, 1] }}
    >
      {children}
    </Component>
  );
}
```

---

## Color & Gradient Effects

### Hero gradient text (the cream-to-steel hero look)

```css
.hero-heading {
  background: linear-gradient(180deg, #646973 0%, #BBCCD7 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
```

Or in Tailwind: `bg-gradient-to-b from-white via-white/95 to-white/70 bg-clip-text text-transparent`

### Magenta-orange button gradient (the Jack ContactButton)

```css
.cta-magenta {
  background: linear-gradient(123deg, #18011F 7%, #B600A8 37%, #7621B0 72%, #BE4C00 100%);
  box-shadow: 0px 4px 4px rgba(181, 1, 167, 0.25), 4px 4px 12px #7721B1 inset;
  outline: 2px solid #fff;
  outline-offset: -3px;
}
```

Use sparingly — only when the brand calls for a saturated accent.

---

## Standard Easing Curves

Use these named easings consistently. They have personality.

| Name | Cubic Bezier | When |
|------|-------------|------|
| Smooth out | `[0.16, 1, 0.3, 1]` | Most hero entrances (the Prisma / Asme default) |
| Pop in | `[0.22, 1, 0.36, 1]` | Card entrances with scale |
| Linear out | `[0.25, 0.1, 0.25, 1]` | FadeIn wrapper default |
| Sharp | `[0.4, 0, 0.2, 1]` | UI state changes |

---

## Layout Frames

### Inset Card Hero (the Prisma & Aethera pattern)

The hero is NOT edge-to-edge. It sits inside the page with a margin, creating a "card" feel.

```jsx
<section className="h-screen p-4 md:p-6">
  <div className="relative h-full rounded-2xl md:rounded-[2rem] overflow-hidden">
    {/* video, overlays, content */}
  </div>
</section>
```

### Full-bleed Hero (the Aetheris / VEX pattern)

Hero takes the entire viewport with no margin.

```jsx
<section className="h-screen relative overflow-hidden">
  {/* video at z-0, content at z-10 */}
</section>
```

### Rounded section reveal (the Jack Services section)

A light section "lifts up" from below with rounded top corners.

```jsx
<section className="bg-white -mt-10 md:-mt-14 rounded-t-[40px] md:rounded-t-[60px] relative z-10">
  {/* content */}
</section>
```

---

## What to NOT do

- **Don't animate `width`, `height`, `top`, `left`, or `margin`.** Always animate `transform` and `opacity` — they're GPU-accelerated. Janky animations come from animating layout properties.
- **Don't use `transition: all`.** Be explicit: `transition: transform 0.3s, opacity 0.3s`.
- **Don't forget `will-change: transform`** on elements that animate often (marquees, magnets, sticky cards).
- **Don't use CSS transitions on the FadingVideo.** It must be rAF-driven, or the loop point will be choppy.
- **Don't stack too many glass surfaces.** One glass nav + one glass CTA + maybe glass cards is the max. More feels muddy.
