---
name: ui-review
description: "Gate visual y de UX de una web viva — UNA sola pasada, report-only (los fixes los hace frontend-builder o /impeccable:polish). Combina: guidelines frescas de Vercel (WebFetch), checklist de 10 categorías con umbrales numéricos, leyes de usabilidad de Krug (trunk test, don't make me think), Goodwill Reservoir puntuado y blacklist de 11 anti-patrones AI-slop. Usa cuando se pida 'gate de UI', 'audita el diseño', 'revisión visual', 'AI slop check', '¿pasa el gate de diseño?', 'review my UI', 'check accessibility'. La invoca ui-designer en fase de diseño y qa-engineer como gate pre-merge. NO prueba funcionalidad (qa-web) ni propone paletas (design-system)."
---

# ui-review — el gate visual

Una pasada sobre una web viva, un reporte, un veredicto. **No arregla nada.**
Esa restricción es deliberada: un revisor que puede editar el código termina
arreglándolo "de paso" y nadie se entera de qué estaba mal. Los hallazgos se
entregan priorizados y el fix lo hace quien corresponde —`frontend-builder`, o
`/impeccable:polish` si el trabajo es de pulido fino.

**No hay fix-loop. No hay segunda vuelta.** Si el reporte sale FAIL, el ciclo
vuelve al builder y esta skill se corre de nuevo desde cero cuando el fix esté
listo.

## Alcance

Por defecto: la home más 2-4 páginas clave que el usuario indique o que salgan
de la navegación principal. Si el usuario pasa una URL suelta, audita esa
página y pregunta si quiere ampliar el alcance antes de invertir la pasada.

Necesitas una URL viva (local o desplegada). Si el sitio redirige a `/login`,
`/signin`, `/auth` o `/sso`, avisa: hace falta importar cookies con
`/setup-browser-cookies` antes de que la auditoría valga algo. No audites la
pantalla de login y llames a eso un gate.

---

## PASO 1 — Traer las guidelines frescas (obligatorio, siempre primero)

Antes de mirar un solo píxel, trae las Web Interface Guidelines de Vercel con
**WebFetch**:

```
https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md
```

El contenido que devuelve trae todas las reglas y su formato de salida. Se
descarga **en cada corrida**, nunca de memoria: el archivo cambia y la gracia
de este paso es que el gate no se congele en el estado del arte de hace seis
meses.

Las reglas de Vercel se suman al checklist de este archivo, no lo reemplazan.
Cuando una regla fresca contradiga algo de acá, gana la fresca y lo anotas en
el reporte ("la guideline de Vercel del [fecha] ahora pide X").

Los hallazgos que salgan de estas reglas se reportan en el formato terso
`file:line` cuando tengas el código a mano; cuando solo tengas la web viva,
usa `url → selector`.

---

## PASO 2 — Mecánica del navegador

**Playwright MCP, siempre.** Dos viewports, sin excepción:

- **Desktop: 1440 × 900**
- **Mobile: 390 × 844**

```
browser_navigate       → ir a la URL
browser_resize         → 1440x900, luego 390x844
browser_take_screenshot→ captura por página y por viewport
browser_snapshot       → árbol de accesibilidad (para jerarquía y roles)
browser_evaluate       → mediciones numéricas (abajo)
browser_console_messages → errores de consola
```

Las mediciones que alimentan los umbrales del checklist se sacan con
`browser_evaluate`, no a ojo. Estas cuatro son el mínimo:

```js
// Fuentes en uso (tope de 500 elementos para no colgar la página)
() => [...new Set([...document.querySelectorAll('*')].slice(0, 500)
  .map(e => getComputedStyle(e).fontFamily))]

// Paleta realmente renderizada
() => [...new Set([...document.querySelectorAll('*')].slice(0, 500)
  .flatMap(e => [getComputedStyle(e).color, getComputedStyle(e).backgroundColor])
  .filter(c => c !== 'rgba(0, 0, 0, 0)'))]

// Jerarquía de headings
() => [...document.querySelectorAll('h1,h2,h3,h4,h5,h6')].map(h => ({
  tag: h.tagName, text: h.textContent.trim().slice(0, 50),
  size: getComputedStyle(h).fontSize, weight: getComputedStyle(h).fontWeight }))

// Touch targets por debajo de 44px
() => [...document.querySelectorAll('a,button,input,[role=button]')]
  .filter(e => { const r = e.getBoundingClientRect();
                 return r.width > 0 && (r.width < 44 || r.height < 44) })
  .map(e => ({ tag: e.tagName, text: (e.textContent || '').trim().slice(0, 30),
               w: Math.round(e.getBoundingClientRect().width),
               h: Math.round(e.getBoundingClientRect().height) })).slice(0, 20)
```

Un número medido vale más que una impresión. "El contraste se ve bajo" no es un
hallazgo; "el texto secundario da 3.1:1 sobre el fondo de la card, hace falta
4.5:1" sí lo es.

---

## UX Principles: How Users Actually Behave

Estos principios gobiernan cómo interactúan los humanos reales con las
interfaces. Son conducta observada, no preferencias. Aplícalos antes, durante y
después de cada juicio de diseño.

### The Three Laws of Usability

1. **Don't make me think.** Every page should be self-evident. If a user stops
   to think "What do I click?" or "What does this mean?", the design has failed.
   Self-evident > self-explanatory > requires explanation.

2. **Clicks don't matter, thinking does.** Three mindless, unambiguous clicks
   beat one click that requires thought. Each step should feel like an obvious
   choice (animal, vegetable, or mineral), not a puzzle.

3. **Omit, then omit again.** Get rid of half the words on each page, then get
   rid of half of what's left. Happy talk (self-congratulatory text) must die.
   Instructions must die. If they need reading, the design has failed.

### How Users Actually Behave

- **Users scan, they don't read.** Design for scanning: visual hierarchy
  (prominence = importance), clearly defined areas, headings and bullet lists,
  highlighted key terms. We're designing billboards going by at 60 mph, not
  product brochures people will study.
- **Users satisfice.** They pick the first reasonable option, not the best.
  Make the right choice the most visible choice.
- **Users muddle through.** They don't figure out how things work. They wing
  it. If they accomplish their goal by accident, they won't seek the "right" way.
  Once they find something that works, no matter how badly, they stick to it.
- **Users don't read instructions.** They dive in. Guidance must be brief,
  timely, and unavoidable, or it won't be seen.

### Billboard Design for Interfaces

- **Use conventions.** Logo top-left, nav top/left, search = magnifying glass.
  Don't innovate on navigation to be clever. Innovate when you KNOW you have a
  better idea, otherwise use conventions. Even across languages and cultures,
  web conventions let people identify the logo, nav, search, and main content.
- **Visual hierarchy is everything.** Related things are visually grouped. Nested
  things are visually contained. More important = more prominent. If everything
  shouts, nothing is heard. Start with the assumption everything is visual noise,
  guilty until proven innocent.
- **Make clickable things obviously clickable.** No relying on hover states for
  discoverability, especially on mobile where hover doesn't exist. Shape, location,
  and formatting (color, underlining) must signal clickability without interaction.
- **Eliminate noise.** Three sources: too many things shouting for attention
  (shouting), things not organized logically (disorganization), and too much stuff
  (clutter). Fix noise by removal, not addition.
- **Clarity trumps consistency.** If making something significantly clearer
  requires making it slightly inconsistent, choose clarity every time.

### Navigation as Wayfinding

Users on the web have no sense of scale, direction, or location. Navigation
must always answer: What site is this? What page am I on? What are the major
sections? What are my options at this level? Where am I? How can I search?

Persistent navigation on every page. Breadcrumbs for deep hierarchies.
Current section visually indicated.

### Mobile: Same Rules, Higher Stakes

All the above applies on mobile, just more so. Real estate is scarce, but never
sacrifice usability for space savings. Affordances must be VISIBLE: no cursor
means no hover-to-discover. Touch targets must be big enough (44px minimum).
Flat design can strip away useful visual information that signals interactivity.
Prioritize ruthlessly: things needed in a hurry go close at hand, everything
else a few taps away with an obvious path to get there.

---

## El trunk test (en cada página)

Imagina que te dejan caer en esta página sin contexto. ¿Puedes responder de
inmediato?

1. **What site is this?** (identidad del sitio visible e identificable)
2. **What page am I on?** (nombre de página prominente, coincide con lo que cliqueé)
3. **What are the major sections?** (nav primaria visible y clara)
4. **What are my options at this level?** (nav local u opciones de contenido obvias)
5. **Where am I in the scheme of things?** (indicador "you are here", breadcrumbs)
6. **How can I search?** (buscador localizable sin cacería)

Score: **PASS** (las 6 claras) / **PARTIAL** (4-5 claras) / **FAIL** (3 o menos).

Un FAIL en el trunk test es un hallazgo de impacto **HIGH** por más pulido que
esté el diseño visual. La versión operativa del test: tapa todo excepto la
navegación. Si con eso ya no sabes qué sitio es ni en qué página estás, la
navegación falló.

---

## Design Audit Checklist (10 categorías, ~89 ítems)

Aplícalo en cada página. Cada hallazgo lleva impacto (**high** / **medium** /
**polish**) y categoría.

**1. Visual Hierarchy & Composition** (8 ítems)
- Clear focal point? One primary CTA per view?
- Eye flows naturally top-left to bottom-right?
- Visual noise — competing elements fighting for attention?
- Information density appropriate for content type?
- Z-index clarity — nothing unexpectedly overlapping?
- Above-the-fold content communicates purpose in 3 seconds?
- Squint test: hierarchy still visible when blurred?
- White space is intentional, not leftover?

**2. Typography** (15 ítems)
- Font count <=3 (flag if more)
- Scale follows ratio (1.25 major third or 1.333 perfect fourth)
- Line-height: 1.5x body, 1.15-1.25x headings
- Measure: 45-75 chars per line (66 ideal)
- Heading hierarchy: no skipped levels (h1→h3 without h2)
- Weight contrast: >=2 weights used for hierarchy
- No blacklisted fonts (Papyrus, Comic Sans, Lobster, Impact, Jokerman)
- If primary font is Inter/Roboto/Open Sans/Poppins → flag as potentially generic
- `text-wrap: balance` or `text-pretty` on headings
- Curly quotes used, not straight quotes
- Ellipsis character (`…`) not three dots (`...`)
- `font-variant-numeric: tabular-nums` on number columns
- Body text >= 16px
- Caption/label >= 12px
- No letterspacing on lowercase text

**3. Color & Contrast** (10 ítems)
- Palette coherent (<=12 unique non-gray colors)
- WCAG AA: body text 4.5:1, large text (18px+) 3:1, UI components 3:1
- Semantic colors consistent (success=green, error=red, warning=yellow/amber)
- No color-only encoding (always add labels, icons, or patterns)
- Dark mode: surfaces use elevation, not just lightness inversion
- Dark mode: text off-white (~#E0E0E0), not pure white
- Primary accent desaturated 10-20% in dark mode
- `color-scheme: dark` on html element (if dark mode present)
- No red/green only combinations (8% of men have red-green deficiency)
- Neutral palette is warm or cool consistently — not mixed

**4. Spacing & Layout** (12 ítems)
- Grid consistent at all breakpoints
- Spacing uses a scale (4px or 8px base), not arbitrary values
- Alignment is consistent — nothing floats outside the grid
- Rhythm: related items closer together, distinct sections further apart
- Border-radius hierarchy (not uniform bubbly radius on everything)
- Inner radius = outer radius - gap (nested elements)
- No horizontal scroll on mobile
- Max content width set (no full-bleed body text)
- `env(safe-area-inset-*)` for notch devices
- URL reflects state (filters, tabs, pagination in query params)
- Flex/grid used for layout (not JS measurement)
- Breakpoints: mobile (375), tablet (768), desktop (1024), wide (1440)

**5. Interaction States** (10 ítems)
- Hover state on all interactive elements
- `focus-visible` ring present (never `outline: none` without replacement)
- Active/pressed state with depth effect or color shift
- Disabled state: reduced opacity + `cursor: not-allowed`
- Loading: skeleton shapes match real content layout
- Empty states: warm message + primary action + visual (not just "No items.")
- Error messages: specific + include fix/next step
- Success: confirmation animation or color, auto-dismiss
- Touch targets >= 44px on all interactive elements
- `cursor: pointer` on all clickable elements
- Mindless choice audit: every decision point (button, link, dropdown, modal
  choice) is a mindless click (obvious what happens). If a click requires
  thought about whether it's the right choice, flag as HIGH.

**6. Responsive Design** (8 ítems)
- Mobile layout makes *design* sense (not just stacked desktop columns)
- Touch targets sufficient on mobile (>= 44px)
- No horizontal scroll on any viewport
- Images handle responsive (srcset, sizes, or CSS containment)
- Text readable without zooming on mobile (>= 16px body)
- Navigation collapses appropriately (hamburger, bottom nav, etc.)
- Forms usable on mobile (correct input types, no autoFocus on mobile)
- No `user-scalable=no` or `maximum-scale=1` in viewport meta

**7. Motion & Animation** (6 ítems)
- Easing: ease-out for entering, ease-in for exiting, ease-in-out for moving
- Duration: 50-700ms range (nothing slower unless page transition)
- Purpose: every animation communicates something (state change, attention,
  spatial relationship)
- `prefers-reduced-motion` respected (verifica con `browser_evaluate`:
  `() => matchMedia('(prefers-reduced-motion: reduce)').matches`)
- No `transition: all` — properties listed explicitly
- Only `transform` and `opacity` animated (not layout properties like width,
  height, top, left)

**8. Content & Microcopy** (8 ítems)
- Empty states designed with warmth (message + action + illustration/icon)
- Error messages specific: what happened + why + what to do next
- Button labels specific ("Save API Key" not "Continue" or "Submit")
- No placeholder/lorem ipsum text visible in production
- Truncation handled (`text-overflow: ellipsis`, `line-clamp`, or `break-words`)
- Active voice ("Install the CLI" not "The CLI will be installed")
- Loading states end with `…` ("Saving…" not "Saving...")
- Destructive actions have confirmation modal or undo window
- Happy talk detection: scan for introductory paragraphs that start with
  "Welcome to..." or tell users how great the site is. If you can hear "blah
  blah blah", it's happy talk. Flag for removal.
- Instructions detection: any visible instructions longer than one sentence. If
  users need to read instructions, the design has failed. Flag the instructions
  AND the interaction they're compensating for.
- Happy talk word count: count total visible words on the page. Classify each
  text block as "useful content" vs "happy talk". Report: "This page has X
  words. Y (Z%) are happy talk."

**9. AI Slop Detection** (11 anti-patrones — la blacklist)

The test: **would a human designer at a respected studio ever ship this?**

- Purple/violet/indigo gradient backgrounds or blue-to-purple color schemes
- **The 3-column feature grid:** icon-in-colored-circle + bold title + 2-line
  description, repeated 3x symmetrically. THE most recognizable AI layout.
- Icons in colored circles as section decoration (SaaS starter template look)
- Centered everything (`text-align: center` on all headings, descriptions, cards)
- Uniform bubbly border-radius on every element (same large radius on everything)
- Decorative blobs, floating circles, wavy SVG dividers (if a section feels
  empty, it needs better content, not decoration)
- Emoji as design elements (rockets in headings, emoji as bullet points)
- Colored left-border on cards (`border-left: 3px solid <accent>`)
- Generic hero copy ("Welcome to [X]", "Unlock the power of...", "Your
  all-in-one solution for...")
- Cookie-cutter section rhythm (hero → 3 features → testimonials → pricing →
  CTA, every section same height)
- system-ui or `-apple-system` as the PRIMARY display/body font — the "I gave up
  on typography" signal. Pick a real typeface.

**10. Performance as Design** (6 ítems)
- LCP < 2.0s (web apps), < 1.5s (informational sites)
- CLS < 0.1 (no visible layout shifts during load)
- Skeleton quality: shapes match real content layout, shimmer animation
- Images: `loading="lazy"`, width/height dimensions set, WebP/AVIF format
- Fonts: `font-display: swap`, preconnect to CDN origins
- No visible font swap flash (FOUT) — critical fonts preloaded

---

## Goodwill Reservoir

Los usuarios llegan con una reserva de buena voluntad. Cada punto de fricción la
drena. Recorre 1-2 flujos clave (el que el producto necesita que funcione:
registro, checkout, la tarea principal) manteniendo el medidor.

**Arranca en 70/100.** Los puntajes son heurísticos, no medidos: el valor está
en identificar los drenajes y las recargas concretas, no en el número final.

Resta puntos por:
- Hidden information the user would want (pricing, contact, shipping): **-15**
- Format punishment (rejecting valid input like dashes in phone numbers): **-10**
- Unnecessary information requests: **-10**
- Interstitials, splash screens, forced tours blocking the task: **-15**
- Sloppy or unprofessional appearance: **-10**
- Ambiguous choices that require thinking: **-5** cada una

Suma puntos por:
- Top user tasks are obvious and prominent: **+10**
- Upfront about costs and limitations: **+5**
- Saves steps (direct links, smart defaults, autofill): **+5** cada uno
- Graceful error recovery with specific fix instructions: **+10**
- Apologizes when things go wrong: **+5**

Reporta el resultado con dashboard visual:

```
Goodwill: 70 ████████████████████░░░░░░░░░░
  Step 1: Login page        70 → 75  (+5 obvious primary action)
  Step 2: Dashboard          75 → 60  (-15 interstitial tour popup)
  Step 3: Settings           60 → 50  (-10 format punishment on phone)
  Step 4: Billing            50 → 35  (-15 hidden pricing info)
  FINAL: 35/100  CRITICAL UX DEBT
```

Por debajo de 30 = critical UX debt. 30-60 = needs work. Arriba de 60 = healthy.
Los drenajes y recargas más grandes entran al reporte como hallazgos con nombre
propio.

---

## Veredicto y reporte

Un solo reporte al final de la pasada. Estructura:

```
# UI Review — <url> — <fecha>

VEREDICTO: PASS | PASS CON OBSERVACIONES | FAIL
Goodwill: NN/100      Trunk test: PASS/PARTIAL/FAIL
Hallazgos: N high · N medium · N polish
Guidelines de Vercel: traídas el <fecha> (<N> reglas aplicadas)

## Hallazgos HIGH
1. [categoría] Qué está mal — dónde (url → selector, o file:line)
   Evidencia: <medición o screenshot>
   Por qué importa: <impacto en el usuario, no en la estética>

## Hallazgos MEDIUM
…

## Polish
…

## Anti-patrones AI-slop detectados
<lista de los que aplican, con el elemento concreto>

## Capturas
desktop-1440/<página>.png · mobile-390/<página>.png
```

**Criterio del veredicto** (aplícalo tal cual, sin negociar):

- **FAIL** si hay al menos un hallazgo HIGH, o el trunk test da FAIL, o el
  Goodwill queda bajo 30, o se detectan 3 o más anti-patrones de la blacklist
  AI-slop.
- **PASS CON OBSERVACIONES** si no hay HIGH pero sí hallazgos medium.
- **PASS** solo con hallazgos de polish o ninguno.

Cuando corre como gate pre-merge de `qa-engineer`, un FAIL emite
`<<NEEDS-REVISION>>` y el trabajo vuelve a `frontend-builder`. Esta skill no
abre la rama, no toca el código y no vuelve a correr sola.

Las capturas van al directorio del proyecto (por ejemplo
`.ui-review/<fecha>/`), nunca a rutas de sistema. Si el usuario quiere el
reporte en archivo, escríbelo también ahí; si no, va en la respuesta y ya.

---

## Frontera

| Necesito… | Va aquí |
|---|---|
| Auditar el diseño de una web viva, con veredicto | **ui-review** (esta) |
| Que además lo arreglen | `frontend-builder`, o `/impeccable:polish` |
| Probar que la funcionalidad sirve (flujos, formularios, errores 500) | skill `qa-web` |
| Elegir paleta, tipografía, estética, tokens | skill `design-system` |
| El proceso de craft de una UI nueva | `/impeccable:init` y sus hermanos |
| Landing cinematográfica con motion pesado | skill `motion` |

`ui-designer` la invoca en fase de diseño para validar una dirección visual ya
implementada; `qa-engineer` la corre como gate antes de mergear. Los dos reciben
el mismo reporte: esta skill no cambia de criterio según quién pregunte.
