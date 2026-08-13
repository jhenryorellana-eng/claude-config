---
name: docs
description: >
  Documentación con framework Diataxis en dos modos. Modo generate: crea docs
  faltantes (tutorial/how-to/reference/explanation) para una feature o módulo.
  Modo release: post-ship, cruza el diff contra los docs existentes, construye el
  coverage map, actualiza README/ARCHITECTURE/CHANGELOG (con sell-test) y reporta
  deuda documental en el PR. Usa cuando se pida "documenta X", "genera
  documentación", "actualiza los docs", "sync docs post-ship", "escribe el
  tutorial de". La invoca docs-writer. NO redacta el historial del proyecto
  (docs/historial/ tiene su propia plantilla en el repo).
---

# Docs — documentación Diataxis, generar y sincronizar

Dos modos que se invocan distinto y sirven a momentos distintos:

- **generate** — hay una feature o módulo sin documentar y hay que escribir los
  documentos desde cero. `/docs generate <alcance>`.
- **release** — algo se shipeó y los docs existentes quedaron desfasados. Se
  cruza el diff contra la documentación, se actualiza lo que quedó mentiroso y se
  reporta la deuda. `/docs release`.

Si no queda claro cuál corresponde: ¿existe ya documentación de esto? Si no
existe, generate. Si existe pero está vieja, release.

## El framework Diataxis en una tabla

Los cuatro cuadrantes sirven a lectores distintos en modos distintos. Mezclarlos
es el error más común de la documentación técnica.

| Cuadrante | Lector | Pregunta que responde |
|---|---|---|
| **Tutorial** | Alguien nuevo, aprendiendo | "Llévame de cero a algo que funcione" |
| **How-to** | Alguien que ya sabe, con una tarea | "¿Cómo logro X?" |
| **Reference** | Alguien que necesita un dato | "¿Qué parámetros acepta esto?" |
| **Explanation** | Alguien que quiere entender | "¿Por qué funciona así?" |

---

# Modo generate

## Paso 1 — Alcance e intención

Determina qué se documenta: una feature, un módulo, un comando, el proyecto
entero. Si el pedido es ambiguo ("documenta el proyecto"), acota con
AskUserQuestion antes de escribir nada: documentar mal 20 archivos cuesta más que
preguntar una vez.

Determina también el lector: ¿usuario del producto, desarrollador que integra,
contribuidor del repo? El mismo módulo se documenta distinto para cada uno.

## Paso 2 — Arqueología del código (investigación)

No se escribe una línea antes de esto:

1. Lee el código de la superficie pública: firmas, tipos, valores por defecto,
   validaciones, errores que lanza.
2. Lee los tests. Los tests son la documentación de comportamiento más honesta
   que hay: dicen qué se espera de verdad, incluidos los casos borde.
3. Lee los docs que ya existen, para no contradecirlos ni duplicarlos.
4. Lee el historial de git de la zona: los mensajes de commit y los ADRs
   explican decisiones que el código no.

Si después de esto no entiendes por qué el módulo existe, no lo documentes
todavía: pregunta. Documentación escrita sin entender produce prosa que suena
bien y miente.

## Paso 3 — Partición Diataxis

Para cada entidad, decide qué cuadrantes produce. No todo necesita los cuatro.

| Tipo de entidad | Tutorial | How-to | Reference | Explanation |
|---|---|---|---|---|
| Feature con la que el usuario interactúa | ✅ | ✅ | ✅ | Quizá |
| Comando o flag de CLI | Quizá | ✅ | ✅ | No |
| Módulo interno / arquitectura | No | No | ✅ | ✅ |
| Opción de configuración | No | ✅ | ✅ | No |
| Patrón de diseño / filosofía | No | No | No | ✅ |
| Endpoint de API | Quizá | ✅ | ✅ | No |
| Flujo de trabajo multi-paso | ✅ | ✅ | No | Quizá |

Publica el plan de partición antes de escribir:

```
Plan de documentación:
  [entidad]              [tutorial] [how-to] [reference] [explanation]
  Módulo de casos        ✅ nuevo   ✅ nuevo  ✅ nuevo     ✅ nuevo
  Flag --verbose         ❌         ✅ nuevo  ✅ inline    ❌
  Motor de generación    ❌         ❌        ✅ nuevo     ✅ nuevo
```

Si el plan tiene más de 5 documentos, confirma con AskUserQuestion antes de
seguir. Con menos, procede directo.

## Paso 4 — Reference primero

Los docs de referencia son la base: son factuales, completos y derivan directo
del código. Se escriben antes que los tutoriales y los how-tos porque establecen
el vocabulario que los demás usan.

```markdown
# [Nombre de la entidad]

[Un párrafo: qué es, qué hace, cuándo la usarías.]

## API / Interfaz

[Listado completo de la superficie pública: funciones, comandos, opciones de
config, parámetros. Incluye tipos, valores por defecto y restricciones. Sale
directo del código — no parafrasees a la ligera.]

## Opciones / Configuración

[Si aplica: cada opción con su tipo, default y efecto.]

## Ejemplos

[2-3 ejemplos concretos de uso real. Prefiere salida real de comandos o código
que efectivamente compile o corra.]

## Relacionado

[Enlaces a otras referencias, how-tos o explicaciones que den contexto.]
```

**Reglas:** precisión antes que elegancia; toda afirmación trazable al código.
Incluye tipos, defaults y restricciones — "acepta un string" es insuficiente,
"acepta un string (máx. 256 caracteres, debe matchear `^[a-z-]+$`)" es grado
referencia. No expliques el *porqué*: eso va en explanation.

## Paso 5 — Explanation

Responde "¿por qué funciona así?". Es la justificación de diseño.

```markdown
# [Concepto / decisión de diseño]

[Párrafo inicial: el problema que este diseño resuelve, en términos que entienda
alguien inteligente que no vio el código.]

## El problema

[Qué sale mal sin este diseño. Modos de falla reales, no riesgos abstractos.]

## El enfoque

[Cómo el diseño resuelve el problema. Incluye diagramas (ASCII o Mermaid) para
conceptos arquitectónicos.]

## Trade-offs

[Qué se resignó. Toda decisión de diseño cambia algo por algo — nómbralo.]

## Alternativas consideradas

[Si es rastreable desde comentarios, ADRs o el historial de git: qué se probó o
se descartó, y por qué.]
```

**Reglas:** abre con el problema, no con la solución. Usa diagramas ASCII para
arquitectura (son grepeables, diffeables y renderizan en todos lados). Nombra los
trade-offs explícitamente: "elegimos X sobre Y porque Z" es el estándar de oro.
No repitas material de referencia — enlázalo.

## Paso 6 — How-to

Orientados a tarea. Asumen que el lector conoce lo básico y quiere lograr algo
específico.

```markdown
# Cómo [lograr la tarea específica]

[Una frase: qué vas a lograr y cuál es el resultado final.]

## Requisitos previos

[Qué necesita el lector antes de empezar. Específico: versiones, herramientas
instaladas, estado de configuración.]

## Pasos

1. [Verbo de acción] [instrucción específica]

   ```bash
   [comando exacto]
   ```

   [Salida o resultado esperado, si no es obvio.]

2. [Siguiente paso...]

## Verificación

[Cómo confirmar que funcionó. Un comando, una URL, un test.]

## Solución de problemas

[Fallas comunes y su arreglo. Sácalas de los tests y del manejo de errores.]
```

**Reglas:** el título empieza con "Cómo", sin excepciones — es la puerta de
entrada del lector. Cada paso debe ser accionable: nada de "considera si..." sino
"corre X" o "agrega Y a Z". La verificación es obligatoria: el lector nunca debe
quedarse preguntando "¿funcionó?". La sección de troubleshooting es obligatoria
si la tarea puede fallar.

## Paso 7 — Tutorial

Orientados a aprendizaje. Llevan a alguien nuevo de cero a un ejemplo que
funciona. Son los más difíciles de escribir bien y los más valiosos.

```markdown
# [Título — describe qué vas a construir o aprender]

[Párrafo inicial: qué vas a construir, por qué sirve y qué vas a entender al
final. Concreto: "vas a construir un X que hace Y", no "este tutorial cubre X".]

## Qué vas a necesitar

[Requisitos: herramientas, versiones, conocimiento previo. Enlaza a las guías de
instalación.]

## Paso 1: [Montar la base]

[Arranca desde un estado limpio. Muestra cada comando. Explica qué hace cada uno
la primera vez que aparece — breve, no una clase.]

## Paso 2: [Construir la primera pieza que funciona]

[Llega a un resultado visible lo antes posible. El lector debe ver algo pasar
dentro de los primeros 3 pasos.]

## Paso N: [Paso final]

## Lo que construiste

[Recapitulación: qué tiene ahora el lector y qué puede hacer. Enlaza a la
referencia para profundizar. Sugiere los siguientes pasos.]
```

**Reglas:** **tiempo al primer resultado < 3 pasos.** Si el lector no vio nada
funcionar para el paso 3, el tutorial está mal estructurado. Cada paso produce un
cambio visible. Usa los comandos exactos que el lector va a escribir, sin
abstracciones tipo "corre el comando correspondiente". Si un paso falla seguido,
muestra el error y el arreglo ahí mismo. Cierra con "Lo que construiste".

## Paso 8 — Enlazado y descubribilidad

1. **Enlaces cruzados entre cuadrantes.** Cada referencia enlaza a su how-to;
   cada how-to a su referencia; los tutoriales a ambos.
2. **Actualiza los puntos de entrada:** README (índice o sección de
   documentación), CLAUDE.md si es relevante para agentes, y cualquier índice o
   sidebar existente.
3. **Verifica la descubribilidad:** todo documento nuevo debe alcanzarse en 2
   clics desde el README.
4. **Revisa enlaces rotos:** busca referencias `](` que apunten a archivos que no
   existen.

## Paso 9 — Autorrevisión de calidad

Antes de dar por terminado, revisa cada documento:

**Gate de precisión:**
- [ ] Todo ejemplo de código compila, corre o pasa si se copia y pega
- [ ] Toda descripción de API coincide con la firma real
- [ ] Todo comando mostrado produce la salida descrita
- [ ] No hay referencias a entidades renombradas o eliminadas

**Gate de completitud:**
- [ ] La referencia cubre el 100% de la superficie pública
- [ ] Los how-tos cubren las 3 tareas principales que intentaría un usuario
- [ ] Los tutoriales llegan a un resultado funcionando en ≤3 pasos
- [ ] Las explicaciones nombran trade-offs, no solo decisiones

**Gate de voz:**
- [ ] Escrito para alguien inteligente que no vio el código
- [ ] Sin jerga sin glosa breve en su primera aparición
- [ ] Voz activa, sustantivos concretos, frases cortas
- [ ] "Ya puedes..." en vez de "El sistema provee..."

Arregla lo que falle antes de continuar.

---

# Modo release

## Paso 1 — Radio de impacto de lo que se shipeó

Corre `git diff <base>...HEAD` y `git log <base>..HEAD --oneline` y clasifica el
cambio:

- **Funcionalidad nueva** — features, comandos, endpoints, opciones nuevas
- **Comportamiento cambiado** — servicios modificados, APIs actualizadas, cambios
  de config
- **Funcionalidad eliminada** — archivos borrados, comandos removidos
- **Infraestructura** — build, tests, CI

Y lista los archivos de documentación que existen en el repo. Salida breve:
"Analizando N archivos cambiados en M commits. Hay K archivos de documentación
para revisar."

## Paso 2 — Coverage map (análisis de radio de explosión)

Antes de tocar un solo archivo de documentación, construye el **coverage map**:
qué se shipeó contra qué está documentado. Es el framework Diataxis usado como
lente de auditoría, no como herramienta de generación.

1. **Extrae los cambios de superficie pública del diff:**
   - Funciones, clases, comandos, flags de CLI, opciones de config y endpoints
     nuevos
   - Capacidades nuevas visibles para el usuario
   - Superficie pública renombrada o eliminada
   - Variables de entorno, feature flags o perillas de configuración nuevas

2. **Para cada ítem, evalúa la cobertura documental:**

```
Coverage map:
  [entidad]        [reference?]  [how-to?]  [tutorial?]  [explanation?]
  /nueva-ruta      ✅ README     ❌         ❌           ❌
  --nuevo-flag     ✅ README     ✅ README  ❌           ❌
  CaseProcessor    ❌            ❌         ❌           ❌
```

Definiciones: **reference** = descripción factual de qué es y qué acepta;
**how-to** = orientado a tarea, "cómo hacer X con esto"; **tutorial** = recorrido
paso a paso para quien recién llega; **explanation** = "por qué funciona así"
(decisiones de ARCHITECTURE, ADRs).

3. **Publica el coverage map.** Los ítems con cobertura cero son **gaps
   críticos**. Los que solo tienen referencia son **gaps comunes**: van al cuerpo
   del PR.

4. **Deriva de diagramas.** Si ARCHITECTURE.md (o cualquier doc) tiene diagramas
   ASCII o bloques Mermaid, extrae los nombres de entidades (módulos, servicios,
   flujos) y crúzalos contra el diff. Marca las entidades del diagrama que fueron
   renombradas, partidas, eliminadas o movidas en el código.

## Paso 3 — Auditoría por archivo

Lee cada archivo de documentación y crúzalo contra el diff:

**README.md:** ¿describe todas las capacidades visibles en el diff? ¿Las
instrucciones de instalación siguen siendo válidas? ¿Los ejemplos siguen
funcionando? ¿El troubleshooting sigue siendo correcto?

**ARCHITECTURE.md:** ¿la lista de componentes coincide con el código? ¿Los
diagramas reflejan la estructura actual? ¿Hay módulos nuevos sin mencionar?

**CONTRIBUTING.md:** ¿la estructura del proyecto que describe sigue existiendo?
¿Los comandos de setup y de test siguen siendo los mismos?

**CLAUDE.md / AGENTS.md:** ¿las instrucciones para agentes reflejan los comandos,
rutas y convenciones actuales? Este archivo se desactualiza en silencio y produce
agentes que trabajan contra un mapa viejo.

Arregla las inexactitudes factuales directamente. Para las contradicciones
narrativas (dos documentos que cuentan historias distintas sobre el mismo
sistema), usa AskUserQuestion.

## Paso 4 — Voz del CHANGELOG (con sell-test)

**CRÍTICO — NUNCA pises entradas del CHANGELOG.**

Este paso pule la redacción. NO reescribe, reemplaza ni regenera contenido. Hubo
un incidente real donde un agente reemplazó entradas existentes que debía
preservar. Esta skill JAMÁS hace eso.

**Reglas:**
1. Lee el CHANGELOG completo primero. Entiende qué hay.
2. Solo modifica la redacción dentro de entradas existentes. Nunca borres,
   reordenes ni reemplaces entradas.
3. Nunca regeneres una entrada desde cero. La entrada se escribió a partir del
   diff y del historial reales: es la fuente de verdad. Estás puliendo prosa, no
   reescribiendo la historia.
4. Si una entrada parece incorrecta o incompleta, usa AskUserQuestion — no la
   arregles en silencio.
5. Usa la tool Edit con `old_string` exacto. Nunca uses Write sobre CHANGELOG.md.

**Si el CHANGELOG no se tocó en esta rama, salta este paso.**

**Sell-test (rúbrica Diataxis).** Puntúa cada entrada de 0 a 3:
- **1 punto** — responde "¿qué cambió?" (reference: nombra la feature o el fix)
- **1 punto** — responde "¿por qué me importa?" (explanation: impacto en el
  usuario, dolor que desaparece)
- **1 punto** — responde "¿cómo lo uso?" (how-to: comando, flag o enlace a los
  docs)

Las entradas con menos de 2 necesitan reescritura; las de 3 son oro.

Además: abre con lo que el usuario **ya puede hacer**, no con detalles de
implementación ("Ya puedes..." en vez de "Se refactorizó el..."). Toda entrada
que se lea como un mensaje de commit se reescribe. Los cambios internos van en
una subsección aparte ("### Para contribuidores"). Ajustes menores de voz se
aplican solos; si la reescritura cambiaría el significado, pregunta.

## Paso 5 — Consistencia cruzada

1. ¿La lista de capacidades del README coincide con lo que describe CLAUDE.md?
2. ¿Los componentes de ARCHITECTURE coinciden con la estructura de CONTRIBUTING?
3. ¿La última versión del CHANGELOG coincide con el archivo de versión?
4. **Descubribilidad:** ¿todo archivo de documentación es alcanzable desde
   README.md o CLAUDE.md? Si ARCHITECTURE.md existe pero nadie lo enlaza,
   márcalo.
5. Marca toda contradicción entre documentos. Arregla las inconsistencias
   factuales evidentes; para las narrativas, pregunta.

## Paso 6 — Deuda documental en el PR

Actualiza el cuerpo del PR con una sección `## Documentación` (reemplázala si ya
existe, agrégala al final si no). Debe incluir:

**a. Qué cambió en los docs** — por cada archivo modificado, una línea concreta:
"README.md: se agregó la ruta /casos a la tabla de módulos, se actualizó el
conteo de 9 a 10".

**b. Deuda documental** — si el coverage map del Paso 2 encontró gaps, una
subsección `### Deuda documental`:
- **Gaps críticos:** superficie pública nueva con cobertura cero
- **Gaps comunes:** features con solo referencia (sin how-to ni tutorial)
- **Diagramas rancios:** diagramas de arquitectura cuyas entidades ya no existen
- Cada ítem con una línea de qué falta y qué cuadrante Diataxis lo llenaría
  ("⚠️ `/nueva-ruta` — tiene referencia en el README pero ningún ejemplo de uso")

Si hay deuda documental, sugiere agregar la etiqueta `docs-debt` al PR.

---

## Reglas importantes

- **Investiga antes de escribir.** La arqueología del código no es opcional. La
  investigación insuficiente produce documentación de superficie.
- **La precisión no se negocia.** Todo ejemplo debe funcionar; toda descripción
  de API debe coincidir con el código. Ante la duda, relee la fuente — no
  adivines.
- **Los cuadrantes sirven a lectores distintos.** No mezcles contenido de
  tutorial en la referencia ni de referencia en un how-to.
- **El coverage map informa, nunca genera.** Textual del original: *"Coverage map
  informs, never generates."* Marca gaps para el cuerpo del PR y el trabajo
  futuro; NO auto-genera páginas ni secciones faltantes. Cuando encuentres gaps,
  el siguiente paso es el modo generate — pero es una decisión, no un automatismo.
- **Nunca pises el CHANGELOG.** Solo puliste la redacción. Nunca borres,
  reemplaces ni regeneres entradas.
- **Nunca subas la versión en silencio.** Siempre pregunta.
- **La deriva de diagramas es informativa.** Marca los diagramas rancios en el PR
  pero no edites ASCII ni Mermaid por tu cuenta: requieren criterio humano.
- **Enlaza todo.** Un documento aislado es un documento que nadie encuentra.
- **Voz: amable, concreta, del lado del usuario.** Escribe como si le explicaras a
  alguien inteligente que no vio el código. Nunca corporativo, nunca académico.
- **Sin PII.** Los ejemplos usan `U26-XXXXXX`, `[CLIENTE-XX]` o correos
  `@e2e.local`. Jamás datos de un cliente real.
- **Esta skill no escribe el historial del proyecto.** Las entradas de
  `docs/historial/` siguen la plantilla del repo y las redacta `docs-writer`
  siguiendo esa plantilla, no esta skill.
