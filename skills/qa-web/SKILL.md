---
name: qa-web
description: >
  QA funcional de una web viva: recorre páginas y flujos reales con Playwright
  MCP (VPS: --headless) o claude-in-chrome (PC), captura errores de consola y
  red, prueba forms/auth/estados vacíos, triage por severidad y loop de fixes
  atómicos autorregulado por la heurística WTF-likelihood (STOP si >20%, tope 50
  fixes). Usa cuando se pida "QA de la web", "prueba el flujo", "test the site",
  "encuentra bugs en el sitio", "¿funciona esto?" sobre una app corriendo. NO es
  el gate visual/estético (ui-review) ni la suite e2e programada
  (npm run test:e2e).
---

# QA Web — recorrer la app viva y arreglar lo que se rompe

Esta skill abre la aplicación de verdad, la usa como la usaría una persona, y
reporta (o arregla) lo que falla. Su moneda es la evidencia: un bug sin repro y
sin captura no es un bug, es una sospecha.

## Herramientas por máquina

**PC (Windows, con Chrome):** `claude-in-chrome`. Abre pestañas en la sesión de
Chrome existente, con las cookies y sesiones reales del usuario. Es lo mejor para
probar páginas autenticadas sin montar login sintético. Invoca primero la skill
`claude-in-chrome` antes de usar sus herramientas.

**VPS (Ubuntu headless) o cualquier corrida desatendida:** Playwright MCP en modo
`--headless`. Herramientas principales:

| Herramienta | Para qué |
|---|---|
| `browser_navigate` | Ir a una URL |
| `browser_snapshot` | Árbol de accesibilidad de la página (más útil que un screenshot para razonar: trae roles, nombres y estado) |
| `browser_click` / `browser_type` / `browser_fill_form` | Interacción |
| `browser_console_messages` | Errores y warnings de consola |
| `browser_network_requests` | Requests fallidos, 4xx/5xx, llamadas colgadas |
| `browser_take_screenshot` | Evidencia visual del bug |
| `browser_wait_for` | Esperar texto o estado antes de afirmar que algo falló |

**Regla de oro:** `browser_snapshot` antes de afirmar. Un screenshot muestra
píxeles; el snapshot muestra qué elementos existen realmente y con qué estado.
Muchos "no funciona el botón" son en realidad "el botón está deshabilitado y
nadie dice por qué".

## Alcance del recorrido

- **Quick:** solo rutas críticas (home, auth, el flujo principal de negocio).
- **Standard (por defecto):** todas las rutas públicas + los flujos autenticados
  principales.
- **Exhaustivo:** además, estados borde: listas vacías, errores de red,
  permisos denegados, formularios con datos inválidos.

---

## Fase 1 — Mapa de rutas y flujos

Antes de abrir el navegador, decide qué vas a recorrer. Las fuentes, en orden:

1. **El router del proyecto.** En Next.js, `app/**/page.tsx`; en otros
   frameworks, su equivalente. Lista las rutas reales, no las imaginadas.
2. **El sitemap o la navegación.** Lo que un usuario puede alcanzar haciendo
   clic.
3. **Los flujos de negocio.** Lee CLAUDE.md o el README: cuáles son los dos o
   tres recorridos que si se rompen, el producto no sirve.
4. **Lo que cambió.** Si hay un diff de rama, las rutas afectadas por él van
   primero.

Salida de la fase: una lista concreta.

```
PLAN DE RECORRIDO
  Rutas públicas:    /, /precios, /login, /registro
  Autenticadas:      /dashboard, /casos, /casos/[id], /ajustes
  Flujos:            1) alta de usuario → verificación → primer caso
                     2) subir documento → generar → descargar
  Base URL:          http://localhost:3000
```

Si la app no está corriendo, levántala primero (o pídele al usuario la URL). No
hagas QA contra producción salvo que el usuario lo pida explícitamente.

---

## Fase 2 — Recorrido sistemático

Por **cada** página del plan, en este orden:

1. **Carga.** `browser_navigate` a la URL. ¿Responde? ¿Cuánto tarda hasta que se
   ve contenido? Un blanco de más de 3 segundos es un hallazgo.
2. **Consola limpia.** `browser_console_messages`. Todo `error` es hallazgo. Los
   `warning` se anotan pero rara vez son bugs — salvo los de React sobre keys
   duplicadas, hidratación o updates de estado en componentes desmontados, que sí
   suelen indicar bugs reales.
3. **Red.** `browser_network_requests`. Busca 4xx, 5xx, requests que nunca
   resuelven, y llamadas duplicadas a la misma API (síntoma de un `useEffect` sin
   dependencias bien puestas).
4. **Estructura.** `browser_snapshot`. ¿Hay un `h1`? ¿Los botones tienen nombre
   accesible? ¿Hay imágenes sin alt? ¿Hay texto de placeholder ("Lorem", "TODO",
   "undefined", "NaN", "[object Object]") visible?
5. **Interacción.** Haz clic en los elementos principales de la página: navegación,
   botones de acción, tabs, acordeones. Después de cada clic, snapshot: ¿cambió
   algo? ¿apareció un error en consola?
6. **Estados vacíos.** Si la página lista datos, ¿qué muestra con la lista vacía?
   Un estado vacío que renderiza una tabla con encabezados y nada más es un
   hallazgo de UX; uno que tira una excepción es un hallazgo Critical.
7. **Formularios.** Cada form se prueba tres veces:
   - **Vacío:** enviar sin llenar nada. ¿Valida? ¿Los mensajes de error son
     comprensibles y están junto al campo?
   - **Inválido:** email malformado, texto donde va número, fecha imposible.
   - **Válido:** con datos de prueba. Los correos van SIEMPRE al dominio
     `@e2e.local` (`qa-<timestamp>@e2e.local`). Nunca uses datos de un cliente
     real: si necesitas referirte a un caso, usa `U26-XXXXXX`.
8. **Autenticación.** Si el flujo requiere login: probar credenciales correctas,
   incorrectas, y el acceso directo a una ruta protegida sin sesión (debe
   redirigir, no mostrar un error crudo ni el contenido).

Anota cada hallazgo en el momento, con la URL, el paso exacto que lo provocó y la
captura. Un hallazgo que no anotaste cuando lo viste se pierde.

---

## Fase 3 — Triage por severidad

Clasifica cada hallazgo:

| Severidad | Criterio | Ejemplos |
|---|---|---|
| **Critical** | Bloquea un flujo de negocio o pierde datos | Página en blanco, 500 al enviar el form, ruta protegida accesible sin sesión, pago que cobra dos veces |
| **High** | Funcionalidad rota con workaround, o error visible al usuario | Botón que no hace nada, error de consola en cada carga, upload que falla con archivos grandes |
| **Medium** | Degradación real que no bloquea | Estado vacío sin mensaje, validación que llega tarde, mensaje de error genérico ("Error"), doble request |
| **Cosmetic** | Nada se rompe | Espaciado inconsistente, texto cortado, foco poco visible |

**Formato por bug (obligatorio):**

```
[SEVERIDAD] Título corto
  URL:        /ruta/exacta
  Repro:      1. Ir a X  2. Hacer Y  3. Observar Z
  Esperado:   qué debería pasar
  Observado:  qué pasa, con el mensaje literal de consola o red
  Evidencia:  screenshot + línea de consola/request
  Sospecha:   archivo:línea si el trazado es evidente (opcional, marcado como sospecha)
```

Un bug sin repro reproducible no entra al reporte: vuelve a intentarlo hasta
tener los pasos, o anótalo como "intermitente, no reproducible en N intentos" —
que es un dato distinto y también vale.

**Salud antes del loop:** cuenta los hallazgos por severidad. Ese es el punto de
partida contra el que se compara al final.

---

## Fase 4 — Loop de fixes atómicos

Solo si el usuario pidió arreglar (no en modo reporte). Se arregla por severidad
descendente: Critical, después High, después Medium. Cosmetic solo si el usuario
lo pide (o si es de `ui-review`).

**Un fix = un commit.** Nada de commits que arreglan tres cosas: si el tercero
rompe algo, hay que poder revertir solo ese.

Por cada bug:

1. **Causa raíz antes del fix.** Si el bug no es obvio en dos minutos de lectura,
   invoca `Skill(name=investigate)`. Nada de parches por síntoma.
2. **Aplicar el fix mínimo.** El que resuelve la causa, no el que aprovecha para
   refactorizar la zona.
3. **Re-verificar en vivo.** Vuelve a la URL, repite los pasos de repro exactos,
   confirma que el comportamiento esperado ocurre y que la consola sigue limpia.
   Sin esta re-verificación el fix no cuenta.
4. **Commit:** `fix(qa): <descripción> — <ruta afectada>`.

### Test de regresión (para bugs Critical y High)

Antes de escribir el test, traza el flujo de datos por el código que acabas de
arreglar:
- ¿Qué input o estado disparó el bug? (la precondición exacta)
- ¿Qué camino de código siguió? (qué ramas, qué llamadas)
- ¿Dónde se rompió? (la línea o condición que falló)
- ¿Qué otros inputs pegarían en el mismo camino? (casos borde alrededor del fix)

El test DEBE:
- Montar la precondición que disparó el bug (el estado exacto que lo rompía)
- Ejecutar la acción que lo expuso
- Afirmar el comportamiento correcto (NO "renderiza" ni "no tira excepción")
- Cubrir los casos borde adyacentes que encontraste al trazar (null, array vacío,
  valor límite)
- Llevar el comentario de atribución completo:

```
// Regression: <ID o slug del bug> — {qué se rompía}
// Encontrado por /qa-web el {YYYY-MM-DD}
```

Tipo de test según el bug:
- Error de consola / excepción JS / bug de lógica → unitario o de integración
- Form roto / falla de API / bug de flujo de datos → integración con
  request/response
- Bug visual con comportamiento JS (dropdown roto, animación) → test de componente
- CSS puro → saltar (lo atrapan las re-corridas de QA)

Mockea todas las dependencias externas (BD, API, colas, sistema de archivos).

Nombres autoincrementales para evitar colisiones: revisa los
`{name}.regression-*.test.{ext}` existentes y toma el máximo + 1.

Corre **solo** el archivo de test nuevo. Si pasa, commitea:
`test(qa): regression test for <bug> — {desc}`. Si falla, arréglalo una vez; si
sigue fallando, bórralo y difiere el test. Si te lleva más de 2 minutos de
exploración, sáltalo y difiérelo.

### Autorregulación: heurística WTF-likelihood

Cada 5 fixes (o inmediatamente después de cualquier revert), calcula:

```
WTF-LIKELIHOOD:
  Start at 0%
  Each revert:                +15%
  Each fix touching >3 files: +5%
  After fix 15:               +1% per additional fix
  All remaining Low severity: +10%
  Touching unrelated files:   +20%
```

**Si WTF > 20%: PARA de inmediato.** Muestra al usuario lo que llevas hecho y
pregunta si continuar. La heurística existe porque el modo de falla del arreglo
automático no es arreglar mal un bug: es entrar en una espiral donde cada fix
genera dos bugs nuevos y nadie se da cuenta hasta que la rama es irrecuperable.

**Tope duro: 50 fixes.** Después de 50, detente sin importar qué quede pendiente.

**Exclusión:** los commits de test no cuentan para la heurística.

---

## Fase 5 — Reporte de salud antes/después

Al terminar:

1. Vuelve a recorrer todas las páginas afectadas por los fixes (no solo la del
   último).
2. Calcula el conteo final por severidad.
3. **Si el resultado final es PEOR que el inicial, avisa de forma prominente:**
   algo regresó y hay que revisar los commits del loop antes de seguir.

```
QA WEB — RESUMEN
════════════════
Base URL:   http://localhost:3000
Recorrido:  12 páginas · 3 flujos · 8 formularios

              Antes   Después
  Critical      2        0
  High          5        1
  Medium        7        4
  Cosmetic      3        3

Arreglados:      9 (9 commits + 4 tests de regresión)
Sin arreglar:    8  → 1 High diferido: <razón>
WTF-likelihood:  10% (bajo el umbral)

VEREDICTO: listo para revisión / bloqueado por <bug>
```

Cierra con la lista de bugs no arreglados y por qué (diferido, requiere decisión
de producto, fuera de alcance). Si queda algún Critical abierto, el veredicto es
**bloqueado**, sin matices.

## Reglas importantes

- **Evidencia o no pasó.** Todo hallazgo lleva repro y captura; todo fix lleva
  re-verificación en vivo.
- **Un fix, un commit.** Sin excepciones.
- **Causa raíz antes del parche.** Si no la tienes, `investigate`.
- **Datos de prueba `@e2e.local`.** Jamás datos de un cliente real, ni en forms
  ni en el reporte.
- **No es el gate visual.** Si el hallazgo es "se ve mal" y no "no funciona", va
  a `ui-review`.
- **No reemplaza la suite e2e.** Esto es exploración dirigida; los flujos que
  importan terminan como tests programados (`npm run test:e2e`), y ahí manda
  `qa-engineer`.
- **En el VPS, siempre headless.** No hay GUI: Playwright MCP con `--headless` y
  nada de `claude-in-chrome`.
