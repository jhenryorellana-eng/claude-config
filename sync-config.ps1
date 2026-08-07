# sync-config.ps1 - sincroniza claude-config (repo) <-> C:\Users\mauri\.claude (live)
# Modos:
#   .\sync-config.ps1 diff      -> muestra divergencias (no toca nada)
#   .\sync-config.ps1 apply     -> repo  -> live   (el repo manda)
#   .\sync-config.ps1 capture   -> live  -> repo   (para commitear cambios hechos en vivo)
#
# Por que robocopy: copia byte a byte, inmune a la trampa de codificacion de
# PowerShell 5.1 (Get-Content/Set-Content corrompen UTF-8 con acentos).
# Por que no junctions: ~/.claude mezcla config versionable con estado runtime
# de Claude Code (projects/, teams/, cache/); un enlace de carpeta arrastraria
# todo y los symlinks de archivo requieren admin en Windows.
#
# NOTA: settings.pc.json (repo) <-> settings.json (live) es el unico rename.
# skills\gstack\ (vendored) y todo lo runtime quedan FUERA del manifiesto.

param([Parameter(Mandatory = $true)][ValidateSet('diff', 'apply', 'capture')][string]$Mode)

$repo = 'C:\Users\mauri\claude-config'
$live = 'C:\Users\mauri\.claude'

# Manifiesto: pares de carpetas espejadas (repo-subdir, live-subdir)
$dirs = @(
    @{ repo = 'agents';         live = 'agents' },
    @{ repo = 'skills';         live = 'skills' },
    @{ repo = 'hooks';          live = 'hooks' },
    # agent-memory es MUTABLE en runtime (los agentes aprenden en vivo):
    # solo viaja live -> repo (capture/diff); apply la OMITE para no pisotear
    # aprendizajes con una copia vieja del repo.
    @{ repo = 'agent-memory';   live = 'agent-memory'; captureOnly = $true },
    @{ repo = 'kimi-plugin-cc'; live = 'kimi-plugin-cc' }
)
# Archivos sueltos (repo-file, live-file)
$files = @(
    @{ repo = 'CLAUDE.md';        live = 'CLAUDE.md' },
    @{ repo = 'TEAM-TEMPLATES.md'; live = 'TEAM-TEMPLATES.md' },
    @{ repo = 'settings.pc.json'; live = 'settings.json' }
)
# Exclusiones dentro de skills (vendored / regenerable)
$skillsExclude = @('gstack')

$rcBase = @('/NJH', '/NJS', '/NDL', '/NP')
$global:drift = 0

function Sync-Dir($src, $dst, $excludeDirs, $listOnly) {
    $args = @($src, $dst, '/MIR') + $rcBase
    foreach ($x in $excludeDirs) { $args += @('/XD', (Join-Path $src $x), (Join-Path $dst $x)) }
    if ($listOnly) { $args += '/L' }
    $out = & robocopy @args 2>&1
    $changed = $out | Where-Object { $_ -match '^\s*(Nuevo|New|\*EXTRA|Newer|Older|Modificado|Modified|Mas nuevo|Mas antiguo)' }
    if ($LASTEXITCODE -ge 8) { Write-Error "robocopy fallo ($LASTEXITCODE): $src -> $dst" }
    elseif ($changed) {
        $global:drift += @($changed).Count
        Write-Host "-- $src -> $dst" -ForegroundColor Yellow
        $changed | ForEach-Object { Write-Host "   $_" }
    }
}

function Sync-File($src, $dst, $listOnly) {
    if (-not (Test-Path $src)) { Write-Host "   FALTA ORIGEN: $src" -ForegroundColor Red; $global:drift++; return }
    $same = (Test-Path $dst) -and
        ((Get-FileHash $src -Algorithm SHA256).Hash -eq (Get-FileHash $dst -Algorithm SHA256).Hash)
    if ($same) { return }
    $global:drift++
    Write-Host "-- $src -> $dst (difiere)" -ForegroundColor Yellow
    if (-not $listOnly) {
        Copy-Item $src $dst -Force   # Copy-Item es byte a byte: seguro para UTF-8
        Write-Host '   copiado'
    }
}

$listOnly = ($Mode -eq 'diff')
foreach ($d in $dirs) {
    if ($d.captureOnly -and $Mode -eq 'apply') { continue }
    if ($Mode -eq 'capture') { $src = Join-Path $live $d.live; $dst = Join-Path $repo $d.repo }
    else { $src = Join-Path $repo $d.repo; $dst = Join-Path $live $d.live }
    $excl = if ($d.repo -eq 'skills') { $skillsExclude } else { @() }
    Sync-Dir $src $dst $excl $listOnly
}
foreach ($f in $files) {
    if ($Mode -eq 'capture') { Sync-File (Join-Path $live $f.live) (Join-Path $repo $f.repo) $listOnly }
    else { Sync-File (Join-Path $repo $f.repo) (Join-Path $live $f.live) $listOnly }
}

if ($global:drift -eq 0) { Write-Host "OK: repo y live sincronizados (modo $Mode)" -ForegroundColor Green }
elseif ($Mode -eq 'diff') { Write-Host "$global:drift divergencia(s): corre 'apply' (repo manda) o 'capture' (live manda)" -ForegroundColor Yellow }
else { Write-Host "sincronizado (modo $Mode): $global:drift cambio(s) aplicados" -ForegroundColor Green }
