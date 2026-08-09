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
cwd=""
if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)"
  cwd="$(printf '%s' "$input" | jq -r '.cwd // ""' 2>/dev/null)"
  # jq presente pero extracción vacía → payload sin comando: permitir.
  [ -z "$cmd" ] && exit 0
else
  # Sin jq (p. ej. Git Bash pelado): evaluar el payload CRUDO. Preferimos un
  # falso positivo raro a un guard que no guarda nada.
  cmd="$input"
fi

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

  # Git destructivo. El force se prohíbe SIEMPRE y en cualquier repo.
  # Lo relativo a `main` NO va aquí: depende del repo (ver check_git_push).
  'git[[:space:]]+push[[:space:]].*(--force|--force-with-lease)'
  'git[[:space:]]+reset[[:space:]]+--hard[[:space:]]+origin'
  'git[[:space:]]+clean[[:space:]]+-[a-z]*f[a-z]*d'
  # flags separadas ('git clean -f -d' / '-d -f') — hueco detectado el 4-ago
  'git[[:space:]]+clean([[:space:]]+-[a-zA-Z]+)*[[:space:]]+-[a-zA-Z]*f'

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

# ---------------------------------------------------------------------------
#  check_git_push — analiza `git push` por TOKENS, no por regex.
#
#  Un regex que describa "empujar a main" tiene que prever cada forma de
#  escribirlo (-u, --set-upstream, HEAD:main, main:main, refs/heads/main) y
#  siempre queda una fuera: así se coló el hueco que se encontró el 2026-08-09.
#  Mirando los tokens la regla se vuelve enunciable en una frase:
#
#    un push legítimo nombra su remoto Y su rama, y esa rama no es main.
#
#  Todo lo demás se bloquea, incluido `git push` a secas: adónde va depende
#  del upstream configurado, así que no se puede auditar leyendo el comando.
# ---------------------------------------------------------------------------
check_git_push() {
  local c="$1" seg resto tok rama destino
  local -a posicionales=()

  printf '%s' "$c" | grep -qE 'git[[:space:]]+push' || return 0

  # Aislar desde 'git push' hasta el siguiente separador de comandos.
  seg="$(printf '%s' "$c" | sed -E 's/.*git[[:space:]]+push//' | sed -E 's/[;&|].*//')"

  for tok in $seg; do
    case "$tok" in
      -*) # Flags: solo nos interesan las que fuerzan.
          case "$tok" in
            --force|--force-with-lease|--force-with-lease=*|-f|-*f)
              echo "BLOQUEADO por hook de seguridad: 'git push' con force ($tok)." >&2
              exit 2 ;;
          esac ;;
      [0-9]*'>'*|'>'*) break ;;   # redirecciones: fin de los argumentos
      *)  posicionales+=("$tok") ;;
    esac
  done

  # Repos de configuración: `main` ES su rama de trabajo y empujar ahí es el
  # flujo normal (así viaja la config al VPS). No despliegan nada a clientes,
  # así que la regla de main no aplica — el bloqueo de force, que va ARRIBA de
  # esta salida, sí sigue aplicando en todas partes.
  # Cuenta tanto el cwd de la sesión como un `cd` explícito dentro del propio
  # comando: se sincroniza la config desde sesiones abiertas en otro directorio.
  case "$cwd" in
    *claude-config*|*orchestrator*) return 0 ;;
  esac
  if printf '%s' "$c" | grep -qE 'cd[[:space:]]+[^;&|]*(claude-config|orchestrator)'; then
    return 0
  fi

  # Red de respaldo por regex, para cuando no hay jq y la tokenización opera
  # sobre el payload crudo en vez de sobre el comando.
  if printf '%s' "$c" | grep -qEi 'git[[:space:]]+push[[:space:]].*refs/heads/(main|master)'; then
    echo "BLOQUEADO por hook de seguridad: push a refs/heads/main." >&2
    exit 2
  fi

  # Sin remoto + rama explícitos el destino no es auditable.
  if [ "${#posicionales[@]}" -lt 2 ]; then
    echo "BLOQUEADO por hook de seguridad: 'git push' sin remoto y rama explícitos." \
         "Escribe 'git push origin <rama>' — el contrato exige rama de feature." >&2
    exit 2
  fi

  # El refspec es el último posicional; su destino es lo que va tras ':'.
  rama="${posicionales[${#posicionales[@]}-1]}"
  destino="${rama##*:}"
  destino="${destino##refs/heads/}"
  case "$destino" in
    main|master)
      echo "BLOQUEADO por hook de seguridad: push a '$destino' (refspec '$rama')." \
           "El deploy sale de main y afecta a clientes reales; el merge es humano." >&2
      exit 2 ;;
  esac

  return 0
}

check_git_push "$cmd"

exit 0
