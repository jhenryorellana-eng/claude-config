---
name: postmortem
description: >
  Postmortem blameless de un incidente de producción YA ocurrido o mitigado:
  reconstruye el timeline con evidencia (logs, deploys, alertas), cuantifica
  impacto, aplica 5-whys apoyándose en la skill investigate para la causa raíz
  técnica, identifica el gap de detección (¿por qué no lo vimos antes?) y produce
  acciones correctivas con dueño y severidad, proponiendo encolarlas con
  encolar-tarea. Usa cuando se diga "postmortem", "incidente de producción", "se
  cayó prod", "análisis del incidente", "por qué se cayó". NO es debugging de
  desarrollo (investigate) ni la retro semanal (retro).
---

# Postmortem — qué pasó, por qué, y qué cambia

Esta skill se usa **después** de que el incidente terminó o se mitigó. Si
producción sigue caída, esto no es lo que necesitas: mitiga primero, entiende
después.

## Regla blameless (no negociable)

El postmortem analiza **sistemas, no personas**. Un incidente causado por "alguien
corrió la migración sin revisar" es en realidad un incidente causado por un
sistema que permite correr migraciones sin revisión. La pregunta nunca es quién
se equivocó, sino qué hizo que ese error fuera posible, fácil o invisible.

Consecuencias prácticas:
- Escribe "el deploy de las 14:32 introdujo X", no "Fulano rompió X".
- Cada acción correctiva cambia un sistema (un check, una alerta, un gate), no
  una conducta ("tener más cuidado" no es una acción correctiva).
- Si el análisis termina en "error humano", no terminaste: sigue preguntando por
  qué el sistema lo permitió.

Esto no es cortesía. Un postmortem que reparte culpas hace que el próximo
incidente se reporte tarde o no se reporte.

---

## Estructura del documento (6 secciones)

### 1. Resumen e impacto

Dos o tres frases que cualquiera pueda leer sin contexto: qué se rompió, para
quién, cuánto duró. Después, el impacto en métricas:

- **Duración:** desde el primer efecto en usuarios hasta la mitigación completa.
- **Alcance:** cuántos usuarios, qué porcentaje del tráfico, qué funcionalidad.
- **Datos:** ¿se perdió algo? ¿quedó algo inconsistente? Esta línea es
  obligatoria aunque la respuesta sea "no".
- **Dinero:** cobros duplicados, ventas perdidas, costo de API desbocado, si
  aplica.
- **Severidad:** SEV1 (producción caída o pérdida de datos) · SEV2
  (funcionalidad crítica rota con workaround) · SEV3 (degradación acotada).

Si un número no se puede establecer, escribe "no cuantificado" y por qué. No
inventes cifras: un impacto inflado o desinflado envenena la priorización de las
acciones correctivas.

### 2. Timeline

Cada evento lleva **timestamp, qué pasó y la fuente de la que salió**. Un evento
sin fuente es una suposición y va marcado como tal.

```
| Hora (UTC) | Evento                                       | Fuente                    |
|------------|----------------------------------------------|---------------------------|
| 14:32      | Deploy de <sha> a producción                 | Vercel deployments        |
| 14:35      | Primeros 500 en /api/casos                   | Vercel runtime logs       |
| 14:51      | Usuario reporta que no puede subir documentos| Mensaje del cliente       |
| 15:04      | Se identifica la migración faltante          | Sesión de investigación   |
| 15:12      | Rollback del deploy                          | Vercel deployments        |
| 15:14      | Tasa de error vuelve a cero                  | Vercel runtime logs       |
```

Fuentes de las que se reconstruye el timeline:
- Historial de deploys (Vercel: `list_deployments`, `get_deployment_build_logs`)
- Logs de runtime y errores (`get_runtime_logs`, `get_runtime_errors`)
- Logs de la base de datos y del proveedor (Supabase Logs Explorer)
- `git log` de la ventana del incidente, para ligar cada evento a un commit
- Mensajes de usuarios o clientes (sin PII: `U26-XXXXXX` / `[CLIENTE-XX]`)
- Alertas que dispararon — y, muy importante, alertas que **no** dispararon

Dos marcas explícitas en el timeline: **T-detección** (cuándo alguien se enteró)
y **T-inicio** (cuándo empezó realmente). La distancia entre ambas es el insumo
de la sección 5.

### 3. Causa raíz

La investigación técnica **se delega**: invoca `Skill(name=investigate)` sobre el
síntoma concreto. Esa skill tiene la disciplina de las cuatro fases y la Ley de
Hierro (sin causa raíz no hay fix); el postmortem no la duplica.

Lo que este documento aporta es el resultado de esa investigación escrito para
alguien que no estuvo: qué cadena de causas llevó del cambio al síntoma, con las
referencias `archivo:línea` y los commits que la prueban.

Una causa raíz válida explica **todos** los hechos del timeline. Si explica el
500 pero no explica por qué empezó a las 14:35 y no a las 14:32, todavía falta
un eslabón.

### 4. Factores contribuyentes (5-whys)

La causa raíz técnica rara vez alcanza. Encadena los porqués hasta llegar a algo
sistémico y accionable:

```
¿Por qué se cayó /api/casos?           → una query referenciaba una columna inexistente
¿Por qué no existía la columna?        → la migración no se aplicó a producción
¿Por qué no se aplicó?                 → el deploy de código y la migración van por caminos separados
¿Por qué van separados?                → las migraciones a prod son un acto manual y deliberado
¿Por qué nada detuvo el deploy?        → no hay check que verifique que el esquema desplegado tiene lo que el código pide
```

El quinto porqué de este ejemplo es la acción correctiva real. Los primeros
cuatro son contexto.

**Reglas del ejercicio:** para cuando llegues a algo que puedas cambiar (no antes
y no mucho después). Si un porqué te lleva a una persona, reformúlalo hacia el
sistema. Pueden salir varias cadenas en paralelo: un incidente casi siempre tiene
más de un factor contribuyente, y listarlos todos es mejor que elegir un culpable
técnico único.

### 5. Gap de detección

La pregunta de esta sección es distinta a la de la causa raíz: **¿por qué no lo
vimos antes, y cómo nos enteramos?**

- ¿Cómo se detectó realmente? (alerta / usuario / casualidad). Si fue un usuario,
  eso ya es un hallazgo.
- ¿Cuánto pasó entre T-inicio y T-detección?
- ¿Qué señal existía en ese momento que nadie estaba mirando?
- ¿Qué alerta habría disparado y por qué no existía o no disparó?

Cierra con una **propuesta concreta de monitoreo**, no con una intención:

> ❌ "Deberíamos monitorear mejor los errores de API."
> ✅ "Alerta cuando la tasa de 5xx de cualquier ruta bajo `/api/` supere el 1% en
> una ventana de 5 minutos, con notificación a <canal>. Habría disparado a las
> 14:37, 14 minutos antes del reporte del usuario."

Toda propuesta dice: qué se mide, con qué umbral, en qué ventana, a quién avisa,
y cuándo habría disparado en este incidente. La última parte es la que la valida:
si la alerta propuesta no habría atrapado el incidente que acabas de analizar, no
es la alerta correcta.

### 6. Acciones correctivas

Cada acción lleva **qué, dueño, fecha y severidad**:

```
| # | Acción                                                        | Dueño   | Para   | Sev |
|---|---------------------------------------------------------------|---------|--------|-----|
| 1 | Check de CI que valide que el esquema de prod tiene las columnas que el código pide | devops  | 20-08  | P0  |
| 2 | Alerta de tasa de 5xx por ruta (ver sección 5)                | devops  | 20-08  | P0  |
| 3 | Test de integración que cubra el listado de casos con esquema desactualizado | qa      | 27-08  | P1  |
```

- **P0** — evita la repetición del mismo incidente. Va primero, sin excepción.
- **P1** — reduce el impacto o el tiempo de detección la próxima vez.
- **P2** — mejora general que el incidente hizo visible.

Criterios: cada acción es verificable (alguien puede decir sin ambigüedad si está
hecha), cambia un sistema y no una intención, y tiene un dueño concreto. Una
acción sin dueño no existe.

Si el postmortem no produce al menos una acción P0, revisa la sección 4: o el
incidente era genuinamente irrepetible (raro), o la cadena de porqués se cortó
temprano.

---

## Salida

El documento se guarda en `docs/historial/` del repo como
`postmortem-YYYY-MM-DD-<slug>.md`, siguiendo la plantilla de historial del
proyecto.

**Antes de guardar, relee buscando PII.** Los incidentes de producción arrastran
datos de clientes reales en los logs: nombres, correos, números de expediente,
contenido de documentos. Todo eso se reemplaza por `U26-XXXXXX` o `[CLIENTE-XX]`.
Los correos `@e2e.local` sí pueden quedar. Lo mismo con secretos que hayan
aparecido en un log: `<redactado>`.

Si el repo no tiene `docs/historial/`, imprime el postmortem y dilo, en vez de
inventar la estructura.

## Cierre: encolar las acciones correctivas

El momento de convertir las acciones en tareas es **ahora**, mientras el contexto
está fresco. Un postmortem cuyas acciones nunca se ejecutan es un documento que
solo sirvió para sentirse mejor.

Ofrece `Skill(name=encolar-tarea)` para cada acción P0 y P1, con el criterio de
aceptación verificable ya redactado desde la sección 6 (la acción correctiva
buena ya está escrita como criterio de aceptación). Si el usuario prefiere
encolarlas después, dilo explícitamente en el documento para que quede
registrado que quedaron sin encolar.

## Reglas importantes

- **Blameless siempre.** Sistemas, no personas. Si el análisis termina en "error
  humano", no terminaste.
- **Cada evento del timeline cita su fuente.** Sin fuente es suposición y va
  marcada como tal.
- **La causa raíz se delega a `investigate`.** Este documento la narra, no la
  descubre por su cuenta.
- **El gap de detección produce una alerta concreta**, con umbral, ventana,
  destinatario y la verificación de que habría disparado en este incidente.
- **Sin PII, sin secretos.** Los logs de producción son la fuente de PII más
  probable de todo el sistema.
- **Al menos una acción P0**, con dueño y fecha, encolada antes de cerrar.
- **Esto no es debugging** (eso es `investigate`) **ni la retro semanal** (eso es
  `retro`).
