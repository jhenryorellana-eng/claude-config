---
name: verify
description: >
  Gate final antes de declarar trabajo completo: ejecuta la verificación y pega
  la evidencia (salida de tests, screenshot, output del comando) ANTES de
  cualquier claim de éxito. "Debería funcionar" está prohibido. Incluye el
  checklist de cierre de rama (tests verdes, rebase, historial limpio, PR o
  merge). Usa cuando un charter llegue a su paso de verificación, o cuando el
  usuario diga "verifica antes de dar por terminado", "¿está realmente listo?",
  "muéstrame la evidencia". NO audita cumplimiento de plan (plan-audit) ni
  revisa calidad de diff (/code-review).
---

# Verify — evidencia antes de la afirmación

## Regla de hierro

```
Toda afirmación de éxito exige evidencia ejecutada en el MISMO turno.
```

Si el comando no se corrió en este mensaje, no puedes decir que pasa. Da igual
que haya pasado hace diez minutos: el árbol cambió desde entonces, o no
cambió pero no lo sabes. Correr la verificación es más barato que retractarse.

Esto aplica a la afirmación literal y a cualquier forma equivalente: "listo",
"ya quedó", "funciona", "perfecto", un resumen en pasado que da a entender que
se probó. La regla es sobre el significado, no sobre las palabras.

## La secuencia

1. **Identifica** qué comando prueba exactamente esta afirmación.
2. **Ejecútalo completo y fresco.** Nada de correr un subconjunto y extrapolar.
3. **Lee la salida entera**: código de salida, cantidad de fallos, warnings.
4. **Compara** salida contra afirmación. ¿La prueba de verdad?
   - No → reporta el estado real, con la salida.
   - Sí → afirma, y pega la salida junto a la afirmación.

Saltarse un paso no es verificar rápido: es afirmar sin saber.

## Las tres reglas que más se rompen

- **Nunca apliques un fix que no puedas verificar.** Si no puedes reproducir el
  problema ni confirmar que desapareció, no lo shippees: márcalo `BLOCKED` y di
  qué hace falta para poder probarlo.
- **Nunca digas "esto debería arreglarlo".** O lo probaste y lo demuestras, o
  no lo sabes. "Debería" es la palabra que precede a los rollbacks.
- **Honestidad sobre el entregable:** *código que **maneja** un entregable no es
  el entregable*. Haber shippeado la librería que extrae markdown no es haber
  shippeado el archivo markdown. Que exista el endpoint que aplica la policy no
  es que la policy esté aplicada en la base. Ante la duda entre "hecho" y "no
  verificable", elige no verificable: un aviso molesto cuesta menos que un
  entregable faltante que nadie notó.

## Evidencia según el tipo de trabajo

| Trabajo | Evidencia que cuenta | Evidencia que NO cuenta |
|---|---|---|
| Backend / lógica | Salida completa del runner: N/N pasando, exit 0 | "Los tests estaban verdes antes"; el linter en verde |
| Bugfix | El test de regresión falla al revertir el fix y pasa con él | "El síntoma ya no aparece" |
| UI | Screenshot de Playwright a 1440 y a 390 px del estado final | Que el build compile; que el componente exista |
| Accesibilidad | Salida de axe sobre la página real, con 0 violaciones serias | Haber puesto los `aria-*` |
| Migración de base | La migración aplicada + chequeo de drift limpio contra el esquema esperado | Que el archivo de migración exista en el diff |
| RLS / permisos | La consulta ejecutada como el rol restringido, mostrando lo que puede y no puede ver | Leer la policy y que "se ve bien" |
| Deploy | El dominio sirviendo el contenido nuevo (código de respuesta y contenido), no solo el build verde | "Vercel dice ready" |
| Integración externa | La llamada real hecha y su respuesta pegada | Que el SDK esté instalado |
| Config del VPS | La salida del comando en la máquina (`systemctl status`, `ls` del directorio destino) | Que el script se haya copiado |
| Docs | El archivo leído después de escrito, con las rutas y comandos que cita comprobados | "Documenté el cambio" |

Regla de UI del sistema: **ningún trabajo de interfaz se declara terminado sin
screenshot de Playwright.** No es un extra, es la evidencia del tipo de trabajo.

## Trabajo delegado a agentes

Que un agente reporte éxito no es evidencia: es un reporte. Verifícalo por tu
cuenta antes de repetirlo — mira el diff real, corre los tests, abre el archivo
que dijo haber creado. Un agente que se equivoca de buena fe produce el mismo
daño que uno que no hizo nada.

## Estados finales

Todo cierre termina en uno de estos tres, nombrado explícitamente:

- **DONE** — se cumplió lo pedido, la verificación corrió en este turno y la
  evidencia está pegada. Sin peros.
- **DONE_WITH_CONCERNS** — el trabajo está hecho pero algo no se pudo probar
  del todo (bug intermitente, requiere staging, depende de estado externo que
  no controlas). Obliga a escribir **qué quedó sin verificar y cómo se
  verifica**. No es un DONE con adornos: es una deuda con nombre.
- **BLOCKED** — no se pudo completar o no se pudo verificar nada. Di dónde se
  trabó, qué se intentó y qué hace falta para destrabarlo.

Un estado sin evidencia adjunta no es un estado, es una opinión.

## Checklist de cierre de rama

Cuando el trabajo se cierra en una rama, antes de proponer integración:

1. **Suite completa en verde.** La suite entera, no la del módulo tocado, y
   corrida sobre el árbol que se va a integrar. Si falla algo, se reporta el
   fallo y se para acá: el menú de integración viene después del verde.
2. **Rebase sobre la base actual.** Trae la base (`main` u otra), rebasea, y
   **vuelve a correr la suite sobre el resultado**: un verde previo solo prueba
   el árbol donde corrió.
3. **Historial limpio.** Commits con mensaje en inglés que dicen qué cambió y
   por qué; sin commits "wip", "fix fix" ni "asdf". Nada de `--no-verify`,
   nunca.
4. **Decisión de integración documentada.** Es del humano, no tuya. Presenta el
   estado y las opciones —merge local a la base, push y PR, o dejar la rama
   como está— y espera respuesta. En repos con deploy automático desde `main`
   (x-legal), la única vía es **PR**: nunca push directo, porque el PR es el
   rollback.
5. **Nada se descarta por iniciativa propia.** Borrar ramas, commits o
   worktrees solo ocurre si el usuario lo pide de forma explícita.

## Racionalizaciones frecuentes

| Excusa | Realidad |
|---|---|
| "Debería andar" | Córrelo |
| "Estoy seguro" | La confianza no es evidencia |
| "Pasó el linter" | El linter no compila ni ejecuta |
| "Solo por esta vez" | No hay excepciones; esta skill existe por las veces anteriores |
| "Corrí una parte, alcanza" | Lo parcial no prueba el conjunto |
| "El agente dijo que funcionó" | Verifica el diff tú mismo |
| "Es tarde y está casi listo" | El cansancio no cambia si el código funciona |
| "Lo digo con otras palabras, la regla no aplica" | La regla es sobre el significado |
