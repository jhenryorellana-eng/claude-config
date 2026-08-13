# Memoria de oficio — code-reviewer
> Máximo 200 líneas cargadas. Curaduría: agent-ops (2026-08-13).
> Solo conocimiento de REVISIÓN. Las recetas de implementación frontend que vivían acá
> se mudaron a `frontend-builder/frontend-recipes-from-review.md`.

## Protocolo (lo que pagué por aprender)

- **Diff que toca migración/auth/pagos/RLS → correr `/codex review` ANTES de formar veredicto, no como formalidad después.** El 2026-08-13 (party-roles lead/companion) las 3 fallas reales — miscount de cardinalidad, fail-closed que congela el modelo de partes equivocado, wizard que no cascadea el borrado — se me pasaron en la primera lectura del diff y solo aparecieron por la escalada cross-model.
- Cuando un comentario del código afirma un invariante ("es byte-idéntico sin X", "RLS enforza el scoping"), **verificarlo contra el código, no creerlo**. Dos hallazgos STRONG salieron exactamente de comentarios falsos.
- Antes de flaggear "creado antes del CAS = doble cobro" o similares, chequear primero si la función creadora ya es idempotente (índice único parcial + read-check + catch 23505). Muchas veces el riesgo real es otro (status-target race), no el que parece.

## Clases recurrentes (ordenadas por reincidencia)

### 1. Falta de chequeo de org-ownership en mutaciones con service-role (≥9 ocurrencias)
El repo usa `createServiceClient()` (bypassa RLS) en TODO el repository layer, así que `can(actor, mod, op)` verifica permiso pero NUNCA pertenencia. Toda mutación que acepte una FK cruda debe cargar la entidad y comparar contra `actor.orgId`, devolviendo el MISMO error que not-found (anti-enumeración).
Ocurrencias: `deactivateEmployee` (F1) → `approveFormResponse`/`generateFilledPdf` (F4) → `sendToFinance`/`markPrinted` (F5) → `translateMessage`/`loadCaseParticipantSources` (F7) → `service_party_roles` CRUD → `markReferralRewarded` → `getZelleEvidenceUrl`/`dismissZelleNotification` (zelle-recon). Referencia canónica bien hecha: `updateService`/`archiveService`, y `markLeadContacted` (hecho bien desde el día uno).

### 2. PII que se escapa a un proveedor de IA
- **Regla dura (DOC-74 §7.1): la ÚLTIMA transformación antes de inyectar texto en un prompt debe ser `maskPii`, jamás un slice/truncate crudo.** `assessPreMortemRisk` truncó ANTES de enmascarar: el corte parte el token de PII, los regex de `maskPii` (que exigen match contiguo) dejan de matchear y llegan fragmentos crudos de SSN/A-number/pasaporte. Enmascarar primero y truncar después solo arriesga garabatear una máscara. Dado el dominio (memos de temor creíble), tratar como CRÍTICO/BLOCKER, no IMPORTANTE.
- **Función nueva que toca IA y NO enmascara mientras su hermana en el MISMO archivo sí**: `translateText` (F8), `runFieldWebResearch` (web_research). Al revisar cualquier llamada nueva a Anthropic/Gemini, comparar contra las funciones vecinas del archivo. Peor aún con `web_search`: los términos salen del perímetro del proveedor hacia un índice de búsqueda.

### 3. Riesgo de orden de deploy (columna nueva referenciada explícitamente)
Cuando un PR agrega una columna y el código la nombra explícitamente en un `.select('a, b, nueva')` o la manda siempre en un upsert, desplegar CÓDIGO antes que MIGRACIÓN hace que PostgREST rechace la query entera. supabase-js devuelve `{data:null, error}` sin tirar, así que los callers con `data || []` degradan a "sin filas" en silencio — y rompe features NO relacionadas que comparten esa query. `select('*')` es inmune. Migración primero, código después, siempre.
Variante encontrada después: se cuela por **defaults del VM** — un campo requerido `T | null` cuyo default es `null` (no `undefined`) satisface para siempre el contrato "solo escribir si vino", porque `null !== undefined` (mailing_cover, 2026-07-22).

### 4. Guard de existencia sin guard semántico en validadores de config-as-data
`validateSourceRef`/`validateLogicalFk` chequean que la entidad referenciada EXISTA pero no que sea del TIPO permitido ni que el id apunte a algo con sentido: `resolveProposedCondition` sin guard auto-referencial (una condición puede apuntarse a sí misma), `field_copy` valida el form pero no el `target_question_id`, `addItem` no chequea que el run no sea de una clase estructuralmente excluida. Los editores de config del repo sub-validan ids cross-entidad que exigirían un segundo round-trip. Un typo se resuelve a `null` para siempre, sin error de publicación ni de runtime — se descubre cuando falta el valor en un PDF legal.

### 5. Read-modify-write sin atomicidad ni constraint que lo respalde
`mergeFormAnswers` (autosave multi-pestaña), `insertNotificationIdempotent` (check-then-insert), `used_count` de promociones (TOCTOU con `max_uses=1`), auto-repair del plan de pagos por page-view. Fix estructural: RPC atómica, `UPDATE ... SET c = c + 1`, índice único parcial como mutex (el patrón bueno del repo es el checkout de Stripe: insertar la fila local ANTES de llamar a Stripe y dejar que el 23505 sea el `PAYMENT_IN_PROGRESS`).

### 6. Estado intermedio no terminal escrito antes de I/O y reusado como guard de reintento
`matchZelleNotification` escribe `lifecycle_status:"applying"` antes de render/upload/RPC sin try/catch; un crash en el medio deja la fila varada para siempre porque el guard de reintento ya no la admite. Envolver todo el tramo y revertir el status ante falla.

### 7. Helpers de lectura de config que tiran y hay que envolver en CADA call site
Los getters de tablas "config-as-data" (`getDeadlinePolicy`, `getStageSlaDays`) no tienen try/catch interno: tiran si la migración no está aplicada. En el PR de deadline-policy 4 de 5 call sites envolvían con `.catch(() => null)`; el que faltaba rompía la creación de casos para TODOS los servicios. Grepear el 100% de los call sites, no "casi todos".

### 8. Inyección de fórmulas en CSV (2 exportadores, misma falta)
`csvEscape` (audit) y `csvCell` (ledger) hacen el quoting RFC 4180 pero no neutralizan el prefijo `=`, `+`, `-`, `@`. El fix vive en `platform/csv.ts` para que futuros exports lo hereden.

### 9. URLs y HTML de autoría staff
Todo campo URL escrito por staff debe validarse como `https?://` en el service layer antes del insert (`live_join_url`, `video_url`) — React no sanitiza `href`, así que un `javascript:` es XSS al click. El HTML de campañas se resolvió con el "trusted renderer" (`renderBlocksToHtml` con `escapeHtml()` + `safeUrl()`), que reemplaza al `dangerouslySetInnerHTML` que era BLOCKER en F6-Ola3.

### 10. Timeout de 15s de los Server Actions en Vercel
Un server action lento (>10s) que llama IA de forma síncrona necesita `export const maxDuration` en ESE page.tsx exacto (o en un layout.tsx ancestro del segmento) — no se hereda de una ruta hermana que comparta el `[caseId]`. `runFieldWebResearch` tiene presupuesto interno de 180s expuesto en 4 rutas sin `maxDuration`: la plataforma lo mata a los 15s y sale un 504 crudo en vez del `AiEngineError` diseñado.

### 11. Migraciones que reestructuran catálogo
- `UPDATE ... SET service_phase_id = superviviente` sin dedupe explota con 23505 en tablas con `unique(case_id, service_phase_id, ...)` apenas un caso tenga filas en ambas fases (0079 pasó en prod solo porque no había solapamiento todavía).
- El `sequence_number` de `appointments` NO se remapea al mergear fases: la cita queda reinterpretada contra la NUEVA plantilla en la misma posición, con label/objetivos distintos de lo que el cliente reservó. Los chequeos de integridad referencial no lo detectan (es deriva semántica, no FK rota).
- Patrón correcto para reordenar: calcular `coalesce(max(position),-1)+1` como offset ANTES de mover, y asignar `offset + row_number()-1` (el rango de append nunca solapa).
- Preferir UPSERT sobre DELETE+INSERT en plantillas de agenda cuando ya hay casos que las referencian.
- Un índice único parcial NUEVO en una tabla caliente puede reventar escritores PREEXISTENTES que no lo esperan (0111 sobre `payments`); grepear todos los escritores.

### 12. Smells menores pero reincidentes
- `console.error/log/warn` en código de servidor: bypassa la redacción de PII de `platform/logger.ts`. Siempre `logger.error({ err }, "msg")`.
- `t("key").replace("{x}", v)` reemplaza SOLO la primera ocurrencia: si el mensaje ICU repite el placeholder, el segundo queda literal en pantalla. Grepear `t\(".*"\)\.replace\(` en cualquier barrido de i18n.
- `new Date('YYYY-MM-DD')` parsea como medianoche UTC: en zonas detrás de UTC se renderiza como el día calendario ANTERIOR al formatear con APIs sensibles al locale. Agregar `T00:00:00` (local) lo arregla. Chequear en toda fecha que venga como string plano de la BD.
- `catch {}` vacío en el repo: convención es `logger.warn({err}, ...)`.
- Un `logger.info("… aplicado …")` fuera del `if (moved)` de un CAS dispara aunque la carrera se haya perdido — justo cuando hace falta un log honesto.
- Helpers privados cuya corrección depende del literal que pasa el caller (`computeBookingWarnings(..., actorKind)`) NO deben tener default en ese parámetro: el default mata la única garantía de compilación.

## Patrones verificados como CORRECTOS (no volver a flaggear)

- `claimWebhookEvent` → "fresh"/"duplicate"/"retry" + `markWebhookEventProcessed` solo tras éxito: contrato de idempotencia definitivo del repo, replicar para toda fuente de webhook nueva.
- `applyPaymentSuccess`: updatePayment → insertLedgerIfAbsent → updateInstallment(paid). El guard `status==='paid'` es seguro SOLO porque el ledger siempre entra antes. Preservar el orden.
- `orgId` de los handlers de webhook viene de la BD (`findOrgIdForCase`), nunca de `metadata` de Stripe.
- `deriveFieldState` (shared/form-logic/conditions.ts) es la fuente única de la lógica de visibilidad, importada por wizard, domain, generateFilledPdf y catalog. Toda feature nueva que toque respuestas la usa; no duplicar.
- `pickCurrentRuns` (clave `formDefinitionId:partyId`, gana la versión más alta) verificado consistente en sus 4 usos.
- `resolveQuestionnaireBaseDefaults`: determinista, no fabrica nada (solo devuelve `default_value` literal de `client_answer`), reusa `resolveBySource`/`mergeFormAnswersIfEmpty`.
- `business-days.ts` (aritmética civil `yyyy-MM-dd`, comparación lexicográfica válida por ancho fijo): implementación de referencia, reusar en vez de reimplementar.
- `checkUrlReachable` nunca tira (convierte todo a `{reachable:false}`), lo que hace seguro el `Promise.all` sin wrappers defensivos. El fallback HEAD→GET ante 405/501/403 es correcto para sitios de noticias.
- `imapflow` en serverless: el `client.on("error", ...)` es OBLIGATORIO (sin listener, un timeout de socket puede tumbar el proceso), `logout()` con `.catch(()=>{})` en `finally`, bufferear resultados del fetch antes de emitir más comandos IMAP.
- Emisión de eventos fire-and-forget: `EventBus` ya adjunta `.catch(logger.error)` desde F7-Ola7b. Las entradas viejas que lo marcaban como smell están superadas.
- `formatPdfDate` (ISO → `MM/DD/YYYY`, mes/año → `MM/YYYY`) es el helper canónico de fechas para llenar AcroForms.
- Re-validación de todo id que devuelve la IA contra sets construidos desde la BD (`autoAssembleWithAi`) es la defensa correcta contra alucinación.
- El seam de stub de IA (`isAiStubEnabled()` tira fuerte si el flag aparece en producción) hace estructuralmente imposible el bypass en prod, no solo por convención de entorno.

## Deuda de cobertura conocida (flaggear si el archivo se vuelve a tocar)

- `ai-engine/filing-addresses.ts`: CERO tests unitarios, y ya se arreglaron 2 bugs reales ahí sin test de regresión. Resuelve direcciones de corte/OPLA para trámites con plazo legal.
- `fillAcroForm` + combobox: la correspondencia entre los `row_key` del catálogo y los export values reales del PDF se verificó UNA VEZ a mano, sin invariante automática. `fillAcroForm` traga los errores por campo en silencio y ningún caller los loguea: una corte nueva mal tipeada sale como dropdown VACÍO en una moción presentada, sin error ni log.
- `getAvailableSlots`: cero tests pese a ser el camino compartido de mayor riesgo entre el picker del cliente y el de staff (se diferencian solo por `actor.kind`).
- `letter_fill.override_question` se referencia por el texto ES literal de la pregunta, no por un id estable: un fix de typo en el label rompe el override en silencio (degrada con gracia, pero a una dirección menos autoritativa en un escrito legal).

## Tooling de revisión en este entorno

- **tindivo-v2 en Windows**: `git status` marca archivos como modificados por pura normalización CRLF/LF con CERO diff real. Verificar SIEMPRE con `git diff HEAD --stat -- <archivo>` antes de meter algo en el scope. `pnpm lint` repo-wide (Biome) tira ~216 errores por el propio `biome.json` con CRLF contra `lineEnding: "lf"` — scopear a los archivos cambiados (`npx biome check <f1> <f2>`) para tener señal.
- `next-env.d.ts` alterna entre `./.next/types/routes.d.ts` y `./.next/dev/types/routes.d.ts` según si lo último que corrió fue `next build` o `next dev`. Autogenerado, nunca es un hallazgo.
- Antes de aprobar cualquier archivo nuevo bajo `docs/_evidence/**`: grepear `sb-.*-auth-token`, `eyJ`, `addCookies`, `Authorization:`. En 2026-07-18 apareció un JWT de sesión de PROD real y vigente hardcodeado en un helper no trackeado. El riesgo es recurrente PORQUE el flujo legítimo del repo exige mintear cookies de sesión reales para verificación E2E.

## Índice de archivos temáticos
- Archivo: hallazgos usalatino-v2 (F1→2026-08-13, verbatim) → `archive-usalatino-v2-findings.md`
- Archivo: hallazgos henryflow / usalatinoprime / tindivo-v2 → `archive-henryflow-y-otros-repos.md`
- Recetas de implementación frontend salidas de estas revisiones → `../frontend-builder/frontend-recipes-from-review.md`
