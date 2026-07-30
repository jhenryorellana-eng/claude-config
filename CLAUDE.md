# Sistema Multi-Agente Colaborativo — Mauri

> Este archivo se carga automáticamente en CUALQUIER sesión de Claude Code desde cualquier carpeta del disco C. Es el "router central" del sistema.

---

## 🎯 Cómo invocar al "agente general" (orchestrator)

**No tienes que llamarlo explícitamente — se invoca solo.** Cuando escribas un prompt que contiene cualquiera de estos triggers, Claude Code despacha automáticamente al `orchestrator`:

| Triggers en tu prompt                                                               |
|--------------------------------------------------------------------------------------|
| "build", "construye", "crea", "haz", "implementa", "desarrolla"                      |
| "MVP", "feature completa", "full-stack", "todo el sistema", "app", "sistema"         |
| "deploy", "ship", "lanza"                                                            |
| "refactoriza", "migra", "mejora", "rediseña"                                         |

**Ejemplos que disparan el orchestrator automáticamente:**
- `creame una landing bonita para mi restaurante con reservas online`
- `construye un MVP de SaaS de control de gastos`
- `implementa el flujo de signup con email confirmación`
- `mejora la performance de mi dashboard`

**Si quieres invocarlo explícitamente** (cuando tu prompt no tiene triggers obvios):
```
@orchestrator: necesito que analices y planifiques [tu pedido]
```
O simplemente: `usa el orchestrator para...`

**Cuándo NO se invoca el orchestrator** (uso directo, sin pasar por él):
- Tareas atómicas: "lee este archivo", "lista X", "muestra el diff"
- Slash commands directos: `/cso`, `/ship`, `/speckit.specify`, `/security-review`
- Skills auto-activantes: `slide` (PPT), `ui-ux-pro-max` (design intelligence), `motionsites-architect` (motion-rich landings)

---

## 👥 Agent Teams — colaboración peer-to-peer entre subagentes

A partir de Claude Code v2.1.32+ (activado en este sistema vía `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` en settings.json), múltiples subagentes pueden trabajar como **equipo coordinado** con:

- **Shared task list** (file locking previene race conditions)
- **Mailbox P2P** — los teammates se mensajean directamente entre sí vía `SendMessage`, NO solo al lead
- **Cada teammate** corre en su propio context window (independiente)
- **In-process mode** en Windows (Shift+Down para navegar entre teammates)

### Cuándo crear un team (vs subagent o uso directo)

| Situación | Modo |
|---|---|
| Tarea atómica ("lee X") | Directo |
| Tarea con un solo dominio (UI o backend o security) | Subagent (Task tool) |
| Tarea multi-dominio donde TODOS los aspectos son interdependientes | Subagent (orchestrator) |
| Tarea multi-dominio donde los aspectos son **independientes** Y se beneficiarían de **cuestionamiento mutuo / paralelización real** | **Agent Team** |

### Diferencia subagent vs teammate (oficial)

- **Subagent**: reporta resultados solo al main agent, NO habla con otros subagents
- **Teammate**: comparte task list, claim work, **comunica directamente con otros teammates** vía mailbox

### Cómo crear un team — frases que activan

```
Create an agent team to build a motion-rich landing for [brief].
Spawn 3 teammates using existing agent types:
- ui-master for UX, palette, accessibility
- motionsites-architect for creative direction + asset curation
- disruptive-landing-builder for scroll engineering with GSAP+Lenis
Have them coordinate via shared task list and message each other directly.
```

O más simple:
```
Crea un team de 3 agentes para [tarea]. Que se cuestionen entre ellos y debatan
las decisiones antes de avanzar.
```

### Patrones recomendados (de docs oficiales)

- **3-5 teammates** óptimo (más coordinación = overhead, menos paralelismo real)
- **5-6 tareas por teammate** óptimo
- **Plan approval requerido** para teammates riesgosos: "Spawn architect teammate ... Require plan approval before changes"
- **Empezar con research/review** (no implementación) si es primera vez con Agent Teams

### Reutilización de subagentes como teammate types

Los 10 subagentes existentes (`orchestrator`, `ui-master`, `ui-builder`, `backend-builder`, `qa-engineer`, `security-auditor`, `code-reviewer`, `devops-engineer`, `disruptive-landing-builder`, `slide-critic`) son **directamente reutilizables como teammate types** sin modificación. Ejemplo:

```
Spawn a teammate using the security-auditor agent type to audit the auth module.
```

**LIMITACIÓN:** los campos `skills:` y `mcpServers:` del frontmatter NO se aplican cuando el subagent corre como teammate. Las skills y MCPs se cargan desde tu project/user settings (igual que sesión normal).

### Limitaciones a recordar

- **Lead es fijo**: la sesión donde se crea el team es lead para siempre. Cierras esa sesión → fin del team.
- **No nested teams**: teammates no pueden crear sub-teams.
- **One team at a time**: un lead solo maneja un team a la vez. Limpia antes de crear otro: "clean up the team".
- **Tokens significativamente más altos** que single session.
- **No `/resume` con in-process teammates**: si resumes una sesión, los teammates no se restauran.

### Templates pre-escritos

Para casos recurrentes (landing motion-rich, code review profundo, debug con hipótesis competidoras, architecture review), consulta `~/.claude/TEAM-TEMPLATES.md` que contiene prompts listos para copy/paste.

---

## Stack default

- **Proyectos** pueden estar en CUALQUIER carpeta del disco C (sin ruta fija)
**OS:** Varía según la máquina. Detecta el entorno antes de asumir sintaxis de comandos:
	- PC local: Windows 11, PowerShell (bash disponible)
	- VPS de automatización: Ubuntu 24.04, bash, headless — sin pantalla ni navegador con GUI
- **Frontend:** Next.js 15 + Tailwind v4 + shadcn/ui + TypeScript strict (a menos que el proyecto declare otro stack)
- **Backend:** Supabase (Postgres + Auth + Edge Functions) por defecto
- **Idioma:** contenido en español, código en inglés
- **Sistema cargado globalmente** desde `~/.claude/` (agentes, skills, plugins, MCPs, claude-mem cuando esté instalado)

---

## REGLA #1 — Multi-agente sumatorio, NO aislado

Todo prompt no-trivial debe rutearse al `orchestrator` PRIMERO. El orchestrator razona qué subagentes + skills + MCPs combinar y produce un plan de despacho explícito.

**NUNCA invocar un solo subagente sin pasar por orchestrator, excepto:**

| Excepción                          | Cuándo aplica                                       |
|------------------------------------|------------------------------------------------------|
| Tareas atómicas claras             | "lee este archivo", "lista X", "muestra Y"          |
| Slash commands directos            | `/speckit.specify`, `/security-review`, `/design-review` |
| Skills auto-activantes triviales   | `slide` (cuando piden ppt), `find-skills`           |

Para todo lo demás (build, crea, MVP, feature, "mejora X", "refactoriza Y"): ruta → orchestrator.

## REGLA #2 — Skills declaradas, no inferidas

Cada subagente declara en su frontmatter qué skills puede cargar. Al ejecutar, **invoca `Skill(name=...)` explícitamente** para las que necesita. No infiere por contexto del prompt.

## REGLA #3 — Two-stage review SIEMPRE antes de "done"

Antes de declarar trabajo "terminado":
1. **code-reviewer** revisa el diff completo (spec compliance + code quality)
2. **verification-before-completion** confirma evidencia ejecutada (tests pasando, screenshots tomados, comandos ejecutados con output)

Si alguno emite NEEDS-REVISION → loop a la fase anterior con el agente correspondiente.

## REGLA #4 — Live Research en cada subagente

Cada subagente DEBE ejecutar su Phase 0 de WebSearch antes de tocar código. El conocimiento no está congelado en el prompt — se valida contra el estado del arte actual en cada invocación.

---

## Routing rápido — cuándo NO usar orchestrator (atajos)

| Prompt directo                                  | Acción                                                       |
|-------------------------------------------------|--------------------------------------------------------------|
| `/speckit.specify [...]`                        | Spec-kit directo                                             |
| `/cso` o "audit security"                       | gstack CSO mode directo (OWASP + STRIDE + supply chain)      |
| `/ship` o "ship this PR"                        | gstack /ship directo (workflow PR creation)                  |
| `/land-and-deploy`                              | gstack merge+deploy+canary directo                           |
| `/office-hours` o "is this worth building"      | gstack YC-style brainstorming directo                        |
| `/autoplan` o "run all reviews"                 | gstack auto-review pipeline (CEO+design+eng+DX)              |
| `/retro` o "weekly retro"                       | gstack retrospective directo                                 |
| "presentación", "ppt", "slides", "deck"         | skill `slide` directa                                        |
| "lee X", "buscar Y", "dime sobre Z"             | Read/Grep/WebSearch directo                                  |
| "crítica este deck"                             | Agent `slide-critic` directo                                 |
| Todo lo demás (build, crea, MVP, feature, fix)  | → **orchestrator**                                           |

---

## 🧰 Catálogo gstack — skills integradas al ecosistema (50+ slash commands)

Las skills de **gstack** son herramientas que los subagentes USAN. No reemplazan a los subagentes — los potencian. El orchestrator decide cuándo invocarlas en su grafo.

### Mapeo skill→agente (qué subagente usa qué skill)

| Subagente            | gstack skills que invoca cuando aplica                                                                                                  |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `orchestrator`       | `/autoplan` `/office-hours` `/plan-ceo-review` `/plan-eng-review` `/plan-design-review` `/plan-devex-review` `/skillify` `/retro`        |
| `ui-master`/`ui-builder` | `/design-consultation` `/design-shotgun` `/design-html` `/design-review` `/plan-design-review` `/landing-report` `/browse`           |
| `backend-builder`    | `/investigate` `/codex` `/health` `/context-save` `/context-restore`                                                                    |
| `qa-engineer`        | `/qa` `/qa-only` `/benchmark` `/canary` `/browse` `/devex-review` `/health` `/ios-qa` (si proyecto iOS)                                 |
| `security-auditor`   | `/cso` (Chief Security Officer — supersede al workflow OWASP manual del prompt)                                                         |
| `code-reviewer`      | `/review` `/codex review` (segunda opinión cross-model) `/document-release`                                                             |
| `devops-engineer`    | `/ship` `/land-and-deploy` `/setup-deploy` `/canary` `/landing-report`                                                                  |

### Skills gstack universales (cualquier agente puede usar)

| Skill                                | Propósito                                                                |
|--------------------------------------|--------------------------------------------------------------------------|
| `/learn`                             | Buscar, prune, exportar aprendizajes pasados                             |
| `/context-save` / `/context-restore` | Guardar/restaurar estado de trabajo entre sesiones                       |
| `/careful` / `/freeze` / `/guard`    | Modos de seguridad (warnings ante rm-rf, edits limitados a una carpeta)  |
| `/make-pdf`                          | Convertir markdown a PDF publicación-quality                             |
| `/document-generate`                 | Auto-generar documentación Diataxis                                      |
| `/scrape`                            | Web scraping vía browse daemon                                           |
| `/health`                            | Code quality score 0-10 compuesto                                        |

---

## ⚖️ Política anti-conflictos: skill custom vs gstack

Cuando hay overlap aparente, esta es la regla:

| Overlap                          | Regla                                                                                                             |
|----------------------------------|-------------------------------------------------------------------------------------------------------------------|
| `qa-engineer` vs `/qa` (gstack)  | El AGENTE custom decide. `/qa` es una skill que invoca dentro de su Phase 0 si necesita el workflow específico.   |
| `code-reviewer` vs `/review`     | code-reviewer es el flow oficial Phase 3. `/review` lo invoca como tool si quiere usar el formato estructurado.   |
| `security-auditor` vs `/cso`     | security-auditor llama a `/cso` automáticamente cuando hace audit comprehensive. El agent es el flow, la skill es la herramienta. |
| `devops-engineer` vs `/ship`     | devops-engineer invoca `/ship` para crear el PR; `/land-and-deploy` para mergear+deployar. Es una pipeline integrada. |
| `Playwright` vs `/browse`        | Playwright para tests programados (E2E suite); `/browse` para dogfooding rápido y diff screenshots (~100ms/comando). |
| `web-design-guidelines` vs `/design-review` / axe-core | Son 3 lentes complementarios, NO se reemplazan: `web-design-guidelines` (Vercel) = checklist canónico de interfaz (100+ reglas, se descargan en vivo); `/design-review` = ojo de diseñador (jerarquía, AI-slop); axe-core = a11y programática. UI premium usa los tres. |
| `web-artifacts-builder` vs stack de producción | `web-artifacts-builder` es SOLO para artifacts/prototipos compartibles de claude.ai (React 18 + Vite/Parcel + Tailwind 3.4.1 + shadcn). Para sitios de producción usa el stack default (Next.js 15 + Tailwind v4 + shadcn). No mezclar. |

**Filosofía:** los subagentes son los "roles" (quién hace qué). Las skills son las "herramientas" (cómo lo hace). Las skills NO reemplazan a los agentes — son tools en su caja.

---

## Subagentes activos y su rol

| Subagente              | Rol                                       | Model  | Skills default                                                       |
|------------------------|-------------------------------------------|--------|----------------------------------------------------------------------|
| `orchestrator`         | Lead architect: razona grafo de despacho  | opus   | brainstorming, writing-plans, dispatching-parallel-agents            |
| `ui-builder` / `ui-master` | Frontend, landing, UI premium         | opus   | frontend-design, ui-ux-pro-max, slide, web-design-guidelines (gate), web-artifacts-builder (artifacts), gsap-awwwards-website (starter) |
| `backend-builder`      | APIs, auth, DB, business logic            | sonnet | test-driven-development, systematic-debugging                        |
| `qa-engineer`          | Tests E2E, unit, a11y, performance        | sonnet | test-driven-development, webapp-testing, verification-before-completion, web-design-guidelines (a11y/perf gate) |
| `security-auditor`     | OWASP, CVE, vulnerability audit           | opus   | /security-review, systematic-debugging                               |
| `code-reviewer`        | Pre-merge code review                     | sonnet | requesting-code-review, verification-before-completion, web-design-guidelines (UI PRs) |
| `devops-engineer`      | CI/CD, deploy, infra                      | opus   | finishing-a-development-branch, verification-before-completion       |
| `disruptive-landing-builder` | Landing premium (legacy — será ui-master) | opus | (mantiene MEMORY.md con CDNs y patrones GSAP)                     |
| `slide-critic`         | Crítica de decks HTML                     | opus   | (especializado en skill `slide`)                                     |

---

## MCPs disponibles (a usar según dominio)

| MCP                  | Cuándo usarlo                                                    |
|----------------------|------------------------------------------------------------------|
| Supabase             | DB design, Auth, Edge Functions, RLS, migrations                 |
| GitHub               | Repos, PRs, issues, releases, Actions                            |
| Playwright           | Browser automation, E2E tests, screenshots                       |
| Context7             | Docs actualizadas de cualquier librería/framework                |
| Firecrawl            | Web scraping, research de competidores, mapeo de sitios          |
| Figma                | Lectura de designs, generación de código desde mockups           |
| Pencil               | Archivos `.pen` para diseño                                      |

---

## Skills universales (vienen del plugin superpowers — ya instalado)

Cualquier subagente puede invocarlas vía `Skill(name=...)`:

- `brainstorming` — antes de cualquier creative work
- `writing-plans` — convertir spec en plan ejecutable
- `executing-plans` — ejecutar plan en sesión separada con checkpoints
- `test-driven-development` — RED → GREEN → REFACTOR estricto
- `systematic-debugging` — ante cualquier bug/test failing
- `dispatching-parallel-agents` — fan-out a múltiples subagentes
- `subagent-driven-development` — ejecutar plan con subagentes
- `requesting-code-review` / `receiving-code-review` — code review riguroso
- `verification-before-completion` — evidencia antes de claim "done"
- `finishing-a-development-branch` — decisión de merge/PR/cleanup
- `using-git-worktrees` — aislamiento de workspace
- `using-superpowers` — meta: cómo encontrar y usar skills

---

## Skills de diseño frontend (origen y confianza)

Estas skills refuerzan la capa de diseño. **Importante: no todas son de Anthropic** — trata las de origen externo con criterio.

| Skill | Invocación | Origen | Confianza | Uso |
|---|---|---|---|---|
| `frontend-design` | `frontend-design:frontend-design` | Anthropic (plugin oficial, marketplace) | Alta | Dirección estética distintiva (evita "AI slop"). Siempre en trabajo visual. |
| `web-artifacts-builder` | `web-artifacts-builder` | Anthropic (skill suelta, `anthropics/skills`) | Alta | Artifacts/prototipos de claude.ai (React 18 + Vite/Parcel + Tailwind 3.4.1 + shadcn). NO para producción Next.js. Sus scripts `.sh` requieren Git Bash. |
| `web-design-guidelines` | `web-design-guidelines` | **Vercel (tercero)** | Media | Quality gate a11y/perf/UX (100+ reglas). ⚠️ **Descarga su rulebook en vivo** desde `raw.githubusercontent.com/vercel-labs/web-interface-guidelines` en cada uso — comportamiento dependiente de contenido remoto. |
| `gsap-awwwards-website` | `gsap-awwwards-website` | **Comunidad (`eng0ai/eng0-template-skills`)** | Baja — auditada | Starter landing Awwwards (React 19 + Vite + GSAP + Tailwind 4). Auditada (SKILL.md + `package.json` limpios, sin `postinstall` ni exfiltración). Clona un repo-plantilla externo al hacer scaffold. |
| `web-prompt-architect` | `web-prompt-architect` | Propia (Mauri) | Alta | **Escribe un PROMPT** hiper-específico (estilo motionsites + estructura [Rol][Contexto][Tarea][Restricciones][Formato] + SDD) para que OTRO agente construya la web. NO genera código — genera el spec/prompt. |

**Regla de procedencia:** skills de tercero/comunidad se auditan antes de instalar y se re-auditan si cambian de versión. Nunca ejecutar sus scripts de `setup`/`deploy` sin revisarlos.

**Regla anti-conflicto (prompt vs build vs spec):** tres roles ortogonales, no compiten:
- `web-prompt-architect` → **escribe el PROMPT denso** (idea vaga → spec para pegar en un agente). Úsala cuando el usuario quiere *arquitectar las instrucciones primero*.
- `motionsites-architect` / `ui-master` / `ui-builder` → **CONSTRUYEN el sitio** (generan el código). Úsalas cuando el usuario quiere el build directo.
- `spec-kit` (`/speckit.*`, `specify init`) → **especifica software** (`.specify/` con constitution/spec/plan/tasks). Es la capa de planificación de producto.
- Pipeline natural: `web-prompt-architect` (o `spec-kit`) produce el spec → `ui-master`/`motionsites-architect` lo construyen.

---

## Workflow estándar (cualquier proyecto nuevo)

```
1. cd <cualquier-carpeta-del-disco>
2. specify init                      # cuando spec-kit esté instalado
3. Hablar al orchestrator             # él razona el grafo
4. Confirmar plan de despacho         # revisar Phase 0 / Phase 1 / etc.
5. orchestrator delega a subagentes   # paralelo + secuencial
6. code-reviewer + verification        # gate antes de done
7. claude-mem captura automáticamente  # próxima sesión ya tiene contexto
```

---

## Flags del protocolo de colaboración

Los subagentes emiten flags en su Handoff. El orchestrator los procesa para expandir el grafo:

| Flag                   | Significado                                    | Reacción del orchestrator                    |
|------------------------|------------------------------------------------|----------------------------------------------|
| `<<NEED-BACKEND>>`     | UI detectó form que necesita persistencia      | Despachar backend-builder                    |
| `<<NEED-EMAIL>>`       | Requiere email transaccional                   | Plantilla react.email + backend              |
| `<<NEED-SEC>>`         | Exposición de PII o auth detectada             | Despachar security-auditor                   |
| `<<NEED-PERF>>`        | Query no escala / LCP > 2.5s                   | Iterar con backend o ui-master               |
| `<<NEED-A11Y-FIX>>`    | Violaciones críticas axe-core                  | Volver a ui-master con findings              |
| `<<NEED-3D>>`          | Three.js / WebGL avanzado                      | ui-master con investigación 3D extra         |
| `<<NEED-VOICE>>`       | Narración / TTS                                | voicebox MCP (cuando esté)                   |
| `<<BLOCK-DEPLOY>>`     | Vulnerabilidad crítica                         | Bloquea devops hasta resolverse              |
| `<<NEEDS-REVISION>>`   | code-reviewer rechazó                          | Loop a fase anterior                         |
| `<<NEED-ROLLBACK-PLAN>>`| Cambio prod sin plan                          | Generar plan antes de deploy                 |

---

## Reglas universales (todos los agentes)

- NUNCA `--no-verify` en commits sin permiso explícito del usuario
- NUNCA `git push --force` a `main`/`master` sin confirmar
- Todo deploy requiere: security-auditor ✅ + qa-engineer ✅
- Todo agente UI debe ejecutar Playwright screenshot antes de declarar "done"
- Todo agente backend debe escribir test PRIMERO (TDD estricto via skill)
- Todo agente debe leer su `agent-memory/<name>/MEMORY.md` al inicio y actualizarlo con aprendizajes al final

---

## Memorias persistentes

| Ubicación                                          | Qué contiene                                      |
|----------------------------------------------------|---------------------------------------------------|
| claude-mem (cuando esté) — viewer `:37777`         | Captura cross-session global automática           |
| `~/.claude/agent-memory/<name>/MEMORY.md`          | Específica por agente (CDN URLs, patrones, etc.)  |
| `~/.claude/skills/slide/memory.json`               | Anti-uniformity log de decks generados            |
| `~/.claude/plans/`                                 | Planes de implementación (uno por feature)        |

---

## Convenciones de comunicación

- Responder al usuario en **español**
- Código en **inglés** (variables, funciones, archivos)
- Comentarios técnicos en **inglés** (sólo cuando hay decisión no obvia)
- Mensajes de commit en **inglés**
- Documentación de producto y README en **español** o el idioma que pida el cliente
