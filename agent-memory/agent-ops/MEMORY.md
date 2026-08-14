# Memoria de oficio — agent-ops
> Máximo 200 líneas cargadas. Curaduría: agent-ops.
> Dueño del SISTEMA de agentes: charters, triggers, skills propias, memoria de oficio
> y drift PC↔VPS. El índice global de triggers vive al final, exento del tope.

## Patrones confirmados

- **La memoria de oficio se cura, no se acumula.** El encabezado de cada MEMORY.md dice
  "Lines after 200 are truncated": todo lo que pase de la línea 200 es conocimiento
  MUERTO que igual cuesta espacio en disco y da falsa sensación de cobertura. La forma
  correcta es MEMORY.md denso (≤200 líneas) + archivos temáticos hermanos
  (`archive-<tema>.md`) con el detalle verbatim, indexados desde el final del MEMORY.md.
- **La memoria pertenece al oficio, no a quien la escribió primero.** En la curaduría
  inaugural, `code-reviewer` tenía 152 KB de los cuales una parte grande eran recetas de
  Astro/GSAP/pdf-lib/react-three-fiber (dueño real: frontend-builder), y `backend-builder`
  abría con 60 líneas de RLS/SECURITY DEFINER/pgTAP (dueño real: db-architect, que estaba
  vacío). Al auditar, la pregunta no es "¿es útil?" sino "¿quién lo va a volver a usar?".
- **Prioridad al comprimir**: conocimiento con incidente/costo real pagado > patrón
  repetido ≥2 veces > nota suelta. Una clase de bug que reincidió 9 veces vale más
  espacio que 40 hallazgos individuales de una ola.
- **Densidad sobre cantidad de líneas**: el corte es por LÍNEAS, no por bytes. Un bullet
  largo y sustancioso cuesta lo mismo que uno trivial. Conviene consolidar N hallazgos
  de la misma clase en un bullet con el conteo de reincidencias.

## Trampas pagadas

- **Escribir memorias con `Out-File` de PowerShell corrompe los acentos** (trampa UTF-8
  de PowerShell 5.1). Usar siempre las herramientas Read/Write/Edit, o Node. Para copiar
  bloques verbatim de un archivo a otro, `sed -n 'X,Yp' src >> dst` desde el tool Bash
  preserva los bytes exactos y es más confiable que retipear.
- **El LIVE (`~/.claude/agent-memory/`) es la fuente de verdad de la memoria**; el repo
  `claude-config` la recibe por `sync-config.ps1 capture`. Editar en el repo y aplicar
  hacia el LIVE es el flujo correcto para CHARTERS y skills, pero al revés para MEMORIAS.
  No confundir las dos direcciones.
- El roster nunca se edita en caliente: charters y skills van por el repo `claude-config`
  y PR. La memoria de oficio es la excepción (se cura en el LIVE y se captura).

## Preferencias de Mauri/Henry
- Respuestas en español; código, identificadores y commits en inglés.
- Nada de PII de clientes reales ni secretos en memorias, charters o bitácoras.
- El VPS no usa Agent Teams (`AGENT_TEAMS=0`); las plantillas de team son solo de PC.

## Changelog del roster

- **2026-08-13 — v3**: 13→18 agentes, skills 32→17 propias, superpowers DESINSTALADO (2026-08-13, orden de Mauri; el VPS nunca lo tuvo), impeccable instalado. Deuda: validación e2e del pipeline v3 pendiente.
- **2026-08-13 — curaduría inaugural de memorias**: se reubicó el conocimiento de
  frontend fuera de `code-reviewer` y el de esquema/RLS fuera de `backend-builder`
  (sembrando `db-architect`); se comprimieron a ≤200 líneas `code-reviewer`,
  `backend-builder`, `ui-designer`, `frontend-builder` y `qa-engineer` con archivos
  temáticos; se sembraron 10 stubs y se creó esta memoria.

<!-- índice: exento del tope -->

## Índice global de triggers

Frase → agente dueño. Construido desde el `description:` de los 18 charters en
`~/.claude/agents/*.md` (2026-08-13). Si un charter cambia sus frases, este índice se
regenera; es la herramienta para responder "¿de quién es esta frase?" sin abrir 18 archivos.

| Frase | Dueño |
|---|---|
| "a11y" | qa-engineer |
| "accesibilidad" | qa-engineer |
| "actualiza el índice" | docs-writer |
| "ADR" | architect |
| "ajusta el agente" | agent-ops |
| "AI" | llm-engineer |
| "alcance" | product-manager |
| "alerta" | sre-observability |
| "alucinación" | llm-engineer |
| "animación" | frontend-builder |
| "antes de commit" | code-reviewer |
| "antes de deploy" | security-auditor |
| "antes de mergear" | qa-engineer |
| "API" | backend-builder |
| "API docs" | docs-writer |
| "architecture" | architect |
| "arquitectura" | architect |
| "arquitectura de información" | ux-designer |
| "arregla este layout" | frontend-builder |
| "audit" | security-auditor |
| "auditoría" | security-auditor |
| "auditoría del sistema de agentes" | agent-ops |
| "axe" | qa-engineer |
| "backend" | backend-builder |
| "backlog" | product-manager |
| "before merge" | code-reviewer |
| "bonito" | ui-designer |
| "boundaries" | architect |
| "branding" | ui-designer |
| "build" | team-lead |
| "build the UI" | frontend-builder |
| "bundle size" | performance-engineer |
| "cache" | performance-engineer |
| "canary" | sre-observability |
| "CD" | devops-engineer |
| "CHANGELOG" | docs-writer |
| "charter" | agent-ops |
| "CI" | devops-engineer |
| "Claude API" | llm-engineer |
| "client component" | frontend-builder |
| "code smell" | refactoring-specialist |
| "cola" | devops-engineer |
| "colores" | ui-designer |
| "compliance" | security-auditor |
| "component" | frontend-builder |
| "construye" | team-lead |
| "Core Web Vitals" | performance-engineer |
| "costo de tokens" | llm-engineer |
| "coverage" | qa-engineer |
| "crea" | team-lead |
| "crea el componente" | frontend-builder |
| "crea un agente" | agent-ops |
| "criterios de aceptación de negocio" | product-manager |
| "cómo debería funcionar" | ux-designer |
| "cómo estructuro esto" | architect |
| "dark mode" | ui-designer |
| "db:types" | db-architect |
| "deploy" | team-lead |
| "desarrolla" | team-lead |
| "descompone" | refactoring-specialist |
| "design system" | ui-designer |
| "design tokens" | ui-designer |
| "DESIGN.md" | ui-designer |
| "deuda técnica" | refactoring-specialist |
| "diseña el flujo" | ux-designer |
| "diseño" | ui-designer |
| "diseño técnico" | architect |
| "docs" | docs-writer |
| "documenta" | docs-writer |
| "documentación" | docs-writer |
| "downtime" | sre-observability |
| "drift" | db-architect |
| "drift de config" | agent-ops |
| "E2E" | qa-engineer |
| "ejecuta el deploy" | devops-engineer |
| "el agente X no se activa" | agent-ops |
| "endpoint" | backend-builder |
| "error en prod" | sre-observability |
| "es seguro" | security-auditor |
| "escribe la entrada" | docs-writer |
| "esquema" | db-architect |
| "estilo" | ui-designer |
| "está bien esto" | code-reviewer |
| "eval" | llm-engineer |
| "experiencia" | ux-designer |
| "explica cómo funciona" | docs-writer |
| "extracción" | llm-engineer |
| "extrae" | refactoring-specialist |
| "feature completa" | team-lead |
| "formulario" | ux-designer |
| "frontend" | frontend-builder |
| "full-stack" | team-lead |
| "Gemini" | llm-engineer |
| "generación" | llm-engineer |
| "GitHub Actions" | devops-engineer |
| "GSAP" | frontend-builder |
| "guía" | docs-writer |
| "hazlo ver profesional" | ui-designer |
| "hidration error" | frontend-builder |
| "historia de usuario" | product-manager |
| "historial" | docs-writer |
| "hook" | frontend-builder |
| "IA" | llm-engineer |
| "implementa" | team-lead |
| "incident" | sre-observability |
| "incidente" | sre-observability |
| "index" | db-architect |
| "information architecture" | ux-designer |
| "INP" | performance-engineer |
| "integración" | backend-builder |
| "is this safe" | security-auditor |
| "job" | backend-builder |
| "journey" | ux-designer |
| "landing" | frontend-builder |
| "latencia" | performance-engineer |
| "LCP" | performance-engineer |
| "legacy" | refactoring-specialist |
| "lento" | performance-engineer |
| "limpia el código" | refactoring-specialist |
| "logs de producción" | sre-observability |
| "look and feel" | ui-designer |
| "lógica de negocio" | backend-builder |
| "memoria de agentes" | agent-ops |
| "mejora" | team-lead |
| "migra" | team-lead |
| "migration" | db-architect |
| "migración" | db-architect |
| "migración de framework" | architect |
| "moderno" | ui-designer |
| "monitoreo" | sre-observability |
| "motion" | frontend-builder |
| "multi-paso" | ux-designer |
| "MVP" | team-lead |
| "módulo" | backend-builder |
| "N+1" | performance-engineer |
| "Next.js" | frontend-builder |
| "onboarding" | ux-designer |
| "optimiza" | performance-engineer |
| "orquestador" | devops-engineer |
| "OWASP" | security-auditor |
| "paleta" | ui-designer |
| "pentest" | security-auditor |
| "performance" | performance-engineer |
| "pgTAP" | db-architect |
| "PII" | security-auditor |
| "Playwright" | qa-engineer |
| "policy" | db-architect |
| "postmortem" | sre-observability |
| "PR ready" | code-reviewer |
| "PRD" | product-manager |
| "premium" | ui-designer |
| "presupuesto de performance" | performance-engineer |
| "prioriza" / "priorización" | product-manager |
| "producción" | devops-engineer |
| "profiling" | performance-engineer |
| "prompt" | llm-engineer |
| "página" | frontend-builder |
| "QA" | qa-engineer |
| "QStash" | backend-builder |
| "query lenta" | db-architect |
| "qué construimos" | product-manager |
| "React" | frontend-builder |
| "README" | docs-writer |
| "refactor" / "refactoriza" | refactoring-specialist |
| "registra lo que se hizo" | docs-writer |
| "regresión" | qa-engineer |
| "release notes" | docs-writer |
| "requisitos de negocio" | product-manager |
| "responsive" | frontend-builder |
| "revisa" / "revisión" / "review" | code-reviewer |
| "RLS" | db-architect |
| "roadmap" | product-manager |
| "rollback" | devops-engineer |
| "roster" | agent-ops |
| "schema" | db-architect |
| "scope" | product-manager |
| "se cayó" | sre-observability |
| "secretos" | devops-engineer |
| "security" / "seguridad" | security-auditor |
| "seed" | db-architect |
| "server action" | backend-builder |
| "shadcn" | frontend-builder |
| "ship" | team-lead |
| "should we use X or Y" | architect |
| "simplifica este código" | refactoring-specialist |
| "skill propia nueva" | agent-ops |
| "SLO" | sre-observability |
| "slow" | performance-engineer |
| "slow query" | db-architect |
| "sync-config" | agent-ops |
| "systemd" | devops-engineer |
| "tabla" | db-architect |
| "Tailwind" | frontend-builder |
| "technical design" | architect |
| "test" / "tests" | qa-engineer |
| "trade-off" | architect |
| "traducción" | llm-engineer |
| "triggers rotos" | agent-ops |
| "tutorial" | docs-writer |
| "usabilidad" | ux-designer |
| "user flow" | ux-designer |
| "user research" | ux-designer |
| "user story" | product-manager |
| "UX" | ux-designer |
| "vale la pena" | product-manager |
| "Vercel" | devops-engineer |
| "visual identity" | ui-designer |
| "vitest" | qa-engineer |
| "VPS" | devops-engineer |
| "vulnerability" | security-auditor |
| "webhook" | backend-builder |
| "wireframe" | ux-designer |
| "índice" | db-architect |

### Colisiones conocidas (vigilar al editar charters)

Frases donde una es prefijo o subcadena de otra, o donde dos agentes comparten campo
semántico. Ninguna es un bug hoy — el charter más específico gana por contexto — pero
son los puntos donde un cambio descuidado rompe el despacho.

| Colisión | Cómo se resuelve hoy |
|---|---|
| "crea" (team-lead) vs "crea un agente" (agent-ops) vs "crea el componente" (frontend-builder) | La frase larga gana; "crea" a secas es despacho, y team-lead reparte |
| "deploy" (team-lead) vs "ejecuta el deploy" (devops-engineer) vs "antes de deploy" (security-auditor) | team-lead planifica, devops ejecuta, security-auditor es el gate previo |
| "migración"/"migration" (db-architect) vs "migra" (team-lead) vs "migración de framework" (architect) | Postgres → db-architect; cambio de stack → architect; pedido amplio → team-lead |
| "auditoría"/"audit" (security-auditor) vs "auditoría del sistema de agentes" (agent-ops) | La frase larga desambigua; sin ella, gana seguridad |
| "índice"/"index" (db-architect) vs "actualiza el índice" (docs-writer) | Índice de Postgres vs índice de documentación |
| "drift" (db-architect, esquema) vs "drift de config" (agent-ops, PC↔VPS) | La frase larga desambigua |
| "refactor"/"refactoriza" (refactoring-specialist) vs "refactor grande" (histórico de architect) | v3 sacó "refactoriza" de team-lead y "refactor grande" de architect: el dueño único es refactoring-specialist |
| "hook" (frontend-builder, React) vs hooks de settings.json (skill `update-config`) | Contexto de código vs configuración del harness |
| "formulario" (ux-designer) vs implementación de forms (frontend-builder) | ux-designer define el flujo; frontend-builder lo codea |
| "módulo" (backend-builder) vs "boundaries"/límites de módulo (architect) | architect define el límite; backend-builder implementa dentro |
| "IA"/"AI" (llm-engineer) | Muy amplia: llm-engineer es dueño de la IA del PRODUCTO, no del tooling de Claude Code |
| "cola" (devops-engineer) | Amplia: se refiere a la cola del orquestador del VPS |
| "N+1" (performance-engineer) vs hallazgos N+1 en review (code-reviewer) | code-reviewer lo DETECTA y emite `<<NEED-PERF>>`; performance-engineer lo diagnostica y corrige |
| "test"/"tests" (qa-engineer) vs disciplina TDD (skill `tdd`, la usan los builders) | qa-engineer es dueño de la suite y del gate; los builders escriben su test-first |
