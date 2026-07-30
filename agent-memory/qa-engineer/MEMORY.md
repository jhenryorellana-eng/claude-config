# Persistent Memory for qa-engineer

_This file is loaded at the start of each invocation. Keep entries concise. Lines after 200 are truncated._

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

### I18nField aria-label pattern (usalatino-v2)
The `I18nField` component uses `aria-label={lang}` ("ES"/"EN") on its inputs by
default, making `getByLabel("ES")` non-unique across multiple fields. Fix:
thread the parent `label` prop into the `Col` sub-component so the aria-label
becomes `"{fieldLabel} {lang}"` (e.g., "Nombre del servicio ES"). This change
was applied in i18n-field.tsx. All existing callers are unaffected (the label
prop was already required).

### Wizard category/phase button selectors
CatalogWizard BasicsStep category buttons had no aria-label. Added
`aria-label={c}` + `aria-pressed={on}`. Phase sidebar buttons had no aria-label.
Added `aria-label={\`Fase ${i+1}: ${ph.label.es || ph.slug}\`}` + `aria-pressed`.
The dashed "Agregar fase" button got `aria-label={t.addPhase}`. These additions
enable getByRole("button", { name }) targeting in E2E without fragile nth().

### ThemeToggle aria-pressed: poll with toHaveAttribute regex instead of getAttribute
`toggle.getAttribute('aria-pressed')` can return null if called before React hydration
(useEffect sets mounted=true asynchronously). Use:
  `await expect(toggle).toHaveAttribute('aria-pressed', /^(true|false)$/, { timeout: 5000 })`
This polls until the attribute appears, making the test resilient to hydration timing.

### Radix Modal footer buttons outside viewport (usalatino-v2)
The Modal component uses `overflow:auto + maxHeight:calc(100vh - 48px)` on
`DialogPrimitive.Content`. When form content is taller than the viewport, footer
buttons are inside the modal scroll container but appear "outside of the viewport"
to Playwright's actionability checker — even `force:true` fails.
Fix: use `.evaluate((el) => el.click())` to dispatch native click on the button element,
bypassing Playwright's viewport guard while still firing the React onClick handler.
Apply to ALL modal footer buttons in usalatino-v2 admin tests.

### getByLabel fails on FieldLabel (usalatino-v2)
`FieldLabel` component renders a `<span>` — not a `<label>` — so `page.getByLabel()`
finds no match. Use `locator('input[type="email"]')` for email fields; for generic
TextInput with no placeholder, use positional: `dialog.locator('input').nth(N)`.
Always scope to `page.locator('[role="dialog"]')` first to avoid page-level ambiguity.

### Toast + router.refresh() race (usalatino-v2 employees)
When an action triggers `toast.success()` followed immediately by `router.refresh()`,
the refresh destroys the toast DOM before Playwright's assertion window expires.
Prefer "resulting state" assertions (e.g., row appears in table) over toast visibility.
Log toast presence as a soft `isVisible().catch(() => false)` check for debugging.

### Scoping dialog assertions avoids hidden <option> matches
The audit view has filter `<select>` elements with options like "Tipo de entidad".
`page.getByText(/Entidad/i)` matches those hidden options. Always scope to
`page.locator('[role="dialog"]')` when asserting content inside a Radix Dialog/SidePanel —
both use `DialogPrimitive.Content` which emits `role="dialog"` in the DOM.

### BUG-LEADS-001 (usalatino-v2) — RESOLVED 2026-06-13
Extracted sourceMeta/SOURCE_META/timeTier/fmtMoney/fmtPercent to
`src/frontend/features/vanessa/shared/source-meta.ts` (no "use client").
ui.tsx re-exports them. leads/page.tsx and mi-dia/page.tsx import from the pure module.
build/tsc/eslint all clean. test.fixme removed from S1/S2/S3 in f3-f1-flow-vanessa.vanessa.spec.ts.

### F3-F1 E2E multi-actor setup pattern (usalatino-v2)
- Vanessa (sales): email/password auth, lands on /admin (same login as all staff),
  storageState in e2e/.auth/vanessa.json. vanessa-auth.setup.ts checks for NOT /login
  (not for /ventas — all staff land on /admin after login regardless of role).
- María (demo client): email/password auth (`demo-maria!` from seed 03),
  lands on /home, storageState in e2e/.auth/maria.json. SMTP/OTP not configured
  → use password auth for E2E; OTP unit-covered in identity/__tests__.
- Projects: "vanessa" + "vanessa-setup", "maria" + "maria-setup" added to
  playwright.config.ts. Test match patterns: *.vanessa.spec.ts / *.maria.spec.ts.
- Rate limit: staff login capped at 5 req/15 min. Setup runs ONCE; all
  dependent tests reuse storageState — no per-test logins.

### AgendarScreen slot-picker: empty state when no availability rules
`/caso/<id>/agendar?reschedule=<id>` navigates to AgendarBlocked or EmptyCase
when Vanessa has no availability_rules configured. The slot picker only renders
when getAvailableSlots returns non-empty slots. Seed 03 does NOT seed availability
rules. Tests must be defensive: check for calendar OR empty/blocked state.

### citas/page.tsx getWeekAgenda not yet wired (F3 scaffold)
The /ventas/citas CalendarGrid renders with static events:[] as of F3.
The `events` and `details` arrays are empty stubs. getWeekAgenda is marked as
pending in the page.tsx comment. CalendarGrid structure tests pass; appointment
visibility tests are fixme'd until getWeekAgenda wiring is complete.

### playwright.config.ts webServer URL must return 2xx (usalatino-v2)
`reuseExistingServer: true` only reuses if the URL returns 2xx before the command.
`/welcome` and `/login` return 500 in dev (RSC render failures when Supabase is
slow or next-intl throws). Use `/favicon.ico` as the health-check URL — it always
returns 200 as a static asset (assuming no Next.js error page overrides it).
If favicon also starts returning 500, the dev server is in a crashed state and
needs restart. Document this in playwright.config.ts comments.

### Dev server crash pattern (usalatino-v2, 2026-06-13)
After multiple failed Playwright webServer spawns (because reuseExistingServer
checked a URL returning 500), the Next.js dev server (PID 380) entered a state
where all routes including /favicon.ico return 500. Solution: user must restart
`npm run dev`. This is likely a Turbopack hot-reload race when multiple `npm run dev`
processes compete for the same port or trigger conflicting HMR clients.
Mitigation: always set webServer.url to a static asset that returns 200 immediately.

### ai-budget-aggregation job unit test pattern (usalatino-v2, 2026-06-15)
The supabase mock for this job must handle TWO different `from()` calls in the
same test: `from('orgs')` (returns array via `.select()`) and `from('users')`
(returns single row via chained `.eq().eq().limit().maybeSingle()`).
Pattern: use `vi.hoisted` mutable objects (`mockOrgsData`, `mockUsersData`) and
branch inside `from(table)` factory. Reset the `.data` property in `beforeEach`.
The `insertNotificationIdempotent` mock uses `.catch(()=>{})` in the job so it
ALWAYS receives the call — the catch is transparent to the mock. For dedupeKey
assertions use `expect.stringContaining(...)` or compute expected month at test
time with `new Date().toISOString().slice(0,7)` (same logic as the job).

### BUG-CATALOG-001 (usalatino-v2) — strings.ts ICU without context
`buildCatalogStrings()` calls `tt("catalog.phases")` without providing `{n}` context.
Same pattern for "entryBadge", "celebrate", "filledBy", "inviteSent" (employees page).
These throw FORMATTING_ERROR from next-intl server components → 500 on /admin/catalogo.
Fix: use `tt.raw("catalog.phases")` or pass dummy context: `tt("catalog.phases", { n: 0 })`.
Affected tests are marked `test.fixme(true, "BUG-CATALOG-001: ...")`.
NOTE: /admin/empleados has a similar but non-blocking bug — buildStrings throws on
"inviteSent" (needs {email} context), logged in server output, page still renders.
