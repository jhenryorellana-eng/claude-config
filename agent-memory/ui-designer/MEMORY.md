# Memoria de oficio — ui-designer
> Máximo 200 líneas cargadas. Curaduría: agent-ops (2026-08-13).
> Segundo eslabón del pipeline UI: recibe spec UX, entrega dirección visual (tokens,
> tipografía, paleta, jerarquía, spacing) consolidada en DESIGN.md. No escribe .tsx.

## Preferencias de Mauri/Henry
- Español rioplatense/peruano según proyecto; código e identificadores en inglés.
- Windows 11. El tool `Bash` es más confiable que PowerShell para curl e interpolación de strings (PowerShell pierde el `$` cuando viene de `eval -c`).
- Stack por defecto: Next.js + Tailwind v4 + shadcn. Astro 5 cuando el proyecto ya está montado sobre Astro.
- Los valores de marca NORMATIVOS de un documento no se cambian por conveniencia: si un par token falla contraste, se mitiga (icono + texto) y se emite `<<NEED-A11Y-FIX>>` al dueño; lo que sí se corrige es el "chrome" propio del showcase.
- Toda entrega visual se verifica con screenshot de Playwright, light Y dark, con 0 console errors.

## Sistema visual UsaLatinoPrime V2 (el proyecto principal)

- **Marca (bandera de Utah)**: navy `#002855` · blue `#2F6BFF` · gold `#FFC629` · green `#1BB673` · red `#E4002B`. Gradiente de marca `linear-gradient(125deg, #2F6BFF, #FFC629)`. Display: **Plus Jakarta Sans** (next/font/google).
- **Plus Jakarta Sans NO tiene peso 900** (Google la tipa 200–800). Si un doc pide 900 se usa 800 y se documenta `TODO(SoT)`.
- **Dos superficies bajo UN solo switch `[data-theme]`**: móvil (app cliente, default) y desktop staff (scope `.surface-staff`, que sobre-escribe los mismos tokens). Los tokens semánticos light/dark viven en `tokens.css` bajo `[data-theme="light"|"dark"]` y `[data-theme].surface-staff`.
- **shadcn sin pelearse con los tokens de marca**: el `@theme inline` de tokens.css ya mapea `--color-bg/card/accent/...`. En `shadcn-theme.css` mapear SOLO los nombres shadcn-específicos (`primary`, `*-foreground`, `popover`, `destructive`, `border`, `input`, `ring`, charts, sidebar) para no colisionar `--color-accent`/`--color-card` (gana el último `@theme`). El `accent` de shadcn (tint sutil del hover ghost/outline) ≠ accent de marca: dejar `bg-accent` como tint y exponer la acción de marca como `bg-action` (`--color-action: var(--accent)`).
- **shadcn manejado por `[data-theme]`, no por `.dark`**: `@custom-variant dark (&:where([data-theme="dark"], [data-theme="dark"] *));` en globals.css.
- **`npx shadcn@latest init` es inestable**: a veces no instala las deps de runtime ni crea `lib/utils.ts`. Verificar e instalar a mano `clsx tailwind-merge class-variance-authority lucide-react` (+ `tw-animate-css` dev) y crear el `cn()`. components.json: `style:new-york`, `baseColor:neutral`, `cssVariables:true`, `tailwind.config:""`.
- **Tema sin flash**: script inline en el `<head>` del layout que lee `localStorage` (`ulp-theme`/`ulp-text-scale`) antes de hidratar, con fallback a `prefers-color-scheme`, más `suppressHydrationWarning` en `<html>`. Escalas de texto 0.92/1/1.12 vía `[data-text-scale]` + `html{font-size:calc(100%*var(--text-scale))}`.
- **Reglas de estado en CSS, no inline**: cuando un componente Radix necesita estilos por `[data-state]`, `:hover` o `:focus-visible`, van a `motion.css` con clase propia (`.staff-switch`, `.dt-row`, `.nav-item`, `.side-panel-content[data-state=open]`). Los estilos inline no pueden targetear pseudo-clases ni data-attributes.
- **Contraste axe conocido**: los pares token-soft de la marca fallan 4.5:1 — StatusPill green/green-soft 2.37, gold-deep/gold-soft 1.93, accent/blue-soft 3.96. Son normativos del documento y están mitigados con icono + texto (§8.4).
- **`ProgressRing`**: el id del `<linearGradient>` se genera con `React.useId()` para evitar colisión en SSR cuando hay varios rings.
- **Iconografía**: el set de marca `Icon` tiene ~55 nombres; para el panel de Vanessa el prototipo usa **Material Symbols Rounded** (vocabulario mucho más rico) vía componente `MSym` con `fontVariationSettings FILL/wght/opsz`.
- **Rechazo de documento = ÁMBAR, jamás rojo** (RF-CLI-028): botón "Corregir" en `--gold-deep`, tarjeta `gold-soft` con borde gold, eyebrow "Casi listo", pie empático "No hiciste nada mal". El rojo implica fatal; rechazado es corregible.
- **Nunca esconder un control deshabilitado**: un CTA con feature flag apagado se muestra `disabled` con label alterno ("Disponible pronto", "Pronto"), no se oculta. Es anti-patrón esconderlo.
- **Escala tipográfica ampliada para audiencia 50+** (Nexo Mentor): base 17px, lg 20px, 2xl 30px, 3xl 36px. Botones primarios `h-14`, textareas `min-h-32 text-lg leading-relaxed`. La accesibilidad de tamaño es decisión de dirección de arte, no un ajuste posterior.

## Reglas de dirección de arte que ya se validaron

- **Aditivo antes que reescritura**: en un rediseño desktop sobre una app mobile-first, no tocar las clases sin prefijo — solo agregar `md:`/`lg:`/`xl:`. Lo que está debajo del breakpoint queda pixel-idéntico por construcción, y eso es verificable.
- **Split desktop canónico**: `lg:grid lg:grid-cols-[1fr_380px] lg:items-start lg:gap-8`, contenido scrolleable en `<div className="lg:min-w-0">` y lateral en `<aside className="hidden lg:sticky lg:top-6 lg:block">`. El `lg:items-start` es LO que hace que el aside no se estire y el sticky funcione.
- **Duplicar y alternar**: instancia mobile con `lg:hidden` y duplicado desktop en el aside con `hidden lg:block`, ambas apuntando a las MISMAS referencias de handler y estado. Mantiene el DOM mobile intacto y no hay riesgo de estado desincronizado.
- **Regla de promoción al design-system**: un componente sube a `packages/ui` recién cuando lo usan 3+ apps. Si depende de un hook de dominio (`useCart()`), se queda en la app y se extraen helpers puros (`CartLineList`, `CartEmptyState`) para reusar entre hoja mobile y sidebar desktop.
- **No hay dark mode por default**: en delivery hiperlocal peruano se decidió luminoso/diurno por contexto cultural. El dark mode es una decisión de producto, no un default técnico.
- **No usar Inter como display** (es body-only). Para friendly+moderno, Bricolage Grotesque. Sobre convergencia tipográfica: Space Grotesk cuenta como Inter para efectos de la blacklist anti-slop.
- **No motion stack (GSAP/Lenis/SplitType) en una PWA mobile limpia** — es peso sin retorno. El motion se justifica en landings, no en producto.
- **No usar `<input>` para una barra de búsqueda sin funcionalidad**: `<button disabled>` con visual de input evita la disonancia de UX.
- **Estructura validada de landing desktop premium (SaaS-style)**: nav sticky transparente → blur al scrollear (umbral 12px) · hero split 50/50 con tipografía masiva (clamp 48-86px) + device embebido + chips flotantes · "cómo funciona" en 4 pasos · grid destacado 3 cards aspect 4/3 · 3 feature cards con UNA de acento como ancla visual · split inverso con mapa estilizado + stats · CTA full-bleed con gradiente · footer oscuro de 4 columnas.
- **Layout dual mobile/desktop en un solo index**: wrappers `.layout-mobile` / `.layout-desktop` toggleados por media query. `display:none` suprime la altura por completo (verificado: el wrapper queda 0px), así que no afecta el scroll.

## Recetas visuales reusables

- **Mockup de iPhone**: dimensiones reales del 15 son 393×852; para mockup con padding holgado usar **402×874**. Dynamic island 126×37 (top 11, radio 24, `#000`); status bar 62px con "9:41" en `-apple-system/SF Pro Text` 600/17px; home indicator 139×5 (bottom 8, radio 100, `rgba(0,0,0,.25)` light). En mobile real (≤480px) **disolver el marco**: padding 0, 100dvh, esconder island/statusbar/home porque los provee el SO.
- **`IconTile`/`IconHalo` con tokens CSS**: el truco del prototipo de concatenar hex-alpha (`${color}2e`) NO sirve con `var(--accent)`. Usar `color-mix(in srgb, ${color} X%, transparent)` — radial mix(18)/mix(7) + boxShadow inset mix(15).
- **Damero**: `repeating-conic-gradient(color 0% 25%, transparent 0% 50%) 0 0/20px 20px`. **Grano**: SVG `feTurbulence` inline como data URI, opacity .04-.05. **Glass**: rgba + `backdrop-filter: blur(12px)` + borde rgba.
- **Reveal con IntersectionObserver** (10 líneas, sin librerías): `threshold: 0.12`, `rootMargin: '0px 0px -8% 0px'`, `unobserve` al revelar; CSS `[data-reveal]{opacity:0;transform:translateY(24px)}` + `.is-revealed{opacity:1;transform:none}`; stagger con `style="--delay:${i*100}ms"`. `prefers-reduced-motion: reduce` neutraliza todo.
- **GIF pesado → WebP animado con `sharp`** (en Windows no hay gifsicle ni ImageMagick reales; el `convert.exe` del sistema NO es ImageMagick): `sharp(src,{animated:true}).resize({width}).webp({quality,effort:4,loop:0})`. Un GIF de 9.5MB (150 frames, 400px) a q40/w272 quedó en 0.977MB. Con `effort:6` tarda minutos; usar 4. Servir con `<picture><source webp><img gif></picture>`.
- **Astro 5 + Tailwind v4**: la integración es `@tailwindcss/vite` (`@astrojs/tailwind` está deprecado). En `global.css`: `@import "tailwindcss"` + bloque `@theme { --color-x: ...; --font-display: "..." }` genera automáticamente `text-x`, `bg-x`, `font-display`. Cambiar `astro.config.mjs` exige reiniciar el dev server (el HMR no toca la config).

## Evidencia visual (harness de Playwright)

- Sin MCP disponible: `node scripts/shoot.cjs` con `require('playwright')` resuelto desde el `node_modules` LOCAL del proyecto — un `.cjs` en `/tmp` no resuelve. En usalatino-v2 los harness van en `docs/_evidence/` (que eslint ignora).
- Desktop 1440×900/960; mobile 390×844 con `deviceScaleFactor:2`, `isMobile:true` y UA de iPhone. `waitUntil:'networkidle'` + `waitForTimeout(900)` para que carguen las fuentes y resuelvan los backdrop-filters.
- **Tema en la captura**: `addInitScript` seteando `localStorage` ANTES de hidratar, y `page.evaluate` seteando `data-theme` en `documentElement` DESPUÉS de cargar (el script no-flash lo lee de localStorage).
- **Ruido a filtrar en consola** (artefactos, no bugs): `/hydrat|caret-color|extension|DevTools|pdf.worker|fake worker/`. El hydration-mismatch del `SwitchBubbleInput` de Radix (por inyección de `caret-color` de una extensión) y el del ThemeToggle al inyectar el tema pre-hidratación son del harness, no del código.
- **Artefactos visuales de dev**: `<astro-dev-toolbar>` en Astro (matar con `addInitScript` que inyecta `astro-dev-toolbar{display:none!important}`) y el badge "N" de Next dev abajo a la izquierda. No son UI.
- **Páginas auth-gated**: no se capturan logueadas sin sesión real. La solución establecida es una ruta de preview pública (`(dev)/admin-preview/[view]`, `(dev)/cliente-preview/[view]`, `(dev)/ventas-preview/[view]`) con `notFound()` si `NODE_ENV==='production'`, agregada a los prefijos públicos del middleware y alimentada con mocks. Con `@supabase/ssr` la sesión vive en COOKIES, no en localStorage.
- **Playwright en Windows sin instalación global**: hay chromium cacheado en `%LOCALAPPDATA%/ms-playwright/`; instalar `playwright-core` en el scratchpad y lanzar con `chromium.launch({executablePath: <headless shell cacheado>, headless:true})` para saltear el check de revisión.
- Un mismo browser context PERSISTE localStorage entre capturas: sembrar estado una sola vez contamina las siguientes. Usar contexts separados si se quiere estado limpio.
- **Herramientas de escritura**: los scripts one-off de i18n/mocks se escriben como archivo con la herramienta Write, NUNCA con heredoc de bash — se rompe con acentos, emoji, apóstrofes y «». Para JSON grandes de i18n, round-trip con Node es lo más seguro.

## Índice de archivos temáticos
- Archivo: bitácora visual por fase de UsaLatinoPrime V2 (F0→F4-Ola3, verbatim) → `archive-usalatino-fases-ui.md`
- Archivo: proyectos freelance (Tindivo, Nexo Mentor) y recetas Astro/mockups → `archive-proyectos-freelance.md`
