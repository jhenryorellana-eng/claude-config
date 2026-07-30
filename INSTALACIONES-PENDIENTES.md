# Estado del sistema multi-agente — Mauri

Última actualización: 2026-05-26

---

## ✅ Sistema instalado y funcional

- **5 CLI tools globales:** uv 0.11.16 · specify 0.8.13 · claude-mem 13.3.0 · uipro 2.2.3 · bun 1.3.14
- **10 agentes globales** en `~/.claude/agents/`
- **56 skills globales** en `~/.claude/skills/` (gstack + custom + plugins)
- **18 plugins activos** incluyendo claude-mem
- **4 MCPs UI conectados:** shadcn-ui, magic-ui, universal-icons, motion (free tier)
- **CLAUDE.md global** como router central
- **9 carpetas `agent-memory/<agente>/MEMORY.md`** — sistema de memoria manual

---

## ⚠️ claude-mem: INSTALADO pero INACTIVO en Windows

**Estado verificado (2026-05-25 23:49):**
- ✅ Plugin v13.3.0 instalado en `~/.claude/plugins/marketplaces/thedotmack/`
- ✅ Worker corriendo en `localhost:37777` (HTTP 200)
- ✅ Plugin habilitado en `settings.json`
- ❌ **Captura automática NO funciona** — bug conocido upstream específico de Windows nativo
- 📍 Archivo marker: `~/.claude-mem/CAPTURE_BROKEN` confirma el fallo
- 📊 DB sin escrituras: 0 observations capturadas desde la instalación

### Causa raíz

Los hooks del plugin (`~/.claude/plugins/cache/thedotmack/claude-mem/13.3.0/hooks/hooks.json`) usan `"shell": "bash"` hardcodeado. Cuando Claude Code en Windows ejecuta el hook, el payload `stdin` se pierde al cruzar la frontera Windows↔bash (sea Git Bash o WSL bash). `bun-runner.js` detecta `payload byte length: 0` y crea el marker `CAPTURE_BROKEN`.

**Issues upstream relacionados:**
- https://github.com/thedotmack/claude-mem/issues/2188
- https://github.com/thedotmack/claude-mem/issues/1482
- https://github.com/thedotmack/claude-mem/issues/1560
- https://github.com/thedotmack/claude-mem/issues/2144
- https://github.com/anthropics/claude-code/issues/17424 (relacionado en Anthropic upstream)

### Decisión actual: dejar instalado y esperar fix

**Por qué dejarlo:**
- Worker consume solo 32 MB RAM
- Los hooks fallan silenciosamente (latencia menor en tool uses, no rompen flujo)
- Cuando llegue el fix upstream, solo `npx claude-mem update` y captura activa

**Por qué NO es urgente:**
- El sistema `agent-memory/<agente>/MEMORY.md` funciona en Windows
- Los 8 subagentes leen/escriben sus memorias manualmente sin hooks
- claude-mem aportaría captura automática pero no es bloqueante

### Cómo monitorear si llegó el fix

1. **Revisar releases:** https://github.com/thedotmack/claude-mem/releases — buscar mención a "Windows", "stdin", "issue #2188" cerradas
2. **Actualizar cuando salga nueva versión:**
   ```powershell
   npx claude-mem update
   ```
3. **Test rápido (después de usar Claude Code unos 10 min):**
   ```powershell
   $db = Get-Item "$env:USERPROFILE\.claude-mem\claude-mem.db"
   $minutesAgo = ((Get-Date) - $db.LastWriteTime).TotalMinutes
   if ($minutesAgo -lt 30) { "OK Capturando" } else { "Sigue roto ($([math]::Round($minutesAgo)) min sin escritura)" }
   ```

### Si en el futuro decides desinstalarlo

```powershell
npx claude-mem uninstall
Copy-Item "$env:USERPROFILE\.claude\settings.json.backup-before-claude-mem" "$env:USERPROFILE\.claude\settings.json"
```

El backup pre-instalación existe en `~/.claude/settings.json.backup-before-claude-mem`.

---

## 📝 Memoria persistente que SÍ funciona ahora (sin claude-mem)

Tu sistema de `agent-memory/` es la fuente activa de memoria persistente. Cada subagente:

1. **Al inicio de cada invocación:** lee `~/.claude/agent-memory/<su-nombre>/MEMORY.md`
2. **Durante el trabajo:** descubre patrones, conventions, CDN URLs, etc.
3. **Al final:** escribe nuevos hallazgos en su MEMORY.md (sin duplicar conocimiento de CLAUDE.md global)

Carpetas activas:
- `agent-memory/orchestrator/MEMORY.md` — grafos exitosos
- `agent-memory/ui-master/MEMORY.md` — patrones UI premium
- `agent-memory/ui-builder/MEMORY.md` — patrones UI standard
- `agent-memory/disruptive-landing-builder/MEMORY.md` — CDN URLs GSAP/Lenis, patrones landings
- `agent-memory/backend-builder/MEMORY.md` — patrones API/DB
- `agent-memory/qa-engineer/MEMORY.md` — patrones testing
- `agent-memory/security-auditor/MEMORY.md` — vulnerabilidades recurrentes
- `agent-memory/code-reviewer/MEMORY.md` — bug patterns
- `agent-memory/devops-engineer/MEMORY.md` — deploy patterns

Estos archivos crecen orgánicamente con el uso. **No requieren claude-mem para funcionar.**

---

## 🚀 Cómo trabajar con el sistema (ahora mismo)

### Sin claude-mem captura automática:
1. `cd <cualquier carpeta del disco C>`
2. `claude` (abrir Claude Code)
3. Escribir tu pedido — el orchestrator se dispara con triggers automáticos
4. Los agentes leen/escriben sus MEMORY.md durante el trabajo
5. CLAUDE.md global se carga automáticamente

### Con worker de claude-mem activo (web viewer útil aunque captura rota):
- Abrir `http://localhost:37777` — ver lo que SÍ capturó claude-mem antes del bug
- Útil como referencia histórica, no para captura nueva

### Si cierras y reabres PC:
- Todo se persiste (agentes, skills, MCPs, MEMORY.md, plugins, settings)
- Solo el worker de claude-mem se apaga
- Para reiniciar worker: `npx claude-mem start` (opcional, solo para el viewer)

---

## 🔧 Tareas opcionales pendientes

### Voicebox (voz local con MCP) — NO instalado
Requiere descarga manual desde voicebox.sh (app desktop Windows). Solo útil si quieres dictar specs o generar narración.

### Skills opcionales de Motion AI Kit
Requieren TOKEN personal (gratis registrándote en motion.dev):
```bash
curl -sL "https://api.motion.dev/registry/skills/motion-ai-kit?token=TU_TOKEN" -o /tmp/ai-kit.sh && bash /tmp/ai-kit.sh
```
Skills: `/motion`, `/motion-audit`, `/css-spring`, `/see-transition`.

### MCP Motion+ ($ pago) — NO instalado
Free tier ya conectado. Upgrade desbloquea acceso al código fuente de 370+ animaciones.
