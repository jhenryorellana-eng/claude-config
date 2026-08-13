# Archivo — proyectos freelance y recetas visuales reusables

> Curaduría agent-ops 2026-08-13. Verbatim, movido desde `MEMORY.md` (tope de 200
> líneas cargadas). Cubre Tindivo (PWA delivery peruano), Nexo Mentor / hgw-platform
> (PWA para audiencia 50+), recetas de Astro 5, mockup de iPhone y el patrón de reveal
> con IntersectionObserver.

---

### Tindivo customer — additive tablet/desktop responsive (mobile-first 1:1 app)
- App es mobile-first (402×874); cada `<main>` usa `max-w-[768px]`. Rediseño desktop = 100% aditivo con `md:`/`lg:`/`xl:`. Nada bajo `md` cambia → mobile queda pixel-idéntico por construcción.
- Patrón split desktop: `<main ... lg:grid lg:max-w-7xl lg:grid-cols-[1fr_380px] lg:items-start lg:gap-8 lg:px-6>`. Envolver el contenido scrolleable en `<div className="lg:min-w-0">` (1 grid item) y el lateral en `<aside className="hidden lg:sticky lg:top-6 lg:block">`. `lg:items-start` es CLAVE para que el aside no se estire y el sticky funcione.
- Header/topbar compartido en grid: envolver en `<div className="lg:col-span-2">` para que abarque ambas columnas (auto-flow coloca el resto en fila 2).
- Listas → grid responsivo: `flex flex-col gap-2.5` + `lg:grid lg:grid-cols-2` (el `lg:grid` pisa `display:flex`; `flex-col` se ignora bajo grid). Home: `grid-cols-1 md:grid-cols-2 lg:grid-cols-3`.
- Patrón "duplicar y alternar": instancia mobile con `lg:hidden`, duplicado desktop en aside `hidden lg:block`. Mantiene el DOM mobile literalmente intacto.
- Cascada CSS conocida: `packages/ui/src/components.css` se importa DESPUÉS de Tailwind → `.t-section-tabs`/`.t-sticky-cta` ganan a utilidades Tailwind de IGUAL especificidad. PERO `lg:hidden` (display:none) SÍ funciona sobre `.t-sticky-cta` porque esa clase no declara `display` (no hay conflicto de propiedad). No pelear la cascada para otras props: envolver en wrapper.
- CartSidebar (bolsa fija desktop) vive en `apps/customer/components/cart-sheet.tsx`, NO en packages/ui (regla design-system: 3+ apps antes de promover; depende de `useCart()`). Extraer helpers `CartLineList({lines})`/`CartEmptyState()` y reusarlos en hoja (mobile) + sidebar (desktop).
- Realidad piloto: home con 1 solo restaurante quedaría vacío en grid 3-col; verificar el conteo real antes de asumir. (En verif. había 5 → grid lleno.)

### Playwright en Windows sin instalación global (tindivo)
- No hay playwright global ni en repo, PERO hay chromium cacheado en `%LOCALAPPDATA%/ms-playwright/` (p.ej. `chromium_headless_shell-1228/chrome-headless-shell-win64/chrome-headless-shell.exe`).
- Instalar `playwright-core` en scratchpad y lanzar con `chromium.launch({ executablePath: <cached headless shell>, headless:true })` (evita el check de revisión).
- Seed del carrito para capturas: `localStorage.setItem('tindivo-cart-v1', JSON.stringify({state:{businessId,businessName,lines:[...]},version:0}))` y `reload()` (CartHydrator rehidrata). Gotcha: un mismo browser context PERSISTE localStorage entre snaps → seedea una sola vez y contamina los siguientes (badge "3" aparece en home). Usar contexts separados si se quiere estado limpio.
- Páginas con auth (`@supabase/ssr` = sesión en COOKIES, no localStorage): checkout/cuenta/pedidos NO se pueden capturar logueadas sin sesión real (OAuth/OTP); sin sesión muestran el sheet de onboarding o redirigen a /entrar. Verificar esas por build+biome+type-check + patrón aditivo idéntico al ya probado.
- El `<main>` con `next build` y `next dev` comparten `.next`; en Next 16 Turbopack el dev (:3000) sobrevivió a un `next build` concurrente (siguió 200). Aun así, hacer capturas ANTES del build.

### Astro 5 + Tailwind v4 — custom font tokens
- Tailwind v4 ya está integrado en Astro 5 via `@tailwindcss/vite` (NO `@astrojs/tailwind`, está deprecado).
- En `src/styles/global.css`: `@import "tailwindcss"` + bloque `@theme { --color-x: ...; --font-display: "..."; }` auto-genera utilities `text-x`, `bg-x`, `font-display`.
- `font-display` token funciona out-of-the-box con Google Fonts CDN sin config adicional. Solo cargar el `<link>` en Layout y declarar `--font-display`.

### iPhone frame mockup (PWA showcase)
- Dimensiones reales iPhone 15: 393×852. Para mockup visual con padding holgado, usar **402×874**.
- Dynamic island = 126×37, top:11, border-radius:24, fondo `#000`.
- Status bar 62px alto con time "9:41" (font: `-apple-system, SF Pro Text`, weight 600, size 17px).
- Home indicator: 139×5, bottom:8px, border-radius:100px, `rgba(0,0,0,0.25)` light / `rgba(255,255,255,0.7)` dark.
- En mobile real (≤480px) **disolver** el frame: padding 0, height 100dvh, esconder island/statusbar/home (el OS los provee).
- Inner screen es `position:absolute; inset:0; border-radius:48px; overflow:hidden`.

### Tindivo color palette (food delivery, peruano)
- `--color-brand: #F97316` (orange Tailwind 500) + `--color-brand-hover: #EA580C` (600) + `--color-brand-deep: #C2410C` (700).
- `--color-ink: #1A1614` (no-puro-negro, cálido).
- `--color-surface: #FAF6F1` (cream-paper) dentro del frame.
- `--color-stage: #ECEAE5` (warm gray) fuera del frame.
- Gradient hero: `linear-gradient(135deg, #F97316 0%, #EA580C 50%, #C2410C 100%)` + shadow `0 12px 32px -10px rgba(249,115,22,0.45)`.

### Typography (PWA/product oriented, no editorial)
- **Bricolage Grotesque** (variable opsz 12-96, wght 200-800) → display. Free Google Font, soporta opsz.
- **Geist** (400-600) → body sans, alternativa moderna a Inter.
- **JetBrains Mono** (400, 500) → micro-labels, eyebrows, version tags.
- URL Google Fonts combinado:
  `https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,400;12..96,500;12..96,600;12..96,700&family=Geist:wght@400;500;600&family=JetBrains+Mono:wght@400;500&display=swap`

### Restaurant card pattern (food delivery)
- Card blanco border-radius:20, padding:12, gap:14.
- Thumbnail 88×88, border-radius:14, foto Unsplash con `background-color: oklch(0.92 0.04 <hue>)` como fallback antes que cargue.
- Estados `open` vs `soon`: para `soon` aplicar `opacity:0.4; filter:grayscale(1); cursor:not-allowed` + `aria-disabled="true"`. Esconder ETA/fee meta.
- Badge "Más pedido" (orange tint translúcido) ENCIMA del nombre con mb:4, font-size:9, weight:700, letter-spacing:0.08em, upper.

### Playwright screenshot harness (sin MCP)
- Cuando no hay `mcp__playwright__*` tools, usar `playwright` directo via `node scripts/shoot.cjs`.
- Script en `<project>/scripts/shoot.cjs` resuelve `require('playwright')` desde el `node_modules` local del proyecto.
- Capturar console errors + pageerror + requestfailed en arrays separados antes de cerrar contextos.
- Desktop default: 1440x900. Mobile: 390x844 + `deviceScaleFactor:2` + `isMobile:true` + UA iPhone.
- `waitUntil:'networkidle'` + `waitForTimeout(900)` para que fonts terminen de cargar y backdrop-filters resuelvan.

### Astro single-component patterns
- Componente con `Fragment` + JSX condicional puro funciona si el componente exporta solo el Fragment como root. NO meter <style scoped> en cada rama — ponerlo después del Fragment.
- `set:html` para inyectar JSON-LD: `<script type="application/ld+json" set:html={JSON.stringify(schema)} />`.
- Para tomar la URL canonical: `new URL(Astro.url.pathname, Astro.site).toString()`.
- Cambiar `astro.config.mjs` (e.g. `site:`) REQUIERE matar dev server y reiniciar (HMR no toca config).

### User profile (Mauri)
- Idioma: español rioplatense / peruano (según proyecto), código en inglés.
- OS: Windows 11. Shell preferido: PowerShell, pero el `Bash` tool funciona y es más confiable para curl/string interpolation.
- PowerShell pierde `$` en interpolación cuando viene de `eval -c` — preferir Bash para curl checks.
- Stack default: Next.js 15 + Tailwind v4 + shadcn, pero también usa Astro 5 cuando el proyecto ya está montado.

### Anti-patterns evitados en Tindivo landing
- NO motion stack (GSAP/Lenis/SplitType) — innecesario para PWA mobile clean.
- NO dark mode en delivery hiperlocal peruano (luminoso/diurno por contexto cultural).
- NO usar Inter como display (es body-only). Bricolage Grotesque mucho mejor para friendly+modern.
- NO usar `<input>` para search bar si no hay funcionalidad — usar `<button disabled>` con visual de input (evita UX disonante).

### Responsive dual-layout pattern (mobile app + desktop landing)
- Cuando tenés app PWA mobile + desktop marketing landing, mantener AMBOS en `index.astro` con wrappers `.layout-mobile` / `.layout-desktop` toggled por media query.
- Default mobile-first: `.layout-mobile { display: block }` / `.layout-desktop { display: none }`, swap at `@media (min-width:1024px)`.
- El display:none totalmente suprime height (verificado: el wrapper queda 0px) — no afecta scroll.
- iPhone frame embebido en hero desktop: scale 0.78, rotateY -6deg, drop-shadow naranja. Reutilizar todos los componentes mobile dentro del IOSFrame.
- Esconder `.ios-home` en desktop (no tiene sentido fuera de un device real) via rule global con `:global` puede fallar — usar selector específico en `global.css`: `.hero__phone-wrap .ios-home { display: none !important; }`.

### Astro Dev Toolbar interfiere en screenshots
- En dev mode aparece `<astro-dev-toolbar>` flotante en bottom. Aparece en screenshots como una barrita pequeña.
- Solución para script Playwright: `addInitScript` que inyecta `<style>astro-dev-toolbar{display:none!important}</style>` en `document.head || document.documentElement`. Cuidado con timing: el init script corre antes de DOM ready.

### Desktop landing structure (SaaS-style, validated 2026)
Pattern profesional para app landing desktop premium:
1. Sticky top nav transparent → blur on scroll (12px threshold)
2. Hero split 50/50: typography masiva izquierda (clamp 48-86px Bricolage) + iPhone con app embebida derecha + floating chips de contexto
3. "Cómo funciona" 4 steps grid (cards cream con número gradient + icon SVG stroke)
4. Featured grid 3 cards aspect 4/3 (badge + soon overlay)
5. 3-column feature cards (1 accent gradient naranja como anchor visual)
6. Split inverso con SVG stylized map + 3 stats inline
7. Full-bleed CTA naranja gradient (mismo blob + glow + grain que mobile hero)
8. Dark footer 4-column con brand mark + producto + soporte + vendors

### Nexo Mentor (hgw-platform) — PWA MLN, audiencia 50+ (Next.js 16 + Tailwind v4)
- Stack: Next.js **16.2.6** (App Router, middleware es `src/proxy.ts` exporta `proxy()` NO middleware.ts), React 19, Tailwind v4, TS strict, data invertida vía `getRepositories()` (`@/data`), Supabase activo (`NEXT_PUBLIC_DATA_SOURCE=supabase`).
- **Design system (tokens en `src/app/globals.css`):** brand = teal `--color-brand-600:#0f766e` (50=#ecfdf5), gold = `--color-gold-400:#f59e0b`. `.gradient-brand` (135deg #0f766e→#164e63), `.gradient-gold`. Radius uniforme `var(--radius-lg/md)`=0.5rem. **Escala tipográfica AMPLIADA para 50+**: base=17px, lg=20px, 2xl=30px, 3xl=36px. Light-first, `.dark` via CSS vars.
- **Lenguaje visual establecido (replicar EXACTO):** secciones = `<section>` con `rounded-[var(--radius-lg)] border border-border bg-card p-5 shadow-sm sm:p-6`. Header de sección = pill `size-12 gradient-brand text-white` + `h2 font-display text-2xl font-bold tracking-tight` + `p text-base leading-relaxed text-muted-foreground`. Botones primarios `h-14 w-full cursor-pointer text-lg`. Textareas `min-h-32/36 text-lg leading-relaxed`. Disclaimer = `rounded-[var(--radius-md)] bg-muted p-4 text-base leading-relaxed text-muted-foreground`. Panel cálido = `bg-brand-50 border-brand-200 ... dark:bg-brand-900/20 dark:border-brand-900/50`.
- **Patrón IA real (loading anunciado):** estado de carga = div `role="status" aria-live="polite"` con `Loader2 animate-spin` en pill brand-100. Llamada `fetch('/api/ai/*')` con `idempotencyKey: crypto.randomUUID()`; manejar `response.status===503` con toast "IA ocupada, intenta en unos segundos" (rate-limit tier gratis, NO es bug; reintentar). `sonner` para toasts, `router.refresh()` tras server action para refrescar server components.
- **Gamificación legal (CRÍTICO §5.2.3):** se premia ACTIVIDAD/esfuerzo, NUNCA dinero/ingresos/ganancias. `ActivityStats{totalPoints,weekCount,streakDays,byKind}`, `ACTIVITY_KIND_LABELS`, `ACTIVITY_POINTS` (learning_logged=8). Logros derivados en cliente desde stats (desbloqueado vs `Lock` dashed). Frase obligatoria visible: "Se premia tu actividad y constancia, no resultados económicos".
- **Arquitectura de feature:** server component orquestador (sin "use client") que importa solo el sub-componente interactivo como cliente (ej. `anti-rejection.tsx` server → importa `RejectionJournal` client). Bloques estáticos/listas como server components puros (mejor perf). Patrón espejo de `prospect-detail` → `conversation-assistant`.
- **Verificación:** `npm run typecheck` + `npm run lint` desde `HGW/`. Login demo: `/login` → click `button` con texto del nombre ("Sofia"). Sofia Castro sembrada: streak 3d, ~10 actividades, 2 aprendizajes. Password demo `NexoDemo2026!`.
- **Playwright harness (`scripts/shoot-*.cjs`, playwright local):** login click botón perfil → `waitForURL(!/login)`. Tema: `addInitScript` set `localStorage.theme`. **OJO**: inyectar el tema antes de hidratar produce 2 console-errors de hydration-mismatch en `<ThemeToggle>` (aria-pressed) — es ARTEFACTO del harness en dark, NO bug del código (light mode = 0 errores). `grantPermissions(['clipboard-*'])` para botones Copiar. Gemini puede tardar → timeout 45s esperando el heading del resultado.
- **a11y recurrente:** botón solo-icono (avatar trigger en `user-menu.tsx`) sin texto → axe `button-name` critical. Fix: `aria-label`. Verificar con axe-core (`require.resolve('axe-core/axe.min.js')` + `addScriptTag`).
- **LOGIN actualizado (ya NO es selector demo):** `/login` tiene `#email` + `#password` + `button[type=submit]` ("Entrar"), `signInWithPassword` real. Admin plataforma: `admin@mercadeo.com` / `dv2PERud6n5%@`. Tras login → redirige a `/`. (El password demo `NexoDemo2026!` quedó obsoleto para este flujo.)
- **Hub de admin por negocio (jun 2026):** `/admin` = overview (admin plataforma: grid de tarjetas de negocio + modal "Crear negocio"; leader con businessId → `redirect(adminBusinessPath(...))`). Layout `admin/[businessId]/layout.tsx` = `BusinessHubHeader` (avatar gradient `linear-gradient(135deg, primaryColor, accentColor)` con iniciales, chip estado, Copiar link de registro, ← Todos los negocios solo admin) + `AdminTabs` client (`usePathname`, rail scrollable, tab activa = `bg-brand-600 text-white`). 7 pestañas: resumen/academia/audiolibros/novedades/mensajes/lideres/ajustes (constantes `ADMIN_TABS`/`adminBusinessPath` en `@/lib/constants`). Subruta lecciones: `academia/[courseId]/page.tsx` carga `academy.getCourseById` (CourseWithContent). **Densidad admin** vs app cliente: helpers en `admin-ui.tsx` (`ManagerCard`/`ManagerHeader`/`ManagerRow` filas densas con acciones inline/`NoticePanel`). Server pages cargan datos + pasan a client managers; mutaciones = `useTransition` + server action + `router.refresh()` + `sonner`; eliminar = `window.confirm` antes.
- **Multi-tenant en UI:** plantillas de mensaje `businessId===null` = "Base global" solo-lectura (badge "Solo lectura" + NoticePanel); `businessId===biz` = CRUD. Admin plataforma tiene `business_id=null` → en vistas cliente (`/audiolibros` etc.) solo ve contenido global (null), NO el de negocios concretos (es correcto, no bug). `MessageTone` NO tiene labels en types.ts → crear `MESSAGE_TONE_LABELS` local (calm/warm/direct/reactivation).
- **FileUpload (`src/components/ui/file-upload.tsx`):** sube DIRECTO a Storage (`business-media` bucket, `{businessId}/{folder}/{uuid}.{ext}`) vía cliente browser, llama `onUploaded({url,path,durationSeconds})`; `url===""` = quitado. Solo acepta `video|audio|image` (PDF NO soportado → usar input URL para PDF). Estado "done" → botón muestra `{filename} — cambiar`. **En Playwright:** apuntar `input[type=file][accept="video/*"|"audio/*"|"image/*"]` (sr-only, setInputFiles funciona en hidden) y esperar `button:has-text("{path.basename(file)}")` — NO esperar texto "cambiar" genérico (ambiguo con varios uploads en un modal). Verificado: 2 uploads (cover+audio) en un modal funcionan así.
- **ffmpeg de Playwright (`$LOCALAPPDATA/ms-playwright/ffmpeg-XXXX/ffmpeg-win64.exe`) es MÍNIMO:** solo vp8/webm, png-encoder, mjpeg-decoder; SIN lavfi, h264, aac, mp3, wav-demuxer. Para media de prueba: WAV + PNG escribir a mano en Node (headers triviales); WebM válido bajar base64 de `github.com/MylesBorins/webm-test`. MIMEs que pasan FileUpload: `video/webm`, `audio/wav`, `image/png`. Verificar persistencia real con REST: `GET /rest/v1/audiobooks?...&select=audio_url` y comprobar `/storage/v1/object/public/` en la URL.

### IntersectionObserver vanilla reveal pattern (10 líneas)
```js
const targets = document.querySelectorAll('[data-reveal]');
if (targets.length && 'IntersectionObserver' in window) {
  const io = new IntersectionObserver((entries) => {
    for (const e of entries) if (e.isIntersecting) {
      e.target.classList.add('is-revealed'); io.unobserve(e.target);
    }
  }, { threshold: 0.12, rootMargin: '0px 0px -8% 0px' });
  targets.forEach((el) => io.observe(el));
}
```
- CSS: `[data-reveal] { opacity:0; transform:translateY(24px); transition:... }` + `.is-revealed { opacity:1; transform:none }`
- Stagger delays via `style="--delay:${i*100}ms"` + `transition: ... var(--delay)`.
- `prefers-reduced-motion: reduce` neutraliza con `opacity:1; transform:none; transition:none`.
