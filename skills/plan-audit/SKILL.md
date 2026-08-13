---
name: plan-audit
description: >
  Plan Completion Audit: extrae los ítems accionables del plan, clasifica cómo
  se verifica cada uno (DIFF-VERIFIABLE / CROSS-REPO / EXTERNAL-STATE /
  CONTENT-SHAPE) y los cruza contra el diff real: DONE / PARTIAL / NOT DONE /
  CHANGED / UNVERIFIABLE, con investigación del porqué de cada gap. Regla de
  honestidad: código que maneja un entregable no ES el entregable. Usa cuando se
  pida "¿se implementó todo el plan?", "audita el plan contra el diff", "plan
  completion", o al cerrar una rama que tuvo plan escrito. La invoca
  code-reviewer como parte del two-stage review. Para calidad/bugs del diff usa
  el built-in /code-review; para evidencia ejecutada usa verify.
---

# Plan Audit — ¿se entregó lo que el plan prometía?

Esta skill responde una sola pregunta: de todo lo que el plan decía que se iba a
hacer, ¿qué se hizo, qué no, y por qué. No juzga la calidad del código (eso es
`/code-review`) ni corre tests (eso es `verify`).

El sesgo por defecto de un agente al cerrar una rama es declarar victoria. Esta
skill existe para contrarrestarlo con evidencia.

---

## Paso 1 — Encontrar el plan

Por orden de confiabilidad:

1. **Contexto de la conversación (primario).** Si hay un plan activo en esta
   sesión (los mensajes de sistema del host incluyen la ruta del archivo de plan
   cuando se estuvo en plan mode), úsalo directo. Es la señal más confiable.

2. **`~/.claude/plans/`.** Busca por contenido: el archivo más reciente que
   mencione la rama actual o el nombre del repo.

```bash
BRANCH=$(git branch --show-current 2>/dev/null | tr '/' '-')
REPO=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
PLAN_DIR="$HOME/.claude/plans"
PLAN=$(ls -t "$PLAN_DIR"/*.md 2>/dev/null | xargs grep -l "$BRANCH" 2>/dev/null | head -1)
[ -z "$PLAN" ] && PLAN=$(ls -t "$PLAN_DIR"/*.md 2>/dev/null | xargs grep -l "$REPO" 2>/dev/null | head -1)
[ -n "$PLAN" ] && echo "PLAN_FILE: $PLAN" || echo "NO_PLAN_FILE"
```

3. **`docs/` del repo.** Planes versionados: `docs/planes/`, `docs/designs/`, o
   la entrada de `docs/historial/` que describe el trabajo de esta rama.

**Validación:** si el plan se encontró por búsqueda de contenido (no por el
contexto de la conversación), lee las primeras 20 líneas y confirma que
corresponde al trabajo de esta rama. Si parece de otro proyecto o de otra
feature, trátalo como "no se encontró plan".

**Manejo de errores:**
- Sin plan → salta con "No se detectó plan — se omite la auditoría de plan"
  (pero mira Paso 6: fuentes de intención alternativas).
- Plan encontrado pero ilegible (permisos, encoding) → "Plan encontrado pero
  ilegible — se omite".

---

## Paso 2 — Extraer los ítems accionables

Lee el plan. Extrae todo lo que describa trabajo a hacer:

- **Checkboxes:** `- [ ] ...` o `- [x] ...`
- **Pasos numerados** bajo encabezados de implementación: "1. Crear...",
  "2. Agregar...", "3. Modificar..."
- **Frases imperativas:** "Agregar X a Y", "Crear el servicio Z", "Modificar el
  controller W"
- **Especificaciones a nivel de archivo:** "Nuevo archivo: path/to/file.ts",
  "Modificar path/to/existing.rb"
- **Requisitos de test:** "Testear que X", "Agregar test para Y", "Verificar Z"
- **Cambios de modelo de datos:** "Agregar columna X a la tabla Y", "Crear
  migración para Z"

**Ignora:**
- Secciones de contexto (`## Contexto`, `## Background`, `## Problema`)
- Preguntas y pendientes abiertos (marcados con `?`, "TBD", "TODO: decidir")
- Secciones de reporte de revisión insertadas en el plan
- Ítems explícitamente diferidos ("Futuro:", "Fuera de alcance:", "NO está en
  scope:", "P2:", "P3:")
- Secciones que registran decisiones, no trabajo

**Tope:** extrae como máximo 50 ítems. Si el plan tiene más, anota: "Se muestran
los primeros 50 de N ítems — la lista completa está en el plan."

**Sin ítems:** si el plan no tiene nada extraíble, salta con: "El plan no
contiene ítems accionables — se omite la auditoría."

Para cada ítem, anota el texto (verbatim o resumido) y su categoría: CODE | TEST
| MIGRATION | CONFIG | DOCS.

---

## Paso 3 — Clasificar CÓMO se verifica cada ítem

Antes de juzgar si algo se hizo, clasifica cómo se puede probar. El diff no
alcanza para todo: los ítems que viven fuera del repo son estructuralmente
invisibles para `git diff`.

- **DIFF-VERIFIABLE** — un cambio de código en este repo se manifestaría en
  `git diff <base>...HEAD`. Ejemplos: "agregar UserService" (aparece el archivo),
  "validar el input X" (aparece la lógica), "crear tabla users" (aparece la
  migración).
- **CROSS-REPO** — el ítem nombra un archivo o cambio en un repo hermano. El diff
  actual NO puede probarlo.
- **EXTERNAL-STATE** — el ítem nombra estado en un sistema externo: config o RLS
  de Supabase, DNS de Cloudflare, variables de entorno en Vercel, allowlists de
  proveedores OAuth, SaaS de terceros. El diff actual NO puede probarlo.
- **CONTENT-SHAPE** — el ítem exige que un archivo siga una convención. Si el
  archivo está en este repo: diff-verifiable. Si está en otro repo o sistema: ver
  CROSS-REPO / EXTERNAL-STATE.

**Despacho de verificación:**

- **DIFF-VERIFIABLE** → cruzar contra el diff (Paso 4).
- **CROSS-REPO** → si el repo hermano es alcanzable en disco (prueba el
  directorio padre del repo actual, `~/Documents/`, `~/Development/`), corre
  `[ -f <path> ]`. El archivo existe → DONE (cita la ruta). No existe → NOT DONE
  (cita la ruta). Ruta inalcanzable → UNVERIFIABLE (cita qué hay que revisar a
  mano).
- **EXTERNAL-STATE** → UNVERIFIABLE. Cita el sistema y el chequeo específico que
  el usuario debe hacer.
- **CONTENT-SHAPE en otro repo** → si el archivo existe, corre cualquier
  validador del proyecto antes de caer en UNVERIFIABLE. Con validador: pasa →
  DONE; falla → NOT DONE (cita la salida). Sin validador: UNVERIFIABLE, citando
  la ruta y la convención a confirmar.

**Regla de concreción de rutas.** Si un ítem nombra una *ruta concreta del
sistema de archivos* (absoluta, `~/...`, o `<repo-hermano>/<archivo>`), DEBE
clasificarse DONE o NOT DONE según `[ -f <path> ]`. UNVERIFIABLE solo vale cuando
la ruta es genuinamente abstracta ("DNS de Cloudflare", "allowlist de Supabase") o
cuando la raíz hermana no existe en esta máquina. "No tengo ganas de chequear" no
es inalcanzable.

**Detección de validador.** Antes de caer en UNVERIFIABLE sobre un ítem
CONTENT-SHAPE, revisa el `package.json` del repo objetivo buscando scripts tipo
`validate-*`, `check-docs`, `lint-*`. Si hay uno, invócalo con la ruta relevante.
Un validador que pasa promueve el ítem de UNVERIFIABLE a DONE; uno que falla lo
degrada a NOT DONE.

**Regla de honestidad (textual del original):**

> Do NOT classify an item as DONE just because related code shipped. Code that
> *handles* a deliverable is not the deliverable. Shipping a markdown-extraction
> library is not the same as shipping the markdown file. When in doubt between
> DONE and UNVERIFIABLE, prefer UNVERIFIABLE — better to surface a confirmation
> prompt than silently miss a deliverable.

---

## Paso 4 — Cruzar contra el diff

Corre `git diff origin/<base>...HEAD` y `git log origin/<base>..HEAD --oneline`
para entender qué se implementó.

Para cada ítem, aplica el despacho del Paso 3 y clasifica:

- **DONE** — evidencia clara de que se entregó. Cita el archivo del diff (para
  DIFF-VERIFIABLE) o la ruta verificada (para CROSS-REPO alcanzable).
- **PARTIAL** — hay trabajo hacia el ítem pero está incompleto (modelo creado
  pero falta el controller; función existe pero no cubre los casos borde).
- **NOT DONE** — la verificación corrió y dio evidencia negativa (archivo
  ausente, código ausente del diff, archivo del repo hermano confirmado ausente).
- **CHANGED** — el ítem se implementó por un camino distinto al que decía el
  plan, pero se logra el mismo objetivo. Anota la diferencia.
- **UNVERIFIABLE** — ni el diff ni los chequeos alcanzables prueban o refutan
  esto. Siempre aplica a EXTERNAL-STATE y a CROSS-REPO inalcanzable. Cita la
  verificación manual concreta que debe hacer el usuario.

**Sé conservador con DONE** — exige evidencia clara. Que un archivo haya sido
tocado no basta: la funcionalidad descrita debe estar presente.
**Sé generoso con CHANGED** — si el objetivo se cumple por otro medio, cuenta.
**Sé honesto con UNVERIFIABLE** — mejor mostrar 5 ítems que el usuario debe
confirmar a mano que clasificarlos DONE en silencio.

### Gate de evidencia (adaptado del gate #1539 de cso)

Ningún ítem se marca **DONE** sin citar el `file:line` del diff que lo prueba,
con el texto verbatim de la línea o el hunk que lo motiva. Si el ítem es "agregar
validación de email al formulario de alta", cita las líneas donde vive esa
validación. Si es "crear la tabla `cases`", cita la migración y la línea del
`create table`.

**Si no puedes citar la línea que lo prueba, el ítem no está DONE.** Bájalo a
PARTIAL (si hay evidencia parcial) o a UNVERIFIABLE (si no la hay). No inventes
certeza: eso derrota el gate y convierte la auditoría en una firma de goma.

Para ítems CROSS-REPO la cita es la ruta verificada con `[ -f ]`; para
EXTERNAL-STATE no hay cita posible y por eso son UNVERIFIABLE por definición.

---

## Paso 5 — Formato de salida

```
PLAN COMPLETION AUDIT
═══════════════════════════════
Plan: {ruta del plan}

## Ítems de implementación
  [DONE]         Crear UserService — src/services/user_service.ts:1-142
  [PARTIAL]      Agregar validación — el modelo valida, falta el chequeo en el controller
  [NOT DONE]     Agregar capa de caché — no hay cambios de caché en el diff
  [CHANGED]      "cola en Redis" → implementado con QStash

## Ítems de test
  [DONE]         Tests unitarios de UserService — tests/services/user_service.test.ts
  [NOT DONE]     Test E2E del flujo de alta

## Ítems de migración
  [DONE]         Crear tabla cases — supabase/migrations/20260813_create_cases.sql:4

## Cross-repo / externos
  [DONE]         repo-hermano tiene /docs/dashboard.md — verificado en la ruta
  [UNVERIFIABLE] RLS de Supabase sobre la tabla cases — sistema externo, revisar en el dashboard
  [UNVERIFIABLE] Variable RESEND_API_KEY en Vercel — sistema externo, confirmar a mano

─────────────────────────────────
COMPLETITUD: 5/9 DONE, 1 PARTIAL, 1 NOT DONE, 1 CHANGED, 2 UNVERIFIABLE
─────────────────────────────────
```

---

## Paso 6 — Fuentes alternativas cuando no hay plan

Sin plan detectado, usa estas fuentes secundarias de intención:

1. **Mensajes de commit:** `git log origin/<base>..HEAD --oneline`. Los commits
   con verbos accionables ("agregar", "implementar", "arreglar", "crear",
   "quitar") son señal de intención. Descarta ruido: "WIP", "tmp", "squash",
   "merge", "chore", "typo", "fixup". Extrae la intención detrás del commit, no
   el mensaje literal.
2. **Backlog del repo** (`TODOS.md` o equivalente), si tiene ítems ligados a esta
   rama o a fechas recientes.
3. **Descripción del PR:** `gh pr view --json body -q .body 2>/dev/null`.

Aplica la misma clasificación, anotando que los ítems de fuente alternativa tienen
menor confianza que los de un plan escrito.

Si no hay ninguna fuente de intención: "No hay fuentes de intención — se omite la
auditoría de completitud."

---

## Paso 7 — Investigar cada discrepancia

Para cada ítem PARTIAL o NOT DONE, investiga POR QUÉ:

1. Revisa `git log origin/<base>..HEAD --oneline` buscando commits que sugieran
   que el trabajo se empezó, se intentó o se revirtió.
2. Lee el código relevante para entender qué se construyó en su lugar.
3. Determina la razón probable de esta lista:
   - **Scope cut** — evidencia de remoción intencional (commit de revert, TODO
     eliminado).
   - **Agotamiento de contexto** — trabajo empezado que se detuvo a mitad
     (implementación parcial, sin commits de seguimiento).
   - **Requisito malentendido** — se construyó algo, pero no coincide con lo que
     el plan describía.
   - **Bloqueado por dependencia** — el ítem depende de algo que no está
     disponible.
   - **Genuinamente olvidado** — sin evidencia de intento alguno.

Salida por discrepancia:

```
DISCREPANCIA: {PARTIAL|NOT_DONE} | {ítem del plan} | {qué se entregó realmente}
INVESTIGACIÓN: {razón probable con evidencia del git log / código}
IMPACTO: {ALTO|MEDIO|BAJO} — {qué se rompe o degrada si esto queda sin entregar}
```

---

## Paso 8 — Integración con detección de scope drift

Los resultados alimentan la lectura de deriva de alcance de la revisión:

- Los ítems **NOT DONE** son evidencia de **REQUISITOS FALTANTES**.
- Los cambios del diff que **no corresponden a ningún ítem del plan** son
  evidencia de **SCOPE CREEP**.
- Las discrepancias de impacto **ALTO** disparan AskUserQuestion con los
  hallazgos de la investigación y estas opciones: A) parar e implementar lo que
  falta, B) shipear igual y crear tareas P1, C) fue una decisión deliberada de
  recortar alcance.

Resumen de scope:

```
Scope: [LIMPIO / DERIVA DETECTADA / FALTAN REQUISITOS]
Intención: <del plan — una línea>
Plan: <ruta del plan>
Entregado: <una línea de lo que hace el diff realmente>
Ítems del plan: N DONE, M PARTIAL, K NOT DONE
[Si hay NOT DONE: cada ítem faltante con su investigación]
[Si hay scope creep: cada cambio fuera de alcance que no estaba en el plan]
```

Salvo que haya discrepancias de impacto ALTO, esto es **INFORMATIVO**: reporta y
deja decidir. Con impacto ALTO, es un gate.

## Reglas importantes

- **Nada es DONE sin cita.** El gate del Paso 4 no tiene excepciones para ítems
  de código.
- **Código que maneja el entregable no ES el entregable.** La regla de honestidad
  es la que más se viola y la que más caro sale.
- **UNVERIFIABLE no es fracaso.** Es la respuesta correcta cuando el diff no
  puede saber. Un ítem UNVERIFIABLE bien citado le ahorra al usuario un incidente
  de producción.
- **Esta skill no revisa calidad.** Los bugs, el estilo y la simplificación son
  de `/code-review`; la evidencia ejecutada es de `verify`.
