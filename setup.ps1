<#
  DauctaurClaude - one-click tiered Claude Code setup (Windows / PowerShell)
  Installs: opusplan main model + high effort, deep-reasoner (Opus) and
  fast-worker (Sonnet) subagents. Non-destructive: backs up anything it touches.

  Usage:
    ./setup.ps1                 # install settings + agents to %USERPROFILE%\.claude
    ./setup.ps1 -WithClaude     # also install a global .claude\CLAUDE.md orchestration memory
    ./setup.ps1 -DryRun         # show what would change, do nothing
    ./setup.ps1 -ClaudeHome D:\path   # override target dir

  If blocked by execution policy, run:
    powershell -ExecutionPolicy Bypass -File .\setup.ps1
#>
[CmdletBinding()]
param(
  [switch]$WithClaude,
  [switch]$DryRun,
  [string]$ClaudeHome
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Src  = Join-Path $ScriptDir 'config'
if (-not $ClaudeHome) { $ClaudeHome = Join-Path $env:USERPROFILE '.claude' }
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

function Say($m) { Write-Host "  $m" }
Write-Host "DauctaurClaude setup -> $ClaudeHome"
if ($DryRun) { Write-Host "(dry run - no changes will be written)" }

if (-not (Test-Path $Src)) { throw "config/ not found next to setup.ps1" }

# 1. dirs
$agentsDir = Join-Path $ClaudeHome 'agents'
if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $agentsDir | Out-Null }

# 2. subagents (back up existing)
foreach ($srcAgent in Get-ChildItem (Join-Path $Src 'agents') -Filter '*.md' -File) {
  $target = Join-Path $agentsDir $srcAgent.Name
  if (Test-Path $target) {
    if (-not $DryRun) { Copy-Item $target "$target.bak-$Stamp" -Force }
    Say "backed up existing $($srcAgent.Name)"
  }
  if ($DryRun) { Say "[dry-run] install agents/$($srcAgent.Name)" }
  else { Copy-Item $srcAgent.FullName $target -Force; Say "installed agents/$($srcAgent.Name)" }
}

# 2b. skills (each skill is a directory containing SKILL.md)
$srcSkills = Join-Path $Src 'skills'
if (Test-Path $srcSkills) {
  $skillsDir = Join-Path $ClaudeHome 'skills'
  if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $skillsDir | Out-Null }
  foreach ($d in Get-ChildItem $srcSkills -Directory) {
    $target = Join-Path $skillsDir $d.Name
    if (Test-Path $target) {
      if (-not $DryRun) { Copy-Item $target "$target.bak-$Stamp" -Recurse -Force }
      Say "backed up existing skill $($d.Name)"
    }
    if ($DryRun) { Say "[dry-run] install skills/$($d.Name)" }
    else { Copy-Item $d.FullName $target -Recurse -Force; Say "installed skills/$($d.Name)" }
  }
}

# 3. settings.json - merge our keys into existing settings
$settings = Join-Path $ClaudeHome 'settings.json'
$add = Get-Content (Join-Path $Src 'settings.json') -Raw | ConvertFrom-Json

if (Test-Path $settings) {
  if (-not $DryRun) { Copy-Item $settings "$settings.bak-$Stamp" -Force }
  Say "backed up existing settings.json"
}

if ($DryRun) {
  Say "[dry-run] would merge model=opusplan, effortLevel=high into settings.json"
} else {
  $base = @{}
  if (Test-Path $settings) {
    try {
      $existing = Get-Content $settings -Raw | ConvertFrom-Json
      foreach ($p in $existing.PSObject.Properties) { $base[$p.Name] = $p.Value }
    } catch { $base = @{} }
  }
  foreach ($p in $add.PSObject.Properties) { $base[$p.Name] = $p.Value }
  ($base | ConvertTo-Json -Depth 20) | Set-Content -Path $settings -Encoding UTF8
  Say "merged settings.json (model=opusplan, effortLevel=high)"
}

# 4. optional global CLAUDE.md
if ($WithClaude) {
  $cm = Join-Path $ClaudeHome 'CLAUDE.md'
  if (Test-Path $cm) {
    if (-not $DryRun) { Copy-Item $cm "$cm.bak-$Stamp" -Force }
    Say "backed up existing CLAUDE.md"
  }
  if ($DryRun) { Say "[dry-run] install global CLAUDE.md" }
  else { Copy-Item (Join-Path $Src 'CLAUDE.md.template') $cm -Force; Say "installed global CLAUDE.md" }
}

Write-Host ""
Write-Host "Done."
Write-Host "Verify:"
Write-Host "  1. Start Claude Code:   claude"
Write-Host "  2. Confirm main model:  /model      (should show opusplan)"
Write-Host "  3. List agents:         /agents     (deep-reasoner, fast-worker, scraper-researcher)"
Write-Host "  4. Test routing (KNOWN BUG on some versions): invoke deep-reasoner and"
Write-Host "     confirm it runs as Opus, not the parent model. If it resolves to the"
Write-Host "     parent, rely on opusplan alone - it is reliable."
Write-Host ""
Write-Host "Per-project: copy config\CLAUDE.md.template into a repo as CLAUDE.md and fill it in."
Write-Host "Backups (if any) use suffix .bak-$Stamp"
