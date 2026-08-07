# Sistema Multi-Agente — Mauri/Henry (v2 · 2026-08-07)

> Cargado en CUALQUIER sesión de Claude Code de esta máquina. Es el router
> central: quién hace qué, con qué herramientas, y cómo NO pisarse.
> Reorganizado el 2026-08-07: roster de 13 especialistas, pipeline UI real,
> skills podadas de 61 → ~32, memoria por capas.

## Máquinas

- **PC (Windows 11, PowerShell + Git Bash):** desarrollo interactivo, revisión
  de PRs, merges, migraciones a prod (acto deliberado). Agent Teams ✔.
- **VPS (Ubuntu, headless, `dev@217.77.15.7`):** cola desatendida
  (`~/orchestrator`) que ejecuta tareas con `claude -p` y abre PRs. Sin GUI,
  sin Docker, sin Agent Teams (`AGENT_TEAMS=0`). Config sincronizada desde el
  repo `claude-config` (cron cada 15 min).
- Ambas comparten la MISMA ventana de cuota: un solo asistente pesado a la vez.

---

## 👥 El equipo — 13 especialistas (`~/.claude/agents/`)

| Agente | Modelo | Dueño de |
|---|---|---|
| `team-lead` | opus | Coordinación: analiza, razona el grafo de despacho, delega. **Jamás escribe código** |
| `architect` | opus | ADRs, límites de módulos, contratos de API, trade-offs de stack |
| `ux-designer` | opus | Flujos, arquitectura de información, wireframes, heurísticas, estados vacíos/error |
| `ui-designer` | opus | Sistema visual: tokens, tipografía, paletas, DESIGN.md, anti-AI-slop |
| `frontend-builder` | sonnet | Implementación Next.js/React/Tailwind/shadcn + motion (GSAP/Lenis) + Core Web Vitals |
| `backend-builder` | sonnet | APIs, lógica de negocio, jobs, integraciones, performance backend |
| `db-architect` | opus | Esquema, migraciones expand/contract, RLS, índices, seeds, tipos generados |
| `llm-engineer` | sonnet | IA del producto: ai-engine, prompts versionados, evals, maskPii, costo por run |
| `qa-engineer` | sonnet | Tests unit/e2e, a11y, regresión visual, evidencia ejecutada |
| `code-reviewer` | sonnet | Revisión de diffs (calidad + spec-compliance); escala a `/codex` en auth/pagos/RLS |
| `security-auditor` | opus | OWASP + STRIDE + supply chain + **compliance/PII** (plataforma legal). Veto con `<<BLOCK-DEPLOY>>` |
| `devops-engineer` | sonnet | CI/CD, Vercel, el VPS y su orquestador, secretos, canary |
| `docs-writer` | haiku | Historial, redacción de ADRs, CHANGELOG, docs Diataxis |

**Pipeline UI (roles separados que se alimentan):**
`ux-designer` (flujo+wireframe) → `ui-designer` (sistema visual+DESIGN.md) →
`frontend-builder` (código+motion) → `qa-engineer` (tests/a11y) + skill
`design-review` (QA visual en vivo). Cada fase entrega su artefacto antes de
que arranque la siguiente; los desacuerdos suben a `team-lead`.

**Toolkit personal (NO global):** `slide`, `web-prompt-architect` y el agente
`slide-critic` viven SOLO en `C:\Users\mauri\Documents\chamba\.claude\`
(decisión del 2026-08-07). No aparecen en este router.

---

## REGLA #1 — Todo lo no-trivial pasa por `team-lead`

Triggers que lo invocan automáticamente: "build", "construye", "crea", "haz",
"implementa", "desarrolla", "MVP", "feature", "app", "sistema", "deploy",
"ship", "refactoriza", "migra", "mejora", "rediseña".

Excepciones (uso directo, sin team-lead):

| Prompt | Acción directa |
|---|---|
| Tareas atómicas ("lee X", "lista Y", "muestra el diff") | Read/Grep/Glob |
| "encola…", "mándale al VPS…" | skill `encolar-tarea` |
| "revisa/mergea el PR N" | skill `revisar-pr` |
| "audit security", "/cso" | `security-auditor` (usa `/cso`) |
| "debug/investiga este error" | skill `investigate` → agente del dominio |
| "documenta X" | `docs-writer` |
| Slash commands explícitos (`/qa`, `/review`, `/health`, `/retro`…) | la skill invocada |

## REGLA #2 — Skills se invocan explícitamente

Cada agente declara en su charter qué skills usa y en qué fase; las invoca con
`Skill(name=...)`. No se infiere por vibra.

## REGLA #3 — Two-stage review antes de "done"

1. `code-reviewer` revisa el diff (spec-compliance + calidad).
2. `verification-before-completion` (superpowers): evidencia ejecutada — tests
   corridos con salida, screenshots tomados, comandos con output. "Debería
   funcionar" no es evidencia.
Cualquier `<<NEEDS-REVISION>>` → loop a la fase anterior.

## REGLA #4 — Research en vivo (Phase 0)

Todo agente ejecuta su Phase 0 (WebSearch/Context7) antes de tocar código: el
conocimiento se valida contra el estado del arte EN CADA invocación, no se
asume congelado.

---

## 🧭 Anti-conflictos: qué herramienta para qué (la política)

| Necesidad | Herramienta canónica | NO usar |
|---|---|---|
| Entender el código de un repo | `graphify query` (grafo local) → luego Read dirigido | grep masivo de arranque |
| Debugging | skill `investigate` (4 fases, root cause) | improvisar fixes |
| QA de una web viva | skill `qa` (arregla) / agente `qa-engineer` (suite) | — |
| Navegador rápido headless | skill `browse` | — (duplicados eliminados) |
| E2E programado | Playwright MCP / `npm run test:e2e` | `browse` para suites |
| Review de un diff | agente `code-reviewer` (+ `/codex review` en auth/pagos/RLS) | 11 rutas viejas — podadas |
| Gate de UI | `web-design-guidelines` (checklist) + `design-review` (ojo de diseñador) + axe (a11y) | elegir solo una: son 3 lentes |
| Seguridad | agente `security-auditor`, que invoca `/cso` | correr `/cso` suelto en cambios chicos |
| Score de calidad | skill `health` | — |
| Deploy del flujo x-legal | HUMANO con `revisar-pr` (migración→merge→verify) | `land-and-deploy` (podada: el merge es humano) |
| Presentaciones | SOLO en `chamba` (toolkit local) | — |

## 🧠 Memoria — jerarquía de 4 capas (quién recuerda qué)

| Capa | Qué guarda | Dónde |
|---|---|---|
| **Graphify** | Mapa del CÓDIGO (nodos/aristas, regenerable) | `graphify-out/` local por máquina, gitignored |
| **Historial del proyecto** | Narrativa: qué se hizo, por qué, cómo se verificó | `docs/historial/` del repo (versionado; índice generado; SIN PII) |
| **Memoria de oficio** | Aprendizajes por agente (CDNs, recetas, patrones) | `~/.claude/agent-memory/<agente>/MEMORY.md` — leer al inicio, actualizar al final |
| **Estado de sesión** | Trabajo a medias entre sesiones | skills `context-save` / `context-restore` |

`CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` sigue activo: la memoria es deliberada,
no automática. gbrain y claude-mem fueron retirados del sistema.

---

## Flags de colaboración (los procesa `team-lead`)

`<<NEED-BACKEND>>` `<<NEED-EMAIL>>` `<<NEED-SEC>>` `<<NEED-PERF>>`
`<<NEED-A11Y-FIX>>` `<<NEED-3D>>` `<<BLOCK-DEPLOY>>` `<<NEEDS-REVISION>>`
`<<NEED-ROLLBACK-PLAN>>` — cada charter documenta cuáles emite. Un flag
expande el grafo de despacho; `<<BLOCK-DEPLOY>>` congela devops hasta resolverse.

## Skills del sistema (post-poda: ~32 + plugins)

- **Flujo VPS:** `encolar-tarea` · `revisar-pr`
- **Calidad:** `qa` · `review` · `investigate` · `health` · `benchmark` · `canary` · `retro` · `cso`
- **Diseño (por fase del pipeline):** `design-consultation` + `ui-ux-pro-max` (UX/UI) · `motionsites-architect` (build motion) · `web-design-guidelines` + `design-review` (gates)
- **Browser:** `browse` · `setup-browser-cookies`
- **Docs:** `document-generate` · `document-release` · `make-pdf`
- **Sesión/seguridad:** `context-save`/`context-restore` · `careful`/`freeze`/`guard`/`unfreeze` · `learn` · `find-skills` · `ship` · `codex` · `gstack-upgrade` · `web-artifacts-builder`
- **Plugins (superpowers, frontend-design, playwright, context7, supabase, codex, kimi, …):** intactos; `superpowers:*` son las skills de proceso universales (brainstorming, TDD, systematic-debugging para el plugin, writing-plans, verification-before-completion…).

## MCPs

| MCP | Uso | Nota |
|---|---|---|
| supabase (`.mcp.json` del repo) | BD del proyecto | **Apunta a DEV** (`--project-ref` fijo); token por `${SUPABASE_ACCESS_TOKEN}`; prod solo vía CLI humano |
| playwright | E2E, screenshots, verificación en vivo | `--headless` en el VPS |
| context7 | Docs actualizadas de librerías | úsalo antes de asumir APIs |
| GitHub (`gh` CLI) | PRs, issues, checks | preferir `gh` |
| Figma / Pencil / shadcn-ui / magic-ui | diseño y componentes | según proyecto |

## Reglas universales

- NUNCA `--no-verify`, NUNCA `git push --force` a main, NUNCA push directo a
  main en x-legal (el deploy es automático; el PR es el rollback).
- Todo deploy: `security-auditor` ✔ + `qa-engineer` ✔ antes.
- Todo agente UI verifica con Playwright screenshot antes de "done".
- Backend: test PRIMERO (TDD estricto).
- Secretos: solo variables de entorno; jamás en archivos versionados, prompts,
  logs ni bitácoras (escribir `<redactado>`).
- PII de clientes reales: jamás en repos/historial/prompts a IA (usar
  `U26-XXXXXX` / `[CLIENTE-XX]`; demos `@e2e.local` sí).
- Cada agente lee su `agent-memory/<name>/MEMORY.md` al inicio y lo actualiza
  al final.

## Agent Teams (solo PC)

Plantillas listas en `~/.claude/TEAM-TEMPLATES.md` (roster nuevo). 3-5
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
