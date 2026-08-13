---
name: write-plan
description: >
  Convierte un brief o spec en un plan de implementación ejecutable: pasos
  numerados con archivos concretos, tests por ítem, dependencias y orden. Cada
  ítem se etiqueta [DIFF] (verificable en el diff), [EXTERNAL] (estado en
  Supabase/Vercel/DNS) o [CROSS-REPO], para que plan-audit pueda auditarlo al
  cerrar. Usa cuando el usuario diga "escribe el plan", "plan de
  implementación", "convierte esta spec en plan", o cuando un agente reciba un
  brief aprobado de brainstorm. NO explora requisitos (brainstorm) ni audita
  planes ya ejecutados (plan-audit).
---

# Write-plan — del brief al plan ejecutable

## Principio

Escribe el plan para alguien competente que **no conoce este repo**: no sabe
dónde vive cada cosa, no conoce las convenciones y va a leer los pasos fuera de
orden. Todo lo que no esté escrito, no existe.

Un plan sirve para dos cosas: que otro lo ejecute sin preguntar, y que al
cerrar se pueda auditar si se cumplió. El etiquetado de la sección siguiente es
lo que hace posible la segunda.

## Antes de escribir

1. **Lee la fuente.** El brief de `brainstorm`, la spec, o el pedido del
   usuario. Si no hay criterios de aceptación verificables, no hay plan que
   escribir: vuelve a `brainstorm`.
2. **Mira el repo.** Rutas reales, patrones existentes, cómo se corren los
   tests aquí. Un plan con rutas inventadas se cae en el primer paso.
3. **Chequeo de alcance.** Si la fuente cubre subsistemas independientes,
   propón partirla: un plan por subsistema, cada uno con software funcionando
   al terminar.

## Estructura del plan

```markdown
# Plan — [nombre del trabajo]

**Objetivo:** [una frase: qué existe al terminar que no existía antes]
**Fuente:** [ruta del brief o spec del que sale este plan]
**Stack tocado:** [lenguajes, frameworks, servicios relevantes]

## Restricciones globales
[Requisitos que aplican a TODOS los pasos: versiones mínimas, convenciones de
naming, "sin PII real", "migraciones expand/contract", límites de dependencias.
Una línea cada uno, con el valor exacto. No los repitas paso por paso.]

## Mapa de archivos
[Qué archivo se crea o se modifica y de qué es responsable cada uno. Aquí se
fijan los límites de módulo, antes de partir en pasos.]

## Pasos

### Paso N — [nombre] · [DIFF|EXTERNAL|CROSS-REPO]
**Archivos:**
- Crear: `ruta/exacta/archivo.ts`
- Modificar: `ruta/exacta/existente.ts:120-145`
- Test: `ruta/exacta/archivo.test.ts`

**Depende de:** [Paso M, o "nada"]

**Qué hacer:** [instrucciones concretas; si hay código, va el código, no una
descripción del código]

**Test:** [el test que prueba este paso, con el comando exacto para correrlo]

**Criterio de cierre (binario):** [una afirmación que es verdadera o falsa sin
interpretación — "GET /api/x devuelve 401 sin sesión", no "la auth funciona"]
```

**Máximo 50 pasos.** Si necesitas más, el trabajo estaba mal partido: vuelve al
mapa de archivos y agrupa. Cada paso es la unidad más chica que carga su propio
ciclo de test y que un revisor podría rechazar sin rechazar a sus vecinos —
setup, configuración y docs se pliegan dentro del paso que los necesita.

## Etiquetado: cómo se va a verificar cada paso

`git diff` no puede probar todo tipo de trabajo. Etiqueta cada paso **en el
momento de escribirlo**, cuando todavía sabes dónde vive el cambio; después,
reconstruirlo es adivinar.

| Etiqueta | Significa | Cómo se prueba al cerrar |
|---|---|---|
| `[DIFF]` | El cambio aparece en `git diff <base>...HEAD` de este repo | Se cruza contra el diff: el archivo o la lógica está o no está |
| `[EXTERNAL]` | El estado vive fuera del repo: policies o config de Supabase, env vars de Vercel, registros DNS, allowlists de OAuth, dashboards de terceros | El diff NO puede probarlo. El paso debe decir **qué comando o pantalla lo confirma** |
| `[CROSS-REPO]` | El archivo vive en otro repo de la máquina | Se prueba con la existencia del archivo en la ruta concreta |

Reglas de etiquetado:

- Un paso `[EXTERNAL]` sin su comprobación explícita escrita es un paso
  inauditable. Escribe la verificación junto al paso: `supabase db diff`,
  `vercel env ls`, `dig +short dominio`, la consulta SQL que muestra la policy.
- Un paso `[CROSS-REPO]` debe nombrar la **ruta absoluta** del archivo en el
  otro repo. Sin ruta concreta no hay forma de comprobarlo.
- Si un paso mezcla código y estado externo, pártelo en dos. Etiquetas mixtas
  producen auditorías mentirosas: el código shippea, el estado no, y el ítem se
  marca hecho.
- Migraciones: el archivo de migración es `[DIFF]`; que esté **aplicada en la
  base** es `[EXTERNAL]`. Son dos pasos distintos.

## Tests por ítem

Cada paso que toca comportamiento lleva su test, y el test se escribe **antes**
que el código (ver la skill `tdd`). En el plan eso se traduce en:

- El test va en el mismo paso que el código, no en un paso "escribir los tests"
  al final. Un paso de tests agrupado al cierre nunca se ejecuta.
- Escribe la aserción concreta, no "testear el caso feliz y los bordes".
- Nombra el comando exacto del proyecto (`npm run test -- ruta/al/test`), no
  "correr los tests".

Pasos que legítimamente no llevan test: mover archivos, docs, configuración sin
lógica. Márcalos como `sin test — [motivo]` para que el vacío sea deliberado.

## Nada de placeholders

Son fallas del plan, no del que lo ejecuta. Nunca escribas:

- "TBD", "TODO: definir", "completar detalles"
- "agregar manejo de errores apropiado", "cubrir los edge cases"
- "escribir los tests correspondientes" sin decir cuáles
- "igual que el Paso N" — repite el contenido; se leerá fuera de orden
- referencias a funciones o tipos que ningún paso define

## Despacho paralelo

Cuando el plan queda escrito, mira las dependencias:

- **Dos o más pasos sin estado compartido y sin archivos solapados** → despacha
  un agente por paso, en paralelo, en un solo mensaje con varias llamadas.
- **Si comparten archivo, esquema de base, o uno consume lo que el otro
  produce** → secuencial. El paralelismo sobre estado compartido no ahorra
  tiempo: produce conflictos que cuestan más que la serie.
- Cada agente paralelo recibe su paso completo (archivos, test, criterio de
  cierre) y devuelve evidencia ejecutada. Ninguno mergea nada por su cuenta.

Cuando hay dudas sobre si dos pasos se pisan, van en serie.

## Auto-revisión antes de entregar

Relee la fuente con ojos frescos y verifica tres cosas:

1. **Cobertura:** cada requisito de la fuente apunta a un paso. Lista los
   huecos y ciérralos.
2. **Consistencia de nombres:** los tipos, funciones y firmas que usa el Paso 7
   son los que definió el Paso 3. Un `clearLayers()` que después es
   `clearAllLayers()` es un bug ya planificado.
3. **Placeholders:** busca los patrones de la sección anterior. Arréglalos en
   el momento.

## Dónde se guarda

- **Trabajo de un repo** → `docs/planes/YYYY-MM-DD-<slug>.md`, versionado con el
  código. El plan viaja con el PR y `plan-audit` lo lee al cerrar.
- **Trabajo de máquina o de configuración** (sin repo de producto) →
  `~/.claude/plans/YYYY-MM-DD-<slug>.md`.

Reporta la ruta al terminar y di cuál es el primer paso ejecutable.
