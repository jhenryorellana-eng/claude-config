/*
  MOTION PRESETS — 8 kinetic signatures
  ============================================
  Each preset is a config object that modifies the deck's master GSAP timeline.
  The Direction Brief picks ONE preset; apply it consistently to every transition.

  HOW TO USE:
    1. Pick one preset based on the Direction Brief's motion line.
    2. Apply MORPH.defaults to your master timeline's defaults.
    3. Use MORPH.transition for slide-to-slide morph configs.
    4. Use MORPH.micro for in-slide micro-interactions.
    5. Use MORPH.heroDrift for any Ken Burns drift on the hero image.

  Example:
    const MOTION = MOTION_PRESETS["editorial-slow"];
    const tl = gsap.timeline({ paused: true, defaults: MOTION.defaults });
    tl.to("#hero", { ...heroEndState, ...MOTION.transition }, "slide2");
    gsap.to(".pin-tag svg", { ...MOTION.micro, scale: 1.15, yoyo: true, repeat: -1 });

  IMPORTANT: a deck commits to ONE preset. Don't mix "fashion-snap" cuts with
  "watercolor-flow" fades in the same deck — it reads as inconsistent.
*/

const MOTION_PRESETS = {

  // -----------------------------------------------------------------
  // 1. editorial-slow
  // Long, patient, considered. The default for asombro/nostalgia arcs.
  // -----------------------------------------------------------------
  "editorial-slow": {
    defaults:   { duration: 1.4, ease: "power3.inOut" },
    transition: { duration: 1.4, ease: "power3.inOut" },
    micro:      { duration: 1.6, ease: "sine.inOut" },
    heroDrift:  { duration: 14,  ease: "sine.inOut", scale: 1.04 },
    staggerEach: 0.12
  },

  // -----------------------------------------------------------------
  // 2. techno-pulse
  // Short, sharp, precise. Snappy landings, occasional overshoot.
  // -----------------------------------------------------------------
  "techno-pulse": {
    defaults:   { duration: 0.6, ease: "power4.out" },
    transition: { duration: 0.6, ease: "power4.out" },
    micro:      { duration: 0.4, ease: "back.out(1.6)" },
    heroDrift:  { duration: 8,   ease: "power1.inOut", scale: 1.02 },
    staggerEach: 0.06
  },

  // -----------------------------------------------------------------
  // 3. documentary-warm
  // Medium, gentle, Ken Burns drift on heroes. Documentary cut feel.
  // -----------------------------------------------------------------
  "documentary-warm": {
    defaults:   { duration: 1.0, ease: "power2.inOut" },
    transition: { duration: 1.0, ease: "power2.inOut" },
    micro:      { duration: 1.2, ease: "sine.inOut" },
    heroDrift:  { duration: 12,  ease: "sine.inOut", scale: 1.06 },
    staggerEach: 0.10
  },

  // -----------------------------------------------------------------
  // 4. fashion-snap
  // Very short, page-turn editorial. Hard cuts with minimal morph.
  // -----------------------------------------------------------------
  "fashion-snap": {
    defaults:   { duration: 0.4, ease: "power4.out" },
    transition: { duration: 0.4, ease: "power4.in" }, // enter sharp
    micro:      { duration: 0.3, ease: "power3.out" },
    heroDrift:  { duration: 0,   ease: "none", scale: 1.0 }, // no drift; fashion is static
    staggerEach: 0.04
  },

  // -----------------------------------------------------------------
  // 5. watercolor-flow
  // Long, fluid, sine-eased, overlapping fades. Organic.
  // -----------------------------------------------------------------
  "watercolor-flow": {
    defaults:   { duration: 1.6, ease: "sine.inOut" },
    transition: { duration: 1.6, ease: "sine.inOut" },
    micro:      { duration: 2.0, ease: "sine.inOut" },
    heroDrift:  { duration: 18,  ease: "sine.inOut", scale: 1.08 },
    staggerEach: 0.15
  },

  // -----------------------------------------------------------------
  // 6. brutalist-snap
  // No easing. Hard swaps. Some slides don't morph at all.
  // -----------------------------------------------------------------
  "brutalist-snap": {
    defaults:   { duration: 0.3, ease: "none" },
    transition: { duration: 0.3, ease: "none" },
    micro:      { duration: 0.2, ease: "none" },
    heroDrift:  { duration: 0,   ease: "none", scale: 1.0 },
    staggerEach: 0,
    /* NOTE: with brutalist-snap, certain slide pairs should SWAP instead of MORPH.
       Set .slide { transition: none } and use display:none/block via the runtime
       for the brutalist transitions instead of GSAP tweens. */
    hardSwap: true
  },

  // -----------------------------------------------------------------
  // 7. cinematic-build
  // Variable durations — slow on hero reveals, fast on detail cuts.
  // Movie-trailer feel.
  // -----------------------------------------------------------------
  "cinematic-build": {
    defaults:   { duration: 1.0, ease: "power2.inOut" },
    transition: { duration: 1.0, ease: "power2.inOut" }, // baseline
    transitionPivotal: { duration: 1.8, ease: "power3.out" }, // for the pivotal slide
    transitionDetail:  { duration: 0.5, ease: "power3.out" }, // for non-pivotal cuts
    micro:      { duration: 0.8, ease: "back.out(1.4)" },
    heroDrift:  { duration: 10,  ease: "power1.inOut", scale: 1.05 },
    staggerEach: 0.08
  },

  // -----------------------------------------------------------------
  // 8. instrumental-tick
  // Mechanical, even, no overshoot. Each transition is a watch tick.
  // Pairs with `instrumental` chrome.
  // -----------------------------------------------------------------
  "instrumental-tick": {
    defaults:   { duration: 0.8, ease: "power1.inOut" },
    transition: { duration: 0.8, ease: "power1.inOut" },
    micro:      { duration: 0.6, ease: "power1.inOut" },
    heroDrift:  { duration: 0,   ease: "none", scale: 1.0 },
    staggerEach: 0.08,
    /* Add a subtle vertical bar tick on each transition (visual metronome) */
    tickAccent: true
  }

};

/* =================================================================
   COUNTER-INTUITIVE PAIRINGS (for the brave Direction Brief)
   =================================================================
   The pairings below are intentional mismatches that create signature decks.
   When the topic permits, they're more memorable than safe pairings:

   - minimal-poetic stance + techno-pulse motion
     = restrained content with sharp delivery (Apple keynote feel)
   - brutalist-asymmetric stance + watercolor-flow motion
     = raw composition softened by motion (contradiction IS the design)
   - dense-editorial stance + brutalist-snap motion
     = magazine layout with no fluid transitions (Bloomberg Businessweek feel)
   - technical-blueprint stance + cinematic-build motion
     = schematic content with theatrical pacing (Westworld opening credits)
*/

/* Export for ES modules; fall back to global for direct script include */
if (typeof module !== 'undefined' && module.exports) {
  module.exports = MOTION_PRESETS;
}
