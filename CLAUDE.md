# Sistema Multi-Agente — Mauri/Henry (v3 · 2026-08-13)

> Cargado en CUALQUIER sesión de Claude Code de esta máquina. Es el router
> central: quién hace qué, con qué herramientas, y cómo NO pisarse.
> v3 (2026-08-13): roster de 18 especialistas (5 nuevos: product-manager,
> performance-engineer, sre-observability, refactoring-specialist, agent-ops),
> skills 32 → 17 propias (gstack muerto podado; superpowers migrado a skills
> propias), cada flag con UN consumidor dueño, plugin impeccable para craft de
> diseño.

## Máquinas

- **PC (Windows 11, PowerShell + Git Bash):** desarrollo interactivo, revisión
  de PRs, merges, migraciones a prod (acto deliberado). Agent Teams ✔.
- **VPS (Ubuntu, headless, `dev@217.77.15.7`):** cola desatendida
  (`~/orchestrator`) que ejecuta tareas con `claude -p` y abre PRs. Sin GUI,
  sin Docker, sin Agent Teams (`AGENT_TEAMS=0`). Config sincronizada desde el
  repo `claude-config` (cron cada 15 min).
- Ambas comparten la MISMA ventana de cuota: un solo asistente pesado a la vez.
- Rutas: la forma canónica es `~/...`; en Windows `~` = `%USERPROFILE%`
  (`C:\Users\mauri`). Ningún charter usa rutas absolutas de Windows.

---

## 👥 El equipo — 18 especialistas (`~/.claude/agents/`)

**Siempre en el grafo** (según la fase):

| Agente | Modelo | Dueño de |
|---|---|---|
| `team-lead` | opus | Coordinación: analiza, razona el grafo de despacho, delega. **Jamás escribe código** |
| `architect` | opus | ADRs, límites de módulos, contratos de API, trade-offs de stack |
| `ux-designer` | opus | Flujos, arquitectura de información, wireframes, heurísticas, estados vacíos/error |
| `ui-designer` | opus | Sistema visual: tokens, tipografía, paletas, DESIGN.md, anti-AI-slop |
| `frontend-builder` | sonnet | Implementación Next.js/React/Tailwind/shadcn + motion (GSAP/Lenis) |
| `backend-builder` | sonnet | APIs, lógica de negocio, jobs, integraciones |
| `db-architect` | opus | Esquema, migraciones expand/contract, RLS, índices, seeds, tipos generados |
| `llm-engineer` | sonnet | IA del producto: ai-engine, prompts versionados, evals, maskPii, costo por run |
| `qa-engineer` | sonnet | Gates del DoD, tests unit/e2e, **gate a11y (axe)**, gate visual `ui-review` — evidencia ejecutada |
| `code-reviewer` | sonnet | Revisión de diffs (calidad + spec-compliance + `plan-audit`); escala a `codex` en auth/pagos/RLS |
| `security-auditor` | opus | OWASP + STRIDE + supply chain + **compliance/PII**. Veto con `<<BLOCK-DEPLOY>>` y árbitro del flag |
| `devops-engineer` | sonnet | CI/CD, Vercel, el VPS y su orquestador, secretos. **EJECUTA** deploys y rollbacks |
| `sre-observability` | sonnet | **Post-deploy**: canary, monitoreo, incidentes (SEV1-3), postmortems. Dueño de `<<INCIDENT>>` |
| `docs-writer` | haiku | Formato y archivo de historial, ADRs, PRDs, postmortems, CHANGELOG, docs Diataxis |

**Bajo demanda** (entran por flag o pedido explícito — nunca en el grafo por defecto):

| Agente | Modelo | Dueño de |
|---|---|---|
| `product-manager` | opus | El QUÉ: PRD, alcance, user stories, priorización. Dueño de `<<NEED-PRODUCT-DECISION>>`. Entra ANTES de team-lead cuando el QUÉ no está definido |
| `performance-engineer` | sonnet | Performance transversal end-to-end: presupuestos, profiling, diagnóstico. Dueño de `<<NEED-PERF>>` |
| `refactoring-specialist` | sonnet | Refactor seguro (comportamiento idéntico + red de tests). Dueño de `<<NEED-REFACTOR>>` |
| `agent-ops` | opus | **El SISTEMA de agentes**: charters, triggers, skills propias, memorias, drift PC↔VPS. Dueño de `<<AGENT-DRIFT>>`. Edita solo vía claude-config + PR + merge humano |

**Pipeline UI (roles separados que se alimentan):**
`ux-designer` (flujo+wireframe) → `ui-designer` (sistema visual+DESIGN.md, con
skill `design-system` y `/impeccable:*`) → `frontend-builder` (código+motion) →
`qa-engineer` (tests/a11y + gate `ui-review`, **una sola pasada**). Cada fase
entrega su artefacto antes de que arranque la siguiente; los desacuerdos suben
a `team-lead`.

**Contrato de tres verbos (fronteras de performance):** `qa-engineer` DETECTA
(mide y emite `<<NEED-PERF>>`) · `performance-engineer` DIAGNOSTICA y verifica
(dueño del flag) · builders/db-architect IMPLEMENTAN lo estructural.
**Frontera deploy:** `devops-engineer` EJECUTA (deploy, rollback, infra) ·
`sre-observability` OBSERVA, declara y coordina (después del deploy).

**Toolkit personal (NO global):** `slide`, `web-prompt-architect` y el agente
`slide-critic` viven SOLO en `C:\Users\mauri\Documents\chamba\.claude\`
(decisión del 2026-08-07). No aparecen en este router.

---

## REGLA #1 — Todo lo no-trivial pasa por `team-lead`

Triggers que lo invocan automáticamente: "build", "construye", "crea", "haz",
"implementa", "desarrolla", "MVP", "feature", "app", "sistema", "deploy",
"ship", "migra", "mejora", "rediseña".

Excepciones (uso directo, sin team-lead):

| Prompt | Acción directa |
|---|---|
| Tareas atómicas ("lee X", "lista Y", "muestra el diff") | Read/Grep/Glob |
| "encola…", "mándale al VPS…" | skill `encolar-tarea` |
| "revisa/mergea el PR N" | skill `revisar-pr` |
| "audit security", "auditoría de seguridad" | `security-auditor` (usa `cso`) |
| "debug/investiga este error" | skill `investigate` → agente del dominio |
| "se cayó prod", "incidente" | `sre-observability` (usa `postmortem`) |
| "va lento", "optimiza performance" | `performance-engineer` |
| "refactoriza X" (sin cambiar comportamiento) | `refactoring-specialist` |
| "PRD", "qué construimos", "prioriza" | `product-manager` |
| "el agente X no dispara", "ajusta el roster" | `agent-ops` |
| "documenta X" | `docs-writer` |
| "gate de UI", "audita el diseño" | skill `ui-review` |
| `/impeccable:*` explícito | plugin impeccable (craft de diseño) |

## REGLA #2 — Skills se invocan explícitamente

Cada agente declara en su charter qué skills usa y en qué fase; las invoca con
`Skill(name=...)`. No se infiere por vibra.

## REGLA #3 — Two-stage review antes de "done"

1. `code-reviewer`: revisa el diff (spec-compliance + calidad) y lo audita
   contra el plan con la skill `plan-audit` — un ítem es DONE con file:line
   del diff que lo prueba, o no es DONE.
2. Skill `verify`: evidencia ejecutada — tests corridos con salida, screenshots
   tomados, comandos con output. "Debería funcionar" no es evidencia.
Cualquier `<<NEEDS-REVISION>>` → loop a la fase anterior.

## REGLA #4 — Research en vivo (Phase 0)

Todo agente ejecuta su Phase 0 (WebSearch/Context7) antes de tocar código: el
conocimiento se valida contra el estado del arte EN CADA invocación, no se
asume congelado.

## REGLA #5 — Cada flag tiene UN consumidor dueño

La matriz de flags de este archivo es la fuente de verdad: quién emite, quién
consume (dueño) y quién lo levanta. Un flag sin dueño es un bug del sistema →
`<<AGENT-DRIFT>>`.

## REGLA #6 — El roster solo lo edita `agent-ops`

Charters, skills propias y este router se editan ÚNICAMENTE vía el repo
`claude-config` → PR → **merge humano** → sync. Nadie edita `~/.claude/` en
caliente. El charter de agent-ops lo mantiene el humano (anti-bucle).

---

## 🧭 Anti-conflictos: qué herramienta para qué (la política)

| Necesidad | Herramienta canónica | NO usar |
|---|---|---|
| Entender el código de un repo | Glob/Grep/Read dirigidos | grep masivo sin objetivo |
| Debugging en desarrollo | skill `investigate` (Iron Law, root cause) | improvisar fixes |
| Incidente de producción | `sre-observability` → skill `postmortem` | investigate a secas |
| QA funcional de web viva | skill `qa-web` (Playwright MCP / claude-in-chrome) | — |
| Gate visual/UX | skill `ui-review` — **UNA sola pasada** (dueño: qa-engineer) | correrla 3 veces (v2) |
| Datos de diseño (paleta/tipo/estilo) | skill `design-system` | inventar paletas de memoria |
| Craft de producto (init/critique/polish) | comandos `/impeccable:*` | duplicarlo con skills propias |
| Landing cinemática | skill `motion` | — |
| Review de diff genérico | `/code-review` built-in (+ `codex` en auth/pagos/RLS) | — |
| ¿El diff cumple el plan? | skill `plan-audit` | — |
| Seguridad completa | `security-auditor` → skill `cso` | `/security-review` para auditorías full |
| Seguridad rápida de un diff | `/security-review` built-in | `cso` en cambios chicos |
| Evidencia de "done" | skill `verify` | claims sin output |
| E2E programado | Playwright MCP / `npm run test:e2e` | — |
| Deploy del flujo x-legal | HUMANO con `revisar-pr` (migración→merge→verify) | merge automático |
| Charts/dataviz | skill `dataviz` (plugin) | design-system (no cubre charts) |
| Presentaciones | SOLO en `chamba` (toolkit local) | — |

Nota: `revisar-pr` menciona `graphify` en su paso 8 — es un no-op tolerado si
graphify no está instalado (la skill es intocable por ser el gate de main).

Desempate impeccable ↔ ui-review: la description de `impeccable` reclama
triggers amplios (design/critique/audit/polish). Regla: el GATE del pipeline
es SIEMPRE `ui-review` (report-only, veredicto PASS/FAIL); `impeccable` es
CRAFT — crear, mejorar, pulir — a pedido del humano o de `ui-designer`. Si
divergen en veredicto, manda `ui-review`.

## 🧠 Memoria — jerarquía de 3 capas (quién recuerda qué)

| Capa | Qué guarda | Dónde |
|---|---|---|
| **Historial del proyecto** | Narrativa: qué se hizo, por qué, cómo se verificó | `docs/historial/` del repo (versionado; índice generado; SIN PII) |
| **Memoria de oficio** | Aprendizajes por agente (recetas, patrones, trampas) | `~/.claude/agent-memory/<agente>/MEMORY.md` — leer al inicio, actualizar al final. **Máximo 200 líneas**; el excedente lo archiva `agent-ops` |
| **Estado de sesión** | Trabajo a medias entre sesiones | Nativo: `/resume` + rewind de Claude Code |

`CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` sigue activo: la memoria es deliberada,
no automática.

---

## Flags de colaboración — matriz v3 (REGLA #5)

| Flag | Emisores | Consumidor DUEÑO | Lo levanta |
|---|---|---|---|
| `<<NEED-BACKEND>>` | ux, architect, db, frontend | team-lead → backend-builder | team-lead al cerrar el nodo |
| `<<NEED-SEC>>` | cualquiera salvo security-auditor | team-lead → security-auditor | security-auditor con veredicto |
| `<<NEED-PERF>>` | qa, backend, frontend, db, llm, code-reviewer, sre | **performance-engineer** | performance-engineer con métricas vs baseline |
| `<<NEED-A11Y-FIX>>` | **solo qa-engineer** | team-lead → frontend-builder | qa-engineer al re-verificar con axe |
| `<<NEEDS-REVISION>>` | qa, code-reviewer, security, team-lead, sre, perf | team-lead → autor del diff | quien lo emitió, al re-validar |
| `<<BLOCK-DEPLOY>>` | security, qa, devops, db, backend, llm, code-reviewer | devops (congela) + team-lead (propaga) | **quien lo emitió; security-auditor arbitra** en conflicto o ausencia |
| `<<NEED-ROLLBACK-PLAN>>` | db, architect, backend, code-reviewer, refactoring, sre | devops-engineer | devops con procedimiento probado |
| `<<NEED-SECRETS-ROTATION>>` | security-auditor, devops | devops (ejecuta rotación) | security-auditor (verifica) |
| `<<NEED-REFACTOR>>` | code-reviewer, architect, perf, qa | team-lead → **refactoring-specialist** | refactoring-specialist con gates verdes |
| `<<INCIDENT>>` | sre, devops, security, humano | **sre-observability** | sre al publicar el postmortem |
| `<<NEED-PRODUCT-DECISION>>` | team-lead, architect, ux, cualquiera ante ambigüedad de negocio | **product-manager** (interactivo) / `.orchestrator-blocked.md` (cola) | product-manager con la decisión en el PRD |
| `<<AGENT-DRIFT>>` | cualquier agente (skill rota, trigger muerto, memoria ajena) | **agent-ops** | agent-ops tras PR mergeado + sync verificado |

Un flag expande el grafo de despacho; `<<BLOCK-DEPLOY>>` congela devops hasta
resolverse. Eliminados en v3: `<<NEED-EMAIL>>` y `<<NEED-3D>>` (huérfanos sin
emisores; ese trabajo viaja como tarea normal).

## Skills del sistema (v3: 17 propias + plugins)

- **Proceso:** `brainstorm` · `write-plan` · `tdd` · `verify` · `investigate`
- **Calidad:** `plan-audit` · `qa-web` · `retro` · `cso` · `codex`
- **Diseño:** `design-system` (datos: 68 estilos, 97 paletas, 57 pairings) ·
  `ui-review` (gate) · `motion` (build cinemático) — el proceso de craft es del
  plugin **impeccable** (`/impeccable:*`, 23 comandos + 59 reglas anti-slop)
- **Docs:** `docs` (Diataxis: modos generate + release)
- **Ops:** `postmortem`
- **Flujo VPS:** `encolar-tarea` · `revisar-pr` (los 2 intocables)
- **Plugins:** impeccable, playwright, context7, supabase, codex, kimi,
  dataviz… (**superpowers se desinstala** tras validar la migración — sus 5
  skills de proceso son ahora propias)

## MCPs

| MCP | Uso | Nota |
|---|---|---|
| supabase (`.mcp.json` del repo) | BD del proyecto | **Apunta a DEV** (`--project-ref` fijo); token por `${SUPABASE_ACCESS_TOKEN}`; prod solo vía CLI humano |
| playwright | E2E, screenshots, verificación en vivo, `qa-web`, `ui-review` | `--headless` en el VPS |
| context7 | Docs actualizadas de librerías | úsalo antes de asumir APIs |
| Vercel | runtime errors, logs, deployments (sre-observability) | — |
| GitHub (`gh` CLI) | PRs, issues, checks | preferir `gh` |
| Figma / Pencil / shadcn-ui / magic-ui | diseño y componentes | según proyecto |

## Reglas universales

- NUNCA `--no-verify`, NUNCA `git push --force` a main, NUNCA push directo a
  main en x-legal (el deploy es automático; el PR es el rollback).
- Todo deploy: `security-auditor` ✔ + `qa-engineer` ✔ antes; `sre-observability`
  toma la ventana después.
- Todo agente UI verifica con Playwright screenshot antes de "done".
- Backend: test PRIMERO (skill `tdd`, estricto).
- Secretos: solo variables de entorno; jamás en archivos versionados, prompts,
  logs ni bitácoras (escribir `<redactado>`).
- PII de clientes reales: jamás en repos/historial/prompts a IA (usar
  `U26-XXXXXX` / `[CLIENTE-XX]`; demos `@e2e.local` sí).
- Cada agente lee su `~/.claude/agent-memory/<name>/MEMORY.md` al inicio y lo
  actualiza al final (tope 200 líneas).
- Comandos destructivos: el hook PreToolUse `block-dangerous.sh` (conectado en
  settings PC y VPS) bloquea rm -rf masivo, DROP/TRUNCATE, fuga de
  credenciales, force-push y push a main sin rama explícita. Es la protección
  REAL — las skills careful/freeze/guard (teatro sin hooks) fueron eliminadas
  en v3.

## Agent Teams (solo PC)

Plantillas listas en `~/.claude/TEAM-TEMPLATES.md` (roster v3). 3-5
teammates, un team a la vez, "clean up the team" al cerrar. El VPS no usa
teams (~7× tokens).

## Convenciones

- Respuestas al usuario en **español** · código e identificadores en **inglés**
  · commits en inglés · docs de producto en español.
- Windows: cuidado con la trampa UTF-8 de PowerShell 5.1 (editar con
  herramientas byte-a-byte o Node); los `.sh` que viajan al VPS van con LF.
- Config compartida: editar en `C:\Users\mauri\claude-config\` → commit →
  `sync-config.ps1 apply` (PC) · el VPS la recibe por cron. `sync-config.ps1
  diff` detecta drift (está en el checklist de `revisar-pr`).
