# 02-packages.ps1 -- install CLI tools + developer toolchain via winget

function Step-Packages {
  Write-Step "CLI tools + developer toolchain (winget)"

  if (-not (Test-HasCommand winget) -and -not $script:DryRun) {
    Stop-Kit "winget not available -- run the 'prereqs' step first."
  }

  # id -> friendly name. Ordering: core CLI, then the dev toolchain.
  $packages = [ordered]@{
    'Git.Git'                        = 'git'
    'GitHub.cli'                     = 'gh (GitHub CLI)'
    'jqlang.jq'                      = 'jq'
    'BurntSushi.ripgrep.MSVC'        = 'ripgrep'
    'sharkdp.fd'                     = 'fd'
    'sharkdp.bat'                    = 'bat'
    'junegunn.fzf'                   = 'fzf'
    'Starship.Starship'             = 'starship'
    'jdx.mise'                       = 'mise'
    'astral-sh.uv'                   = 'uv'
    'Rustlang.Rustup'                = 'rustup'
    'Oven-sh.Bun'                    = 'bun'
    'DEVCOM.JetBrainsMonoNerdFont'   = 'JetBrainsMono Nerd Font'
  }

  foreach ($id in $packages.Keys) {
    Install-WingetPackage -Id $id -Name $packages[$id]
  }

  # `tree` and `curl` are built into Windows; ast-grep is installed via mise
  # (ubi backend) in the runtimes step to stay in lockstep with the other kits.

  Update-SessionPath
  if ($script:WingetFailures.Count -gt 0) {
    Write-Warn ("Some packages did not install: " + ($script:WingetFailures -join ', '))
    Write-Info "On a managed/standard-user PC these usually need admin (UAC) or your org's software portal."
    Write-Info "Re-run this step from an elevated PowerShell to retry: .\install.ps1 -Only packages"
  }
  Write-Ok "packages step complete"
}
