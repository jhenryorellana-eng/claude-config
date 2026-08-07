# Estado de instalaciones — actualizado 2026-08-07

> Reescrito en la reorganización del 7-ago. La versión anterior estaba
> desactualizada (describía claude-mem como instalado y conteos viejos).

## Instalado y operativo

| Pieza | Estado |
|---|---|
| **Roster de 13 agentes** | `agents/` (team-lead, architect, ux-designer, ui-designer, frontend-builder, backend-builder, db-architect, llm-engineer, qa-engineer, code-reviewer, security-auditor, devops-engineer, docs-writer) |
| **Skills** | ~32 tras la poda del 7-ago (de 61; ver CLAUDE.md §Skills). `slide` + `web-prompt-architect` + `slide-critic` → movidos a `Documents\chamba\.claude\` (toolkit personal local) |
| **Plugins** | 19 (17 oficiales + codex + kimi) — sin cambios |
| **Graphify** | `graphifyy[sql]` 0.9.35 vía uv en PC y VPS; grafo local por máquina (`graphify . --code-only`); hook-guard SOLO en PC (settings.local.json del repo x-legal) |
| **Hooks** | `hooks/block-dangerous.sh` (Bash) + `hooks/mcp-supabase-guard.sh` (mcp__supabase__.*) — activos en PC (vía Git Bash) y VPS |
| **Sync** | PC: `sync-config.ps1` (diff/apply/capture, robocopy). VPS: cron 15 min (`sync-config.sh`) |
| **MCPs del repo x-legal** | `.mcp.json` versionado (PR #18): supabase(dev) + playwright + context7 |

## Retirado deliberadamente

- `claude-mem` — desinstalado (ya lo estaba; la doc vieja mentía).
- gbrain (`setup-gbrain`/`sync-gbrain`) — retirado; la memoria es de 4 capas
  (ver CLAUDE.md §Memoria).
- 29 skills redundantes (5 iOS, duplicados de browser, plan-reviews, diseño
  redundante, deploy-automático) — lista completa en la bitácora
  `Documents\vps\docs\registro\2026-08-07-claude.md`.
- Agentes viejos: `orchestrator` (→ team-lead), `ui-master`/`ui-builder`/
  `disruptive-landing-builder` (→ pipeline ux/ui/frontend), `slide-critic` (→ chamba).
- `skills/gstack/` vendored — eliminado en la poda (recuperable con
  `/gstack-upgrade` si alguna skill gstack lo extraña).

## Pendiente (dueño: Henry — ver `Documents\vps\05-PASOS-FINALES-HUMANO.md`)

- Seguridad FASE 0.5 (rotaciones + re-login) · bot de Telegram · merge de PRs
  #12/#13/#14/#15/#16/#18/#19/#20/#21 · encendido de `queue@x-legal`.
