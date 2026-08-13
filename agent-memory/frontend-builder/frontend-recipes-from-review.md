# Recetas de frontend rescatadas de las revisiones de code-reviewer

> Curaduría agent-ops 2026-08-13. Estos bloques vivían en `code-reviewer/MEMORY.md`
> pero son conocimiento de IMPLEMENTACIÓN, no de revisión. Verbatim, sin recortar.
> Archivo temático: no cuenta para el tope de 200 líneas del MEMORY.md.

---

## Astro + motion stack (olivar-landing)

### Astro + CDN globals pattern
- When GSAP/Lenis/SplitType are loaded via CDN `is:inline` scripts, component `<script>` blocks that import from local lib files must use a `waitForGlobal()` polling pattern to avoid race conditions. Polling with `setTimeout` (50ms, 60 retries) is the established pattern in this codebase.
- Astro bundles `<script>` (no directive) separately from `is:inline`. Imports from local TS lib files work inside bundled scripts; they do NOT have access to CDN globals at module parse time — only at runtime, hence the polling approach.

### `scroll-behavior: smooth` + Lenis conflict
- `scroll-behavior: smooth` on `html` element causes ScrollTrigger refresh/pin bugs in some browsers. The correct fix is to override it to `auto` via `.lenis.lenis-smooth { scroll-behavior: auto !important; }`. Flag if ever removed.

### `will-change` in global CSS — known performance smell
- Applying `will-change: transform` statically in CSS on `.split-char`, `.char`, `.tilt-card`, `.marquee__track` promotes ALL those elements to GPU layers at paint time, even before animation. For landing pages with many splits, this can cause excessive GPU memory. The pattern to prefer: set `will-change` dynamically in JS right before animating, remove in `onComplete`. The motion.ts library does this correctly; the global.css declarations are redundant and slightly wasteful.

### SplitType + GSAP `yPercent` trick
- Wrapping parent element needs `overflow: hidden` on the `.split-word`/`.word` class for the "slide up from below" effect. If ever removed, the character animation leaks outside its container.

### GSAP ScrollTrigger cleanup in Astro (SPA concern)
- In a static Astro site (`output: static`) there is no client-side routing by default, so ScrollTrigger instances persist for the full page lifetime — cleanup is not necessary. If View Transitions are ever added, all ScrollTrigger instances must be killed and Lenis destroyed in the `astro:before-swap` event.

### Marquee `data-dir` attribute referenced but never set
- `initMarqueeVelocity()` reads `track.dataset.dir` to determine direction, but Marquee.astro never sets that attribute. All tracks always go left. Harmless visually, but the reverse-direction feature is silently dead.

### og:type "restaurant" is non-standard
- The Open Graph protocol does not define a "restaurant" type. Valid values include "website", "article", etc. Using "restaurant" is harmless (falls back to "website" in most parsers) but technically incorrect per OGP spec.

---

## Tindivo v2 — tipografía y responsive

### Manrope-only typography migration (2026-06-30)
- All 4 apps (`customer`, `motorizados`, `admin`, `negocios`) load 3 `Manrope({...})` instances per `layout.tsx`, keeping the original CSS variable names (`--font-bricolage` 600/700/800, `--font-geist` 400/500/600, `--font-jetbrains` 500/600/700). Manrope supports weights 200-800, so all requested weights are valid for `next/font/google`.
- Consuming code swapped literal `'JetBrains Mono'`/`monospace` fallbacks to `'Manrope'`/`sans-serif` in `apps/negocios/app/dashboard-tokens.css`, `primitives.tsx`, `pedido-detail.tsx`, `nuevo/page.tsx`. One spot missed: `packages/ui/src/theme.css`'s `--font-mono: var(--font-jetbrains), ui-monospace, monospace;` still has the old literal fallback — harmless (the var always resolves first) but inconsistent.
- `apps/*/public/icon.svg` reference `font-family="Bricolage Grotesque, Arial, sans-serif"` as static SVG brand-mark text — NOT part of the next/font system, correctly out of scope for a "no hardcoded font literal" grep.

### Responsive additive pattern — dos enfoques, ambos seguros
- Preferido (usado en `cuenta/page.tsx`, `negocio/[id]/page.tsx`): dejar las clases sin prefijo intactas (`flex flex-col gap-2.5`) y solo APPEND `lg:grid lg:grid-cols-2 lg:gap-3`. La cascada de Tailwind deja que las utilidades `lg:` pisen `display:flex`; por debajo del breakpoint el comportamiento flex queda 100% intacto.
- Segundo patrón (en `apps/customer/app/page.tsx`, `pedidos/page.tsx`): cambiar la clase base de `flex flex-col gap-2.5` a `grid grid-cols-1 gap-2.5 md:grid-cols-2 lg:grid-cols-3`. Para hijos block-level (`<Link>`, `<div>`) es visual y funcionalmente idéntico en el breakpoint base, así que no es regresión — pero viola un instructivo de "additive-only, nunca tocar clases sin prefijo" si se dio uno. Recomendar el primero por consistencia.

### Checkout duplicate-CTA desktop/mobile — patrón canónico seguro
- `apps/customer/app/checkout/page.tsx` renderiza el botón CTA dos veces (desktop `<aside hidden lg:block>` y mobile `<div class="t-sticky-cta lg:hidden">`), pero ambas copias llaman a las MISMAS referencias de función (`goToPayment`/`placeOrder`) y leen el mismo estado `loading`/`locating` — sin riesgo de estado desincronizado. Este es el patrón seguro de "render duplicado, handler compartido" para el trabajo responsive split-screen.
- El store del carrito (`apps/customer/lib/cart.ts`) es mono-negocio por diseño: `cart.lines` siempre pertenece al único `cart.businessId` activo. `CartSidebar` (en `cart-sheet.tsx`) guarda con `cart.businessId === businessId` antes de renderizar líneas.

### useCatalogSearch — AbortController + debounce + useRef (implementación de referencia)
- `apps/customer/lib/use-search.ts` combina debounce (`setTimeout`) con un AbortController guardado en `useRef` (no en state, evitando renders extra), y chequea defensivamente `controller.signal.aborted` antes de CADA `setState` tanto en `.then` como en `.catch` — protege contra respuestas rancias/fuera de orden aunque el cliente HTTP no cancele de verdad. Coincide con la best-practice 2026 (el debounce solo no previene race conditions; hay que combinarlo con AbortController + chequeo al resolver). Buen patrón de referencia para futuros hooks de búsqueda con debounce.

---

## React Three Fiber (carnivoro-pe, revisado 2026-07-16)

### `setFrameloop('never'/'always')` resetea `clock.elapsedTime` silenciosamente — clase BLOCKER
- `@react-three/fiber@9.6.0`'s store `setFrameloop` hace incondicionalmente `clock.stop(); clock.elapsedTime = 0;` y, al pasar a un valor distinto de 'never', `clock.start(); clock.elapsedTime = 0;` otra vez — confirmado leyendo `node_modules/@react-three/fiber/dist/events-*.cjs.dev.js`. Cualquier componente que alterne `frameloop` entre `'never'`/`'always'` (p.ej. para pausar el render cuando el canvas sale de pantalla) resetea `state.clock.elapsedTime` a 0 en AMBAS transiciones.
- Cualquier `useFrame` que derive la fase de animación de `state.clock.elapsedTime` (sobre todo motion con módulo/loop — `life = (t * speed + phase) % 1`) va a SALTAR visiblemente al reanudar, porque el siguiente frame recalcula desde `t≈0`. El pop ocurre en el primer frame tras reanudar, es decir justo cuando el contenido vuelve a ser visible.
- `invalidate()` también es no-op mientras `state.frameloop === 'never'` (early-return guard en el source), así que llamarlo justo después de `setFrameloop('never')` no hace nada.
- Fix: capturar `clock.elapsedTime` en un ref antes de pausar, restaurarlo manualmente justo después de `setFrameloop('always')` (deshaciendo el reset de la librería) y antes de `invalidate()`. NO confiar en que la librería preserve el tiempo entre toggles.
- Regla general: si un diff introduce `setFrameloop`/maquinaria pause-resume, grepear cada `useFrame` de la escena por `state.clock.elapsedTime` / `clock.getElapsedTime()` y ver si alguno maneja motion con módulo — ese es el tell confiable de esta clase de bug.

### `React.lazy()` dentro de un árbol Canvas/3D sin ErrorBoundary — riesgo de crash de página entera
- Convertir un componente importado estáticamente a `lazy(() => import(...))` para bundle-splitting introduce un modo de falla NUEVO (fallo de fetch del chunk: red inestable, ad-blocker, caché rancia tras deploy) que no existía cuando estaba bundleado. El App Router de Next.js solo auto-recupera ChunkLoadError para chunks de navegación de ruta, NO para un `React.lazy()` suelto dentro de un árbol de componentes.
- Si la app no tiene `error.tsx` / ErrorBoundary (chequear con `grep -r "ErrorBoundary\|error.tsx\|global-error" src/`), un fallo de carga de chunk tumba la página entera, no solo la feature perezosa. Es desproporcionado cuando lo lazy es un realce cosmético (p.ej. postprocessing).
- Fix: envolver el `Suspense` de todo componente nuevo lazy y no crítico en un ErrorBoundary de clase chico que degrade con gracia (saltear el realce, no crashear).

---

## Patrones de React/Next.js de app

### Handler async que setea busy sin `finally` — smell recurrente
- `onDownloadForm` en `fases-anteriores-tab.tsx` llama `setBusyForm(responseId)` antes de esperar `getFilledPdfUrl`, y `setBusyForm(null)` después. Si la action tira a nivel de transporte (error de red, sesión expirada), el `setBusyForm(null)` se saltea y el botón queda deshabilitado para siempre en esa sesión. Regla: TODO event handler async que setea un flag de loading/busy DEBE envolver el await en try/finally para garantizar que el flag se limpia. Los server actions de Next.js sí tiran en el callsite ante fallo de red.

### Toggle "revertir a X" respaldado solo por un booleano — pierde el valor original
- `WebResearchField` (form-wizard/fields.tsx) tiene un toggle "Corregir a mano" / "Volver al resultado de la IA" respaldado por un solo `const [manual, setManual] = useState(false)`. Al clickear "Volver al resultado de la IA" solo se vuelve `manual` a `false` (re-bloqueando el textarea) — NO restaura el resultado original de la IA. El texto que esté en la caja (incluida una edición manual hecha con `manual===true`) queda tal cual, ahora presentado falsamente como si fuera el valor verificado por la IA.
- Regla reusable: todo botón "revertir a X" / "volver a Y" debe estar respaldado por un SNAPSHOT del valor al que se revierte (un ref/state separado capturado en el momento en que X se produjo), no por un booleano de modo que reusa lo que sea que haya en el campo.

### Resolución de locale en RSC — patrón bueno
- Las labels de `priorPhases` se resuelven en la página RSC (`resolveI18n(g.label, locale)`) antes de pasarse al componente cliente vía `CaseWorkspaceVM`. El componente cliente recibe `string` plano (no objetos `{es, en}`). Ese es el patrón correcto para i18n en el split RSC/cliente: resolver el locale en el servidor y pasar strings a través de la frontera. NO pasar objetos `{es, en}` a componentes cliente para resolverlos allá.

### `aria-hidden="true"` + `sr-only` en un `<input type="file">` oculto — anti-patrón de a11y recurrente
- `free-translation-tool.tsx` y `adjust-to-letter-tool.tsx` ocultan el input nativo con `className="sr-only" aria-hidden="true"` mientras un `<button>` hermano dispara `.click()` programáticamente. `aria-hidden="true"` sobre un elemento que sigue siendo focuseable (un `<input>` nativo no tiene `tabIndex={-1}`) es violación de axe-core (`aria-hidden-focus`): un usuario de teclado puede tabular a un elemento oculto del árbol de accesibilidad. Fix batcheado en todos los componentes de file-upload: sacar `aria-hidden` o agregar `tabIndex={-1}` al input.

---

## pdf-lib en el navegador (henryflow, tool de traducción/PDF)

### `ignoreEncryption: true` NO desencripta — clase BLOCKER
- pdf-lib no tiene NADA de desencriptado RC4/AES en su core (confirmado por grep del source: no existe código `decrypt`/`CryptFilter`). `PDFDocument.load(bytes, { ignoreEncryption: true })` solo saltea el throw de `EncryptedPDFError` — no desencripta los streams. Para PDFs genuinamente encriptados (incluso los de solo owner-password/permisos, porque el contenido sigue encriptado igual) esto produce de forma confiable **páginas en blanco o corruptas** en vez de un error limpio (confirmado en varios issues de Hopding/pdf-lib; los mantenedores dicen explícitamente "you should not use this option"). Toda herramienta que mute/copie páginas de un PDF provisto por el usuario debe chequear `src.isEncrypted` justo después del load y tirar un error amigable y específico ANTES de procesar. Crítico para output de trámite legal, donde una página en blanco silenciosa puede pasar desapercibida.

### `PDFPage.setRotation()` tira si el ángulo no es múltiplo limpio de 90
- `setRotation` llama internamente `assertMultiple(degreesAngle, 'degreesAngle', 90)` y tira ante cualquier valor no múltiplo de 90. Si el código lee el `/Rotate` de la página fuente defensivamente (try/catch con default 0) pero después llama `setRotation` sobre la página de SALIDA *fuera* de ese try/catch, una sola página fuente malformada aborta el procesamiento del documento/batch entero con un error inútil de nivel superior. Envolver la llamada a `setRotation` (no solo la lectura de `getRotation`) en el mismo try/catch defensivo, o validar `angle % 90 === 0` antes.

### Matemática de rotación de páginas — dibujar sin rotar + `setRotation` de página entera es CORRECTO
- Patrón: embeber la página fuente cruda (`embedPdf`/`PDFPageEmbedder` de pdf-lib siempre devuelve ancho/alto crudos del MediaBox SIN rotar, ignorando `/Rotate`), escalarla y centrarla usando el ancho/alto destino *sin rotar* como bounds, dibujarla en una página de salida nueva sin rotar, y RECIÉN AHÍ llamar `outputPage.setRotation(degrees(originalAngle))` sobre la página nueva entera. Verificado con la transformada de coordenadas: para 90°/270° la propia semántica de rotación intercambia ancho/alto de la página, así que usar las dimensiones destino sin rotar como caja de ajuste ya es el bound intercambiado matemáticamente correcto post-rotación, y el centrado se preserva. Es sutil y fácil de errar (parece que fuera a doble-rotar) — reusar como implementación de referencia.

### Techo de memoria de pdf-lib en el navegador
- El uso de memoria reportado por la comunidad es mucho peor de lo que sugiere el tamaño del archivo (p.ej. un PDF de 200 páginas / ~10MB reportado usando ~6GB de RAM durante el procesamiento). Cualquier tool client-side (in-browser, sin subida al server) con pdf-lib que acepte uploads de hasta 100MB debe tratarse como riesgo real de crash de pestaña en laptops típicas de staff, no como mero detalle de UX. Considerar un cap materialmente más bajo (~40-50MB) o estrategias chunked/streaming para expedientes escaneados multi-página.

---

## dmadrugada-web-v2 — voice assistant MVP (ElevenLabs), revisado 2026-08-12

- **Drift de plata/cantidad al mergear líneas del carrito**: `lib/cart/store.tsx`'s `add()` capea silenciosamente una línea mergeada en `LIMITS.MAX_LINE_QTY` (20) sin decirle al caller cuánto se aplicó realmente. Cualquier código que hable o reporte una cantidad o subtotal calculado desde la qty CRUDA pedida (en vez del delta realmente aplicado) va a sobredeclarar el carrito real una vez que la línea esté cerca del cap. `lib/voice/cart-adapter.ts`'s `changeCartLine` lo maneja bien (capea `newQty` antes de hablar); `addToCart` no lo hacía.
- **Fetches de cliente sin `AbortSignal.timeout`**: ni `/api/orders` (CheckoutScreen.tsx) ni `/api/voice/session` (VoiceProvider.tsx) setean timeout del lado cliente, así que una conexión colgada deja un booleano `submitting`/`requesting` en `true` para siempre, sin recuperación visible salvo recargar. Patrón preexistente del repo.
- **Patrón bridge de stale-closure (deliberado, NO es bug)**: este repo usa un objeto a nivel de módulo (`lib/voice/bridge.ts`) + un `useEffect(() => { registerX(freshClosures) })` sin array de dependencias para evitar que los callbacks que sostiene el SDK capturen estado rancio del store (los setters cambian de identidad cuando cambia su array de respaldo). NO flaggear el array de dependencias faltante en ESTE patrón — es el fix intencional, no el bug.
