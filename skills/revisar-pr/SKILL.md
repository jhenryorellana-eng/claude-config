---
name: revisar-pr
description: >
  Ejecuta la revisión y el merge de un PR de x-legal siguiendo el gate completo
  de docs/plantillas/REVISION-PR.md. Usa cuando el usuario diga "revisa el PR
  N", "revisemos lo que hizo el asistente", "mergea el PR", o después de que la
  cola del VPS abra un PR. ES EL GATE DE MAIN: no hay branch protection en este
  plan de GitHub, así que esta skill se NIEGA a mergear con checks en rojo o
  con migraciones sin aplicar a prod.
---

# Revisar y mergear un PR (el gate de `main`)

## Reglas inquebrantables

1. **Checks verdes o no hay merge.** `gh pr checks <N>` con CUALQUIER check en
   rojo → se arregla en la rama o se re-encola la tarea. Jamás "mergeamos por
   ahora". Acostumbrarse al rojo es cómo entra el PR roto de verdad.
2. **Un merge a la vez.** Si hay varios PRs verdes, se procesan en serie y el
   siguiente se actualiza contra main (`gh pr update-branch`) antes de
   revisarlo — dos PRs verdes por separado pueden romper main juntos.
3. **Migración a prod ANTES del merge**, jamás después (si se mergea primero,
   Vercel despliega código que espera columnas inexistentes). Y toda migración
   debe ser retrocompatible — un `DROP`/`RENAME`/`NOT NULL` sin default
   devuelve la tarea (destructivo = 3 despliegues).
4. **La decisión de mergear es del usuario.** Tú ejecutas el checklist, le
   presentas la evidencia y ÉL da el OK final. Nunca mergees sin su
   confirmación explícita en el turno.

## Flujo (el detalle canónico vive en `docs/plantillas/REVISION-PR.md` del repo)

1. `gh pr checkout <N>` + `gh pr update-branch <N>` si main avanzó.
2. `gh pr checks <N>` — TODO verde (regla 1).
3. Leer el diff completo. Verificar: ¿cumple el criterio de aceptación de la
   tarea CON EVIDENCIA? ¿trae su entrada de `docs/historial/` (sin PII)?
   ¿el alcance es el pedido y nada más?
4. **Si toca auth, pagos, RLS o migraciones** → segunda opinión obligatoria:
   `/codex review` y/o despacho a `code-reviewer` + `security-auditor`.
5. Verificación en vivo si toca UI: preview de Vercel o `npx next dev -p 3100`
   + recorrido del flujo con Playwright MCP.
6. Migraciones (si las hay): leerlas ENTERAS con su rollback → `supabase link`
   a prod (verificar con `projects list`) → `db push` → `npm run db:types` →
   commit de tipos → **volver a linkear dev SIEMPRE**.
7. Con el OK del usuario: `gh pr merge <N> --squash`.
8. Post-merge: `node scripts/gen-historial-index.mjs` + `graphify update .` +
   verificar `https://x-legal.usalatinoprime.com` (y si hubo e2e: dashboard de
   prod SIN registros nuevos inesperados).
9. Reportar: qué entró, qué se verificó, qué quedó pendiente (follow-ups →
   proponer encolarlos con `encolar-tarea` ahora, antes de perder el contexto).
