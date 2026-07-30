# Team Templates — copy/paste prompts para Agent Teams

> Estos prompts están listos para usar. Solo reemplaza `[BRIEF]`, `[PR#]`, `[BUG]` con tu input específico y pega en una nueva sesión de Claude Code.

---

## 🎨 Landing motion-rich completa (3 dimensiones, lo más común)

```
Create an agent team with 3 teammates to build a landing page for [BRIEF]:
- One using ui-master agent type — focus on UX, industry-appropriate palette, accessibility, anti-patterns
- One using motionsites-architect agent type — creative direction + free asset curation from Pexels/Coverr/Unsplash
- One using disruptive-landing-builder agent type — scroll engineering with GSAP+Lenis patterns from MEMORY.md

Have them:
1. Debate the animation engine (Framer Motion vs GSAP vanilla) BEFORE deciding — share rationale via SendMessage
2. Challenge each other's palette decisions (ui-master has veto on industry conventions)
3. Agree on a spec.md before any code is written
4. Whoever owns the chosen engine (motionsites for FM, disruptive for GSAP) leads the build phase
5. End with synthesis: deliverables list, decisions log, screenshots
```

---

## 🔒 Code review profundo (3 reviewers, paralelo independiente)

```
Create an agent team with 3 reviewers for PR #[PR#]:
- One using security-auditor agent type — OWASP Top 10 + CVE check + supply chain
- One using qa-engineer agent type — performance + accessibility + test coverage
- One using code-reviewer agent type — idiom + maintainability + obvious bugs

Have them:
1. Review the diff independently in parallel
2. Challenge each other's findings via SendMessage when severity disputed
3. Reject findings without code:line evidence
4. Approve only with consensus from all 3
5. Output a unified review.md with sections: Critical (block deploy), Strong, Suggested, Praise
```

---

## 🐛 Debug con hipótesis competidoras (5 detectives, debate científico)

```
Users report: "[BUG]"

Create an agent team with 5 teammates to investigate different root cause hypotheses:
- One thinks it's a race condition
- One thinks it's a stale cache / state issue
- One thinks it's an environment-specific bug (browser/OS/version)
- One thinks it's a regression from a recent change (git bisect mindset)
- One playing devil's advocate (challenge all theories, propose unconventional)

Have them:
1. Investigate their own theory in parallel
2. Talk to each other via SendMessage to try to disprove other theories
3. Update findings.md with evidence collected (NOT speculation)
4. Converge on consensus theory only when 3+ teammates can't disprove it
5. Lead synthesizes findings + proposes fix
```

---

## 🏗️ Architecture review (3 perspectivas críticas)

```
Create an agent team to evaluate the proposed architecture in plan.md (or design.md):
- One playing devil's advocate — challenge every assumption, find weak points
- One playing CEO — "what's the 10-star version?", scope expansion mindset
- One playing senior engineer — find production risks, edge cases, ops concerns

Require plan approval — they MUST converge on a verdict before implementation can start.

Have them:
1. Read the plan independently first
2. Each one writes their critique (3 separate critiques)
3. Cross-message with SendMessage to debate top concerns
4. Vote: GO (proceed), REVISE (needs changes), STOP (architecturally flawed)
5. If REVISE/STOP, output specific fixes required
```

---

## 🚀 Full feature build (5 specialists, complex multi-domain)

```
Create an agent team with 5 teammates to build feature: [BRIEF]:
- One using backend-builder agent type — APIs, DB schema, business logic
- One using ui-master agent type — UI components, design system, a11y
- One using qa-engineer agent type — tests (unit + integration + E2E)
- One using security-auditor agent type — review auth/PII/inputs
- One using devops-engineer agent type — CI/CD, deploy config

Have them:
1. Coordinate via shared task list — assign tasks based on owned files (no conflicts)
2. Communicate via SendMessage when contracts change (API shape, DB column rename)
3. Backend completes endpoint → notifies UI via SendMessage
4. Security review can BLOCK others via flag <<BLOCK-DEPLOY>>
5. devops requires sec ✅ + qa ✅ before producing deploy config
6. Final synthesis: spec.md + deliverables + tests passing + security audit ✅
```

---

## 📊 Research + competitive analysis (3 researchers)

```
I'm evaluating [TOPIC / PRODUCT / TECHNOLOGY]. Create an agent team with 3 researchers:
- One investigates competitors / alternatives (top 5, pricing, feature comparison)
- One investigates technical landscape (libraries, frameworks, gotchas)
- One investigates community / adoption (GitHub stars, recent activity, opinions)

Have them:
1. WebSearch + WebFetch independently
2. Share findings via SendMessage when they discover something relevant to others
3. Challenge each other's sources (peer review)
4. Output a research.md with 3 sections + executive summary
```

---

## Tips para usar Agent Teams efectivamente

- **3-5 teammates es óptimo**. Menos = pierdes paralelismo. Más = coordinación se vuelve caótica.
- **5-6 tareas por teammate es óptimo**. Menos = overhead. Más = checkpoints raros.
- **Shift+Down** para navegar entre teammates en in-process mode (Windows)
- **"clean up the team"** antes de cerrar la sesión para liberar recursos
- **Empieza con research/review** si es tu primera vez con Agent Teams — no implementación
- **Plan approval** es tu amigo para teammates riesgosos: agregar al prompt "Require plan approval before any changes"
- **Si un teammate se queda atascado**, mensaje directo: "Hey [name], status?" o "Try [alternative approach]"
- **Tokens consumidos son significativamente más altos** que single session — usa Agent Teams cuando justifica el costo

## Limitaciones a recordar

- **Lead es fijo** — la sesión donde creas el team es lead para siempre
- **No nested teams** — teammates no pueden crear sub-teams
- **One team at a time** — limpia antes de crear otro
- **No `/resume` con in-process teammates** — si resumes sesión, respawn manual
- **In-process mode en Windows** — funciona en cualquier terminal (no necesitas tmux/iTerm2)
