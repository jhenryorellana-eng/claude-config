---
name: brainstorm
description: >
  Explora intención, requisitos y alternativas ANTES de diseñar o construir algo
  nuevo. Una pregunta a la vez (AskUserQuestion), propone 2-3 enfoques con
  trade-offs y cierra con un brief acordado. Usa cuando el usuario diga
  "brainstorm", "lluvia de ideas", "explora qué construir", "no sé bien qué
  quiero", "ayúdame a definir esta feature", o cuando un pedido de feature sea
  ambiguo (sin criterios de aceptación deducibles). NO es para planificar lo ya
  decidido (eso es write-plan) ni para decisiones visuales (design-system).
---

# Brainstorm — de la idea al brief

## Principio

Un pedido ambiguo no se arregla escribiendo código rápido: se arregla
preguntando. Esta fase termina con un **brief acordado**, no con una
implementación empezada.

## Regla dura: aquí no se escribe código

Mientras dure el brainstorm no se crea ni se edita ningún archivo de
producción, no se instala nada, no se hace scaffolding y no se invoca ninguna
skill de construcción. Se permite leer el repo (Read/Grep/Glob) y buscar en la
web para informar las preguntas.

El motivo no es ceremonial: cualquier código escrito antes del acuerdo se
convierte en un ancla. Después se defiende lo escrito en vez de discutir lo
correcto.

Si a mitad del brainstorm queda claro que el trabajo era trivial y ya está
decidido, dilo y sal de la skill; no la uses como trámite.

## Fase 1 — Contexto antes de la primera pregunta

Antes de preguntar nada, mira lo que ya existe: archivos y módulos del área
afectada, `docs/historial/` si el repo lo tiene, commits recientes de la zona.
Una pregunta cuya respuesta está en el repo quema el turno del usuario.

Si el pedido describe varios subsistemas independientes ("una plataforma con
chat, facturación y analítica"), no refines detalles todavía: propón la
descomposición primero y haz brainstorm del primer subsistema.

## Fase 2 — Una pregunta por turno

- **Una sola pregunta por mensaje.** Si un tema necesita tres preguntas, son
  tres turnos.
- Usa `AskUserQuestion` con **opciones cerradas** (2-4 alternativas concretas
  con su consecuencia), no preguntas abiertas del tipo "¿qué te gustaría?".
  Elegir es más barato que redactar.
- Prioriza por lo que cambia el diseño: propósito, usuario real, restricciones
  duras, qué queda fuera, cómo se sabrá que funcionó. Las preferencias de
  detalle van al final o no van.
- Corta cuando ya puedas escribir criterios de aceptación verificables. Seguir
  preguntando después de eso es hacer perder el tiempo.

## Fase 3 — Al menos dos enfoques, con SAFE y RISK

Nunca presentes una sola alternativa: una opción sin comparación no es una
decisión, es una imposición. Propón 2-3 enfoques y para cada uno di qué cuesta
y qué se gana. Lidera con tu recomendación y explica por qué.

Presenta el contraste con esta forma:

```
ENFOQUE SEGURO — [nombre]
  Qué es: [una línea]
  Ganas: [lo predecible: menos riesgo, menos trabajo, patrón ya conocido aquí]
  Cuesta: [lo que se resigna: techo bajo, más deuda después, resultado genérico]

ENFOQUE ARRIESGADO — [nombre]
  Qué es: [una línea]
  Riesgo deliberado 1: [qué convención se rompe, por qué vale la pena,
                        qué se pierde si sale mal]
  Riesgo deliberado 2: [ídem]
  Ganas: [lo que solo se consigue por acá]

RECOMENDACIÓN: [cuál y por qué, en dos frases]
```

El enfoque arriesgado necesita **al menos dos riesgos deliberados y
justificados**. Un "arriesgado" que solo es el seguro con más trabajo no es una
alternativa: es relleno. Aplica YAGNI a los dos: saca de cada enfoque todo lo
que nadie pidió.

## Fase 4 — El brief

Cierre de la skill. 10-15 líneas, en el formato de `docs/plantillas/TAREA.md`
para que se pueda encolar tal cual sin reescribirlo:

```
QUÉ: [una o dos frases imperativas con el cambio pedido, nombrando el módulo
o la ruta si se conoce]

POR QUÉ: [el problema de usuario o negocio, 1-2 frases]

ENFOQUE ELEGIDO: [cuál de los propuestos y en una frase por qué; nombra el
descartado para que no se re-litigue después]

Criterio de aceptación:
- [comprobable 1: un test que pasa, un flujo que funciona, un archivo que existe]
- [comprobable 2]
- [comprobable 3]

Límites:
- NO toques [área fuera de alcance]

Supuestos: [solo si quedó algo sin confirmar — ver modo desatendido]
```

Un criterio de aceptación es verificable o no existe. "Que quede bien",
"mejorar la experiencia" y "que sea rápido" no son criterios; "LCP bajo 2.5 s
en móvil", "el login funciona con dos países distintos" y "vitest en verde" sí.

Pide confirmación explícita del brief antes de dar por cerrada la fase.

## Handoff

Con el brief aprobado, una de dos:

- **`write-plan`** — si se va a implementar acá, con pasos, archivos y tests.
- **`encolar-tarea`** — si el trabajo se manda a la cola del VPS. El brief ya
  está en el formato correcto.

Nunca saltes del brainstorm directo a construir: falta el plan o falta la cola.

## Modo desatendido (cola del VPS)

En la cola no hay nadie a quien preguntar. Si esta skill corre sin usuario
interactivo:

- No uses `AskUserQuestion`. Cada pregunta que habrías hecho se convierte en un
  **supuesto documentado** en la sección `Supuestos` del brief, con la
  alternativa que descartaste.
- Elige siempre el enfoque seguro. Un riesgo deliberado sin nadie que lo apruebe
  no es un riesgo asumido, es un riesgo impuesto.
- Si los supuestos son tantos que el brief se vuelve ficción (más de tres
  decisiones de producto inventadas), no sigas: entrega el brief marcado como
  `BLOQUEADO — requiere decisiones humanas` con la lista de preguntas abiertas.
