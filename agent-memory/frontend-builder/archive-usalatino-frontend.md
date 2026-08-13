# Archivo — APIs de componentes, boundaries e i18n por proyecto

> Curaduría agent-ops 2026-08-13. Verbatim, movido desde `MEMORY.md` (tope de 200
> líneas cargadas). Detalle operativo de tindivo-negocios y usalatino-v2: firmas de
> props, reglas de boundaries de eslint, puntos de inserción de i18n y gaps de módulos.
> Consultar antes de asumir la firma de un componente o de un read del backend.

---

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
