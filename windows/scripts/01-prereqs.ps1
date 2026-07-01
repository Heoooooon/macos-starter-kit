# 01-prereqs.ps1 -- winget (App Installer) + TLS + execution policy

function Step-Prereqs {
  Write-Step "Prerequisites: winget + TLS + execution policy"

  if (Test-IsAdmin) {
    Write-Info "Running as administrator."
  } else {
    Write-Info "Running as a standard user (no admin) - installing per-user where possible."
  }

  # --- TLS 1.2 for any Invoke-WebRequest downloads (older PS defaults) ----
  try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

  # --- winget (Windows Package Manager, ships in App Installer) -----------
  if (Test-HasCommand winget) {
    $ver = (winget --version 2>$null)
    Write-Ok "winget present ($ver)"
  } else {
    Write-Warn "winget not found."
    Write-Info "winget ships with 'App Installer'. Install it from the Microsoft Store:"
    Write-Info "  https://apps.microsoft.com/detail/9nblggh4nns1"
    Write-Info "or via: Add-AppxPackage from https://github.com/microsoft/winget-cli/releases"
    if (-not $script:DryRun) {
      Stop-Kit "winget is required -- install App Installer, then re-run this script."
    }
  }

  # --- execution policy so the PowerShell profile can load ---------------
  try {
    $cur = Get-ExecutionPolicy -Scope CurrentUser
    if ($cur -in @('Restricted', 'Undefined', 'AllSigned')) {
      if ($script:DryRun) {
        Write-Info "[dry-run] Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
      } else {
        Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
        Write-Ok "execution policy (CurrentUser) -> RemoteSigned"
      }
    } else {
      Write-Ok "execution policy (CurrentUser): $cur"
    }
  } catch {
    Write-Warn "could not adjust execution policy: $($_.Exception.Message)"
  }

  Write-Ok "prerequisites ready"
}
