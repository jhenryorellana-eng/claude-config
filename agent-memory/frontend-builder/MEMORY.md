# MEMORY - frontend-builder

> Fusion inicial (2026-08-07): disruptive-landing-builder (motion/GSAP) + ui-builder (implementacion). Recetas en archivos hermanos.

---

# DisruptiveLanding Builder - Memory

## Confirmed CDN URLs (May 2026)
- GSAP 3.12.7: `https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/gsap.min.js` (works)
- ScrollTrigger: `https://cdn.jsdelivr.net/npm/gsap@3.12.7/dist/ScrollTrigger.min.js`
- Lenis 1.1.18: `https://cdn.jsdelivr.net/npm/lenis@1.1.18/dist/lenis.min.js` (works)
- SplitType 0.3.4: `https://cdn.jsdelivr.net/npm/split-type@0.3.4/umd/index.min.js` (UMD global `SplitType`)
- Three.js r128: `https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js` (UMD, works)
- Swiper 11: `https://cdn.jsdelivr.net/npm/swiper@11/swiper-bundle.min.js` (works)
- vanilla-tilt 1.8.1: `https://cdnjs.cloudflare.com/ajax/libs/vanilla-tilt/1.8.1/vanilla-tilt.min.js`
- simpleParallax 6.0.0: `https://cdn.jsdelivr.net/npm/simple-parallax-js@6.0.0/dist/vanilla/simpleParallax.min.js` (UMD global `simpleParallax`)
- NOTE: GSAP 3.13.0 SplitText CDN path NOT confirmed on jsdelivr. Use 3.12.7.

## See also (topic files)
- `astro-motion-stack.md` — full recipes para Astro 5 + GSAP/Lenis/SplitType desde CDN
- `motion-recipes.md` — patterns reusables (clip-path, scrub, marquee, counter-up, tilt, magnetic)

## Key Patterns (quick reference)
- Lenis + GSAP sync: `lenis.on('scroll', ScrollTrigger.update)` + `gsap.ticker.add(time => lenis.raf(time*1000))` + `gsap.ticker.lagSmoothing(0)` ← confirmed Context7 darkroomengineering
- SplitType + GSAP: `new SplitType(el, {types:'lines,words,chars', tagName:'span'})` → gsap stagger chars con yPercent:110→0
- IMPORTANT: `.word, .split-word { overflow: hidden; display: inline-block; vertical-align: top }` para que yPercent funcione bien
- Canvas DPR: cap at 1.5 on desktop, reduce particles on mobile (35 vs 80)
- Word-by-word reveal: split text, wrap in .word spans, ScrollTrigger onUpdate with progress
- Magnetic buttons: mousemove offset * 0.18, mouseleave elastic.out(1,.4) reset
- FAQ accordion: gsap.to maxHeight with scrollHeight + padding (avoid animating height — auto trick)
- Custom cursor: dot=direct, ring=GSAP ticker lerp 0.15
- Three.js render via GSAP ticker: `gsap.ticker.add(() => renderer.render(scene, camera))`
- Three.js disable on mobile < 768px entirely for performance
- ScrollTrigger pin: use `gsap.matchMedia()` to enable only desktop + no-preference reduced-motion

## Astro 5 — CDN globals + modular TS (CRITICAL)
- CDN scripts go in `<body>` end with `is:inline` to skip bundler
- Module `<script>` (no `is:inline`) can `import` from `../lib/*.ts` and gets bundled per-page
- Declare globals once in lib file: `declare global { interface Window { gsap: any; ScrollTrigger: any; Lenis: any; SplitType: any; ... } }`
- Each component init pattern: `function waitGsap(cb, retries=60) { if (window.gsap) cb(); else setTimeout(..., 50); }` polls until CDN globals exist
- Components that need motion: write `<script>` block at end, import from `../lib/motion`, call `waitGsap(initMyComponent)`

## Lenis CSS overrides (REQUIRED for proper smooth scroll)
```css
html.lenis, html.lenis body { height: auto; }
.lenis.lenis-smooth { scroll-behavior: auto !important; }
.lenis.lenis-stopped { overflow: hidden; }
.lenis.lenis-scrolling iframe { pointer-events: none; } /* IMPORTANT: maps inside scroll-smooth break without this */
```

## prefers-reduced-motion strategy
- Detect at runtime in each component init
- Skip Lenis init entirely (smooth scroll annoys reduced-motion users)
- Skip pin/scrub; use opacity-only fade-ins
- Render canvas as single static frame, no rAF loop
- CSS @media query also kills scroll-progress, marquee, animations

## Common Mistakes Avoided
- Animating width/height/top/left → use transform/opacity ALWAYS
- Forgetting `gsap.ticker.lagSmoothing(0)` → scrub stutters
- Not refreshing ScrollTrigger after fonts load → wrong positions. Pattern: `document.fonts.ready.then(() => ScrollTrigger.refresh())`
- Pinning on mobile → janky, sometimes scroll breaks. Use matchMedia.
- iframe inside lenis-scrolling block → pointer events trap. CSS fix above.
- SplitType chars sin overflow:hidden en .word → yPercent visible afuera del rect

## Playwright Testing
- Must serve via http-server (no file:// URLs)
- Check port availability - 8765 often in use, use 8799+ as fallback
- Wait 4s after navigation for loader animations
- fullPage screenshots work well for landing pages
- favicon.ico 404 is expected/normal

## Performance Notes
- Single-file HTML with inline CSS/JS loads fastest (but Astro modular OK too)
- IntersectionObserver for lazy canvas init
- Debounce canvas resize at 200ms
- Three.js: `setPixelRatio(Math.min(devicePixelRatio, 1.5))`

## Three.js Food Objects
- Low-poly: SphereGeometry(scaled) body + CylinderGeometry bone + small sphere bumps
- Checkered texture: CanvasTexture with 64x64 canvas, 8x8 grid pattern
- MeshPhongMaterial flatShading:true for stylized look
- PointLight blue + AmbientLight gold = nighttime food scene

## CSS Patterns
- Damero: `repeating-conic-gradient(color 0% 25%, transparent 0% 50%) 0 0/20px 20px`
- Grain: inline SVG feTurbulence data URI, opacity .04-.05
- Glassmorphism: rgba bg + backdrop-filter:blur(12px) + rgba border
- Scroll progress bar: `animation-timeline: scroll(root)` native CSS (no JS) — supported Chrome 115+
- Marquee mask edges: `mask-image: linear-gradient(90deg, transparent 0, #000 8%, #000 92%, transparent 100%)`

## Font Pairings
- Bangers + Nunito 400-800 = fun street-food / youth brand
- Syne 700/800 + Manrope 300-700 = premium agency aesthetic
- Fraunces (opsz + ital variable) + Inter = editorial restaurant / bistró
  - For HUGE display: opsz 144, ital 1, weight 400, letter-spacing -0.04em
  - Fraunces Google Fonts URL with italics: `?family=Fraunces:opsz,ital,wght@9..144,0,400;9..144,0,500;9..144,1,400;9..144,1,500`

## simpleParallax patterns (v6.0+)
- Init: `new simpleParallax(images, { orientation:'up', scale:1.4, delay:0.4, overflow:false })`
- Combina bien con Lenis (Lenis maneja scroll, simpleParallax lee scrollY)
- NO usar simultáneamente con GSAP ScrollTrigger sobre los mismos elementos (doble animación)
- Mobile: bajar scale a 1.2 o desactivar (matchMedia `(max-width: 768px)`) — parallax pierde impacto en pantallas chicas y consume batería
- Para 5+ imágenes: instanciar dentro de IntersectionObserver (solo cuando entran al viewport)
- Industries que funcionan: arquitectura, fotografía, restaurantes con food shots, travel, fashion lookbooks, agency case studies
- NO usar en: fintech, banking, corporate, healthcare/wellness — parallax sugiere "marketing tone" inadecuado para trust-focused brands
- Bug típico: img sin `width/height` HTML attrs → CLS alto. Siempre setear ambos.
- React variant: import default `SimpleParallax` desde `simple-parallax-js`, wrap `<img>` con `<SimpleParallax orientation="up" scale={1.5}>`

## Food Delivery Landing
- WhatsApp cart: encodeURIComponent, asterisks for bold in message
- Menu tabs: data-cat filter, re-render with GSAP stagger
- Peru phone: wa.me/51XXXXXXXXX
- Argentina: wa.me/5491XXXXXXXX

## Restaurant / Bistró Landing (Olivar)
- Editorial cinematic = Fraunces italic huge + dark night bg + terracotta accent
- Effective sections order: Hero pinned → Marquee transición → About clip-paths → Menu asimétrico → Space horizontal → Wines mask reveals → Reservas stagger → Visit radial map → Footer wordmark grow
- WhatsApp reservation form: stub `buildWhatsappMessage` lanza error hasta que user lo implemente → siempre catch con fallback message

## User Preferences
- Working dirs vary: C:\Users\mauri\Documents\agentes\* OR C:\Users\mauri\Documents\Trabajos\*
- Platform: Windows 11, PowerShell + bash both available
- Language: Spanish content (rioplatense), English code/docs
- For bash: forward-slash paths `/c/Users/...` work better than escaped backslashes
- For PowerShell: `$env:USERPROFILE` for home


---

# Persistent Memory for ui-builder

_This file is loaded at the start of each invocation. Keep entries concise. Lines after 200 are truncated._

## Patterns learned

### Tindivo negocios app (2026-06-06)
- **Design system** lives in `apps/negocios/app/dashboard-tokens.css` (tv-* classes, Material Symbols Rounded via Google link).
- **Primitives** in `apps/negocios/components/dashboard/primitives.tsx`: `MS`, `soles`, `solesPlain`, `mmss`, `SourceBadgeMini`, `PayBadgeMini`, `FONT_MONO`, `FONT_DISPLAY`, `PAYMENT_META`, `PAY_DISPLAY`. Import these — never redeclare.
- **Shell** in `apps/negocios/components/dashboard/shell.tsx`: `DashboardShell` + `useDashboard()`. Every new view wraps in shell. Auth gate is built-in.
- **Responsive breakpoint pattern**: `className="lg:hidden"` / `className="hidden lg:grid"` — Tailwind `lg:` overrides `hidden`. `style` prop adds non-display CSS properties (gridTemplateColumns, gap, etc.) on the same element. TS doesn't complain; works correctly at runtime.
- **TS strict noUncheckedIndexedAccess**: use `?? fallback` on all index accesses and Record lookups.
- **Payment intent mapping**: `pending_yape` → `pending_wallet` (see `mapPayment()` in view-model.ts).
- **Supabase client**: `getSupabaseBrowser()` from `@/lib/supabase/client` (singleton browser client).
- **Date-range for "today"**: compute Lima UTC-5 day boundaries manually — Supabase has no timezone-aware filter helper.
- **Biome** is the formatter/linter. `button type="button"` is required or Biome flags it.
- **No inline `<style>` tags** in TSX — use Tailwind classes + inline style prop split. `<style>` inside JSX causes issues with RSC and SSR.
- **Biome `noLabelWithoutControl`**: `<label>` with slot-pattern children (no literal `<input>` sibling) always fires this. Replace with `<div className="tv-label-input">`. The class provides identical visuals.
- **Biome import sort**: when Biome flags `organizeImports`, run `biome format --write <file>` rather than hand-sorting — it handles both sort and format in one pass.
- **JSX text wrapping**: multi-word strings broken across lines trigger a Biome format diff. Wrap in template literal `{`…`}` to keep on one line.
- **Port pattern (prototype → Next.js)**: lift state to page level; keep Supabase queries from old implementation; split `lg:hidden` / `hidden lg:block` for mobile/desktop layout; never re-import `soles`/`MS` — always from primitives.tsx.
- **`satisfies` + literal type clash**: `{ isExpanded: false }` makes the field a literal `false`, so `satisfies ModifierGroup` (which has `boolean`) fails. Use `flatMap` + explicit typed variable instead of `map` + `.filter((x): x is T => x !== null)` — avoids both the predicate-type error and the literal-narrowing issue.
- **`declare module` inside a file**: causes TS errors in Next.js App Router due to module resolution conflicts. Never use `declare module './page'` as a workaround — fix the root type issue instead.
- **Supabase menu schema** (tindivo-v2): `menu_categories`, `menu_items` (badges text[] NOT NULL default '{}', is_compact bool), `menu_modifier_groups` (selection_type text, is_required, min_selections, max_selections nullable), `menu_modifier_options` (additional_price numeric), `menu_item_modifier_groups` (item_id, group_id, display_order) junction.
- **Editor full-screen custom page pattern**: `'use client'` page that renders `<>mobileView desktopView</>` where mobile is `className="lg:hidden"` and desktop is `className="hidden lg:flex"`. Auth + bizId loaded in a single `useEffect`. DashboardSidebar imported directly for desktop nav (not DashboardShell — that wraps content in its own layout).

### UsaLatinoPrime V2 — usalatino-v2 (2026-06-15)
- **Repo path**: `C:/Users/mauri/Documents/Trabajos/usalatino-v2/` (NOT "USALATINO V2").
- **Brand components**: `import { Card, GradientBtn, GhostBtn, StatusPill, Chip, Lex, type StatusKind } from "@/frontend/components/brand"`. `toast` from `@/frontend/components/desktop`.
- **CSS vars in use**: `var(--ink)`, `var(--ink-2)`, `var(--ink-3)`, `var(--accent)`, `var(--line)`, `var(--card)`, `var(--blue-soft)`, `var(--gold-soft)`, `var(--gold-deep)`, `var(--green)`, `var(--green-soft)`, `var(--red)`, `var(--red-soft)`, `var(--font-title)`.
- **Auth pattern**: server components use `getActor()` from `@/backend/modules/identity`; server actions use `requireActor()`. Actor kind check: `actor.kind !== "staff"` → redirect("/login").
- **Module-pub boundary**: import only from `@/backend/modules/<name>` (never from service.ts / repository.ts directly).
- **Action return shape**: `{ ok: true, data? } | { ok: false, error: { code: string } }` — mirror formularios/actions.ts pattern.
- **Optimistic reload**: `window.location.reload()` after successful mutations (matches formularios pattern — no optimistic local state needed).
- **Per-action busy state**: separate `busy*` booleans for each distinct action type. For item-level busy use `busyItem` keyed as `itemId + ":verb"` (e.g. `:remove`, `:move`, `:toc`).
- **Server page structure**: `export const dynamic = "force-dynamic"` + `<div>` wrapper (NOT `<main>` — panel layout already has one). Back link to `/admin/casos/${caseId}`.
- **ESLint gate**: the `[boundaries]` stderr messages are plugin initialization deprecation warnings, not rule violations. Exit code 0 = pass.
- **GhostBtn + GradientBtn `size` prop**: accepts `"lg"` | `"md"`. Use `size="md"` for inline/compact buttons. Heights: lg=60px, md=52px. Set `full={false}` for auto-width.
- **Inline edit pattern**: a `<button>` that shows as text when idle and swaps to `<input autoFocus>` when clicked; `onBlur` saves. Avoids form elements that need labels.
- **Boundaries rule**: frontend features (`src/frontend/features/`) MUST NOT import from `@/backend/modules/*`. Types flow via VM structs defined in the feature file. Server pages (RSC) import backend types, map to VM, and pass serializable VM to the client component.
- **Icon names available** for Timeline/Stepper: "send", "clock", "check", "info", "shield", "bell", "doc", "form", "calendar", "phone", "edit", "user", "star", "home", "globe", "chat", "sparkle", "upload". NO "alert-triangle" — use "info" for warnings.
- **ListValidationsFilters shape**: `{ caseId?, status?, page?, pageSize? }` — no `limit` field. Use `pageSize` for max rows.
- **Unused function params**: ESLint `@typescript-eslint/no-unused-vars` requires unused args to match `/^_/u`. Prefix with `_` (e.g., `_index`) or remove.
- **Modal pattern**: position:fixed overlay with backdrop (rgba + backdropFilter blur), role="dialog" aria-modal="true", Escape-closable via onClose prop, GhostBtn cancel + GradientBtn confirm.
- **Kanban page pattern (Diana)**: server page imports `getBoard` from `@/backend/modules/kanban` and `listCasesAdmin` from `@/backend/modules/cases`; maps `BoardDto.cards` (ref_type='case') to VM structs; passes serialisable VMs + server actions to the client view. `AdminCaseListItem` has: id, caseNumber, status, clientName, serviceLabelI18n, planKind, phaseLabelI18n. `planKind === 'with_lawyer'` maps to the "Con abogado" chip. Alert data (docs_to_review, corrections_needed, generation_failed, rfe_overdue) is NOT in the Admin list — needs a batch endpoint (GAP-3, document in handoff with <<NEED-BACKEND>>).
- **i18n insertion point**: to add a new `staff.legal` namespace, insert `"legal": {...}` inside the `staff` object AFTER `"ventas": {...}` closes (line ~1315 in es.json / en.json) with a trailing comma on `ventas`.
- **`getBoard` returns `BoardDto`** = `{ board: BoardRow, columns: ColumnRow[], cards: CardRow[] }`. `CardRow` has: id, column_id, ref_type, ref_id, position, pinned_note, created_at, updated_at. No hydrated display data — hydration must be done in the RSC page via separate module calls.
- **Column color token→CSS var** for kanban board: accent→var(--accent), navy→var(--brand-navy), gold→var(--brand-gold), purple→#7C3AED, green→var(--green), red→var(--red).
- **Billing module** exports `getPaymentPlanForCase(actor, caseId)` → `PaymentPlanRow & { installments: InstallmentRow[] } | null`. No `getAccountStatement` yet — aggregate in RSC layer. `BillingError` exported from `@/backend/modules/billing`.
- **InstallmentRow** has: id, number, amount_cents, due_date, status ('pending'|'processing'|'paid'|'overdue'|'waived'), is_downpayment, paid_at.
- **Org module** (`@/backend/modules/org`): `OrgSettings` does NOT have `zelle_destination`. Use `NEXT_PUBLIC_ZELLE_DESTINATION` env var as bridge until schema is extended.
- **Stripe Checkout / Zelle proof actions** (API-BIL-01, API-BIL-04, API-BIL-05) are not yet in the billing module (F5 scope). Leave stubs with TODO BIL-RSC-3 comments.
- **Account-level pagos page**: use `getCasesForClient(actor, { limit: 1 })` to get the primary `caseId`, same as `/home`. Multi-case selector is out of scope.
- **i18n insertion point** for `cliente.pagos`: insert after `"config": { … "soon": "Pronto" },` block (before `"agendar"`) in both es.json and en.json.
- **Server actions in RSC pages with "use server"**: declare `async function foo() { "use server"; … }` inline in the RSC page file, then pass as props to the client view. Avoids the need for a separate actions.ts file when actions are tightly scoped to one page.
- **Radio card pattern** for payment method selection: `role="radio" aria-checked={selected}` on a div with border 2px accent when active; keyboard handling via onKeyDown Enter/Space.
- **Collections kanban page pattern (Andrium)**: uses `getBoard(actor, { kind: 'collections' })` + `listCasesAdmin(actor, { limit: 500 })`. Card kind (initial/overdue/print/done/generic) resolved from column label via case-insensitive match against seed labels. `listCasesAdmin` signature is `(actor, { status?, cursor?, limit? })` — NOT `{ page, pageSize }`. `Chip` tone values allowed: "neutral" | "blue" | "gold" | "green" | "amber" | "red" — NO "pending" or "done" tones.
- **`t.raw(...)` for interpolated templates**: any string containing `{n}`, `{monto}`, `{column}` etc. that the client interpolates via `.replace()` MUST use `t.raw(...)` not `t(...)` — otherwise next-intl formats/errors on the `{}` placeholder at compile time.
- **Pre-existing TS errors in usalatino-v2** (as of 2026-06-15): billing/__tests__/service-ola2.test.ts, expediente/__tests__/print-queue.test.ts — Actor type mismatch in test fixtures. These are pre-existing — do not count against new work.
- **Pagos/cuotas (Andrium) — billing module gaps** (2026-06-15): `listDueCalendar`, `listOverdueForCollections`, `rescheduleInstallment`, `waiveInstallment` are NOT yet exported from `@/backend/modules/billing`. Stubs left with `TODO BIL-RSC-3/4/5` comments. When billing module exports these, replace stubs in `src/app/(staff)/(panel)/finanzas/pagos/caso/[caseId]/actions.ts` and `src/app/(staff)/(panel)/finanzas/pagos/page.tsx`.
- **BillingResult type for frontend**: define locally in the view file (e.g. `export interface BillingResult<T = undefined> { ok: boolean; data?: T; error?: { code: string }; }`). NEVER import from `@/app/(staff)/...` in a `src/frontend/features/` file — that crosses the boundary and ESLint will error.
- **Lex size prop**: takes numeric `LexSize = 56 | 62 | 78 | 92 | 120 | 130 | 166 | 186` — NOT "sm"/"md"/"lg" strings.
- **Sonner toast API**: call as `toast.success("msg")` / `toast.error("msg")` — NOT `toast({ title, kind })`. The sonner `toast` export does not accept an object with `title` and `kind` props.
- **i18n insertion point for `staff.finanzas.impresion`**: insert after `cobranza` block closes (before outer `finanzas` block closes) in both es.json and en.json. Total key count after adding 62 new impresion keys: 1520.
- **`listPrintQueue` + `PrintQueueItemDto`** exist in `expediente/service.ts` but were NOT exported from `expediente/index.ts` — had to add them. Always check the index before assuming module-pub exposure.
- **`ExpedienteRow` fields available**: `attempt_no`, `built_by` (uuid), `printed_by` (uuid), `sent_to_finance_at`, `printed_at`, `shipped_at`, `filed_at`, `status`, `id`, `case_id`. No `built_by_name`, no `with_lawyer`, no `lawyer_verdict` — those require a dedicated DTO join (TODO API-EXP-20).
- **`Lex` size prop is `number`** (union: 56|62|78|92|120|130|166|186) — never pass string `"md"` or `"lg"`.
- **`Chip` has no `style` prop** — use a wrapper `<span>` with style if positioning needed.
- **Icon set does NOT include `"download"`** — use `"doc"` for file-related actions or omit icon prop entirely.
- **i18n insertion for `staff.finanzas.*`**: `staff.finanzas` object did not exist — create with `d.staff.finanzas = {}` in node script then assign sub-keys. Node JSON round-trip is the safest approach for large i18n files.
