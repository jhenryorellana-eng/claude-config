#!/usr/bin/env bash
# ============================================================================
#  block-dangerous.sh — hook PreToolUse (matcher: Bash)
#  Segunda capa de defensa, para patrones que las reglas estáticas de
#  permisos no atrapan. exit 2 = bloquear la llamada.
#
#  Vive en:  ~/claude-config/hooks/block-dangerous.sh
#  Se edita SIEMPRE en la PC y se sincroniza al VPS con git.
# ============================================================================
input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)"
[ -z "$cmd" ] && exit 0

# ---------------------------------------------------------------------------
#  IMPORTANTE: cada patrón es un regex ERE evaluado con grep -Ei.
#  NO uses patrones amplios como 'prod|production': bloquearían
#  'npm ci --production', 'cd ~/repos/henry/mi-producto' y medio flujo normal.
#  Los patrones deben describir el DAÑO, no una palabra suelta.
# ---------------------------------------------------------------------------
patrones=(
  # Borrado masivo desde raíz o home
  'rm[[:space:]]+(-[a-zA-Z]*[rf][a-zA-Z]*[[:space:]]+)+(/|~|\$HOME)[[:space:]]*$'
  'rm[[:space:]]+-rf[[:space:]]+/([[:space:]]|$)'
  'rm[[:space:]]+-rf[[:space:]]+(~|\$HOME)(/(\.ssh|\.claude|claude-config|repos|orchestrator))?[[:space:]]*$'

  # Destrucción de datos
  'DROP[[:space:]]+(DATABASE|SCHEMA)'
  'TRUNCATE[[:space:]]+TABLE'
  'DELETE[[:space:]]+FROM[[:space:]]+[a-zA-Z_]+[[:space:]]*;'   # DELETE sin WHERE

  # Fuga o destrucción de credenciales
  'cat[[:space:]]+[^|]*\.env'
  '\.env[[:space:]]*>'
  '(curl|wget)[[:space:]].*(\.env|credentials|id_ed25519|id_rsa|hosts\.yml)'
  '(id_ed25519|id_rsa|\.credentials\.json|hosts\.yml)[[:space:]]*[|>]'

  # Sabotaje del propio orquestador o del historial
  'history[[:space:]]+-c'
  'crontab[[:space:]]+-r'
  'chmod[[:space:]]+777'
  'systemctl[[:space:]]+--user[[:space:]]+(disable|mask)'
  'loginctl[[:space:]]+disable-linger'

  # Git destructivo (refuerza las reglas deny)
  'git[[:space:]]+push[[:space:]].*--force'
  'git[[:space:]]+push[[:space:]]+[^[:space:]]+[[:space:]]+(main|master)([[:space:]]|$)'
  'git[[:space:]]+reset[[:space:]]+--hard[[:space:]]+origin'
  'git[[:space:]]+clean[[:space:]]+-[a-z]*f[a-z]*d'

  # Producción — AJUSTA ESTO a tus hostnames/dominios reales y descomenta
  # 'ssh[[:space:]]+[^[:space:]]*@(api|www)\.tudominio\.com'
  # 'vercel[[:space:]]+.*--prod'
  # 'wrangler[[:space:]]+deploy'
)

for p in "${patrones[@]}"; do
  if printf '%s' "$cmd" | grep -qEi "$p"; then
    echo "BLOQUEADO por hook de seguridad: el comando coincide con /$p/" >&2
    exit 2
  fi
done

exit 0
