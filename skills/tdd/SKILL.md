---
name: tdd
description: >
  Disciplina test-first: escribe el test, míralo FALLAR con salida real, escribe
  el mínimo código que lo pasa, refactoriza en verde. Usa cuando el usuario o un
  charter diga "TDD", "test primero", "escribe el test antes", o al implementar
  cualquier feature/bugfix de backend o lógica de negocio (regla del router:
  backend = TDD estricto). NO es la verificación final de un trabajo (verify) ni
  el QA de una web viva (qa-web).
---

# TDD — test primero, siempre

## Principio

**Si no viste el test fallar, no sabes qué está probando.**

Un test escrito después del código pasa a la primera. Eso no prueba que el test
sirva: prueba que el test fue escrito mirando la implementación. Solo el fallo
observado demuestra que el test puede atrapar el bug.

## La regla dura

```
El test debe FALLAR sin el cambio y PASAR con él.
Un test que nunca falló no prueba nada.
```

No hay excepción por urgencia, por trivialidad ni por "ya lo probé a mano".
Si escribiste código antes del test, bórralo y empieza de nuevo — no lo
guardes "de referencia", porque lo vas a adaptar, y adaptarlo es escribir el
test después.

## Ciclo RED → GREEN → REFACTOR

### RED — escribe un test que falla

Un test, un comportamiento, nombre que describe la conducta esperada. Prueba el
**contrato** (qué debe pasar), no la implementación (cómo lo hace por dentro).
Usa código real; mockea solo lo inevitable (red, reloj, servicios externos).

Antes de correrlo, di en una frase qué cambio de producción haría fallar este
test. Si no puedes nombrarlo, el test no está probando nada.

### Verificar RED — míralo fallar

Obligatorio. Corre el test y **pega la salida**:

```
npm run test -- ruta/al/archivo.test.ts
```

Confirma tres cosas en esa salida:

- Falla, no explota. Un `SyntaxError` o un import roto no es un RED válido.
- Falla por la razón esperada (falta la funcionalidad), no por un typo.
- Si pasa a la primera: estás testeando comportamiento que ya existía. El test
  está mal, no el código.

### GREEN — el mínimo código que lo pasa

Lo más simple que haga pasar ese test. Nada de parámetros opcionales "por si
acaso", nada de refactors de paso, nada de arreglar lo de al lado. Si aparece
una necesidad nueva, es otro ciclo RED.

### Verificar GREEN — míralo pasar

Corre otra vez y pega la salida. Confirma que el test pasa, que los demás
siguen pasando y que la salida está limpia (sin warnings nuevos ni errores en
consola). Si falla, arregla el código, nunca el test.

### REFACTOR — limpia en verde

Solo después del verde: quita duplicación, mejora nombres, extrae helpers. Los
tests quedan verdes en todo momento y no se agrega comportamiento nuevo.

## Prohibido declarar verde sin la salida

Nunca escribas "los tests pasan", "quedó verde" ni "debería funcionar" sin la
salida del runner en el mismo turno. Una afirmación de éxito sin evidencia
ejecutada es una mentira, aunque sea cierta por casualidad. El gate completo de
cierre vive en la skill `verify`.

## Tests de regresión (bugfix)

Todo bugfix nace de un test que reproduce el bug. Ese test:

- Monta la **precondición exacta** que disparó el fallo, ejecuta la acción que
  lo expuso y afirma el comportamiento correcto. Nunca `no lanza excepción` ni
  `renderiza` como aserción.
- Cubre también los bordes adyacentes que encontraste al trazar (entrada nula,
  arreglo vacío, valor límite).
- Lleva comentario de atribución arriba:

  ```
  // Regresión: <id-o-slug-del-bug> — <qué se rompía>
  // Encontrado el <YYYY-MM-DD> · causa raíz: <una línea>
  ```

- Se nombra `<modulo>.regression-<n>.test.<ext>`, con `<n>` autoincremental:
  mira los `<modulo>.regression-*.test.*` existentes y toma el máximo más uno.
  Evita colisiones cuando varios bugs tocan el mismo módulo.

Tipo de test según el bug: excepción de JS o error de lógica → unitario;
formulario roto, fallo de API o de flujo de datos → integración con
request/response; bug visual con comportamiento JS → test de componente; CSS
puro → no se testea acá, va al QA visual.

**Prueba del rojo-verde en un fix:** con el fix aplicado el test pasa; revierte
el fix, corre, **debe fallar**; restaura, corre, pasa. Sin ese ciclo, el test
de regresión no está verificado.

## Anti-patrones

| Patrón | Por qué está mal |
|---|---|
| Escribir el test después "para cumplir" | Pasa a la primera; nunca demostró que atrapa el bug. Documenta lo que el código hace, no lo que debería hacer |
| Testear la implementación en vez del contrato | Se rompe en cada refactor legítimo y no se rompe cuando el comportamiento cambia de verdad. Un test así es puro costo |
| Afirmar sobre el mock | Comprueba que el mock fue llamado, no que el sistema funciona. El test pasa con el código roto |
| `.skip` silencioso | Un test apagado sin motivo escrito es cobertura falsa. Si se apaga, va el motivo y la fecha en la misma línea |
| "Es muy simple para testear" | El código simple también se rompe, y el test cuesta treinta segundos |
| "Ya lo probé a mano" | La prueba manual no deja registro, no se repite sola y se olvida bajo presión |
| Varios comportamientos en un test | Cuando falla no sabes cuál. Si el nombre lleva "y", pártelo |

## Cuándo se traba

- **No sé cómo testear esto** → escribe primero la API que te gustaría usar, y
  después la aserción. El test es el primer consumidor del diseño.
- **El setup es enorme** → el diseño está acoplado; inyecta dependencias en vez
  de mockear medio mundo.
- **Difícil de testear** → difícil de usar. Escucha al test y simplifica la
  interfaz antes de seguir.
