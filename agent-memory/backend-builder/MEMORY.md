# Memoria de oficio — backend-builder
> Máximo 200 líneas cargadas. Curaduría: agent-ops (2026-08-13).
> Esquema, migraciones, RLS, Storage policies, triggers, seeds y pgTAP ya NO viven acá:
> son de `db-architect`. Acá vive APIs, lógica de negocio, jobs e integraciones.

## Arquitectura y boundaries (usalatino-v2, `eslint-plugin-boundaries`)

- Capas: `app` → `module-pub` (`index.ts` y `actions.ts`) → `module-int` (service/repository) → `platform` → `shared`.
- **`app` SOLO importa `app, module-pub, frontend, shared`.** NUNCA `platform/*` ni service/repository directos. Si una action de app necesita storage/signed-url/wrap de PDF, esa lógica se muda DENTRO del módulo (module-pub sí puede importar platform).
- **`jobs` solo importa module-pub, platform y shared** (regla R3). Si un job necesita una función interna, primero se exporta desde el `index.ts` del módulo. Un `registry.ts` dentro de `src/backend/jobs/` genera violación jobs→jobs: poner el mapa del registry inline en el route handler (`app/api/webhooks/qstash/[job]/route.ts`, que es tipo `app-webhooks`).
- Reglas que hubo que agregar a `eslint.config.mjs`: `{from:"module-pub", allow:["module-int","platform","shared","module-pub"]}`, `{from:"app", allow:["app","module-pub","frontend","shared"]}`, `"jobs"` dentro del allow de `from:"jobs"` (los tests bajo `jobs/__tests__/` también son tipo `jobs`), `settings["boundaries/ignore"]: ["**/*.css"]`.
- **Dependencias circulares entre módulos**: import dinámico dentro del cuerpo de la función — `await import("@/backend/modules/X")`, casteando el path `as string` cuando el módulo aún no existe, con try/catch para degradar. Patrón establecido en `onDownpaymentConfirmed` y extendido a kanban/catalog/ai-engine. El cast tipado (`as { fn: (a) => R }`) evita necesitar el `eslint-disable` de `no-explicit-any`.
- `export { X } from "./repository"` re-exporta sin necesitar un `import` previo; importarlo y re-exportarlo por separado dispara `no-unused-vars`.
- Los archivos `"use server"` SOLO pueden exportar funciones async: nada de re-exports de no-actions ni `void x` a nivel de módulo.

## Autorización — el contrato que más se rompe

- **`can(actor, mod, op)` verifica PERMISO, no PERTENENCIA.** Todo el repository layer usa `createServiceClient()` (service-role, bypassa RLS), así que la autorización es 100% responsabilidad del service layer. Toda mutación que reciba una FK cruda: cargar la entidad primero y comparar `entity.org_id === actor.orgId`, tirando el MISMO error que not-found (anti-enumeración). Este gap reincidió ≥9 veces (ver `../code-reviewer/MEMORY.md`).
- Orden de guards para acciones sobre empleados (DOC-22 §9.3): (1) guard de auto-acción (`actor.userId === staffId`), (2) guard de pertenencia a la org, (3) guard de último admin. Todos ANTES de cualquier mutación.
- `requireCaseAccess(actor, caseId)` va después de `can()` y antes de la primera escritura, en toda mutación que acepte un caseId. Si la firma solo trae otro id, cargar la entidad y usar su `case_id`.
- IDOR fail-closed: si el lookup de pertenencia devuelve null para un actor cliente, tirar `AuthzError("forbidden_case")` — nunca seguir sin verificar.
- `AuthzError` tiene una unión cerrada en `.reason`: agregar códigos nuevos ahí (`self_deactivation_denied`, `cross_org_access_denied`), NO crear clases de error nuevas.
- **Nunca fabricar un Actor** para poder llamar a `can()`. Si una función necesita autorizar, cambia su firma para recibir el Actor real (un actor fabricado con `userId:""` pasa el `can()` pero saltea toda validación real).
- `Actor` = `{ userId, orgId, kind: "client"|"staff", role: "admin"|"sales"|"paralegal"|"finance"|null, permissions: ReadonlyMap<ModuleKey,{view,edit}> }`. Los clientes tienen `role: null` (NO `"client"`). Las fixtures de test deben traer los 5 campos.
- `getActor()` memoiza por request con `cache()` de React y lee los claims de `user.app_metadata` (los inyecta el Custom Access Token Hook). El claim es `user_role`, no `role` (`role` es reservado por PostgREST).

## Idempotencia y carreras (patrones canónicos del repo)

- **Webhooks**: `claimWebhookEvent()` devuelve `"fresh" | "duplicate" | "retry"`. `"duplicate"` (processed_at seteado) → 200 y saltear; `"retry"` (processed_at null, el intento previo crasheó) → re-correr el handler. `markWebhookEventProcessed` SOLO tras el éxito. Un 500 deja processed_at en null a propósito para que la fuente reintente. NUNCA devolver 200 ante un 23505 sin chequear processed_at — eso causó fallas de pago silenciosas.
- **Doble checkout (TOCTOU)**: insertar la fila local de payment (status=pending, session_id=NULL) ANTES de llamar a Stripe. El índice único parcial es el mutex: un 23505 significa `PAYMENT_IN_PROGRESS`. Después de crear la sesión, parchear la fila. La BD es el mutex, no una query de pre-chequeo. Residual conocido: si Stripe tira por timeout de red después del insert, la fila pending bloquea al cliente hasta 24h (falta job de limpieza/TTL).
- **Orden crash-safe de confirmación de pago**: `updatePayment` → `insertLedgerIfAbsent` → `updateInstallment(paid)`. El guard `status==='paid'` es seguro SOLO porque el ledger siempre entra antes. Preservar el orden en cualquier camino de confirmación nuevo.
- **`orgId` de un webhook viene de la BD** (`findOrgIdForCase(caseId)`), jamás de `metadata` de Stripe (lo controla quien creó el objeto).
- **Reagendar es insert-first**: insertar la cita nueva y RECIÉN marcar la vieja como `rescheduled`. El orden inverso deja huérfanos silenciosos ante fallo. Nuevo invariante: si falla el insert, la vieja queda scheduled (limpio); si falla el marcado, quedan dos scheduled (visible, recuperable).
- **Recordatorios: marcar ANTES de despachar** (`markReminderSent` antes de `dispatchReminderNotifications`). El orden inverso duplica emails ante re-delivery del cron. Si el marcado devuelve false (otra corrida ya lo tomó), saltear el despacho entero.
- **`moveCard`**: efectos sobre el lead (contacted_at, won/lost) ANTES de mover la tarjeta; emisión de evento y broadcast de Realtime SIEMPRE al final, después de todas las escrituras.
- Todo contador con límite de negocio (`used_count` con `max_uses`) se incrementa atómicamente en SQL, nunca read-modify-write.
- `insertNotificationIdempotent` dedupea por `dedupe_key` y devuelve `{created, row}`. El dedupeKey no debe tener granularidad de fecha si un crash entre insert y enqueue puede hacer que el reintento saltee el email: usar el UUID de la notificación como dedupeId del enqueue e intentar el enqueue siempre.

## Jobs, eventos, colas

- QStash: devolver **200 ante job key desconocido** (evita reintentos infinitos) y 500 solo si el handler tira (dispara retry con backoff). El job key se parsea de `params.job`.
- Los workers verifican `verifyQStashSignature` y devuelven 403 solo si `!valid && NODE_ENV === 'production'` — a propósito, para poder llamarlos en dev/test sin firma.
- Un job no aborta por el fallo de un target: catch-and-continue por target, y tirar solo si falla la carga de la lista (para que QStash reintente).
- `EventBus.emit()` es fire-and-forget pero desde F7-Ola7b adjunta `.catch(logger.error)` a la promesa: los rechazos async se loguean, ya no se tragan.
- Un mismo evento puede registrar varios consumidores a propósito (p.ej. `appointment.no_show` → notificación + timeline). No es duplicación.
- `notifyFromEvent` es no-op para eventos fuera de la matriz: es seguro registrarlo para todos los eventos de dominio.

## Integraciones y librerías (versiones confirmadas jun 2026)

- **Anthropic**: `client.messages.stream({...})` + `.finalMessage()`. Los tokens de caché están en `message.usage` pero NO en el tipo `Usage` del SDK — castear `(message.usage as unknown) as Record<string,number>` para leer `cache_creation_input_tokens`/`cache_read_input_tokens`.
- **Prompt caching, regla de prefijo**: `system[0]` = system prompt fijo, `system[1]` = XML del dataset. `cache_control: {type:"ephemeral"}` SOLO en el último bloque estable. Nada variable en `system[]`.
- **Costo Anthropic**: `(regularInput×P_in + cacheCreation×P_in×1.25 + cacheRead×P_in×0.10 + output×P_out) / 1e6`, con `regularInput = input − cacheCreation − cacheRead`. Ojo IEEE 754: `(0.00195).toFixed(4) === "0.0019"`, no "0.0020" — testear contra el comportamiento real de Node.
- **`@google/genai` v2.x**: la clase es `GoogleGenAI` (no `GoogleGenerativeAI`), `new GoogleGenAI({apiKey})`, acceso por `client.models.generateContent(...)`. No existe `getGenerativeModel()`. Multimodal: `contents:[{role:"user",parts:[{text},{inlineData:{mimeType,data}}]}]` + `generationConfig:{responseMimeType:"application/json", responseSchema}`.
- **mupdf en Next.js**: `serverExternalPackages: ['mupdf']` en `next.config.ts` y `await import('mupdf')` DENTRO de cada función (nunca top-level) para evitar el bundling CJS del paquete ESM/WASM. Llenado de AcroForm: descartar XFA (borrar todas las claves) → `setTextValue`/`setChoiceValue` → `field.update()` → `doc.bake()` → `doc.saveToBuffer("incremental")`. mupdf indexa páginas desde 0, el dominio desde 1 (`+1` al mapear). Tipos: `combobox→dropdown`, `radiobutton→radio`, `button→unknown`.
- **Stripe**: versión de API pineada `"2026-05-27.dahlia"`.
- **Resend v6**: `client.batch.send(payload)` → el data interno es `{ data: {id}[] }`, o sea `result.data.data.map(r => r.id)`.
- **@upstash/redis**: importar `@upstash/redis` (el barrel raíz re-exporta desde nodejs.js), NO `@upstash/redis/nodejs`.
- **Rate limits multi-tier de Upstash**: chequear los tiers SECUENCIALMENTE y cortar en la primera negación. Con `Promise.all` se decrementan TODOS los contadores aunque un tier deniegue, quemando cuota horaria/diaria en ráfagas denegadas.
- **zxcvbn-ts v3**: exporta la clase `ZxcvbnFactory` (no la función `zxcvbn` + singleton). `new ZxcvbnFactory({graphs, dictionary} as any).check(password)`.
- **Zod v4**: `z.record(z.string(), z.unknown())` requiere dos args; `.email()`/`.uuid()` no aceptan string; los errores están en `ZodError.issues` (no `.errors`). Las fixtures de test deben usar UUIDs RFC 4122 válidos — `"service-uuid-1111"` falla el parse y produce fallos confusos.
- **`logger.ts`**: `logger.info(context, message)` — DOS args, contexto primero. `logger.info({msg:"..."})` es error de TS.
- **`crypto.ts` rotación de llaves**: `tryDecrypt(ciphertext, mainKey)` en try/catch; si tira, reintentar con `ENCRYPTION_KEY_PREVIOUS`. El fallo del auth tag de GCM es determinista e inmediato, no hay corrupción silenciosa.
- **Separación de dominios de llave**: cada propósito criptográfico lleva su secreto (el HMAC de unsubscribe NO puede reusar `ENCRYPTION_KEY`, que es la de PII: los ciclos de rotación difieren y rotar PII invalidaría los links en vuelo).

## Contratos de seguridad y datos que hay que respetar

- **Contrato de PII (DOC-74 §7.1)**: `decryptPiiField` se llama LOCALMENTE en `resolveBySource` y el valor descifrado solo llena el campo del AcroForm. NUNCA se loguea, ni va en payload de evento, ni a un endpoint de IA, ni se guarda en `answers`.
- **La última transformación antes de mandar texto a un prompt debe ser `maskPii`**, jamás un truncate crudo (el corte parte el token y los regex dejan de matchear). Enmascarar y después truncar.
- **Password temporal de invitación**: `crypto.randomBytes(18).toString('base64url')`, va directo al mail y a ningún otro lado (ni evento, ni audit diff, ni log). El payload de `staff.created` solo lleva userId, orgId, email, displayName, role, invitedBy.
- **Neutralización de fórmulas CSV**: prefijar `\t` cuando la celda empieza con `=`,`+`,`-`,`@`,`\t`,`\r`, ANTES del quote-wrap RFC 4180 (el prefijo fuerza el quoting porque `neutralized !== s`). Vive en un helper compartido para que todo export nuevo lo herede.
- **Anti-enumeración en endpoints públicos**: 404 uniforme para token inexistente / expirado / consumido. Jamás distinguir.
- **Token de firma de un solo uso**: setear `signing_token: null` en el MISMO update que `status:"signed"`, nunca en dos escrituras (TOCTOU).
- **Aislamiento por prefijo de path en Storage**: ANTES de llamar `validateUploadedObject`, verificar que el path empiece con `{entity_type}/{entity_id}/` y tirar un error de dominio específico sin tocar storage. Sanitizar el filename con `.replace(/[^a-zA-Z0-9._-]/g, "_")` antes de embeberlo en el path.
- `auth.admin.listUsers()` pagina de a 1000 por defecto: nunca usarlo para buscar un usuario por teléfono. Consultar `public.users` por `phone_e164` (indexado) con el service client.
- `revokeAllSessions`: baja = `signOut(userId,'global')` + `updateUserById(userId,{ban_duration:'876600h'})`; alta = `ban_duration:'none'`. Ambos no fatales (loguear y seguir).

## Testing (Vitest) — trampas que cuestan horas

- **Hoisting de mocks**: toda variable usada dentro de una factory de `vi.mock()` debe declararse con `vi.hoisted()` (las factories corren antes del código de módulo). Una sola llamada a `vi.hoisted()` para todas las variables.
- `authz.ts` importa `supabase.ts` a nivel de módulo: cualquier test que importe de authz (directa o transitivamente) debe mockear `@/backend/platform/supabase` o `env.ts` explota al cargar.
- **Mock encadenable de Supabase**: `Object.assign(Promise.resolve({data,error}), {eq, gte, lt, not, select, in})` — hace la cadena thenable y encadenable a la vez. Para servicios que hacen N llamadas en `Promise.all`, usar una cola de resultados indexada por llamada.
- Un import dinámico dentro de una función se sigue interceptando con `vi.mock` a nivel de módulo (mismo grafo).
- Cuando una función nueva del service usa un repo nuevo, agregar el export a la MISMA factory `vi.mock("../repository")` existente — nunca declarar una segunda.
- Assertions de orden de llamada: `const callOrder: string[] = []` + `mockFn.mockImplementation(async () => { callOrder.push("x") })` → comparar índices.
- Import dinámico para aislar tests: si un service agrega un import top-level de un módulo de platform que exige env vars (qstash → env.ts), rompe todos los tests preexistentes de ese módulo. Usar `await import(...)` dentro de la función.
- Orden de gates: `tsc` → `eslint` → `vitest` → `check:i18n`. El error de eslint más común tras tsc es `no-unused-vars` por resultados de query que se dejaron de consumir (borrarlos, no prefijarlos con `_`).

## Reglas de negocio que no se deducen del código

- `registerZellePayment` requiere `cases:edit` (NO un permiso de billing): el preset de finanzas incluye `cases:edit`.
- Los contratos se leen con `cases:view` — `"contracts"` no es un ModuleKey válido.
- La frontera de fase (`advanceCasePhase`) es admin+finance, no paralegal. `force:true` es solo admin y saltea los chequeos de stage e impresión.
- `document.rejected` usa color ámbar, JAMÁS rojo: rechazado es corregible y el rojo implica fatal (RF-TRX-022). Lo mismo en la UI del cliente.
- `sendToFinance` chequea primero `sent_to_finance`/`printed` y recién después trae el plan (evita un query innecesario en el re-envío).
- Merge JSONB "último que escribe gana por campo": fetch-then-spread en JS, casteando `merged as Json`. Para autosave concurrente real hace falta una RPC atómica (ver deuda en code-reviewer).
- `|| true` en cualquier guard booleano es siempre un bug (saltea el chequeo entero); para "mandar por default hasta que exista la tabla de preferencias" va `?? true`.

## Índice de archivos temáticos
- Archivo: bitácora backend por fase F0→F6-Ola2 de usalatino-v2 (verbatim) → `archive-usalatino-fases.md`
- Esquema, migraciones, RLS, Storage, seeds, pgTAP → `../db-architect/MEMORY.md`
- Clases de bug recurrentes vistas en revisión → `../code-reviewer/MEMORY.md`
