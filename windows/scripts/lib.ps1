# lib.ps1 -- shared helpers for lazy-starter-kit
# dot-sourced by install.ps1 and every scripts/NN-*.ps1 step.
# Targets Windows PowerShell 5.1+ and PowerShell 7+.

Set-StrictMode -Version Latest

# ---------------------------------------------------------------------------
# Global flags (set by install.ps1)
# ---------------------------------------------------------------------------
if (-not (Test-Path variable:script:DryRun))    { $script:DryRun = $false }
if (-not (Test-Path variable:script:AssumeYes)) { $script:AssumeYes = $false }

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
function Write-Step { param([string]$Message) Write-Host ""; Write-Host "==> $Message" -ForegroundColor Blue }
function Write-Info { param([string]$Message) Write-Host "  - $Message" -ForegroundColor DarkGray }
function Write-Ok   { param([string]$Message) Write-Host "  ok  $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Warning $Message }
function Write-Err  { param([string]$Message) Write-Host "  x   $Message" -ForegroundColor Red }
function Stop-Kit   { param([string]$Message) Write-Err $Message; exit 1 }

# Tracks winget packages that failed to install, for an end-of-step summary.
if (-not (Test-Path variable:script:WingetFailures)) { $script:WingetFailures = @() }

# ---------------------------------------------------------------------------
# Predicates
# ---------------------------------------------------------------------------
function Test-HasCommand {
  param([Parameter(Mandatory)][string]$Name)
  return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-IsWindows {
  # $IsWindows exists on PS 7; on 5.1 it's undefined but the host is Windows.
  if (Test-Path variable:global:IsWindows) { return $global:IsWindows }
  return ($env:OS -eq 'Windows_NT')
}

function Test-IsAdmin {
  try {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  } catch { return $false }
}

# ---------------------------------------------------------------------------
# Command execution -- run, or just print under -DryRun
# ---------------------------------------------------------------------------
function Invoke-Run {
  param(
    [Parameter(Mandatory)][string]$Exe,
    [string[]]$Arguments = @()
  )
  if ($script:DryRun) {
    Write-Host ("  [dry-run] {0} {1}" -f $Exe, ($Arguments -join ' ')) -ForegroundColor DarkGray
    return $true
  }
  & $Exe @Arguments
  return ($LASTEXITCODE -eq 0 -or $null -eq $LASTEXITCODE)
}

# ---------------------------------------------------------------------------
# Prompts
# ---------------------------------------------------------------------------
function Read-Default {
  param([string]$Question, [string]$Default = '')
  if ($script:AssumeYes -or [Console]::IsInputRedirected) { return $Default }
  $ans = Read-Host $Question
  if ([string]::IsNullOrWhiteSpace($ans)) { return $Default }
  return $ans
}

function Confirm-Action {
  param([string]$Question)
  if ($script:AssumeYes) { return $true }
  if ([Console]::IsInputRedirected) { return $false }
  $ans = Read-Host ("{0} [Y/n]" -f $Question)
  return ([string]::IsNullOrWhiteSpace($ans) -or $ans -match '^[Yy]')
}

# ---------------------------------------------------------------------------
# PATH refresh -- winget-installed tools land on the Machine/User PATH but the
# current process won't see them until we re-read the environment.
# ---------------------------------------------------------------------------
function Update-SessionPath {
  $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
  $user    = [Environment]::GetEnvironmentVariable('Path', 'User')
  $parts = @()
  foreach ($p in @($machine, $user)) { if ($p) { $parts += $p } }
  # user-local tool dirs (guard each base env var; may be unset off-Windows)
  if ($env:USERPROFILE) {
    $parts += (Join-Path $env:USERPROFILE '.cargo\bin')
    $parts += (Join-Path $env:USERPROFILE '.bun\bin')
  }
  if ($env:LOCALAPPDATA) { $parts += (Join-Path $env:LOCALAPPDATA 'mise\shims') }
  if ($env:APPDATA)      { $parts += (Join-Path $env:APPDATA 'npm') }
  if ($parts.Count -gt 0) { $env:Path = ($parts -join ';') }
}

# ---------------------------------------------------------------------------
# winget helpers
# ---------------------------------------------------------------------------
function Test-WingetPackage {
  param([Parameter(Mandatory)][string]$Id)
  $null = winget list --id $Id -e --accept-source-agreements 2>$null | Out-String -Stream | Select-String -SimpleMatch $Id
  return ($LASTEXITCODE -eq 0)
}

# Install-WingetPackage <Id> [<Friendly name>]  -- idempotent winget install
function Install-WingetPackage {
  param(
    [Parameter(Mandatory)][string]$Id,
    [string]$Name = $null
  )
  if (-not $Name) { $Name = $Id }
  if (-not $script:DryRun -and (Test-WingetPackage -Id $Id)) {
    Write-Ok "$Name present"
    return
  }
  Write-Info "Installing $Name (winget: $Id)..."
  $wingetArgs = @('install', '--id', $Id, '-e', '--accept-package-agreements',
                  '--accept-source-agreements', '--silent',
                  '--disable-interactivity')
  if ($script:DryRun) {
    Write-Host ("  [dry-run] winget {0} [--scope user, then default]" -f ($wingetArgs -join ' ')) -ForegroundColor DarkGray
    return
  }
  # Prefer a per-user install (no admin/UAC). If the package has no user-scope
  # installer, retry at default scope (which may prompt for elevation).
  winget @wingetArgs --scope user
  if ($LASTEXITCODE -ne 0) { winget @wingetArgs }
  if ($LASTEXITCODE -ne 0) {
    Write-Warn "winget install for $Name exited with code $LASTEXITCODE (may need admin/UAC, a reboot, or be unavailable here)"
    $script:WingetFailures += $Name
  } else {
    Write-Ok "$Name installed"
  }
}

# Uninstall-WingetPackage <Id> [<Friendly name>]  -- used by the uninstaller
function Uninstall-WingetPackage {
  param([Parameter(Mandatory)][string]$Id, [string]$Name = $null)
  if (-not $Name) { $Name = $Id }
  if (-not $script:DryRun -and -not (Test-WingetPackage -Id $Id)) {
    Write-Info "$Name not installed"
    return
  }
  if ($script:DryRun) {
    Write-Host ("  [dry-run] winget uninstall --id {0} -e --silent" -f $Id) -ForegroundColor DarkGray
    return
  }
  winget uninstall --id $Id -e --silent --disable-interactivity
  Write-Ok "$Name removed"
}

# ---------------------------------------------------------------------------
# Managed-block injection -- idempotent insert/replace between markers
# Update-ManagedBlock -Path <file> -Tag <tag> -Content <string>
# Re-running replaces the block; never duplicates.
# ---------------------------------------------------------------------------
function Update-ManagedBlock {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Tag,
    [Parameter(Mandatory)][string]$Content
  )
  $begin = "# >>> $Tag >>>"
  $end   = "# <<< $Tag <<<"
  $short = $Path.Replace($env:USERPROFILE, '~')

  if ($script:DryRun) {
    if ((Test-Path $Path) -and (Select-String -Path $Path -SimpleMatch $begin -Quiet)) {
      Write-Info "[dry-run] would update '$Tag' block in $short"
    } else {
      Write-Info "[dry-run] would add '$Tag' block to $short"
    }
    return
  }

  $dir = Split-Path -Parent $Path
  if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

  $lines = @()
  if (Test-Path $Path) {
    $skip = $false
    foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
      if ($line -eq $begin) { $skip = $true; continue }
      if ($skip -and $line -eq $end) { $skip = $false; continue }
      if (-not $skip) { $lines += $line }
    }
  }
  $lines += $begin
  foreach ($l in ($Content -split "`r?`n")) { $lines += $l }
  $lines += $end

  [System.IO.File]::WriteAllLines($Path, $lines)
  Write-Ok "wrote '$Tag' block -> $short"
}

# Remove-ManagedBlock -Path <file> -Tag <tag>  -- delete a managed block. Idempotent.
function Remove-ManagedBlock {
  param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Tag)
  $begin = "# >>> $Tag >>>"
  $end   = "# <<< $Tag <<<"
  $short = $Path.Replace($env:USERPROFILE, '~')
  if (-not (Test-Path $Path)) { Write-Info "no $short (skip '$Tag')"; return }
  if (-not (Select-String -Path $Path -SimpleMatch $begin -Quiet)) {
    Write-Info "no '$Tag' block in $short"; return
  }
  if ($script:DryRun) { Write-Info "[dry-run] would remove '$Tag' block from $short"; return }

  $lines = @()
  $skip = $false
  foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
    if ($line -eq $begin) { $skip = $true; continue }
    if ($skip -and $line -eq $end) { $skip = $false; continue }
    if (-not $skip) { $lines += $line }
  }
  [System.IO.File]::WriteAllLines($Path, $lines)
  Write-Ok "removed '$Tag' block from $short"
}
