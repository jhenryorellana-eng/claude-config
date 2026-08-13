---
name: investigate
description: >
  Debugging sistemático con causa raíz obligatoria (Iron Law: no fixes without
  root cause). Cuatro fases: investigación, análisis de patrones, hipótesis
  verificada, fix mínimo con test de regresión. Regla 3-strikes (3 hipótesis
  fallidas = STOP y cuestionar la arquitectura) y gate de blast radius (>5
  archivos = preguntar). Usa cuando el usuario reporte errores, stack traces,
  500s, "dejó de funcionar", "ayer funcionaba", "¿por qué está roto?",
  "investiga/debug este error". Invócala SIEMPRE en vez de debuggear directo.
  NO es para incidentes de producción ya ocurridos (postmortem).
---

# Investigate — debugging sistemático

## Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.
```

Arreglar síntomas produce debugging de topo: cada parche esconde la causa y
hace más difícil encontrar el siguiente bug. Encuentra la causa raíz, después
arregla.

Esta regla aplica **especialmente** cuando hay apuro, cuando el fix "obvio"
está a la vista y cuando ya probaste dos cosas que no funcionaron. Un bug
simple también tiene causa raíz, y encontrarla es más rápido que adivinar tres
veces.

---

## Fase 1 — Investigación

Junta contexto **antes** de formular cualquier hipótesis.

1. **Lee el mensaje de error COMPLETO.** Entero: el stack trace hasta el fondo,
   los números de línea, los códigos de error, los warnings de arriba. Muchas
   veces la solución está escrita ahí y se pierde por leer solo la primera
   línea. No pases a la siguiente fase sin haberlo leído completo.

2. **Reproduce.** ¿Puedes dispararlo de forma determinista? ¿Cuáles son los
   pasos exactos? ¿Pasa siempre o a veces? Si no es reproducible, junta más
   evidencia; no adivines sobre un fenómeno que no puedes observar.

3. **Lee el código.** Traza el camino desde el síntoma hacia atrás, hasta el
   origen del valor malo: ¿quién lo produjo?, ¿quién llamó con ese valor? El
   fix va en el origen, no donde explotó.

4. **Mira los cambios recientes.**
   ```bash
   git log --oneline -20 -- <archivos-afectados>
   ```
   ¿Antes funcionaba? Si es una regresión, la causa raíz está en el diff.

5. **Instrumenta los límites** cuando el sistema tiene varias capas (CI →
   build → deploy, API → servicio → base, cliente → server action → Postgres).
   Antes de proponer nada, loguea qué entra y qué sale de cada frontera y corre
   una vez. Eso revela **en qué capa** se rompe, que es información distinta de
   "se rompió".

6. **Revisa si es recurrente.** Bugs repetidos en los mismos archivos son un
   olor arquitectónico, no una casualidad. Si `git log` muestra fixes previos
   en la misma zona, la causa raíz probablemente sea estructural.

Al cerrar la fase, escribe: **"Hipótesis de causa raíz: ..."** — una afirmación
específica y testeable sobre qué está mal y por qué.

### Bisección cuando hay una regresión con rango conocido

Si el bug es una regresión y sabes un commit donde funcionaba, no leas el diff
completo a ojo: bisecta. Es logarítmico y devuelve el commit culpable exacto.

```bash
git bisect start
git bisect bad                       # el HEAD actual está roto
git bisect good <sha-que-funcionaba>
git bisect run npm run test -- ruta/al/test-que-reproduce
git bisect reset                     # SIEMPRE al final: deja el árbol como estaba
```

- El comando de `run` debe salir con código 0 en los commits buenos y distinto
  de 0 en los malos. Sirve el test que reproduce el bug o, si aún no existe, un
  script de una línea que dispare el síntoma.
- Los commits que no compilan se marcan `git bisect skip`: el resultado sigue
  siendo válido, con más pasos.
- El commit culpable es el **punto de partida** de la investigación, no la
  respuesta: todavía hay que explicar *por qué* ese cambio rompe esto. Un
  commit señalado sin mecanismo explicado es un sospechoso, no una causa raíz.

---

## Fase 2 — Análisis de patrones

Chequea si el bug encaja en un patrón conocido:

| Patrón | Firma | Dónde mirar |
|---|---|---|
| Race condition | Intermitente, depende del timing | Acceso concurrente a estado compartido |
| Propagación de nulos | `TypeError`, `undefined is not a function`, `NoMethodError` | Guardas faltantes sobre valores opcionales |
| Corrupción de estado | Datos inconsistentes, actualizaciones a medias | Transacciones, callbacks, hooks, efectos |
| Fallo de integración | Timeout, respuesta inesperada | Llamadas a APIs externas, bordes de servicio |
| Config drift | Funciona local, falla en staging o prod | Env vars, feature flags, estado de la base |
| Caché rancio | Muestra datos viejos, se arregla al limpiar caché | Redis, CDN, caché del navegador, revalidación |

Además:

- Busca en `TODOS.md` (o equivalente) si el problema ya estaba anotado.
- Revisa `git log` de la zona: fixes previos en los mismos archivos son señal
  de causa estructural.
- **Búsqueda externa:** si no encaja en ningún patrón, busca en la web
  `"<framework> <tipo de error genérico>"` o `"<librería> <componente> known
  issues"`. **Sanitiza primero**: fuera hostnames, IPs, rutas locales,
  fragmentos de SQL y cualquier dato de cliente. Se busca la categoría del
  error, jamás el mensaje crudo. Si el mensaje es demasiado específico para
  sanitizarlo con seguridad, no lo busques. Si aparece un bug documentado de la
  dependencia, entra como hipótesis candidata a la Fase 3.

---

## Fase 3 — Hipótesis

Antes de escribir CUALQUIER fix, verifica la hipótesis.

1. **Confírmala con evidencia.** Agrega un log temporal, una aserción o un
   breakpoint en el punto sospechoso. Corre la reproducción. ¿La evidencia
   coincide con lo que predijiste? Si no coincide exactamente, la hipótesis es
   falsa aunque el síntoma se parezca.

2. **Una hipótesis a la vez, un cambio a la vez.** Si tocas tres cosas y el
   síntoma desaparece, no sabes cuál fue — y probablemente introdujiste dos
   bugs nuevos.

3. **Si la hipótesis falla:** vuelve a Fase 1 con la información nueva. Junta
   más evidencia. No apiles un segundo fix encima del primero: revierte el
   intento fallido antes de probar el siguiente.

4. **Regla 3-strikes.** Si fallan 3 hipótesis, **PARA**. Usa `AskUserQuestion`:
   ```
   Probé 3 hipótesis, ninguna coincide. Esto huele a problema arquitectónico
   más que a un bug puntual.

   A) Seguir investigando — tengo una hipótesis nueva: [descríbela]
   B) Escalar a revisión humana — hace falta alguien que conozca el sistema
   C) Instrumentar y esperar — dejar logging en la zona y atraparlo la próxima
   ```
   Tres fallos no son tres hipótesis malas: son la señal de que el modelo
   mental del sistema está equivocado. El cuarto intento a ciegas es el que
   rompe producción.

**Banderas rojas** — si te escuchas pensando esto, frena:

- "Un fix rápido por ahora" — no existe el "por ahora". Se arregla bien o se
  escala.
- "Proponer el fix antes de trazar el flujo de datos" — eso es adivinar.
- "Cada fix destapa un problema nuevo en otro lado" — capa equivocada, no
  código equivocado.
- "No entiendo bien esto pero quizás funcione" — decir "no entiendo X" es una
  respuesta válida; fingir que entiendes no lo es.

---

## Fase 4 — Implementación

Con la causa raíz confirmada:

1. **Arregla la causa, no el síntoma.** El cambio más chico que elimine el
   problema real.

2. **Diff mínimo.** Menos archivos, menos líneas. Nada de refactorizar lo de al
   lado "ya que estoy": eso convierte un fix revisable en un diff que nadie
   puede revisar. Mantén las ediciones dentro del módulo afectado.

3. **Escribe el test de regresión** (ver la skill `tdd`) que:
   - **Falla** sin el fix — pruébalo revirtiendo el fix y corriendo el test.
   - **Pasa** con el fix.
   Un test de regresión que nunca se vio en rojo no protege de nada.

4. **Corre la suite completa** y pega la salida. Cero regresiones.

5. **Gate de blast radius:** si el fix toca **más de 5 archivos**, para y usa
   `AskUserQuestion`:
   ```
   Este fix toca N archivos. Es mucho radio para un bugfix.
   A) Seguir — la causa raíz genuinamente abarca esos archivos
   B) Partir — arreglar el camino crítico ahora, diferir el resto
   C) Repensar — quizás hay un enfoque más quirúrgico
   ```

---

## Fase 5 — Verificación y reporte

**Verificación fresca:** reproduce el escenario original y confirma que el bug
ya no ocurre. No es opcional y no se reemplaza por "los tests pasan". Corre la
suite y pega la salida (el gate completo está en la skill `verify`).

Cierra con el reporte estructurado:

```
DEBUG REPORT
════════════════════════════════════════
Síntoma:          [lo que observó el usuario]
Causa raíz:       [qué estaba mal de verdad, y por qué producía ese síntoma]
Fix:              [qué se cambió, con referencias archivo:línea]
Evidencia:        [salida de tests, reproducción mostrando que ya no falla]
Test de regresión:[archivo:línea del test nuevo]
Relacionado:      [ítems de TODOS.md, bugs previos en la zona, notas de arquitectura]
Estado:           DONE | DONE_WITH_CONCERNS | BLOCKED
════════════════════════════════════════
```

Si la investigación reveló un patrón no obvio o una trampa del proyecto,
anótalo en la memoria de oficio del agente que corresponda; si el trabajo vive
en un repo con `docs/historial/`, la entrada del historial es el lugar
adecuado.

---

## Reglas finales

- **Nunca arregles sin causa raíz.** Es la regla que no admite prisa.
- **3+ intentos fallidos → PARA y cuestiona la arquitectura.**
- **Nunca apliques un fix que no puedas verificar.** Sin reproducción ni
  confirmación, no se shippea.
- **Nunca digas "esto debería arreglarlo".** Demuéstralo con la salida.
- **Fix que toca >5 archivos → pregunta** antes de seguir.
- **Nunca busques en la web el mensaje de error crudo.** Se busca la categoría
  del error, no los datos del cliente.
- **Estados de cierre:** `DONE` (causa raíz encontrada, fix aplicado, test de
  regresión escrito, suite en verde) · `DONE_WITH_CONCERNS` (arreglado pero sin
  verificación completa — escribe qué quedó sin probar) · `BLOCKED` (causa raíz
  no identificada; escala diciendo qué se descartó).
