#!/usr/bin/env bash
# mcp-supabase-guard.sh — PreToolUse hook, matcher: mcp__supabase__.*
# Segunda capa de defensa para la superficie MCP (FASE 7.4 del plan del VPS):
# el --project-ref ata el servidor a dev, pero este hook bloquea ademas los
# patrones de dano irreversible sin importar a que proyecto apunte el server.
#
# Serializa tool_input COMPLETO con jq (no adivina si el campo se llama query,
# sql o migration_sql). exit 2 = bloquear; exit 0 = permitir.
# Regla de patrones: describir EL DANO, no una palabra suelta (un patron
# amplio como 'prod' romperia operaciones legitimas).

set -u
payload="$(cat)"

# Con jq, inspeccionamos tool_input serializado; sin jq (p. ej. Git Bash en
# Windows), caemos al payload CRUDO — mas vale un patron evaluado sobre el JSON
# entero que un guard que no guarda nada.
if command -v jq >/dev/null 2>&1; then
  input="$(printf '%s' "$payload" | jq -r '.tool_input | tostring' 2>/dev/null)" || input="$payload"
else
  input="$payload"
fi
[ -n "$input" ] || exit 0

deny() {
  echo "mcp-supabase-guard: BLOQUEADO — $1" >&2
  echo "Si esto es legitimo y deliberado, hazlo desde el CLI de supabase (acto humano), no via MCP." >&2
  exit 2
}

# Destruccion estructural masiva
printf '%s' "$input" | grep -qiE 'drop[[:space:]]+(database|schema)' \
  && deny "DROP DATABASE/SCHEMA"
printf '%s' "$input" | grep -qiE 'truncate[[:space:]]+table' \
  && deny "TRUNCATE TABLE"

# Borrado sin WHERE (la clase entera de 'DELETE FROM tabla;')
printf '%s' "$input" | grep -qiE 'delete[[:space:]]+from[[:space:]]+[a-z_."]+[[:space:]]*(;|$)' \
  && deny "DELETE FROM sin WHERE"

# Sabotaje de identidad/seguridad
printf '%s' "$input" | grep -qiE 'delete[[:space:]]+from[[:space:]]+auth\.users' \
  && deny "DELETE sobre auth.users"
printf '%s' "$input" | grep -qiE 'alter[[:space:]]+table[[:space:]]+[^;]*disable[[:space:]]+row[[:space:]]+level[[:space:]]+security' \
  && deny "DISABLE ROW LEVEL SECURITY"
printf '%s' "$input" | grep -qiE 'drop[[:space:]]+policy' \
  && deny "DROP POLICY (las policies se cambian por migracion revisada)"

exit 0
