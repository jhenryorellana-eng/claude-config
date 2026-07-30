#!/usr/bin/env node
// Stable-path shim for the kimi-plugin-cc PreToolUse approval hook.
//
// Why this file exists:
//
//   /kimi:setup refuses to write a hook path containing backslashes into
//   kimi-code's TOML config (PATH_FORBIDDEN_RE in runtime/commands/setup.ts),
//   and on Windows the auto-resolved path always has them — the plugin's own
//   threat model excludes Windows. The documented escape hatch is the
//   KIMI_PLUGIN_CC_HOOK_SCRIPT override, but the real hook lives under a
//   VERSION-STAMPED directory (.../kimi/<version>/dist/hooks/approval-hook.js),
//   so every plugin update would invalidate a hardcoded override.
//
//   This shim sits at a stable path and resolves the newest installed plugin
//   version at run time, so plugin updates need no reconfiguration.
//
// Path requirements this file must keep satisfying (plugin internals):
//   - basename MUST stay `approval-hook.js`      -> isOurApprovalHookCommand()
//   - path MUST contain a `/kimi-plugin-cc/` segment -> isOurApprovalHookCommand()
//   - path MUST contain a `/.claude/` segment    -> hostIdFromHookScript() = "claude-code"
//
// Hook contract (see the real approval-hook.js header):
//   stdin: JSON payload | exit 0 = allow | exit 2 = deny (stderr is the reason)
//   any other exit code = fail-OPEN (kimi-code allows the tool call).
//   Therefore every failure path here exits 2: a broken shim must block, not
//   silently disable the plugin's read-only enforcement.

const fs = require("node:fs");
const path = require("node:path");
const { pathToFileURL } = require("node:url");

// <claude-dir>/kimi-plugin-cc/approval-hook.js -> <claude-dir>
const CLAUDE_DIR = path.dirname(__dirname);
const VERSIONS_DIR = path.join(
  CLAUDE_DIR,
  "plugins",
  "cache",
  "kimi-marketplace",
  "kimi",
);
const HOOK_SUBPATH = path.join("dist", "hooks", "approval-hook.js");

/**
 * Pick the hook script to run: highest semantic version that actually ships
 * the hook artifact. Numeric per-segment compare, so 1.10.0 > 1.9.2 (a plain
 * string sort would get that backwards). Returns null when nothing qualifies.
 */
function resolveRealHook() {
  let entries;
  try {
    entries = fs.readdirSync(VERSIONS_DIR, { withFileTypes: true });
  } catch {
    return null;
  }

  const candidates = [];
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    const parsed = /^(\d+)\.(\d+)\.(\d+)/.exec(entry.name);
    if (parsed === null) continue;
    const hookPath = path.join(VERSIONS_DIR, entry.name, HOOK_SUBPATH);
    if (!fs.existsSync(hookPath)) continue;
    candidates.push({
      hookPath,
      order: [Number(parsed[1]), Number(parsed[2]), Number(parsed[3])],
    });
  }

  candidates.sort((a, b) => {
    for (let i = 0; i < 3; i += 1) {
      if (a.order[i] !== b.order[i]) return b.order[i] - a.order[i];
    }
    return 0;
  });

  return candidates.length > 0 ? candidates[0].hookPath : null;
}

const realHook = resolveRealHook();

if (realHook === null) {
  process.stderr.write(
    "kimi-plugin-cc safety hook: shim could not locate an installed " +
      `approval-hook.js under ${VERSIONS_DIR}. Denying the tool call because ` +
      "a hook that cannot run would otherwise fail open. Reinstall the kimi " +
      "plugin, then re-run /kimi:setup.\n",
  );
  process.exit(2);
}

// Dynamic import: the real hook is ESM (dist/package.json declares
// "type":"module") and executes on load. pathToFileURL is required — ESM
// import() rejects a bare Windows path like C:\... as an unknown protocol.
// Loading it in-process preserves stdin, stderr and the exit code, and the
// module keeps its OWN import.meta.url, so its sibling imports still resolve.
import(pathToFileURL(realHook).href).catch((err) => {
  process.stderr.write(
    "kimi-plugin-cc safety hook: shim failed to load " +
      `${realHook}: ${err && err.message ? err.message : String(err)}. ` +
      "Denying the tool call.\n",
  );
  process.exit(2);
});
