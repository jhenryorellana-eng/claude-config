---
name: retro
description: >
  Retrospectiva de ingeniería semanal: analiza historial de commits y PRs de la
  ventana con jerarquía de métricas anti-inflación (features shipped primero;
  raw LOC degradado a contexto porque la IA lo infla). Desglose por persona con
  praise y áreas de mejora. Usa cuando se pida "retro", "retro semanal", "qué
  shipeamos esta semana", "retrospectiva de ingeniería". NO analiza incidentes
  (postmortem) ni audita planes (plan-audit).
---

# Retro — retrospectiva semanal de ingeniería

Mira una ventana de tiempo (por defecto 7 días) sobre la rama principal y cuenta
la historia de lo que se shipeó: qué recibió el usuario, quién contribuyó qué, y
qué patrón conviene corregir la semana que viene.

La retro se guarda como una entrada en `docs/historial/` del repo. Sin PII de
clientes reales: usa `U26-XXXXXX` o `[CLIENTE-XX]`.

## Argumentos

- `/retro` — ventana por defecto: 7 días.
- `/retro 14` o `/retro --since="2 weeks ago"` — ventana explícita.
- `/retro --no-save` — solo imprime, no escribe en `docs/historial/`.

En lo que sigue, `<default>` es la rama principal del repo (`main` salvo que el
repo diga otra cosa) y `<window>` es la ventana en el formato que entiende
`git log --since`.

---

## Paso 0 — Pre-check de ventana rancia (BLOQUEANTE)

Una retro que analiza una copia local desactualizada reporta "una semana sin
actividad" cuando en realidad el equipo shipeó todos los días. Antes de contar
nada, verifica que la base esté fresca.

```bash
_RETRO_GUARD_VERDICT=""

# A: ¿hay remote 'origin'?
git remote get-url origin >/dev/null 2>&1 || {
  echo "RETRO_GUARD: sin remote 'origin', frescura no verificada — se procede"
  _RETRO_GUARD_VERDICT="skip-no-remote"
}

# B: ¿HEAD desprendido?
if [ -z "$_RETRO_GUARD_VERDICT" ] && [ -z "$(git symbolic-ref --quiet HEAD 2>/dev/null)" ]; then
  echo "RETRO_GUARD: HEAD desprendido, frescura no verificada — se procede"
  _RETRO_GUARD_VERDICT="skip-detached"
fi

# C: fetch; si falla, avisa pero sigue
if [ -z "$_RETRO_GUARD_VERDICT" ] && ! git fetch origin <default> --quiet 2>/dev/null; then
  echo "RETRO_GUARD: 'git fetch origin <default>' falló (¿sin red?) — se procede contra el último origin/<default> conocido"
  _RETRO_GUARD_VERDICT="warn-fetch-failed"
fi

# D: fecha del commit más reciente de la base
if [ -z "$_RETRO_GUARD_VERDICT" ]; then
  echo "RETRO_GUARD: último commit de origin/<default> el $(git log -1 --format=%ci origin/<default> 2>/dev/null | awk '{print $1}')"
fi
```

**Cómo evaluar la salida.** Calcula "hoy" desde el tag `## currentDate` del
recordatorio de sesión, **nunca** desde `date` del sistema (el reloj de un
contenedor puede estar horas o días corrido).

- Si la fecha del último commit es **anterior a (hoy − días de la ventana)**,
  BLOQUEA con este mensaje y detén la skill: "La ventana de la retro está
  rancia. El último commit de `origin/<default>` es del `<FECHA>`, pero la
  ventana cubre de `<desde>` a `<hoy>`. Suele significar (a) que la fecha de hoy
  está mal en esta sesión o (b) que `origin/<default>` está materialmente atrás.
  Confirma la fecha en el recordatorio de sesión; si es correcta, corre
  `git fetch origin <default>` a mano y vuelve a lanzar /retro."
- Si no puedes calcular "hoy" con confianza, detente y pregúntale al usuario con
  AskUserQuestion. No adivines.
- En caso contrario escribe: "RETRO_GUARD: último commit `<FECHA>` dentro de la
  ventana — se procede."

Las tres rutas de escape (`skip-no-remote`, `skip-detached`, `warn-fetch-failed`)
continúan al Paso 1, pero la razón se arrastra hasta la narrativa final ("corrida
sin red, ventana no verificada") en vez de reportar mal en silencio.

---

## Paso 1 — Recolección de datos

Identifica primero quién corre la retro:

```bash
git config user.name
git config user.email
```

El nombre que devuelve `git config user.name` es **"vos"** — la persona que lee
esta retro. Todos los demás autores son compañeros de equipo. Eso orienta la
narrativa: tus commits contra las contribuciones del resto.

Corre estos comandos en paralelo (son independientes):

```bash
# 1. Commits de la ventana con autor y shortstat
git log origin/<default> --since="<window>" --format="%H|%aN|%ae|%ai|%s" --shortstat

# 2. Desglose test vs total por commit (bloques COMMIT:<hash>|<autor> + numstat)
#    Separa archivos de test (test/|spec/|__tests__/) de los de producción.
git log origin/<default> --since="<window>" --format="COMMIT:%H|%aN" --numstat

# 3. Timestamps para detectar sesiones de trabajo y distribución horaria
git log origin/<default> --since="<window>" --format="%at|%aN|%ai|%s" | sort -n

# 4. Archivos más tocados (hotspots)
git log origin/<default> --since="<window>" --format="" --name-only | grep -v '^$' | sort | uniq -c | sort -rn

# 5. Números de PR desde los mensajes de commit
git log origin/<default> --since="<window>" --format="%s" | grep -oE '[#!][0-9]+' | sort -u

# 6. Hotspots por autor (quién toca qué)
git log origin/<default> --since="<window>" --format="AUTHOR:%aN" --name-only

# 7. Commits por autor (resumen rápido)
git shortlog origin/<default> --since="<window>" -sn --no-merges

# 8. Archivos de test tocados en la ventana
git log origin/<default> --since="<window>" --format="" --name-only | grep -E '\.(test|spec)\.' | sort -u | wc -l
```

Si el repo tiene `gh` configurado, complementa con los PRs mergeados en la
ventana: `gh pr list --state merged --limit 50 --json number,title,mergedAt,author`.
Los títulos de PR son la mejor fuente de "features shipped".

---

## Paso 2 — Métricas, en este orden

| Métrica | Valor |
|---|---|
| **Features shipped** (de CHANGELOG + títulos de PR mergeados) | N |
| Commits a la rama principal | N |
| Commits ponderados (commits × archivos tocados, tope 20 por commit) | N |
| Contribuidores | N |
| PRs mergeados | N |
| **SLOC lógico agregado** (sin blancos ni comentarios — métrica primaria de volumen) | N |
| Raw LOC: inserciones | N |
| Raw LOC: borrados | N |
| Raw LOC: neto | N |
| Test LOC (inserciones) | N |
| Ratio de test LOC | N% |
| Días activos | N |
| Sesiones detectadas | N |
| Salud de tests | N tests totales · M agregados · K de regresión |

**Por qué este orden (no lo cambies):**

> features shipped leads — what users got. Commits and weighted commits reflect
> intent-to-ship. Logical SLOC added reflects real new functionality. Raw LOC is
> demoted to context because AI inflates it; ten lines of a good fix is not less
> shipping than ten thousand lines of scaffold.

Esa jerarquía es lo que impide que la retro premie el volumen. Con agentes
escribiendo código, el raw LOC dejó de correlacionar con valor entregado: un
scaffold generado infla las inserciones sin mover una sola cosa que el usuario
pueda usar. Si vas a citar una sola métrica en el resumen, cita features shipped.

**Detección de sesiones:** agrupa commits separados por menos de 2 horas. Cada
grupo es una sesión de trabajo. Sirve para leer el ritmo (muchas sesiones cortas
vs pocas largas), no para medir productividad.

---

## Paso 3 — Desglose por persona

Debajo de la tabla de métricas va el leaderboard:

```
Contribuidor        Commits   +/-          Área principal
Vos (mauri)              32   +2400/-300   src/modules/cases/
asistente-vps            12   +800/-150    supabase/migrations/
```

Ordena por commits descendente. La persona que corre la retro (según
`git config user.name`) va siempre primera, etiquetada "Vos (nombre)".

Después, para **cada** contribuidor, escribe dos párrafos cortos:

**Praise — qué hizo bien, con evidencia.** Nombra el commit o el PR concreto y
por qué importó. "Mergeó el PR #47" no es praise; "cerró la fuga de N+1 en el
listado de casos (PR #47), que era la queja de performance más vieja del
backlog" sí lo es. Si alguien tuvo una semana floja, no inventes elogios: di que
la semana fue de mantenimiento.

**Área de mejora — un patrón, no un incidente.** Un commit revertido no es un
patrón; tres reverts en la misma área sí. Ejemplos de patrones que valen la pena
nombrar: commits gigantes que nadie puede revisar, features sin tests, PRs que
esperan días por review, la misma zona del código tocada una y otra vez sin
refactor. Formúlalo como algo accionable la semana entrante.

**Regla de tono:** la retro es sobre el trabajo, no sobre las personas. "Este PR
llegó sin tests" está bien; "sos descuidado con los tests" no.

---

## Paso 4 — Narrativa y patrones

Cierra con prosa, no con más tablas:

1. **Qué recibió el usuario esta semana.** Dos o tres frases en el lenguaje del
   producto, no del código.
2. **Hotspots.** Los archivos más tocados. Un archivo que aparece en la mitad de
   los commits o es el corazón del sistema o pide un refactor: decide cuál.
3. **Deuda que creció.** TODOs agregados, tests saltados, migraciones pendientes.
4. **Una cosa a cambiar la semana que viene.** Una sola, concreta, con dueño.

---

## Paso 5 — Guardar

Salvo que se haya pasado `--no-save`, escribe la retro en `docs/historial/` del
repo siguiendo la plantilla de historial del proyecto, con nombre
`retro-YYYY-MM-DD.md` (la fecha del cierre de la ventana). Si el repo no tiene
`docs/historial/`, dilo e imprime la retro sin guardar en vez de crear la
estructura por tu cuenta.

Antes de guardar, relee buscando PII: nombres de clientes reales, correos que no
sean `@e2e.local`, números de expediente. Reemplázalos por `U26-XXXXXX` o
`[CLIENTE-XX]`.

## Reglas importantes

- **Nunca reportes una ventana que no verificaste.** El Paso 0 es bloqueante por
  una razón: una retro con datos rancios es peor que no tener retro.
- **Features primero, LOC al final.** Si el resumen abre con líneas de código, lo
  escribiste al revés.
- **Evidencia por afirmación.** Todo praise y toda área de mejora cita un commit,
  un PR o un archivo.
- **Sin ranking de personas.** El leaderboard ordena por commits porque hay que
  ordenar por algo, no porque más commits sea mejor.
- **Esta skill no analiza incidentes** (eso es `postmortem`) **ni audita el
  cumplimiento de un plan** (eso es `plan-audit`).
