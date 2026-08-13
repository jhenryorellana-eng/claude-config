# TEAM-TEMPLATES — prompts listos para Agent Teams (solo PC)

> Agent Teams corre SOLO en la PC (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`,
> `teammateMode: in-process`). En el VPS queda apagado (`AGENT_TEAMS=0`): un
> team consume ~7× tokens y la cola no lo necesita.
> Todos los teammate types de abajo existen en `~/.claude/agents/` (roster de 18).
> Regla de oro: 3-5 teammates, 5-6 tareas por teammate, un team a la vez,
> "clean up the team" al terminar.

---

## 1. Landing / web premium (el pipeline UI completo)

```
Create an agent team to build a motion-rich landing for [BRIEF DEL NEGOCIO].
Spawn 3 teammates using existing agent types:
- ux-designer: user flows, information architecture, wireframes, estados vacíos/error
- ui-designer: sistema visual (tokens, tipografía, paleta) con skill design-system, DESIGN.md
- frontend-builder: implementación Next.js/React + motion (GSAP/Lenis vía skill motion)
Have them coordinate via shared task list and message each other directly.
ux-designer entrega wireframe ANTES de que ui-designer elija estética;
frontend-builder no escribe código hasta tener DESIGN.md aprobado.
Debate obligatorio: motor de animación y presupuesto de performance (LCP < 2.5s)
antes de la primera línea de código.
```

## 2. Code review profundo (pre-merge de un PR grande)

```
Create an agent team to review PR [N] in depth.
Spawn 3 teammates using existing agent types:
- code-reviewer: calidad, mantenibilidad, spec-compliance, boundaries del repo
- security-auditor: OWASP, RLS, PII/compliance, supply chain
- qa-engineer: cobertura de tests, e2e, a11y, evidencia ejecutada
Rules: ningún hallazgo sin evidencia code:line; los tres deben aprobar para
recomendar merge; desacuerdos se debaten por mailbox antes del veredicto.
```

## 3. Debug con hipótesis competidoras

```
Create an agent team to debug: [SÍNTOMA + contexto].
Spawn 5 teammates (general-purpose) each defending ONE hypothesis:
race condition / stale cache-estado / entorno-config / regresión reciente /
devil's advocate (ninguna de las anteriores).
Each gathers evidence from the repo and tries to REFUTE the others via mailbox.
Converge when 3+ cannot refute one hypothesis; report root cause + fix propuesto.
```

## 4. Architecture review (antes de una decisión grande)

```
Create an agent team to review this architectural decision: [DECISIÓN].
Spawn 3 teammates using existing agent types:
- architect: opciones, trade-offs, ADR draft, límites de módulos
- db-architect: impacto en esquema/migraciones/RLS (si toca datos)
- security-auditor: superficie de ataque y compliance
team-lead (yo) modera. Verdict: GO / REVISE / STOP con el ADR como entregable.
```

## 5. Full feature build (feature multi-dominio)

```
Create an agent team to build [FEATURE] end-to-end.
Spawn 5 teammates using existing agent types:
- architect (plan approval requerido antes de tocar código)
- db-architect: migraciones expand/contract + RLS + seeds
- backend-builder: API/lógica/jobs
- frontend-builder: UI (con handoff previo de ux-designer/ui-designer si hay diseño nuevo)
- qa-engineer: tests unit+e2e con datos @e2e.local
security-auditor revisa al final y puede BLOQUEAR con <<BLOCK-DEPLOY>>.
```

## 6. Respuesta a incidente de producción (v3)

```
Create an agent team to respond to this production incident: [SÍNTOMA].
Spawn 3 teammates using existing agent types:
- sre-observability: triage SEV, timeline, coordina; escribe el postmortem al cierre
- devops-engineer: ejecuta la mitigación decidida (rollback / redeploy / config)
- security-auditor: SOLO si hay indicio de explotación — lidera el forense
Rules: mitigación ANTES que causa raíz; sre-observability declara <<INCIDENT>>
y solo lo levanta con el postmortem publicado en docs/historial/.
```

## 7. Research + análisis competitivo

```
Create an agent team to research [TEMA/MERCADO].
Spawn 3 teammates (general-purpose):
- competidores directos (features, pricing, posicionamiento)
- landscape técnico (librerías, patrones, benchmarks actuales)
- comunidad (quejas reales de usuarios, gaps de mercado)
Synthesize into one report with recommendation.
```

---

## Tips

- Empieza con teams de research/review si es tu primera vez; implementación
  con teams solo cuando el patrón ya te funcione.
- `Shift+Down` navega entre teammates (in-process).
- "Require plan approval before changes" para teammates que tocan código.
- Cierra siempre: "clean up the team" (un lead solo maneja un team a la vez).

## Limitaciones

- El lead es fijo (la sesión que crea el team); cerrarla mata el team.
- Sin teams anidados; sin `/resume` con teammates in-process.
- Los campos `skills:`/`mcpServers:` del frontmatter NO aplican en modo
  teammate — las skills se cargan de la config global igual que en sesión normal.
