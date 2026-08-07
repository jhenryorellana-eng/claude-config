---
name: encolar-tarea
description: >
  Encola una tarea para el asistente autónomo del VPS (cola ~/orchestrator de
  x-legal). Usa cuando el usuario diga "encola", "mándale esta tarea al VPS",
  "que el asistente haga X", "agrega a la cola", o describa trabajo que debe
  ejecutarse desatendido. Convierte el pedido en una tarea con criterio de
  aceptación verificable (plantilla docs/plantillas/TAREA.md del repo x-legal),
  la valida y la deposita en pending/ del VPS por SSH.
---

# Encolar una tarea en el VPS

## Principio

En la cola no hay conversación: **una tarea sin criterio de aceptación
verificable es una tarea que el agente interpreta solo**. Tu trabajo aquí es
convertir el pedido del usuario en una orden autosuficiente, no transcribirlo.

## Flujo

1. **Clasifica el pedido.**
   - ¿Grande, ambiguo o de alto riesgo (auth/pagos/RLS/migraciones)? → propona
     encolar primero una tarea de INVESTIGACIÓN con la estructura de
     `docs/plantillas/SPEC-INVESTIGACION.md` (spec → PR → aprobación → recién
     implementar).
   - ¿Acotado y claro? → tarea directa con la estructura de
     `docs/plantillas/TAREA.md`.
2. **Redacta la tarea** siguiendo la plantilla correspondiente del repo
   (`C:\Users\mauri\Documents\Trabajos\usalatino-v2\docs\plantillas\`):
   QUÉ imperativo + contexto de 1-2 frases + **criterios de aceptación
   comprobables** (tests que pasan, flujos que funcionan) + límites explícitos.
   Si el usuario no dio criterios, PROPONLOS tú y muéstraselos antes de enviar.
3. **Valida antes de enviar:**
   - Sin secretos ni PII de clientes en el texto (usa `U26-XXXXXX`).
   - Sin `\r` (la tarea viaja de Windows a Linux — trampa conocida).
   - Una tarea = un objetivo. Dos objetivos = dos tareas encoladas en orden.
4. **Envía** (el nombre del archivo: `YYYYMMDD-HHMMSS-<slug-ascii>.md`):
   ```bash
   # escribir la tarea a un archivo temporal local, luego:
   tr -d '\r' < <archivo-local> | ssh vps 'cat > /tmp/tarea-nueva.md && mv /tmp/tarea-nueva.md ~/orchestrator/projects/x-legal/queue/pending/<nombre>.md'
   ```
5. **Confirma**: `ssh vps 'ls ~/orchestrator/projects/x-legal/queue/pending/'`
   y reporta al usuario: nombre encolado + criterios con los que quedó.

## Recuerda

- La cola procesa en serie por proyecto; el resultado llega como **PR en
  GitHub** + aviso por Telegram. La revisión se hace con la skill `revisar-pr`.
- Si la cola está apagada (`systemctl --user is-enabled queue@x-legal` →
  disabled), la tarea queda esperando en pending/ — avisa al usuario que el
  encendido está en su checklist (`Documents\vps\05-PASOS-FINALES-HUMANO.md`).
