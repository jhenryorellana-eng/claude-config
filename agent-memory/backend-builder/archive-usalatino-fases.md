# Archivo — bitácora backend por fase de UsaLatinoPrime V2 (F0 → F6-Ola2)

> Curaduría agent-ops 2026-08-13. Historial verbatim, movido desde `MEMORY.md` para
> respetar el tope de 200 líneas cargadas. El MEMORY.md conserva la destilación densa
> (gotchas de librerías, boundaries, patrones de test, contratos de negocio).
>
> Lo que NO está acá porque cambió de dueño:
> - Esquema, migraciones, RLS, políticas de Storage, triggers, seeds y pgTAP →
>   `../db-architect/MEMORY.md` (eran patrones de db-architect, no de backend).

---

### UsaLatinoPrime V2 — platform/ client layer (F0, confirmed June 2026)

**`employee_module_permissions` FK column**: it's `staff_id` (not `user_id`). The column references `staff_profiles(user_id)`. Confirmed from database.types.ts.

**`@google/genai` v2.x API**: main class is `GoogleGenAI` (not `GoogleGenerativeAI`). Constructor: `new GoogleGenAI({ apiKey })`. API access via `client.models.generateContent(...)` (models namespace). No `getGenerativeModel()` method.

**Stripe pinned API version June 2026**: `"2026-05-27.dahlia"` — update per release notes.

**Resend v6 batch API**: `client.batch.send(payload)` returns `Response<CreateBatchSuccessResponse>`. The inner data has shape `{ data: { id: string }[] }` — access as `result.data.data.map(r => r.id)`.

**Vitest + dynamic imports**: use top-level `await import(...)` in test files (ESM, vitest handles it). Do NOT use `await import()` inside `describe/it` callbacks — Vite's OXC parser chokes on it as non-top-level.

**JSDoc comment gotcha**: `/*/` inside a `/** */` block comment (e.g. `modules/*/events.ts`) terminates the comment in OXC/Vite parsers — causes parse errors. Use `{name}` placeholder instead.

**Phone regex in logger must not match UUID segments**: Use `(?<![0-9a-fA-F])` negative lookbehind to avoid matching digit runs inside UUID strings. UUID hex chars `a-f` around the digits create a natural exclusion boundary.

**crypto.ts key rotation pattern**: `tryDecrypt(ciphertext, mainKey)` in try/catch; if throws, retry with `ENCRYPTION_KEY_PREVIOUS`. GCM auth tag failure is deterministic and immediate — no silent corruption.

**getActor() caching**: uses React `cache()` for per-request memoization. Claims are read from `user.app_metadata` (set by the Custom Access Token Hook in Supabase); column is `user_role` (not `role` — `role` is reserved by PostgREST).

### UsaLatinoPrime V2 — identity module + F0 auth (June 2026)

**zxcvbn-ts v3 API change**: exports `ZxcvbnFactory` class (not `zxcvbn` function + `zxcvbnOptions` singleton). Usage: `new ZxcvbnFactory({ graphs, dictionary } as any)` then `.check(password)` returns `{ score }`. Cast needed because Options type requires all fields but constructor accepts partial at runtime.

**@upstash/redis package.json main**: `./nodejs.js` — import as `@upstash/redis` (NOT `@upstash/redis/nodejs`). The root barrel re-exports from nodejs.js.

**logger.ts signature**: `logger.info(context: Record<string, unknown>, message: string)` — TWO args required. Context goes first, message string second. Calling `logger.info({ msg: "..." })` is a TS error (missing second arg).

**Vitest ZxcvbnFactory mock**: Must use a plain function (not `vi.fn().mockImplementation`) so `new ZxcvbnFactory()` works. Pattern:
```typescript
vi.mock("@zxcvbn-ts/core", () => {
  function ZxcvbnFactory() { return { check: (pw: string) => ({ score: ... }) }; }
  return { ZxcvbnFactory };
});
```

**app→platform boundary violation fix**: App-layer pages MUST NOT import from `@/backend/platform/*`. Export `getActor`, `requireActor`, `can`, `AuthzError`, `Actor` through the identity module's `index.ts` (module-pub boundary). Then pages import `from "@/backend/modules/identity"`.

**eslint-plugin-boundaries v6 — module-pub rule missing**: The default config has no `from: "module-pub"` rule, causing actions.ts and index.ts to fail. Add: `{ from: "module-pub", allow: ["module-int", "platform", "shared", "module-pub"] }`.

**app→app imports for co-located screens**: Next.js pages import `./page-screen.tsx` (same route folder). This is app→app. Add `{ from: "app", allow: ["app", "module-pub", "frontend", "shared"] }` to allow it.

**users table**: NO `display_name` column. Has `email`. Client name lives in `client_profiles (first_name, last_name)`. For F0 stubs derive from email local-part. services has `label_i18n` (not `name_i18n`).

**Staff login server action location**: belongs in `identity/actions.ts` (module-pub), NOT in `src/app/(staff)/login/login-action.ts` (which would be app→platform violation). Move it, update login-screen.tsx import to `@/backend/modules/identity/actions`.

**Supabase User type cast**: `(user as Record<string, unknown>)` fails TS check ("Index signature missing"). Use double cast: `(user as unknown as Record<string, unknown>)`.

### UsaLatinoPrime V2 — F1 backend modules (June 2026)

**Zod v4 API changes**: `z.record(z.string(), z.unknown())` — two args required (key schema + value schema). `.email()` and `.uuid()` validators take no string argument. `ZodError.issues` (not `.errors`). `z.record(z.unknown())` was Zod v3.

**Vitest mock hoisting pattern**: Variables used inside `vi.mock()` factories must be declared with `vi.hoisted()` before the factories, NOT as regular `const`. Otherwise variables are uninitialized when the factory runs (hoisting issue).
```typescript
const { mockFn } = vi.hoisted(() => ({ mockFn: vi.fn() }));
vi.mock("./module.js", () => ({ fn: mockFn }));
```

**authz.ts imports supabase.ts at module level** (for createServerClient in getActor). Any test that imports from authz (directly or transitively) must mock `@/backend/platform/supabase` to prevent env.ts validation failure at module load.

**inviteEmployee security contract**: temp password generated with `crypto.randomBytes(18).toString('base64url')`. It is passed directly to `buildStaffInviteEmail()` and sent via Resend. It NEVER goes into: event payload (staff.created), audit diff, any log line. The event payload only carries userId, orgId, email, displayName, role, invitedBy.

**employee_module_permissions FK is staff_id referencing staff_profiles(user_id)** (NOT user_id referencing users). This is critical for INSERT — column name is `staff_id`.

**revokeAllSessions pattern (DOC-22 §3.3)**: 
- Deactivation: `signOut(userId, 'global')` + `updateUserById(userId, { ban_duration: '876600h' })` 
- Reactivation: `updateUserById(userId, { ban_duration: 'none' })`
- Both are non-fatal (log + continue on error)

**Permission preset matrix**: admin always bypasses (no rows needed). Non-admin roles: iterate MODULE_KEYS, return rows only for cells ≠ "-". `can_edit = (cell === "E")`. `can_view = true` for any cell ≠ "-".

**Catalog domain Zod schemas**: All changed from `z.record(z.unknown())` → `z.record(z.string(), z.unknown())` in F1 fix for Zod v4.

**Dynamic import of non-existent module**: cast path as `string` to suppress TS module resolution error: `await import("@/backend/modules/cases" as string)`. Wrap in try/catch so F-future modules degrade gracefully.

**catalog_publish_version RPC**: not in database.types.ts (not yet in migrations). Cast around TypeScript: `(client.rpc as any)("catalog_publish_version", {...})`. Falls back to manual two-step update.

**eslint `@typescript-eslint/no-unused-vars` argsIgnorePattern**: Next.js default config does NOT respect underscore prefix by default. Must override rule in eslint.config.mjs with `argsIgnorePattern: "^_"`.

### CSV injection neutralization (confirmed June 2026)

Pattern: neutralize Excel formula prefixes (`=`,`+`,`-`,`@`,`\t`,`\r`) by prepending `\t` BEFORE the RFC 4180 quote-wrap. The tab prefix forces the cell to be quoted because `neutralized !== s`.
```typescript
const FORMULA_PREFIX = /^[=+\-@\t\r]/;
const neutralized = FORMULA_PREFIX.test(s) ? `\t${s}` : s;
if (neutralized.includes(",") || neutralized.includes('"') || neutralized.includes("\n") || neutralized !== s) {
  return `"${neutralized.replace(/"/g, '""')}"`;
}
```

### AuthzError reason codes — extensible union

`AuthzError` in `platform/authz.ts` has a closed union for `.reason`. Add new business-logic guard reasons directly to the union (`self_deactivation_denied`, `cross_org_access_denied`). Do NOT create a new error class.

### Guard pattern for employee self-action (DOC-22 §9.3)

Order: (1) self-action guard (compare actor.userId === staffId), (2) org membership guard (findStaffById + compare orgId), (3) last-admin guard (only if target.role === "admin", call countActiveAdminsByOrg). All before DB mutation.

### countActiveAdminsByOrg — two-step query

PostgREST `.eq("related_table.column", value)` does NOT filter by join column reliably. Two separate queries: (1) get active staff IDs for org from `users`, (2) count admin rows from `staff_profiles` `.in("user_id", ids)`. Return 2 (safe fallback) on error — never block deactivation incorrectly.

### M-5 org ownership check

For mutators that already load the entity: `if (entity.org_id !== actor.orgId) throw catalogError("X_NOT_FOUND")`. Same error as not-found avoids leaking existence. Document as tech debt for mutators where entity is NOT loaded.


### UsaLatinoPrime V2 — F2 backend modules (June 2026)

**`TablesInsert<T>` / `TablesUpdate<T>` are top-level exports** in Supabase generated types. They are NOT nested as `Tables<T>["Insert"]` or `Tables<T>["Update"]`. Import them directly: `import type { Tables, TablesInsert, TablesUpdate } from "@/shared/database.types";`.

**`StorageValidationResult` shape**: `validateUploadedObject()` returns `{ ok: boolean; reason?: string }`. Do NOT destructure `{ exists, mimeType, size }`. Check `validated.ok` — if false, throw a domain error.

**`appendCaseTimeline` lives in `audit/service.ts`** (RF-TRX-024 CA3). Uses service client directly (not actor client). Never throws — catches internally and logs error. Required arg shape: `{ caseId, eventType, actorKind, actorUserId, titleI18n: { en, es }, occurredAt, ... }`.

**Single-use signing token**: set `signing_token: null` in the SAME DB update as `status: "signed"`. Never two separate writes (TOCTOU risk).

**Anti-enumeration on public endpoints**: uniform 404 for token not found / expired / consumed. Do NOT distinguish between "never existed" and "already used".

**`export type` required for re-exported types** when `isolatedModules: true`. `export { SomeType }` from a file that only re-exports a type fails at build time. Use `export type { SomeType }`.

**Module boundary R3 (jobs → module-pub only)**: `src/backend/jobs/` can only import from `module-pub` (index.ts), `platform/`, and `shared/`. Never from `module-int/` (repository, service internals). Add needed functions to the module's `index.ts` first.

**`renderContent(_payload)` pattern**: pure content map functions that receive a payload for future-extensibility but don't yet use it should use `_payload` (underscore prefix) to silence `no-unused-vars`. Add `argsIgnorePattern: "^_"` to ESLint config.

**Vitest mock hoisting** (confirmed F2): `vi.hoisted()` must declare any variables used inside `vi.mock()` factory closures. Factory closures run before module-level code. Pattern:
```typescript
const mockFn = vi.hoisted(() => vi.fn());
vi.mock("../module.js", () => ({ fn: mockFn }));
```

**`buildInstallments` rounding invariant I6** (last installment absorbs remainder): use a fixture where `floor(remainder / (count-1))` divides cleanly. Example: totalCents=110, downpaymentCents=10, installmentCount=4 → remainder=100, base=floor(100/3)=33, last=34.

**`insertNotificationIdempotent` dedupes by `dedupe_key`**: always look up before inserting. Returns `{ created: boolean; row: NotificationRow }`.

**`notifyFromEvent` is a no-op for events not in the F2 matrix**: safe to register as listener for ALL domain events.

**QStash route handler**: return 200 on unknown job key (prevents infinite retries). Return 500 only on handler throw (triggers retry with backoff). Parse job key from `params.job` in Next.js route handler.

**F2 notification color rule (RF-TRX-022)**: `document.rejected` uses `color: "amber"`, NEVER `"red"`. Rejected is correctable — red implies fatal/error.

**`registerZellePayment` permission**: `cases:edit` (NOT billing-specific). Confirmed DOC-48 — finance staff have `cases:edit` permission preset.

### UsaLatinoPrime V2 — F1 Gate del negocio (June 2026, Gate F1 closure)

**`provisionClientUser` pattern** (DOC-22 §1.2 H-2): `can(actor, "clients", "edit")` → `findClientByPhone` (idempotent) → `auth.admin.createUser({ phone, phone_confirm: true }, no password)` → `insertClientRows` → `writeAudit`. Race condition: if createUser returns "User already registered", call `listUsers` to get the pre-existing auth UID, then upsert public rows.

**`createCaseFromContract` pattern** (DOC-41 §3.1): idempotency check via `findCaseByContractId` → validate service (catalog fallback to direct DB query) → validate plan → validate `downpaymentCents <= totalCents` → `nextCaseNumber` → `insertCase(status:'payment_pending')` → `upsertCaseMember(owner)` → parties via identity dynamic import → `createContract` (contracts module) → `createPaymentPlan` (billing module, PAYMENT_PLAN_EXISTS = idempotent) → emit `case.created` + optional `case.assigned` → `writeAudit`.

**`getSigningTokenForContract`** added to contracts/service.ts (API-CTR-02). Permission: `can(actor, "cases", "view")` — "contracts" is NOT a valid ModuleKey (only "cases", "clients", "billing" etc). Use `cases:view` for contract reads.

**Vitest hoisting for multiple variables**: all variables used inside `vi.mock()` factories must be declared via ONE `vi.hoisted()` call. Chainable client mocks (Supabase query builder) must also be hoisted — assigning `vi.fn().mockReturnThis()` chains inside `vi.hoisted()` factory using a temporary `const client = {...}` pattern.

**UUID fixtures in Vitest**: Zod v4 `z.string().uuid()` validates with strict RFC 4122 format. Test fixtures MUST use valid UUIDs (e.g. `11111111-1111-4111-8111-111111111111`). Strings like "service-uuid-1111" or "client-user-uuid-3" will fail Zod parse and cause confusing test failures.

**Dynamic imports for cross-module calls** (avoid circular deps): use `await import("@/backend/modules/X")` inside the function body for modules that transitively depend on each other (cases↔identity↔contracts↔billing). Cast to the needed type inline. This is the established pattern in `onDownpaymentConfirmed`.

**`eslint-disable @typescript-eslint/no-explicit-any`** on dynamic import casts is NOT needed when the cast is typed: `as { fnName: (args) => ReturnType }`. Remove the disable comment to keep lint clean.

**Re-exporting repo functions from service.ts**: `export { insertCasePartyRow } from "./repository"` in service.ts does NOT require importing `insertCasePartyRow` at the top of service.ts. The `export { X } from "..."` syntax imports and re-exports in one step — no separate `import { X }` needed. Importing it separately then re-exporting causes `@typescript-eslint/no-unused-vars`.

### UsaLatinoPrime V2 — F2 code-review fixes (June 2026)

**`createServiceClient()` returns auth-only mock by default in tests**: when adding a DB query path to a service that previously only used `serviceClient.auth.*`, the Vitest mock for `createServiceClient` must be extended with a chainable `.from()` stub. Pattern: hoist a `chain` object with `from/select/eq/maybeSingle` all returning `chain` (or the resolved value), then add `from: chain.from` to the mock return value.

**`auth.admin.listUsers()` paginates at 1 000 by default** (Supabase GoTrue): never use it to find a single user by phone in large orgs. Always query `public.users` by `phone_e164` with the service client instead (indexed by `users_phone_e164_idx`). Race-condition recovery path confirmed in `provisionClientUser`.

**`|| true` in conditional expressions**: a `|| true` short-circuit anywhere in a boolean guard is always a bug — it bypasses the intended check entirely. Pattern for "default send until pref table exists": use `?? true` (nullish coalescing), not `|| true`.

**`instrumentation.ts` in Next.js 15**: no `experimental.instrumentationHook` flag needed. File at `src/instrumentation.ts` is auto-discovered. Add `{ type: "instrumentation", pattern: "src/instrumentation.ts", mode: "full" }` to `boundaries/elements` and a `{ from: "instrumentation", allow: [...] }` rule. The `register-consumers.ts` file is at `src/backend/modules/` root (unclassified by boundaries) — safe to dynamic-import from instrumentation.

**`escapeHtml` shared utility**: extracted to `src/shared/html.ts` so both `jobs/` layer and `module-int/identity` can use it. Keeps the boundary rule: `jobs` → `shared` (allowed).

**Storage path prefix validation for confirmDocumentUpload**: guard BEFORE `validateUploadedObject` — if the prefix is wrong, don't even hit storage. Guard: `if (!parsed.uploadRef.startsWith(\`case/${parsed.caseId}/\`)) throw new CaseError("DOC_UPLOAD_INVALID")`.

**Filename sanitization for storage paths**: `parsed.filename.replace(/[^a-zA-Z0-9._-]/g, "_")` before embedding in a storage path. Test assertion: check path starts correctly AND the timestamp-filename segment matches `/^[a-zA-Z0-9._-]+$/`. Do NOT assert that word-level segments (like "etc") are removed — the sanitizer replaces slashes/spaces, not substrings.

**M-1 billing error re-throw**: in `createCaseFromContract`, only swallow `PAYMENT_PLAN_EXISTS`. Any other billing error must re-throw so the admin can retry. The idempotency guard on `contractId` makes retries safe.

**pgTAP RLS contracts test (T18)**: contracts table has NO anon policy (deny-by-default). Test must verify: (a) anon sees 0 rows, (b) authenticated non-member sees 0 rows, (c) case_member sees their signed contract (status='signed'), (d) case_member cannot see 'sent' contract via RLS, (e) cross-org isolation. Use prefix `fa…` / `fb…` for Org A / Org B to avoid UUID collisions with earlier tests.

### UsaLatinoPrime V2 — F3 scheduling module (June 2026)

**`Slot` type uses `startUtc`/`endUtc`** (not `startsAt`/`endsAt`). The `MaterializeSlotsInput.booked` and `.exceptions` use `{ startsAt: Date; endsAt: Date }[]` — different shape. `findBookedForMaterialization` must return `Array<{ startsAt: Date; endsAt: Date }>` (NOT `Slot[]`). Service.ts uses `b.startsAt` when filtering booked; this is correct.

**Computed-key update breaks Supabase typing**: `supabase.from("t").update({ [dynamicCol]: value })` widens to `{ [x: string]: string }` which the TS client rejects. Use explicit if/else branches per column, or ternary on the entire `.update()` chain. Pattern used in `markReminderSent`.

**`createServerClient` vs `createServiceClient`**: all scheduling writes (insert, update, delete) use `createServiceClient` (bypasses RLS). Never import `createServerClient` unless you have an actor-scoped read. Removing the unused import avoids ESLint no-unused-vars warning.

**`_settings` unused parameter pattern**: if a function parameter is intentionally unused (e.g. kept for API compat but function re-fetches internally), prefix with `_` and type as `_settings?: unknown`. ESLint `argsIgnorePattern: "^_"` allows this.

**DST spring-forward fix verification**: In tests, don't filter for "gap hour" slots in UTC — the local gap simply never produces slots. Count total slots instead: spring-forward produces 4 slots (01:00 EST, 01:30 EST, 03:00 EDT, 03:30 EDT) not 6 when 2:xx AM local doesn't exist.

**DST fall-back deduplication**: `fromZonedTime("2026-11-01T01:00:00", NY)` returns 05:00Z (first occurrence, EDT). 01:30→05:30Z, 02:00→07:00Z (EST). All 4 slots are unique UTC instants; the deduplication Set correctly preserves them. Test should verify NO duplicate UTC keys, not that specific UTC times are absent.

**`materializeSlots` inputs `exceptions`/`booked` field naming**: spec uses `startsAt`/`endsAt` for the overlap-check inputs (not `startUtc`/`endUtc`). Internal algorithm accesses `ex.endsAt`, `ex.startsAt`, `b.endsAt`, `b.startsAt` — consistent with the `{startsAt, endsAt}` shape from `getExceptionsInRange` and `findBookedForMaterialization`.

**SOT-6 interim pattern**: when `cases/index.ts` doesn't yet export a needed function, implement it directly via `createServiceClient` inside `getCasesModule()` dynamic-import factory. Mark with `// TODO(SoT-6)` and the PR/ticket reference. This avoids circular imports while keeping the code grepable.

**`getLeadsModule` never-called function**: if you add a lazy loader for leads but the actual use case is shelved, remove it immediately — ESLint `no-unused-vars` will fail CI. Add it only when consumed.

**Domain test count for scheduling**: 72 tests covering all domain functions (state machine, penalties, rules, materializeSlots, DST, exceptions, buffer). Combined with 322 F0-F2 tests = 394 total. All pass in 5-6s.

### UsaLatinoPrime V2 — F3 notifications module (June 2026)

**MatrixRule resolver keys**: `appointment_staff`, `appointment_client`, `appointment_counterpart`, `lead_assigned_staff` — added for F3 appointment events. `appointment_counterpart` uses `cancelledBy`/`rescheduledBy` from payload to determine the counterpart.

**`buildActionUrl` enrichment for rescheduled**: when payload has `newAppointmentId`, inject `appointmentId = newAppointmentId` before template interpolation so the deep link points to the new appointment, not the old one.

**`jobs → jobs` boundary rule**: `eslint-plugin-boundaries` classifies `src/backend/jobs/**` as type `jobs`, which by default cannot import from other `jobs` files. Test files under `src/backend/jobs/__tests__/` also match `jobs` and need to import their handler. Solution: add `"jobs"` to the `from: "jobs"` allow list in `eslint.config.mjs`. Production handlers still only import from module-pub/platform/shared.

**registry.ts location**: do NOT put a `registry.ts` in `src/backend/jobs/` — it creates jobs→jobs boundary violations. Instead, put the registry map inline in the route handler (`src/app/api/webhooks/qstash/[job]/route.ts`), which is `app-webhooks` type and allowed to import from `jobs`.

**job boundary for appointment-reminders**: the job imports `insertNotificationIdempotent` and `findUserById` from `@/backend/modules/notifications` (module-pub index.ts). These must be exported from `notifications/index.ts` (module-pub). Confirm exports before writing the job.

**`*/N` in JSDoc block comment terminates the comment** (e.g. `"*/15 * * * *"` cron expression inside `/** */`). Replace with prose like "every-15-minutes cron".

**`lead.assigned_to` vs DB lookup**: the `lead.created` event payload already carries `assignedTo` (the staff user_id). The service resolver for `lead_assigned_staff` reads it directly from payload — no additional DB query needed.

**`findLeadAssignedStaff` in repository**: exported from `notifications/repository.ts` and re-exported from `notifications/index.ts` for future use by jobs/other modules, even though the service itself uses the inline payload field.

### UsaLatinoPrime V2 — F3 kanban module (June 2026)

**`staff_profiles` has NO `org_id` column**: `org_id` lives on `users` table. To find staff by org: (1) query `users` where `org_id=X AND kind='staff'`, (2) filter `staff_profiles` `.in("user_id", ids)`. Two-step, no join shortcut via Supabase JS typed client.

**Supabase JS join filters**: `.eq("related_table.column", value)` after `.select("*, related_table!inner(col)")` correctly filters by the join column at the DB level. Used in `listCards` and `findCardByRef` to filter by `kanban_columns.board_id`.

**Kanban broadcast pattern (DOC-25 §1.1)**: use `createServiceClient().channel('board:'+boardId).send({ type: 'broadcast', event: 'card.moved', payload })` after the DB transaction commits. Failures are non-fatal (catch + logger.warn) — client degrades to 30s polling. Never use await inside the catch.

**Seed column idempotence**: `upsert` on `kanban_columns` with `onConflict: "board_id,position"` + `ignoreDuplicates: true` handles concurrent board creation races. The board itself uses `upsert` with `onConflict: "owner_staff_id,board_kind"`.

**Dynamic cross-module calls inside service (R3 + avoid circular)**: `await import("@/backend/modules/cases" as string)` casted with `as string` suppresses TS module-resolution check. Same for `identity`. Pattern established in F2 and extended in F3 kanban.

**`findLeadDuplicates` pure function — test fixture note**: if the fixture has two leads sharing last-4 digits with the test phone AND one is an exact match, the OTHER appears in `weakMatches` (not zero). Test must account for all existing leads with same last-4, not just those that differ from the exact match.

**Realtime channel on Supabase JS service client**: `client.channel(name).send(...)` works with service_role key for broadcast (bypasses Realtime auth policies, correct for server-side). Staff board visibility is enforced by the frontend's subscription policy, not by the server broadcast.

**Domain test count F3 cumulative**: 394 (F0-F3 scheduling) + 59 (kanban domain) = 453 total. All pass in ~6-7s.

### UsaLatinoPrime V2 — F3 code-review fixes (June 2026)

**C-1 reschedule atomicity — insert-first ordering**: `rescheduleAppointment` MUST insert the new appointment first, THEN mark the old one `rescheduled`. Old order (mark-first) caused silent orphan if insert failed. New invariant: insert fail → old stays scheduled (clean); mark-old fail → two scheduled rows (visible, not silent). Documented with comment block in service.ts. Optional: Postgres RPC `reschedule_appointment_tx` in migration 0016_scheduling_rpcs.sql.

**H-3 moveCard ordering invariant**: lead side effects (contacted_at, won/lost) BEFORE card position update. Rationale: if card-update fails after lead-state write, the lead status is updated but card stays in source column — visible inconsistency, recoverable. Event emission and Realtime broadcast ALWAYS last (post all-DB-writes). Postgres RPC `move_kanban_card_tx` in 0016 for true atomicity.

**H-4 reminder ordering — mark-before-enqueue**: `appointment-reminders.ts` must call `markReminderSent` BEFORE `dispatchReminderNotifications` (which calls `enqueueJob`). Old order (notify then mark) had double-email risk on cron re-delivery. New order: if mark returns false (already marked by concurrent run), skip dispatch entirely.

**C-2 expressServiceInterest org validation**: validate `clientUserId` belongs to `clientOrgId` BEFORE any lead creation. Query `users.org_id` for the client — mismatch returns `{ created: false, reason: 'org_mismatch' }`. No phone → `{ created: false, reason: 'no_phone' }` (never invent placeholder phone). Rate limit (60/min/IP) defined as `limitExpressInterestIp` in `platform/ratelimit.ts` with TODO note in kanban/index.ts.

**H-6 LEAD_NOT_FOUND enum**: added to KanbanError union. All lead-by-id 404s (`markLeadWon`, `markLeadLost`, `updateLead`, `createCaseFromLead`) now throw `LEAD_NOT_FOUND`. `LEAD_PHONE_INVALID` reserved strictly for phone format/validation failures.

**M-7 getWeekAgenda DST-safe week-end**: use `addDays(new Date(weekStartLocal), 7).toISOString().slice(0,10)` to get the civil week-end date string, then `fromZonedTime(weekEndStr + "T00:00:00", tz)`. Never add 7×86400000ms to fromUtc (breaks across DST boundary by 1h).

**H-5 PII-safe logging in actions**: `console.error` in `app/` actions must log only `(err as Error)?.message ?? String(err)`, never the raw `err` object (which may carry stack traces with PII). app/ cannot import platform/logger.

**Test count F3 code-review**: 507 total (488 pre-existing + 4 C-1 reschedule + 10 C-2/H-6 kanban + 3 H-4 ordering + 2 M-7 DST domain). All pass in ~11s.

**`vi.mock` for dynamic import of identity**: kanban tests that exercise `updateLead` or `expressServiceInterest` must mock `@/backend/modules/identity` to prevent zxcvbn library load (`decompress is not a function`). Pattern: `vi.mock("@/backend/modules/identity", () => ({ normalizePhoneE164: (p: string) => /^\+\d{7,15}$/.test(p) ? p : null }))`.

**`require()` in test files forbidden**: `@typescript-eslint/no-require-imports` blocks it. Add top-level ES imports (`import { fromZonedTime } from "date-fns-tz"`) even in test files that previously used require() for type-casting.

### UsaLatinoPrime V2 — F3 data-wiring (June 2026)

**`staff_profiles` read from client actor**: use `createServiceClient` (service_role) AFTER enforcing `requireCaseAccess(actor, caseId)`. This is the SOT pattern when a table has no SELECT policy for `authenticated` (deny-by-default for clients). Return ONLY `{displayName, avatarUrl}` — never PII fields like email or role.

**`Actor.role` for clients = `null`** (not `"client"`). The union is `"admin" | "sales" | "paralegal" | "finance" | null`. Client actors have `kind: "client"` and `role: null`. Test fixtures must use `role: null` for client actors.

**Chainable Supabase mock for sequential calls**: when service makes N parallel calls in Promise.all, each call ends with `lt()` or `not()` (the terminal filter). Pattern:
```typescript
function makeChainMock(callQueue: unknown[][], inData = []) {
  let callIdx = 0;
  function makeCall(data: unknown[]) {
    const p = Promise.resolve({ data, error: null });
    return Object.assign(p, { eq: () => makeCall(data), gte: () => makeCall(data),
      lt: () => makeCall(data), not: () => makeCall(data), select: () => makeCall(data),
      in: () => Promise.resolve({ data: inData, error: null }) });
  }
  return { from: () => { const data = callQueue[callIdx++] ?? []; return { select: () => makeCall(data) }; } };
}
```
The `Object.assign(Promise, {chainMethods})` approach makes the chain both thenable (awaitable) and chainable. The `in()` method resolves separately for follow-up queries (e.g. case ownership check).

**`getSalesMetrics` drops prev-appointments query**: the previous-period appointments query was fetched but never consumed (rescheduled trend not implemented). Dropped entirely to eliminate ESLint `no-unused-vars` warning. The service now runs 6 parallel queries, not 7.

**`noShowCount` derivation from attendancePct**: `noShow = completed * (100 - attendancePct) / attendancePct`. This inverts the service formula `attendancePct = completed/(completed+noShow)*100`. Guard: `attendancePct > 0` (if 0, display "—" per DOC-50 §5).

**next-intl strong typing for `t()` key**: `t("legendC" + kind.replace("c",""))` will fail tsc because the argument must be a literal union member. Always use an explicit `Record<kindString, TranslationKey>` mapping instead: `const KIND_TO_KEY = { c1: "legendC1", c2: "legendC2", c3: "legendC3" }; t(KIND_TO_KEY[kind])`.

**`?week=YYYY-MM-DD` searchParam for calendar navigation**: staff citas page derives week from this param or falls back to current week. `toZonedTime(now, tz)` + `startOfISOWeek` + `format("yyyy-MM-dd")` for timezone-correct week calculation.

**Gate order**: run tsc → eslint → vitest → check:i18n in that order. tsc errors surface first; unused-var ESLint warnings are the most common post-tsc issue (drop unused query results, not prefix with `_`).

### UsaLatinoPrime V2 — F4 ai-engine module (June 2026)

**mupdf in Next.js 15**: add `serverExternalPackages: ['mupdf']` to `next.config.ts`. Use dynamic `await import('mupdf')` inside each function (not top-level) — prevents CJS bundling of the ESM/WASM package. mupdf API: `Document.openDocument(buffer, "text/html")` → `.layout(612,792,11)` → `.toPDFDocument()`. For AcroForm fill: drop XFA (delete all keys), then `setTextValue/setChoiceValue`, call `field.update()`, call `doc.bake()`, `doc.saveToBuffer("incremental")`.

**Anthropic streaming via SDK**: `client.messages.stream({ model, max_tokens, system, messages })` returns a stream. `.finalMessage()` returns the completed message. Cache tokens are in `message.usage` but NOT in the SDK's `Usage` type (index signature missing) — must cast via `(message.usage as unknown) as Record<string,number>` to access `cache_creation_input_tokens` and `cache_read_input_tokens`.

**Prompt caching prefix-match rule**: `system[0]` = fixed system_prompt (static), `system[1]` = dataset XML (static). `cache_control: {type: "ephemeral"}` ONLY on the LAST stable block. If no dataset: cacheControl on system[0]. If dataset: cacheControl on system[1], system[0] has NO cacheControl. Nothing variable in system[].

**Cost formula (Anthropic)**: `(regularInput × P_in + cacheCreation × P_in × 1.25 + cacheRead × P_in × 0.10 + output × P_out) / 1_000_000`. regularInput = inputTokens - cacheCreationTokens - cacheReadTokens. Use `parseFloat(value.toFixed(4))`. NOTE: IEEE 754 rounding means `(0.00195).toFixed(4) = "0.0019"` (not "0.0020") — test against actual Node.js behavior.

**Gemini 2.5 Flash pricing (June 2026)**: $0.30 input + $2.50 output per MTok. `(0.00155).toFixed(4) = "0.0015"` (not "0.0016") — IEEE 754 rounding.

**`@google/genai` v2.x multimodal**: `getGeminiModels()` from `platform/gemini.ts` returns models object. `models.generateContent({ model, contents: [{role:"user", parts:[{text},{inlineData:{mimeType,data}}]}], generationConfig: { responseMimeType:"application/json", responseSchema } })` for structured extraction.

**document_translations has NO `error` column**: use `void errorMsg` comment pattern + log error externally. Update only status + updated_at via direct supabase call.

**Dynamic import pattern for test isolation**: if a service adds a top-level `import` of a platform module that requires env vars (e.g. qstash → env.ts), it will break all existing tests of that service's module that don't mock the platform module. Use `await import("@/backend/platform/qstash")` INSIDE the function body (dynamic import) to avoid this. Cases/service.ts `confirmDocumentUpload` enqueueJob uses dynamic import for this reason.

**markRunFailedByCallback idempotence**: the service calls `repoMarkRunFailed` regardless of current run status — the repo layer's `UPDATE WHERE status NOT IN ('completed','cancelled')` guard enforces idempotence at DB level. Do NOT add status-check guards in service layer.

**getRunsForCase authorization**: uses only `requireCaseAccess(actor, caseId)` — does NOT call `can()`. isCurrent logic: iterate runs in DESC version order (as returned by DB); first completed run per (form_definition_id, party_id) key = isCurrent.

**Actor type shape**: `{ userId, orgId, kind: "client"|"staff", role: "admin"|"sales"|"paralegal"|"finance"|null, permissions: ReadonlyMap<ModuleKey, {view,edit}> }`. Client actors have `kind:"client"`, `role:null`. Test fixtures must include all 5 fields.

**Document_extractions idempotence**: `upsertExtraction` uses `ON CONFLICT (case_document_id)`. `markExtractionFailed` directly upserts with `status:"failed"` — no find-then-update pattern.

**vitest mock for supabase chainable builder**: for tests where functions do `createServiceClient().from("t").update({}).eq("id",x).in("status",["y"])`, provide a nested mock: `from: vi.fn(() => ({ update: vi.fn(() => ({ eq: vi.fn(() => ({ in: vi.fn(() => Promise.resolve({data:null,error:null})) })) })) }))`.

**F4 test count**: 528 (F0-F3) + 143 new (domain.test.ts: 113, service.test.ts: 30) = 671 total. All 29 test files pass.

### UsaLatinoPrime V2 — F4-2 catalog stubs + M-12 (June 2026)

**`createAutomationVersion` chains `redetectFields` immediately**: the insert creates the row with `detected_fields: []`, then redetectFields runs in the same call and returns the updated version. Single public function, no polling.

**mupdf 0-indexed pages → 1-indexed domain**: `detectAcroFields` returns pages starting at 0. Repository stores pages starting at 1. Always `+1` when mapping.

**mupdf type → domain type mapping**: `combobox → dropdown`, `radiobutton → radio`, `button → unknown`. All other types pass through as-is (text, checkbox, signature, etc.).

**`new Blob([uint8Array.buffer as ArrayBuffer])` in test fixtures**: TypeScript strict mode rejects `new Blob([Uint8Array<ArrayBufferLike>])` because `ArrayBufferLike` includes `SharedArrayBuffer`. Cast `.buffer as ArrayBuffer` to satisfy the `BlobPart` union.

**Actor.permissions in test fixtures**: use `new Map()` (empty) since `can()` is mocked. Using `new Map([["key", value]])` gives type error because the map key is `string` not `ModuleKey` union. The typed `Actor` import is required to let `new Map()` satisfy `ReadonlyMap<ModuleKey, ...>`.

**M-12 tolerant JSON parsing**: `stripFencesAndParse<T>(text)` — strips ` ```json ``` ` fences, tries parse, falls back to bare parse. 2-attempt retry loop in `proposeFormSegmentation` and `proposeExtractionSchema` ai-engine functions. Retry prompt includes the parse error as feedback (DOC-74 §6.4).

**`validateExtractionSchema` must recurse into properties**: the domain function originally checked only the top-level object for forbidden keys (`$ref`, `if`, `anyOf`, etc.). Added recursion into `properties` values and `items` to catch nested forbidden keys. Gemini portability check must cover the entire schema tree.

**`updateDatasetItem` token recalculation**: recalculates `token_count` only when `content` key is present in the patch (not when only `title`/`tags`/etc. change). On failure, sets `token_count = null` and calls `logger.warn` (non-fatal, same pattern as `createDatasetItem`).

**Dynamic import for cross-module ai-engine calls from catalog**: `const { proposeFormSegmentation } = await import("@/backend/modules/ai-engine")` inside the function body. Prevents circular dependencies at module load time. Mock as `vi.mock("@/backend/modules/ai-engine", () => ({...}))` in tests.

**`deleteDataset` FK guard pattern**: repo throws raw Postgres error; service calls `isFkViolation(err)` and maps to `CATALOG_DATASET_IN_USE`. Test: mock `repo.deleteDataset` to reject with `{ code: "23503" }`.

**F4-2 test count**: 672 (F4-Ola1 baseline) + 28 new (catalog-service-f4.test.ts) = 700 total. 30 test files. tsc 0 errors, eslint 0 warnings (only pre-existing boundaries deprecation). Build: clean.

### UsaLatinoPrime V2 — F4-2 code-review fixes (June 2026)

**Storage path-prefix isolation pattern**: BEFORE calling `validateUploadedObject`, check that the path starts with `{entity_type}/{entity_id}/`. Throw a specific domain error (e.g. `CATALOG_PDF_INVALID_PATH`) without touching storage. This prevents cross-entity path traversal even with catalog:edit permission.

**`validateUploadedObject` is imported dynamically**: `const { validateUploadedObject } = await import("@/backend/platform/storage")` inside the function body (same pattern as createSignedUploadUrl/createSignedDownloadUrl in this module). Mock at module level with `vi.mock("@/backend/platform/storage", () => ({...}))` — Vitest intercepts dynamic imports from the same module graph.

**Org ownership guard for service-client mutations**: pattern = `const existing = await repo.findEntity(id); if (!existing || existing.org_id !== actor.orgId) throw catalogError("X_NOT_FOUND")`. Use the same error as not-found to avoid existence leakage. Apply to EVERY mutator that uses service client (which bypasses RLS).

**M-2 org ownership for testGeneration**: form → phase → service → org_id chain. Requires `repo.findPhaseById` and `repo.findServiceById`. All return the same `CATALOG_FORM_NOT_FOUND` error (anti-enumeration).

**M-3 deleteQuestion status guard**: pattern = `repo.findVersionByQuestion(questionId)` (question → group → version). Required new `findVersionByQuestion` repo function (two-step: question → group_id → findVersionByGroup). Returns null for orphaned questions → skip guard.

**M-4 AI-first ordering in aiProposeStructure replace mode**: call `proposeFormSegmentation` first, then delete existing groups. Prevents empty-version state when AI throws. Preserves existing content on AI failure.

**M-5 listDatasets bad-actor pattern**: never fabricate an Actor just to call `can()`. Change signature to `listDatasets(actor: Actor)` and use `can(actor, ...)`. The fabricated actor with `userId:""` would pass the `can()` check but bypass actual actor validation.

### UsaLatinoPrime V2 — Etapa D Pre-Mortem backend (June 2026)

**`form_definitions` has NO `service_id`**: it has `service_phase_id` → `service_phases.id`. To find form_definitions for a service: `cases.service_id → service_phases.service_id → form_definitions.service_phase_id`. Three-step join (all via Supabase JS client).

**pgvector RPC client.rpc() must be inline**: `const { data, error } = await client.rpc("match_dataset_items", { ... })` — NEVER destructure `.rpc` from client object (breaks `this` binding). Same rule applies to all RPC calls.

**`matchDatasetItems` RPC arg names**: `query_embedding` (string, vector literal "[0.1,…]"), `p_dataset_id` (uuid), `match_count` (int, default 8), `filter_tags` (text[] or undefined). RPC returns similarity column not present in `ai_dataset_items` Row type.

**Semantic → lexical fallback pattern**: try `embedText(query)` + `matchDatasetItems()`; if embedText throws OR matchDatasetItems returns [] → call `loadDatasetItems(datasetId)` + `selectDatasetItems(allItems, {}, budget)`. Log warn on embedText failure; log nothing on empty matchDatasetItems (expected until backfill completes).

**Pre-Mortem JSON cast pattern**: `(Array.isArray(row.reasons) ? row.reasons : []) as unknown as PreMortemReason[]` — direct cast from `Json[]` to a typed interface requires double-cast through `unknown`.

**`findLatestEligibleRunForPreMortem` loop pattern**: fetches all completed runs for case in DESC created_at order, then loops checking each run's `ai_generation_configs.pre_mortem_enabled`. Returns first match. Avoids N+1 by checking at most a handful of runs (usually 1-2 completed runs per case).

**AiEngineError code union extension**: adding a new code (e.g. `PREMORTEM_NO_ELIGIBLE_RUN`) requires editing only the string union in the constructor's `code` parameter. No separate class needed.

**Tolerant critic output**: use `stripFencesAndParse<T>` (already in service.ts) for all AI JSON responses. Validate `overallRisk` enum explicitly (default to `"medium"` on unknown value). Filter reasons with `isDenialReasonCode(r.code)` before mapping.

**Test file for new service functions**: when the new functions live in service.ts alongside existing ones, add them to the SAME vi.mock('../repository') factory by extending the hoisted mock object. Never create a new vi.mock('../repository') — that would conflict with the existing one. Create a new test file (pre-mortem.test.ts) that sets up all mocks independently.

**H-3 raw_text reserved field**: `validateExtractionSchema` checks `obj.properties?.raw_text` existence and rejects it. The recursive walk already covers nested schemas so the check only needs to be at each properties-level (not at arbitrary depth).

**`findVersionByQuestion` and `findDatasetItem` repo additions**: add to `vi.mock("../repository", ...)` in test files whenever the service functions that use them are being tested. Missing exports in the mock produce a clear vitest error: "No X export is defined on the mock".

**F4-2 CR test count**: 700 (post F4-2 stubs) + 27 new (catalog-service-cr.test.ts) = 727 total. 31 test files. All gates clean.

### UsaLatinoPrime V2 — F4-Ola3 form runtime backend (June 2026)

**JSONB merge pattern (RF-DIA-023 last-writer-wins)**: fetch-then-spread in JS — `const merged = { ...existingAnswers, ...patch }`. No Postgres function needed. Must cast `merged as Json` when passing to Supabase typed `.update()` because `Record<string,unknown>` does not satisfy Supabase's `Json` union (import `Json` from `@/shared/database.types`).

**PII security contract (DOC-74 §7.1)**: `decryptPiiField` is called LOCALLY in `resolveBySource`. The decrypted value is used only to fill the AcroForm field. It is NEVER: logged, emitted in an event payload, sent to any AI endpoint, or stored in `answers`. Mock `@/backend/platform/crypto` in tests to assert `decryptPiiField` is called only for `pii.*` profile fields.

**`resolveBySource` is exported from cases/index.ts** (module-pub). It is consumed by both `getFormForClient` (wizard pre-fill) and `generateFilledPdf` (PDF rendering). Tests mock all 4 source paths independently.

**`automation_version_id` frozen at first save**: `insertFormResponse` receives the version ID resolved at save-time. Subsequent saves call `mergeFormAnswers` without touching `automation_version_id`. `generateFilledPdf` gates `FORM_VERSION_MISMATCH` if `response.automation_version_id !== publishedVersion.id`.

**`filled_by` gate for PDF**: `generateFilledPdf` allows PDF when `status=submitted` AND `filled_by=staff`. For `filled_by=client`, requires `status=approved` (client must be approved before PDF generation). Gate throws `FORM_PDF_BLOCKED` in both denied cases.

**`listFormResponsesForCase` unused**: imported in service.ts but not used by any exported function (getFormForClient builds from questions directly). Remove from the named import block to satisfy ESLint `no-unused-vars`.

**Storage PDF upload**: use `uploadBytesToStorage(bucket, path, bytes, contentType)` added to `platform/storage.ts`. Download URL for the generated PDF: `createSignedDownloadUrl("generated", path)`. The signed URL is the return value of `generateFilledPdf`.

**`case_form_responses` `party_id` nullable**: `findFormResponse(caseId, formDefinitionId, partyId)` must use `.is("party_id", null)` when partyId is null (NOT `.eq("party_id", null)` which does not filter NULL rows in PostgREST).

**F4-Ola3 test count**: 727 (F4-Ola2 baseline) + 55 new (form-runtime.test.ts) = 782 total. 32 test files. tsc 0 errors, eslint 0 warnings (only pre-existing boundaries deprecation). Build: clean.

### UsaLatinoPrime V2 — F5 expediente module (June 2026)

**`expedientes_one_draft_per_case_idx`**: partial unique index `WHERE (status = 'draft')`. The DB enforces one draft per case; service ALSO enforces via `findDraftExpedienteForCase` before insert for a better error code (`EXPEDIENTE_DRAFT_EXISTS`).

**`expediente_items` position constraint is DEFERRABLE**: `unique (expediente_id, position) deferrable initially deferred`. When reordering via JS (not a single TX), use a two-phase update: (1) set all positions to negative temps, (2) set final positions. Prevents constraint violations from intermediate position collisions.

**`resolveItemBytes` pattern**: `createServiceClient().storage.from(bucket).download(path)` returns `{ data: Blob, error }`. Convert with `await data.arrayBuffer()` then `new Uint8Array(arrayBuffer)`. Do NOT use `bytes.buffer` from mupdf WASM outputs (large SharedArrayBuffer slice — use `uploadBytesToStorage` which handles it correctly).

**Logical FK validation for expediente items**: The DB `ref_id` column has NO FK constraint (logical FK validated in service). Pattern: switch on `item_type` → query the correct source table (`cover_renders`, `ai_generation_runs`, `case_form_responses`, `case_documents`). `external_file` type uses `external_file_path` instead.

**`emitExpedienteCompiled` in createCorrectionAttempt**: the correction creates a new draft, but we still emit the event so consumers (future F6 finance wiring) can hook in. The `createExpediente` function does NOT emit (it's just a draft shell — no compilation happened).

**`listCoverRendersForCase` in repo**: exported but NOT imported in service.ts (material library read uses `listCoverRendersForMaterial` instead). Remove from service imports to avoid `no-unused-vars`. Pattern confirmed.

**F5 expediente test count**: 782 (F4-Ola3 baseline) + 73 new (expediente.test.ts) = 855 total. 33 test files. tsc 0 errors, eslint exit 0.

### UsaLatinoPrime V2 — F6-Ola1 billing two-stage review fixes (June 2026)

**Stripe webhook idempotency — canonical pattern**: use `claimWebhookEvent()`/`markWebhookEventProcessed()` from `platform/webhook-events.ts`. Returns `"fresh"|"duplicate"|"retry"`. `"duplicate"` = processed_at set (safe to skip). `"retry"` = processed_at null (prior attempt crashed, re-run handler). NEVER return 200 on 23505 without checking processed_at — this caused silent payment failures.

**applyPaymentSuccess crash-safe order**: updatePayment → insertLedger → updateInstallment(paid). The `status="paid"` guard (idempotency) must come AFTER ledger insert. If crash between steps 1-2, retry re-runs all steps (installment still "pending"). If crash between steps 2-3, retry re-runs all steps too. Only after step 3 does the guard fire safely on future retries.

**IDOR fail-closed for client access**: when `findInstallmentCaseId` returns null, client actor MUST get `AuthzError("forbidden_case")` — never continue without verification. Staff passes through `can(actor, 'billing', 'edit')` which is independent of caseId.

**BLOCKER-2 TOCTOU double-checkout prevention**: insert payment row (status=pending, method=stripe, session_id=NULL) BEFORE calling Stripe. Unique partial index `payments_active_stripe_unique_idx ON payments(installment_id) WHERE status='pending' AND method='stripe'` raises 23505 on concurrent insert → map to `PAYMENT_IN_PROGRESS`. After Stripe session created, `updatePayment(localPayment.id, {stripe_checkout_session_id})`. BD is the mutex, not a pre-check query.

**MED-3 orgId from BD**: always `findOrgIdForCase(caseId)` for ledger entries. Never `session.metadata?.org_id` or `charge.metadata?.org_id` — those are controllable by whoever created the Stripe object.

**Rate limiters in service layer**: if route layer (app layer) can't import platform, move rate limiting into the service function (service.ts/module-int can import platform). Throw `BillingError("RATE_LIMITED")`, route maps to HTTP 429.

**STRONG-4 repo boundary**: never export raw repo functions (findInstallmentById, findInstallmentCaseId) from module-pub index.ts. Route handlers must use service functions which call them internally. Document the decision in index.ts.

**LOW-1 safe INTERNAL_ERROR**: actions.ts `fail()` must log the raw error server-side (logger.error) and return generic message to client. Never `err.message` in response — may expose Postgres internals.

**Nit: dead Zod guard**: after `z.string().min(1)` in schema, `if (!parsed.reason)` is always false (Zod already rejected empty string). Remove to avoid confusion.

**Test pattern — AuthzError mock**: `AuthzError: class AuthzError extends Error { reason: string; constructor(reason: string) { super(reason); this.reason = reason; this.name = "AuthzError"; } }` — must store reason in property, not hardcode it.

**Test pattern — call order assertions**: `const callOrder: string[] = []` + `mockFn.mockImplementation(async () => { callOrder.push("label"); })` → `expect(callOrder.indexOf("a")).toBeLessThan(callOrder.indexOf("b"))`.

**Migration numbering**: last existing migration is 0018. New migration for payments unique index = `0019_payments_active_stripe_unique.sql`.

### UsaLatinoPrime V2 — F5-Ola3 Andrium handoff (June 2026)

**`findCasePlanRequiresLawyerValidation` in expediente/repository**: two-step service_role query: `cases.service_plan_id` → `service_plans.requires_lawyer_validation`. Determines whether `sendToFinance` requires `status='approved'` (with_lawyer) or `status='compiled'` (self). Place in the expediente repo to keep the gate within the module boundary (no cross-module call needed).

**`sendToFinance` block order**: check `sent_to_finance`/`printed` first (EXPEDIENTE_ALREADY_SENT_TO_FINANCE), THEN fetch plan (avoids unnecessary DB call on re-send). Gate codes: `EXPEDIENTE_NOT_APPROVED` (with_lawyer) and `EXPEDIENTE_NOT_COMPILED` (self).

**`emitExpedienteSentToFinance` payload must include `orgId`**: consumers (kanban, cases) need `orgId` to route to the right staff board. The original F5 payload didn't have it — added in Ola3.

**`onExpedienteSentToFinanceCase` bypasses domain gate**: the case may jump from `active` directly to `ready_for_delivery` (ruta corta plan self — no intermediate `in_validation`). This path doesn't exist in `CASE_TRANSITIONS`, so use `updateCase(caseId, {status:'ready_for_delivery'})` directly (service_role), same pattern as `onDownpaymentConfirmed`. Do NOT call `transitionCaseSystem` for this consumer.

**`onExpedienteSentToFinance` kanban consumer**: uses exact same pattern as `onContractSigned`. Key difference: targets `"Por imprimir"` column (position 4, label-based search) instead of the entry column. Column label lookup: `columns.find(c => c.label === "Por imprimir")`. The board uses `seedColumnsFor("collections")` which seeds this column at position 4.

**Kanban `findCardByRef` idempotency semantics**: checks if a card with (board_id, ref_type, ref_id) already exists on ANY column. If it does, skip — the card may have been moved by Andrium. The DB unique `(ref_type, ref_id, column_id)` constraint is a secondary guard against column-level duplicates only.

**F5-Ola3 test count**: 855 (F5 baseline) + 35 (andrium.test.ts) + 6 (andrium-consumer.test.ts) + 16 (andrium-consumers.test.ts) = 912 new in those files; total suite 1017 across 41 test files. tsc 0 errors, eslint exit 0.

### UsaLatinoPrime V2 — F6-Ola2 Andrium cobranza/impresion (June 2026)

**`case_members` has NO `is_active` column**: `is_active` lives on `users` table (not `case_members`). The `case_members` columns are: `id, case_id, user_id, access_role, created_at, updated_at`. To filter active clients from a case: join `case_members` → `users!inner(kind, is_active, ...)`, then post-filter `m.users.kind === "client" && m.users.is_active`. Never `.eq("is_active", true)` on `case_members`.

**`orgId` in `InstallmentOverdueEvent` payload**: added to enable kanban listeners to find finance staff by org. Kanban consumer `onInstallmentOverdue` reads `payload.orgId` → `findFinanceStaff(orgId)` → finds/creates board. If `!payload.orgId` guard fires, skip without error.

**`listPrintQueue` (expediente/repository)**: multi-level join from `expedientes` → `cases!inner` → `client_profiles!cases_primary_client_id_fkey`, `services`, `service_plans` + `staff_profiles!expedientes_sent_to_finance_by_fkey` for sentByName. Use FK hint syntax when multiple FKs point to the same table. `withLawyer = service_plans.requires_lawyer_validation`. Post-filter by `org_id` for safety.

**`listDueCalendar`/`listOverdueForCollections` `case_members` join**: remove `is_active` from `case_members` select; instead add `users!inner(kind, is_active, client_profiles(...))` and filter `m.users.is_active && m.users.kind === "client"` in JS post-processing.

**`OverdueItemRepo` uses `daysLateVal`**: repo returns `daysLateVal` (avoids shadowing `daysLate` domain function). Service `listOverdueForCollections` maps `r.daysLateVal → daysLate` in the DTO. Always add a mapping step in service when repo field name differs from DTO field name.

**`installment-reminders` job**: calls `markOverdues(actor, today)` → `listReminderTargets(today)` → per-target: mark BEFORE dispatch (H-4 ordering). `today` comes from payload (org TZ) or falls back to UTC. Job does NOT abort on single-target failure — catch-and-continue per target, throw on `markOverdues`/`listReminderTargets` failure (trigger QStash retry).

**Kanban self-heal column-less board**: when `columns.length === 0` after `listColumns`, call `seedBoardColumns(board.id)` then re-read columns. Use `repo.seedBoardColumns` not `repo.createBoardWithSeed` (board already exists). Idempotency: `onInstallmentOverdue` creates card if not found, moves to Vencidas if exists elsewhere, skips if already in Vencidas. `onExpedientePrinted` is no-op if no card (maintenance event, not creation).

**Actor fixtures in Vitest**: `new Map([["billing", {...}]]) as import("@/backend/platform/authz").Actor` — the `as Actor` cast is required because `Map<string, ...>` is wider than `ReadonlyMap<ModuleKey, ...>`. Without the cast, tsc errors on the `permissions.forEach` type mismatch. Empty `new Map()` also works if `can()` is mocked.

**F6-Ola2 test count**: 1017 (F5-Ola3 baseline) + 23 (service-ola2.test.ts) + 13 (ola2-consumers.test.ts) + 7 (print-queue.test.ts) = 1060 total. 44 test files. tsc 0 errors, eslint 0 code warnings.
