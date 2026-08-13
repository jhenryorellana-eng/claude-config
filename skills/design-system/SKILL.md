---
name: design-system
description: "Base de datos de diseño consultable: 68 estilos, 97 paletas (hex exactos), 57 font pairings, 99 reglas UX, motor de decisión ui-reasoning y guías por stack (React, Next.js, Vue, Svelte, SwiftUI, Flutter, Tailwind, shadcn/ui). Produce propuestas con bloque SAFE/RISK y directiva anti-convergencia (blacklist de fuentes; Space Grotesk cuenta como Inter). Usa cuando se pida 'paleta', 'tipografía', 'font pairing', 'elige el estilo', 'design tokens', '¿qué estética le va a este producto?', o cuando ui-designer arme los datos para DESIGN.md antes de /impeccable:init. NO es el gate visual (ui-review), ni el proceso de craft (/impeccable:*), ni charts (skill dataviz)."
---

# design-system — la base de datos de diseño

Esta skill no opina sola: **consulta**. Debajo de `data/` hay 24 CSV planos
(~476 KB) con estilos, paletas, tipografías, reglas UX y guías por framework,
y debajo de `scripts/` un buscador que los cruza. Tu trabajo es traer los datos
correctos y convertirlos en una propuesta con criterio — no inventar hex ni
recordar fuentes de memoria.

## Qué hay adentro

Conteos reales del repositorio (verificados con `grep -c '^[0-9]\+,'`):

| Archivo | Filas | Para qué |
|---|---|---|
| `data/styles.csv` | 67 | **Elección de estética.** Cada estilo trae keywords, colores primarios y secundarios, efectos y animación con milisegundos, "Best For" / "Do Not Use For", soporte light/dark, nota de accesibilidad, compatibilidad por framework, checklist de implementación y variables de design system listas. |
| `data/colors.csv` | 96 | **Paleta por tipo de producto.** Hex exactos para primary, secondary, CTA, background, text y border, con una nota que explica la lógica del contraste. |
| `data/typography.csv` | 57 | **Font pairing.** Heading + body, mood keywords, "Best For", URL de Google Fonts, `@import` CSS listo para pegar y el bloque `fontFamily` de Tailwind. |
| `data/ui-reasoning.csv` | 100 | **Motor de decisión.** Por categoría de UI: patrón recomendado, prioridad de estilo, mood de color y tipografía, efectos clave, `Decision_Rules` en JSON (condicionales del tipo `if_data_heavy → add-glassmorphism`), anti-patrones y severidad. Este es el archivo que convierte "es un SaaS financiero" en decisiones concretas. |
| `data/ux-guidelines.csv` | 99 | **Reglas Do/Don't.** Categoría, issue, plataforma, descripción, qué hacer, qué no hacer, ejemplo de código bueno y malo, severidad. |
| `data/products.csv` | 96 | Tipo de producto → estilo primario, estilos secundarios, patrón de landing, estilo de dashboard, foco de paleta. |
| `data/landing.csv` | 30 | Estructuras de landing y estrategias de CTA. |
| `data/icons.csv` | 100 | Sets de iconos y criterios de uso. |
| `data/web-interface.csv` | 30 | Guidelines de interfaz web (aria, focus, teclado, semántica, virtualización). |
| `data/react-performance.csv` | 44 | Waterfalls, bundle, suspense, memo, rerenders, cache. |
| `data/charts.csv` | 25 | Solo como referencia cruzada — **para gráficos manda la skill `dataviz`**, no este CSV. |
| `data/stacks/*.csv` | 13 archivos, 49-60 filas c/u | Guía por framework: `astro`, `flutter`, `html-tailwind`, `jetpack-compose`, `nextjs`, `nuxt-ui`, `nuxtjs`, `react`, `react-native`, `shadcn`, `svelte`, `swiftui`, `vue`. |

## Cómo consultar

El buscador vive en `scripts/search.py`, junto a este archivo (instalado suele
ser `~/.claude/skills/design-system/scripts/search.py`).

```bash
# Búsqueda libre — infiere el dominio por las keywords
python scripts/search.py "saas dark dashboard"

# Sistema completo: cruza product + style + color + landing + typography
# y aplica las reglas de ui-reasoning.csv
python scripts/search.py "fintech b2b analytics" --design-system -p "Nombre del Proyecto"

# Dominio específico
python scripts/search.py "elegant luxury serif" --domain typography
python scripts/search.py "glassmorphism dark" --domain style
python scripts/search.py "animation accessibility" --domain ux

# Guía del framework que se va a usar
python scripts/search.py "layout responsive form" --stack nextjs
```

Dominios disponibles: `product`, `style`, `typography`, `color`, `landing`,
`chart`, `ux`, `react`, `web`, `prompt`. Stacks: los 13 archivos de
`data/stacks/`. El flag `-f markdown` cambia la salida de caja ASCII a
Markdown, útil cuando el resultado va a parar a DESIGN.md.

### Fallback cuando no hay Python

En la PC de Mauri `python` **no está en el PATH** (el `python3` de WindowsApps
es el stub del Microsoft Store y falla con un mensaje de instalación). Dos
salidas, en orden de preferencia:

```bash
# 1. uv está instalado y gestiona su propio intérprete
uv run --python 3.12 python scripts/search.py "saas dark dashboard"

# 2. Sin Python: los CSV son planos, se leen con Grep
#    (usa la tool Grep con output_mode "content", no grep por Bash)
```

Grepear directo es un fallback legítimo, no una degradación: los archivos son
CSV sin comprimir y cada fila es autocontenida, con todos sus hex e imports
dentro. Busca `Financial Dashboard` en `products.csv`, `fintech` en
`colors.csv`, `luxury` en `typography.csv`. Lo único que pierdes es el cruce
automático entre dominios que hace `--design-system`; eso lo haces tú leyendo
dos o tres archivos y combinando.

## Toda propuesta lleva un bloque SAFE/RISK

Cuando presentes una dirección de diseño, no entregues una lista de decisiones
sueltas: entrega un sistema, y explica dónde juega seguro y dónde arriesga.

```
AESTHETIC: [dirección] — [rationale de una línea]
LAYOUT: [enfoque] — [por qué encaja con este tipo de producto]
COLOR: [enfoque] + paleta propuesta (hex) — [rationale]
TYPOGRAPHY: [3 fuentes con sus roles] — [por qué estas]
SPACING: [unidad base + densidad] — [rationale]
MOTION: [enfoque] — [rationale]

Este sistema es coherente porque [cómo las decisiones se refuerzan entre sí].

SAFE CHOICES (baseline de la categoría — tus usuarios las esperan):
  - [2-3 decisiones que siguen la convención, con el rationale de jugar seguro]

RISKS (donde el producto gana cara propia):
  - [2-3 desviaciones deliberadas de la convención]
  - Por cada riesgo: qué es, por qué funciona, qué ganas, qué cuesta
```

> The SAFE/RISK breakdown is critical. Design coherence is table stakes — every
> product in a category can be coherent and still look identical. The real
> question is: where do you take creative risks? The agent should always propose
> at least 2 risks, each with a clear rationale for why the risk is worth taking
> and what the user gives up.

Los riesgos pueden ser una tipografía inesperada para la categoría, un acento
que nadie más usa, spacing más apretado o más suelto que la norma, un layout que
rompe la convención, o decisiones de motion con personalidad. Las decisiones
seguras te mantienen legible dentro de tu categoría; los riesgos son lo único
que hace memorable al producto.

## Fuentes: la blacklist manda sobre el CSV

**Font blacklist** (never recommend):
Papyrus, Comic Sans, Lobster, Impact, Jokerman, Bleeding Cowboys, Permanent
Marker, Bradley Hand, Brush Script, Hobo, Trajan, Raleway, Clash Display,
Courier New (for body).

**Overused fonts** (never recommend as primary — use only if user specifically
requests): Inter, Roboto, Arial, Helvetica, Open Sans, Lato, Montserrat,
Poppins, Space Grotesk.

> Space Grotesk is on the list specifically because every AI design tool
> converges on it as "the safe alternative to Inter." That's the convergence
> trap. Treat it the same as Inter: only use if the user asks for it by name.

Cuidado con un choque real: `typography.csv` es una base de datos, no un
curador. Varias de sus 57 filas recomiendan Inter, Poppins u Open Sans porque
el CSV se armó con criterio de popularidad. **La blacklist tiene prioridad
sobre el CSV.** Si la fila que mejor matchea trae una fuente sobreusada como
primaria, sigue buscando o sustituye la display conservando el mood y el
`@import`. Alternativas que el CSV no siempre ofrece —

- **Display/Hero:** Satoshi, General Sans, Instrument Serif, Fraunces, Cabinet Grotesk
- **Body:** Instrument Sans, DM Sans, Source Sans 3, Geist, Plus Jakarta Sans, Outfit
- **Data/tablas:** Geist o DM Sans con `tabular-nums`, JetBrains Mono, IBM Plex Mono
- **Código:** JetBrains Mono, Fira Code, Berkeley Mono, Geist Mono

## Directiva anti-convergencia

> **Anti-convergence directive:** Across multiple generations in the same
> project, VARY light/dark, fonts, and aesthetic directions. Never propose the
> same choices twice without explicit justification. If the user's prior session
> used Geist + dark + editorial, propose something different this time (or
> explicitly acknowledge you're doubling down because it fits the brief).
> **Convergence across generations is slop.**

Antes de proponer, revisa si el proyecto ya tiene un DESIGN.md o una sesión
previa. Repetir la misma combinación sin decir por qué es el fallo más común y
el más difícil de ver desde adentro.

## Anti-patrones de slop (nunca en tus recomendaciones)

- Purple/violet gradients as default accent
- 3-column feature grid with icons in colored circles
- Centered everything with uniform spacing
- Uniform bubbly border-radius on all elements
- Gradient buttons as the primary CTA pattern
- Generic stock-photo-style hero sections
- system-ui / -apple-system as the primary display or body font (the "I gave up
  on typography" signal)
- "Built for X" / "Designed for Y" marketing copy patterns

## La pregunta forzadora

Antes de consultar un solo CSV, haz esta pregunta y consigue una respuesta
concreta:

> **¿Qué es lo único que quieres que recuerden de esta interfaz?**

Si la respuesta es "que se ve profesional" o "moderno", todavía no hay brief —
hay un adjetivo. Insiste hasta llegar a algo que se pueda diseñar: una
sensación, una comparación, una tensión ("un banco que no dé miedo", "denso como
Bloomberg pero legible", "que se sienta hecho a mano"). Esa frase es la que
después desempata entre dos filas del CSV que puntúan igual.

## Self-gates antes de entregar

1. **Never recommend blacklisted or overused fonts as primary.** Si el usuario
   pide una explícitamente, cumple, pero explica el tradeoff.
2. **¿Un diseñador humano se avergonzaría de firmar esto?** Si la respuesta es
   sí o dudosa, no está listo. No es retórica: mira la propuesta e imagina el
   nombre de alguien real debajo.
3. Cada recomendación tiene un "porque". Nunca "recomiendo X" a secas.
4. Coherencia sobre decisiones individuales: un sistema donde cada pieza
   refuerza a las otras le gana a un set de decisiones individualmente óptimas
   pero desalineadas.
5. Al menos 2 riesgos deliberados en el bloque RISK, con su costo declarado.

Cuando el usuario sobrescribe una parte del sistema, verifica que el resto siga
cohesionando y avisa con un empujón suave — nunca bloquees. "Los layouts
editoriales son preciosos pero pelean con la densidad de datos, ¿quieres ver un
híbrido?" es la forma correcta. La decisión final es del usuario, siempre.

## Frontera con las otras skills de diseño

Esta skill son **los datos**. No es el proceso ni el gate.

| Necesito… | Va aquí |
|---|---|
| Paleta, tipografía, estética, tokens, guía por stack | **design-system** (esta) |
| El proceso de craft: iniciar el sistema, refinar, animar, pulir | `/impeccable:init`, `/impeccable:animate`, `/impeccable:polish` |
| Auditar una web viva: gate visual, a11y, AI-slop, score | skill `ui-review` (una pasada, report-only) |
| Gráficos, dashboards de datos, paletas categóricas | skill `dataviz` |
| Landing cinematográfica con video y scroll-driven motion | skill `motion` |

En el pipeline UI del equipo, `ui-designer` invoca esta skill para armar los
datos duros —hex, imports de fuentes, tokens, anti-patrones del tipo de
producto— que van a DESIGN.md, y recién después arranca `/impeccable:init`.
`frontend-builder` la consulta puntualmente vía `--stack` cuando necesita la
guía del framework. Los datos no se copian de memoria: se traen del CSV con su
hex exacto y su `@import` tal cual.
