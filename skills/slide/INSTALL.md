# Instalación — slide v2

## Qué hay en este zip

Una reescritura completa del skill `slide` (Asombro Presentations) que ataca el problema raíz: **todos los decks de v1 salían estructuralmente idénticos** (chrome `editorial-rail`, hero diagonal clip-path, orbital ring, secuencia A→B→C→D→E, paleta navy+coral). Solo cambiaban colores.

La v2 reemplaza el `boilerplate.html` por un kit compositivo de 6 chromes, 17 layouts, 8 motion presets y una biblioteca de geometrías. **Obliga al skill a razonar** con un Direction Brief explícito y visible en chat antes de tocar HTML, y a **chequear contra uniformidad** antes de presentar. Memoria persistente en `memory.json` impide repetir paleta/fonts/chrome en decks consecutivos.

---

## Instalación del skill

```bash
# 1. Backup de la versión anterior por si querés volver
mv ~/.claude/skills/slide ~/.claude/skills/slide-v1-backup

# 2. Descomprimir el zip donde Claude Code lo lee
unzip slide.zip -d ~/.claude/skills/

# 3. Verificá que la carpeta quedó con este path exacto
ls ~/.claude/skills/slide/SKILL.md   # tiene que existir

# 4. Reiniciá Claude Code si está corriendo (solo la primera vez)
```

Después de eso, el skill se invoca igual que antes: pedile a Claude algo como *"crea una presentación sobre X"* o usá el slash command `/slide` si tu Claude Code lo expone.

---

## Instalación del subagent crítico (opcional pero recomendado)

El `slide-critic` es un subagent que actúa como third-party design critic. Lo invoca el skill después de generar el HTML para que devuelva un verdict (APPROVED / NEEDS REVISION / TEMPLATE OVERFITTING).

```bash
# Copiar el archivo del agent al directorio que Claude Code escanea
mkdir -p ~/.claude/agents
cp ~/.claude/skills/slide/agents/slide-critic.md ~/.claude/agents/

# Verificar
ls ~/.claude/agents/slide-critic.md
```

Si lo instalás, el Step 10 del workflow del skill lo invocará automáticamente. Si no lo instalás, ese paso se salta y el deck se entrega sin el verdict — la calidad sigue siendo buena gracias al refactor del skill, solo perdés la red de seguridad final.

---

## Qué cambió respecto a la v1

| Cosa | v1 | v2 |
|---|---|---|
| Archivo template | `assets/boilerplate.html` (529 líneas con chrome + hero + orbital ring baked-in) | `assets/core-runtime.html` (solo scale wrap, GSAP, dispatcher, keyboard nav — sin nada visual) |
| Chrome | Uno solo (paper-plane + dots + pin + flag) | 6 variantes en `assets/kit/chrome/`, ninguna por default |
| Layouts | 5 blueprints (A-E) + 8 recipes, con Recipe 1 como default implícito | 17 layout primitives en `assets/kit/layouts/`, sin recipe default |
| Razonamiento previo | Inexistente — saltaba directo a "fill the boilerplate" | Step 1 lee `references/critical-thinking.md` (5 preguntas), Step 3 emite Direction Brief visible |
| Memoria | Ninguna — cada deck arrancaba sin contexto de los anteriores | `memory.json` registra los últimos 10 decks y prohíbe repetir paleta/fonts/chrome/layouts |
| Chequeo antes de presentar | Ninguno | Step 8: anti-uniformity check contra `examples/paris-eiffel.html`; si 3+ matches → recomponer |
| Critic | Inexistente | Subagent opcional `slide-critic` con 3 verdicts |
| Reglas hard rules | 16 | 20 (las 4 nuevas son: no consecutive same layout, Direction Brief mandatory, anti-uniformity check, memory.json mandatory) |

Los archivos que **no** cambiaron: `references/elicitation.md`, `references/design-system.md`, `references/iconography.md`, `references/morph-animations.md`, `references/interactions.md`, y los dos ejemplos en `examples/`. Las paletas y typography pairings de v1 siguen siendo válidos — el problema nunca fue ese.

---

## Cómo verificar que la v2 funciona como debe

Después de instalar, pedile a Claude tres decks distintos en la misma sesión para probar que la memoria y la anti-uniformidad funcionan:

1. *"Crea una presentación sobre el Machu Picchu"* → primer deck, sin restricciones
2. *"Ahora una sobre la Torre Eiffel"* → debería elegir paleta, chrome, geometría **distintas** al primero
3. *"Ahora una sobre el coral reef en peligro"* → debería elegir paleta, chrome, geometría distintas a las dos anteriores

Si los tres salen con el mismo chrome o la misma paleta, algo falló — abrí `~/.claude/skills/slide/memory.json` y verificá que tiene 3 entries. Si está vacío, el skill no está actualizando la memoria.

El Direction Brief debería ser **visible en el chat** antes de cada deck. Si no aparece, el skill no está siguiendo el Step 3.

---

## Estructura completa del zip

```
slide/
├── SKILL.md                          ← workflow de 10 pasos + 20 hard rules
├── memory.json                        ← log de decks (vacío al inicio)
├── INSTALL.md                         ← este archivo
├── references/
│   ├── elicitation.md                 ← intacta de v1 (script de entrevista)
│   ├── critical-thinking.md           ← NUEVA (5 preguntas antes de componer)
│   ├── art-direction.md               ← NUEVA (8 grids, 6 stances, 6 chromes, 7 geometries, 8 motions)
│   ├── design-system.md               ← intacta de v1 (paletas + fuentes)
│   ├── morph-animations.md            ← intacta de v1 (patterns GSAP)
│   ├── slide-blueprints.md            ← REESCRITA (17 primitives, sin recipe default)
│   ├── iconography.md                 ← intacta de v1 (catálogo de iconos)
│   └── interactions.md                ← intacta de v1 (data-trigger system)
├── assets/
│   ├── core-runtime.html              ← solo scaffold no-visual
│   └── kit/
│       ├── chrome/                    ← 6 variantes (editorial-rail, minimal-rail, archival, peripheral-data, invisible, instrumental)
│       ├── layouts/                   ← 17 primitives
│       ├── accent-geometries.svg      ← biblioteca de symbols SVG
│       └── motion-presets.js          ← 8 motion signatures
├── examples/
│   ├── paris-eiffel.html              ← referencia de UN estilo (NO copiar)
│   └── database-fundamentals.html     ← referencia de UN estilo interactivo (NO copiar)
└── agents/
    └── slide-critic.md                ← subagent opcional (copiar a ~/.claude/agents/)
```

---

## Si algo sale mal

- **El skill sigue produciendo decks idénticos**: chequeá que `memory.json` se está actualizando. Abrílo después de generar 2-3 decks — debería tener entries.
- **El Direction Brief no aparece en chat**: el skill no está leyendo el SKILL.md actualizado. Reiniciá Claude Code.
- **El skill se queja de no encontrar archivos del kit**: verificá que la estructura de carpetas quedó como `~/.claude/skills/slide/assets/kit/chrome/...` (no `~/.claude/skills/slide-v2/...` ni con un nivel extra).
- **Querés volver a la v1**: `rm -rf ~/.claude/skills/slide && mv ~/.claude/skills/slide-v1-backup ~/.claude/skills/slide`.

---

## Iteración futura

Si después de usar la v2 querés escalar más todavía:

1. Mirá el `memory.json` después de 10-15 decks. Si ves que el skill sigue gravitando a 2-3 combinaciones, ampliá los catálogos en `art-direction.md` (más palettes, más motion presets).
2. Si querés que el critic sea más estricto, editá `agents/slide-critic.md` y agregá checkpoints específicos en Check 4 (composition principles).
3. Si querés A/B testear con un humano, generá dos versions del mismo brief con diferentes critic verdicts y comparalos.

Pero antes de cualquiera de eso, dale 5-10 decks de uso real. Casi todo lo que parece "falta una mejora" en abstracto se resuelve solo con el refactor que ya está acá.
