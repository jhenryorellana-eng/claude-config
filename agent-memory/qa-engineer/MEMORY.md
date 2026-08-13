# Memoria de oficio — qa-engineer
> Máximo 200 líneas cargadas. Curaduría: agent-ops (2026-08-13).
> Dueño del gate a11y (axe-core) de todo el pipeline. La moneda es la evidencia ejecutada.

## Patterns learned

### axe-core impact filtering (2025)
After `new AxeBuilder({ page }).withTags([...]).analyze()`, filter violations
post-hoc via `.filter(v => v.impact === 'serious' || v.impact === 'critical')`.
The AxeBuilder API itself does not expose an impact filter — filtering is done
on the returned `violations` array. Use `expect.soft()` to surface the full
list before the hard assertion.

### Astro 5 webServer config
`webServer.url` must be set (not `port`) when using `reuseExistingServer`.
Astro dev defaults to port 4321. `stdout: 'pipe'` prevents noise in test output.

### Selectors: prefer getByRole / getByLabel for form fields
For form inputs, `page.getByLabel(/pattern/i)` validates both existence and
correct label association in one call — no need for separate label checks.

### WhatsApp redirect testing
When the form redirects via `location.href` (not `window.open`), use
`page.waitForURL(/wa\.me/)` inside a `Promise.all` alongside the click.
When it uses `window.open`, intercept via `page.addInitScript` patching
`window.open` before navigation.

### fixme pattern for stub-dependent tests
Use `test.fixme('description', async ({page}) => { ... })` to mark tests that
depend on user-implemented stubs. Add a comment block explaining the activation
steps. This keeps the suite green without silently skipping coverage intent.

### Performance proxy without Lighthouse
`Date.now()` diff around `page.goto('/', { waitUntil: 'domcontentloaded' })`
gives a useful CI gate without the heavy @lhci/cli setup.
Document explicitly that it is not a substitute for real CWV measurement.
Motion-heavy stacks (GSAP+Lenis CDN) justify relaxing the gate to 3500ms TTI.

### GSAP CDN + motion stacks: use networkidle before visibility assertions
When a page loads GSAP, ScrollTrigger, Lenis, SplitType from CDN, elements
start at opacity:0 set by GSAP initializers. `toBeVisible()` may fail before
CDN scripts execute. Fix: add `await page.waitForLoadState('networkidle')`
after `goto('/')` in tests that assert visibility of animated elements.
Apply to Hero h1, form fields, and CTA buttons in motion-heavy builds.

### Asymmetric layout / h2 text drift
When a section heading no longer contains the expected keyword (e.g. Menu h2
reads "Lo que estamos cocinando ahora." not "Carta"), expand the regex pattern
to include an alternate phrase from that section's copy (e.g. `|cocinando`).
Prefer targeting eyebrow or section-level text over requiring exact h2 match.

### select vs input type=number: getByLabel is agnostic
`page.getByLabel(/personas/i)` works equally for `<input>` and `<select>`
as long as the `<label for="...">` association exists. No need to assert
inputType separately — the label association test is sufficient.

### WebGL + continuous RAF loops block axe-core in headless (2026)
Pages with OGL/Three.js shaders or infinite CSS animations (conic-gradient spin,
constellation RAF) prevent `waitForLoadState('networkidle')` from resolving and
cause axe-core `.analyze()` to timeout (30s default) in headless Chromium.
Fix: `await page.emulateMedia({ reducedMotion: 'reduce' })` before `page.goto()`.
This disables the shader (GPU ReadPixels stalls gone) and pauses CSS animations.
Use `waitForLoadState('load')` instead of `'networkidle'` throughout.
Add `test.slow()` for complex sections (Rewards, Connected) to get 90s timeout.

### aria-prohibited-attr: aria-label on bare <span>/<p> without role
axe rule `aria-prohibited-attr` fires when `aria-label` is on a `<span>` or `<p>`
without an explicit ARIA role. Common in animated text components (SplitText pattern).
Best fix: SR-only text wrapper (`position:absolute; clip:rect(0,0,0,0)`) + `aria-hidden`
on the visual wrapper. Avoid `role="text"` — spotty support in VoiceOver iOS + NVDA.

### color-contrast: brand orange #F97316 on white fails at small sizes
`#ffffff` on `#f97316` → 2.8:1 — fails 4.5:1 for any text under 18.67px normal or
14px bold. Orange badges with white text at 10px are always a violation.
Fix options: (1) dark ink text on brand-soft (#ffedd5) background; (2) font-size ≥ 14px bold.
`--color-ink-muted` (rgba ink at 0.55 alpha) on white cards gives ~3.98:1 — also fails.
Needs alpha ≥ 0.65 or fixed hex ≥ #6b6663 for WCAG AA compliance on white.

### Lenis snap tests need Lenis active — split describe blocks by reducedMotion
DOM presence checks → `emulateMedia({ reducedMotion: 'reduce' })` (fast, stable).
Scroll interaction tests (ProgressDot click, hash update, viewport landing) → NO reducedMotion
(Lenis must be instantiated for scrollToSection to work). Separate into two `describe` blocks.
Run Lenis tests against `pnpm start` (production build) for stability — HMR Fast Refresh
in dev mode disrupts snap timing when multiple headless workers share the same dev server.

### UsaLatinoPrime V2 admin E2E: storageState pattern (canonical)
The staff login endpoint has a 5-req/15-min in-memory rate limit (dev).
Per-test login in beforeEach trips the limit when running 16+ tests.
Canonical fix: Playwright storageState project dependency.

Pattern used in this codebase:
  1. e2e/admin/auth.setup.ts — setup test does ONE UI login, asserts
     page.url().includes("/admin") (requires Custom Access Token Hook active).
     Saves: `await page.context().storageState({ path: "e2e/.auth/admin.json" })`.
     If it lands on /login → throws with actionable message; dependent tests
     show "did not run" (not "skipped") in the reporter.
  2. playwright.config.ts — project "admin-setup" (testMatch: auth.setup.ts),
     project "admin" (testMatch: *.admin.spec.ts, dependencies: ["admin-setup"],
     storageState: "e2e/.auth/admin.json").
  3. *.admin.spec.ts — NO logins anywhere. beforeEach calls page.goto() only.
  4. e2e/.auth/ added to .gitignore — session cookies never committed.
  5. "desktop" project uses testIgnore on *.admin.spec.ts to avoid overlap.

Output hook INACTIVE: 13 F0 passed, 1 admin-setup FAILED (clear msg), 16 "did not run".
Output hook ACTIVE: 30 passed (13 F0 + 1 setup + 16 admin).

## Playwright — selectores y timing (destilado, detalle en el archivo)

- **`getByLabel` falla si el "label" no es un `<label>`**: el componente `FieldLabel` de usalatino-v2 renderiza un `<span>`. Caer a `locator('input[type="email"]')` o posicional `dialog.locator('input').nth(N)`, siempre scopeando primero a `[role="dialog"]`.
- **Scopear al diálogo evita matches de `<option>` ocultos**: `page.getByText(/Entidad/i)` matchea las opciones de un `<select>` de filtros que no se ven. Radix Dialog y SidePanel emiten ambos `role="dialog"`.
- **`aria-label` no único**: un componente bilingüe que pone `aria-label={lang}` ("ES"/"EN") en cada input hace ambiguo el `getByLabel("ES")`. El fix va en el componente (concatenar el label del campo), no en el test.
- **Atributos que dependen de hidratación**: `getAttribute('aria-pressed')` puede devolver null si corre antes del `useEffect`. Usar `await expect(el).toHaveAttribute('aria-pressed', /^(true|false)$/, {timeout: 5000})` para que poll.
- **Botones del footer de un modal fuera del viewport**: con `overflow:auto + maxHeight:calc(100vh-48px)` en el Content de Radix, Playwright los considera fuera del viewport y ni `force:true` alcanza. Fix: `.evaluate((el) => el.click())` — dispara el click nativo salteando el guard de actionability, y el onClick de React igual corre.
- **Carrera toast + `router.refresh()`**: el refresh destruye el DOM del toast antes de que expire la ventana de assertion. Preferir assertions de "estado resultante" (la fila aparece en la tabla) y dejar la presencia del toast como chequeo blando `isVisible().catch(() => false)`.
- **`webServer.url` debe devolver 2xx**: `reuseExistingServer:true` solo reusa si la URL responde 2xx. `/welcome` y `/login` devuelven 500 en dev cuando Supabase está lento o next-intl tira. Usar `/favicon.ico` (estático, 200 siempre). Si el favicon también devuelve 500, el dev server está en estado crasheado y hay que reiniciarlo — pasó tras varios spawns fallidos de webServer.
- **Tests defensivos ante datos de seed faltantes**: el picker de slots solo renderiza si `getAvailableSlots` devuelve algo, y el seed 03 no siembra reglas de disponibilidad. Chequear "calendario O estado vacío/bloqueado", no asumir el camino feliz.

## Índice de archivos temáticos
- Archivo: infraestructura E2E y bugs específicos de usalatino-v2 (verbatim: multi-actor setup, BUG-LEADS-001, BUG-CATALOG-001, scaffolds fixme'ados, test del job ai-budget) → `archive-usalatino-e2e.md`
