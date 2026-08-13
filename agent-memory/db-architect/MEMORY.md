# Memoria de oficio — db-architect
> Máximo 200 líneas cargadas. Curaduría: agent-ops (2026-08-13).
> Sembrada moviendo acá los patrones de esquema/migraciones/RLS/pgTAP que estaban en
> `backend-builder/MEMORY.md` (dueño equivocado). backend-builder consume el esquema
> por tipos generados; acá vive cómo el esquema se diseña y se prueba.

## Proyecto UsaLatinoPrime V2 — coordenadas
- Supabase ref: uexxyokexcamyjcknxua, Postgres 17.
- Migraciones: `C:\Users\mauri\Documents\Trabajos\usalatino-v2\supabase\migrations\`
- Seeds: `...\supabase\seeds\` · Tests RLS: `...\supabase\tests\rls\`
- Staff demo UUIDs: Henry=...0001, Vanessa=...0002, Diana=...0003, Andrium=...0004.
- Numeración de migraciones: correlativa de 4 dígitos (`0019_payments_active_stripe_unique.sql`); leer la última antes de crear una nueva.

---

## Patrones de migración y RLS (Supabase / Postgres 17)

**Helper location rule**: Define a SECURITY DEFINER helper in the same migration that creates its underlying table, not in 0001. Example: `is_case_member` defined in 0004 (case_members table created there); `is_conversation_participant` defined in 0010 (conversation_participants table created there). The 0001 grant block explicitly defers these.

**RLS policy naming**: `{tablename}_{op}` single policy per op; use `{tablename}_{op}_client` / `{tablename}_{op}_staff` when a single op needs two branches joined by OR (Postgres unions them).

**`messages` table has no `updated_at`**: immutable by design (no trigger needed). The DOC-30 DDL shows only `created_at`.

**`is_conversation_participant` grant**: add `grant execute on function public.is_conversation_participant(uuid) to authenticated;` in 0010_messaging.sql (NOT in 0001, because the underlying table doesn't exist until 0010).

**EXCLUDE constraint for overlap**: requires `btree_gist` extension (created in 0001). Use `tstzrange(starts_at, ends_at)` — not `daterange` — for timestamptz columns. The partial WHERE clause `where (status = 'scheduled')` is supported by btree_gist.

**`ledger_entries` partial unique**: `unique (payment_id, kind) where payment_id is not null` — accounting idempotency for auto-generated entries. Standard Postgres partial unique index.

**States = text + CHECK**: never `CREATE TYPE ... AS ENUM`. This is a hard project rule (DOC-30 C8) — avoids `ALTER TYPE` debt.

**`service_role` bypass patterns**: tables where `authenticated` has NO insert/update policy are effectively service_role-only. Comments mark them as `-- P-SERVICE-ROLE-ONLY`. Do NOT add a restrictive policy that matches nothing — just leave no policy (deny-by-default is correct).

**`(select public.helper())` pattern in policies**: wrap every helper call in a subselect so Postgres evaluates it once per statement (InitPlan), not per row. This is mandatory for STABLE SECURITY DEFINER functions used in RLS.

**`messages` unique index on conversation + created_at**: named `messages_conversation_created_at_idx` for cursor-based pagination. DOC-30 declares it inline: `created_at índice: (conversation_id, created_at desc)`.

**`calls` unique partial**: `unique (conversation_id) where (status in ('ringing','active'))` — one live call per conversation.

**`legal_validations` polling index**: partial index `where (status in ('sent','queued','in_review'))` — only rows awaiting response scanned by cron.

**FK cycle pattern (services ↔ service_phases)**: Create `services` without `entry_phase_id` FK, create `service_phases` with FK to `services`, then `ALTER TABLE services ADD CONSTRAINT ... FOREIGN KEY (entry_phase_id) REFERENCES service_phases`. All in 0002.

**Deferred FKs across migrations**: `leads.won_case_id` and `staff_tasks.case_id` created as bare UUID columns in 0003 (cases doesn't exist yet). FK constraints added via `ALTER TABLE` in 0004 after `cases` is created.

**`person_records` policy forward reference**: The SELECT policy in 0001 references `case_parties` and `case_members` (created in 0004). This is valid — Postgres resolves table names at query time. Marked with `TODO(SoT)` comment.

**Auth hook claim is `user_role` not `role`**: `role` is reserved by Supabase/PostgREST (maps to Postgres role). Custom staff role MUST be `user_role`. Confirmed across DOC-22 §3.1 and DOC-31 N1.

**Partial unique index for at-most-1 active**: `create unique index idx on table(org_id) where is_active = true` — enforces single active row per org without a global constraint.

**`_case_number_counters` internal table**: hidden from authenticated users (no RLS policies = deny-by-default). Only accessible via `next_case_number()` SECURITY DEFINER function.

**Column-level GRANT pattern**: `revoke update on table from authenticated; grant update (col1, col2) on table to authenticated;` — restricts which columns client can update even when the row-level policy allows the UPDATE.

### Supabase Realtime — private channels
- Policies on `realtime.messages` use `realtime.topic()` for channel name matching.
- `split_part(realtime.topic(), ':', 2)::uuid` throws cast error on malformed topics = effective deny.
- Channels for UsaLatino V2: `user:{uid}`, `conv:{id}`, `board:{id}`, `team:{org_id}`.
- `alter publication supabase_realtime add table ...` is additive only; hard to remove in prod.

### Storage policies — path parsing helpers
- `(storage.foldername(name))[2]::uuid` = second segment UUID (e.g. case/{uuid}/...).
- `(storage.foldername(name))[1]::uuid` = first segment UUID (e.g. avatars/{user_id}/...).
- Omit INSERT/UPDATE/DELETE policies = service_role only for that operation.

### audit_log — immutability trigger pattern
- Separate function `prevent_audit_log_mutation()` on BEFORE UPDATE OR DELETE; raises exception.
- audit_log has NO `updated_at` column — rows are immutable post-INSERT by design.
- System actors: `actor_user_id IS NULL` + `action LIKE 'system.%'` enforced via CHECK constraint.

### Seeds — auth.users bootstrap in local dev
- Wrap direct insert into `auth.users` in a DO block guarded by `current_setting('app.environment', true) != 'production'`.
- Use fixed UUIDs (e.g. ...0001 through ...0004) for staff; resolve by email in downstream inserts.
- In prod/staging: `scripts/bootstrap-staff.mjs` uses auth.admin.createUser API.

---

## Tests pgTAP de RLS

- `supabase test db` discovers all *.sql under supabase/tests/ recursively. Files in subdirs (tests/rls/) ARE picked up.
- Each file: `begin; create extension if not exists pgtap with schema extensions; select plan(N); ...; select * from finish(); rollback;`
- auth.users minimum columns for fixture INSERT: `id, instance_id, aud, role, email, created_at, updated_at`. `instance_id = '00000000-...'`, `aud='authenticated'`, `role='authenticated'` for non-anon users.
- JWT simulation: `set local role authenticated;` then `select set_config('request.jwt.claims', json_build_object('sub',uid,'role','authenticated','org_id',oid,'user_kind',kind,'user_role',role_or_null)::text, true);`
- Between scenario switches: `set local role postgres;` (reset to superuser bypass) THEN `set local role authenticated;` — do NOT just call `set local role authenticated` again without resetting, because the claims accumulate.
- `\set` variables with embedded quotes: `\set varname '''uuid-string'''` — triple quotes give you `'uuid'` in the SQL. Reference as `:varname::uuid`. NOT usable inside `$$ ... $$` dollar-quoted strings in throws_ok/lives_ok — use hardcoded literals there.
- Catalog skeleton minimum for cases: `services (id, org_id, name_i18n jsonb, is_active bool)` + `service_phases (id, service_id, name_i18n jsonb, position int)` + `service_plans (id, service_id, name_i18n jsonb, price numeric, currency text, is_active bool)`. All three required by `cases` FK chain.
- admin bypass test: insert staff user with `role='admin'` in staff_profiles, NO rows in employee_module_permissions — has_module() still returns true for any module.

### UsaLatinoPrime V2 — pgTAP RLS F1 patterns (June 2026)

**Real `services` schema** (0002_catalog.sql): columns are `slug` (NOT NULL, unique), `category` (check: 'migratorio'|'empresarial'|'familiar'), `label_i18n` (NOT `name_i18n`), `is_active` default false. F0 tests used incorrect `name_i18n` — F1 tests use the real schema.

**Real `service_plans` schema**: `kind` (check: 'self'|'with_lawyer'), `price_cents` integer, `currency` char(3). No `price numeric` or `name_i18n` columns.

**Real `service_phases` schema**: `slug` NOT NULL, `label_i18n` NOT NULL, `position` NOT NULL. No `name_i18n`.

**Real `leads` schema**: `phone_e164` NOT NULL (not `contact_name`). `interested_service_id` is the FK column (not `service_id`).

**`contracts` NOT NULL columns**: `plan_snapshot jsonb NOT NULL`, `parties_snapshot jsonb NOT NULL`. Use `'{}'::jsonb` or `'[]'::jsonb` for minimal test values.

**`legal_validations` chain**: requires `expediente_id` FK (0009 depends on 0008). To test legal_validations you must also insert an expediente.

**`expedientes` schema**: `case_id`, `attempt_no` integer NOT NULL (default 1), `status` (default 'draft'), `built_by` references staff_profiles.

**services SELECT policy**: non-catalog staff who are `is_staff()=true` CAN see active+non-archived services via the second branch of the OR. Only draft/archived services require the catalog module. When asserting "staff without catalog sees 0 services", if there are active services they will be visible (count=1, not 0).

**T13 (RF-ADM-045) pattern**: DELETE employee_module_permissions row as postgres mid-transaction; then re-set `set local role authenticated` with same JWT claims — `has_module()` re-evaluates the table on next statement (InitPlan). No re-login needed; effect is immediate within the same session.

**F1 UUID scheme**: files 06-09 use prefixes f6/f7/f8/f9 with letter suffixes f00100-f00e00 to avoid collision with F0 (a/b/c/d/e series).

**auth.users GoTrue token columns**: ALL fixture inserts into auth.users must include 8 token columns set to '' to prevent GoTrue 500 errors: `confirmation_token, recovery_token, email_change, email_change_token_new, email_change_token_current, phone_change, phone_change_token, reauthentication_token`. Confirmed in seeds/01_org_y_staff.sql and applied to all 9 test files.

**`notifications` column is `type` NOT NULL** (not `kind`). INSERTs must use `type` as column name (0011_notifications_campaigns.sql confirmed).

**`conversations.scope` NOT NULL** with CHECK: `(scope='case')=(case_id IS NOT NULL) AND (scope='lead')=(lead_id IS NOT NULL)`. For fixtures with neither FK, use `scope='support'`. Bare `INSERT INTO conversations (id, org_id, title)` fails.

**`community_posts` real schema**: `kind` (default 'text'), `body text`, `is_published`. No `title_i18n` or `body_md` columns (0012_community.sql confirmed).

**`audit_log` real schema**: `entity_type text NOT NULL`, `entity_id uuid`. No `table_name` or `record_id` columns. `actor_user_id IS NULL` only allowed when `action LIKE 'system.%'` (0013_audit.sql CHECK constraint).

**`leads` real schema**: `phone_e164 text NOT NULL`. FK to services is `interested_service_id` (nullable). No `contact_name` column (use `full_name`). No direct `service_id` column (0003_leads_kanban.sql confirmed).

---

## Hechos de esquema dispersos (recogidos de revisiones y del trabajo de backend)

Cada uno costó una confusión real; verificar contra `database.types.ts` antes de asumir lo contrario.

- **`staff_profiles` NO tiene `org_id`**: el `org_id` vive en `users`. Para buscar staff por org: (1) query a `users` where `org_id=X AND kind='staff'`, (2) filtrar `staff_profiles` con `.in("user_id", ids)`. Dos pasos, no hay atajo por join con el cliente tipado de Supabase.
- **`case_members` NO tiene `is_active`**: vive en `users`. Columnas reales de `case_members`: `id, case_id, user_id, access_role, created_at, updated_at`. Para filtrar clientes activos de un caso, joinear `users!inner(kind, is_active, ...)` y post-filtrar en JS.
- **`employee_module_permissions`** tiene FK `staff_id` (NO `user_id`), que referencia `staff_profiles(user_id)`.
- **`users`** no tiene `display_name`; tiene `email`. El nombre del cliente vive en `client_profiles (first_name, last_name, preferred_name)`.
- **`form_definitions` NO tiene `service_id`**: tiene `service_phase_id` → `service_phases.id`. Para llegar de un caso a sus forms: `cases.service_id → service_phases.service_id → form_definitions.service_phase_id` (join de tres pasos).
- **`case_form_responses.party_id` es nullable**: en PostgREST hay que usar `.is("party_id", null)`, NUNCA `.eq("party_id", null)` (que no filtra las filas NULL).
- **`document_translations` no tiene columna `error`**: loguear el mensaje afuera y actualizar solo `status` + `updated_at`.
- **`expedientes_one_draft_per_case_idx`**: índice único parcial `WHERE (status = 'draft')` — la BD garantiza un solo borrador por caso; el service igual chequea antes para dar un código de error mejor (`EXPEDIENTE_DRAFT_EXISTS`).
- **`expediente_items` tiene `unique (expediente_id, position) DEFERRABLE INITIALLY DEFERRED`**: al reordenar desde JS (no en una sola TX) hacer update en dos fases — (1) todas las posiciones a temporales negativas, (2) posiciones finales.
- **`expediente_items.ref_id` no tiene FK**: es una FK lógica que valida el service según `item_type` contra la tabla correcta (`cover_renders`, `ai_generation_runs`, `case_form_responses`, `case_documents`); `external_file` usa `external_file_path`.
- **`payments_active_stripe_unique_idx`**: `unique (installment_id) WHERE status='pending' AND method='stripe'` — es el mutex que previene el doble checkout. La BD es el mutex, no un pre-check.
- **`ledger_entries`**, **`calls`**, **`legal_validations`**: ver los índices parciales arriba.
- Grants por defecto de Supabase: TODA función nueva en `public` recibe EXECUTE automático para `anon` Y `authenticated` (y `service_role`), a diferencia de Postgres vanilla. Si la intención es "solo authenticated", hay que `revoke execute ... from anon` explícitamente — omitirlo deja a anon con EXECUTE en silencio.

## Trampas pagadas en migraciones de reestructuración de catálogo

- Un `UPDATE ... SET service_phase_id = <superviviente>` a secas revienta con 23505 en toda tabla con `unique(case_id, service_phase_id[, ...])` apenas UN caso tenga filas en ambas fases. La migración 0079 pasó en prod solo porque todavía no había solapamiento. Dedupear defensivamente antes del UPDATE ciego o manejar `on conflict`.
- El `sequence_number` de `appointments` NO se remapea al fusionar fases: una cita ya reservada queda reinterpretada contra la NUEVA plantilla en esa misma posición, con label/objetivos/duración posiblemente distintos de lo que el cliente reservó. Los chequeos de integridad referencial no lo detectan (es deriva semántica, no FK rota). Remapear explícitamente o documentar el trade-off en el encabezado de la migración y confirmarlo con producto antes de aplicar a prod con reservas reales.
- Renumerar posiciones: calcular `coalesce(max(position),-1)+1` como offset ANTES de mover las filas y asignar `position = offset + row_number()-1`. El rango de append nunca solapa, sin depender del constraint diferido.
- Preferir `INSERT ... ON CONFLICT DO UPDATE` sobre DELETE+INSERT en plantillas de agenda (`service_appointment_schedule`) cuando ya hay casos que las referencian.
- `ALTER TABLE ... DISABLE/ENABLE TRIGGER` dentro de un bloque DO es transaccional y correcto, pero toma ACCESS EXCLUSIVE y lo retiene hasta el commit — o sea, por el resto del bloque, no solo por el DELETE. Mantener la secuencia disable/delete/enable lo más apretada posible.
- Agregar un índice único parcial NUEVO a una tabla caliente puede hacer explotar escritores PREEXISTENTES que no capturan el `unique_violation` (0111 sobre `payments`). Grepear todos los escritores que puedan tocar el constraint nuevo.
- `jsonb_agg(...)` sobre un conjunto vacío devuelve NULL, no `[]` — cualquier UPDATE que bumpee secciones jsonb debe guardarse con `AND c.sections IS NOT NULL` para no borrar la config en silencio.
- **Deriva de seeds**: los slugs de `supabase/seeds/*.sql` se apartaron de la realidad de producción desde la migración 0048 (`sustentos`/`reforzar` en el seed vs `fase-1`/`fase-2` en prod). Consecuencia: muchas data-migrations de catálogo hacen no-op silencioso en una base fresca/CI porque sus WHERE no matchean nada — es decir, CI nunca probó su salida real. Auditar si alguna vez los tests de catálogo divergen del comportamiento de prod.

## Preferencias de Mauri/Henry
- Estados = `text` + CHECK, jamás `CREATE TYPE ... AS ENUM` (regla dura del proyecto, DOC-30 C8).
- Migraciones a prod: SIEMPRE acto humano deliberado desde la PC Windows, con gate. El MCP de Supabase apunta a DEV.
- Migración primero, código después. El orden inverso rompe queries por columna desconocida en PostgREST.
