<div align="center">

### One command turns a fresh Windows PC into a complete dev environment.

_winget packages · runtimes · PowerShell profile · containers · and AI coding agents — installed and verified._

**[← Back to repo root](../README.md)** · [macOS kit](../README.md) · [Linux kit](../linux/README.md)

</div>

---

> **🇰🇷 한국어 빠른 시작** — 시작 버튼에서 `PowerShell`을 찾아 열고, 아래 한 줄을 붙여넣고 Enter:
> ```powershell
> irm https://raw.githubusercontent.com/Heoooooon/lazy-starter-kit/main/windows/install.ps1 | iex
> ```
> 끝나면 PowerShell을 새로 여세요. 막히면 앞에 `powershell -ExecutionPolicy Bypass -Command "..."`로 감싸 실행. (한국어 전체 안내: [저장소 메인 README](../README.md#-windows-설치-제일-자세히))

## Quick start

Open **PowerShell** (Windows PowerShell 5.1 or PowerShell 7) and run:

```powershell
irm https://raw.githubusercontent.com/Heoooooon/lazy-starter-kit/main/windows/install.ps1 | iex
```

Prefer to read before you run (recommended):

```powershell
git clone https://github.com/Heoooooon/lazy-starter-kit.git
cd lazy-starter-kit\windows
.\install.ps1 -DryRun     # see exactly what it would do
.\install.ps1             # apply
```

> If scripts are blocked, the installer sets `RemoteSigned` for the current user
> itself. To run the local copy before that, start it with:
> `powershell -ExecutionPolicy Bypass -File .\install.ps1`

**Requirements**: Windows 10 (1809+) or Windows 11 with **winget** (App Installer).
If `winget` is missing, install *App Installer* from the Microsoft Store first.

## What you get

| Layer | Tools |
|---|---|
| **Base** | winget (App Installer), TLS 1.2, `RemoteSigned` execution policy (CurrentUser) |
| **CLI** | git, gh, jq, ripgrep, fd, bat, fzf (`tree`/`curl` are built into Windows) |
| **Shell** | PowerShell profile with **starship** prompt · **PSReadLine 2.2+** inline autosuggestions + list predictions (the `zsh-autosuggestions` equivalent) · **CompletionPredictor** (command-based predictions) · Tab completion menu + history-substring search on ↑/↓ · **PSFzf** (Ctrl-T/Ctrl-R) · JetBrainsMono Nerd Font |
| **Runtimes** | **mise** → node (LTS), python, go, **ast-grep** · **rustup** → rust + rust-analyzer · **uv** · **bun** |
| **Containers** | **Docker Desktop** (optional; needs WSL2/virtualization) |
| **Git/GitHub** | identity (GitHub noreply email), HTTPS credential helper, `core.autocrlf`, sane defaults |
| **AI agents** | **gajae-code** (`gjc`), **codex**, **lazycodex** (OmO). Hermes Agent runs inside WSL2. |

## Steps & flags

Steps run in this order:

```
prereqs  packages  runtimes  shell  docker  git  agents
```

```powershell
.\install.ps1 -DryRun               # change nothing, just print
.\install.ps1 -Yes                  # non-interactive, accept defaults
.\install.ps1 -Only packages,shell  # run a subset
.\install.ps1 -Skip agents          # run all but one
.\install.ps1 -NoAgents             # alias for -Skip agents
.\install.ps1 -List                 # print step ids
.\install.ps1 -Version              # print the kit version
```

Every step is **idempotent** — safe to re-run. Your PowerShell profile
(`$PROFILE.CurrentUserAllHosts`) is edited via a clearly marked managed block
(`# >>> lazy-starter-kit:main >>>`) that gets replaced (never duplicated) on
re-runs. Existing files you own are preserved.

## Design notes

- **winget-first.** Plain tools come from winget; the runtimes are managed by
  **mise** (node/python/go/ast-grep) and **rustup** (rust) so versions are easy
  to switch. `ast-grep` is installed via mise's `ubi` backend to match the
  macOS/Linux kits.
- **No admin required** for the default flow — everything installs per-user.
  Docker Desktop is the exception (needs virtualization + a reboot) and is
  strictly opt-in.
- **PATH refresh.** winget puts new tools on the persistent PATH; the installer
  re-reads the environment mid-run so later steps see them without a restart.
  Still, **open a new PowerShell window** afterwards to load the profile.
- **Runtimes shadow, never replace.** node/python/go from another source
  (system MSI, nvm-windows, scoop) are left alone; mise's win on PATH. Verify
  with `Get-Command node -All`.
- **Hermes Agent** has no native Windows build — install it inside a WSL2 distro:
  `wsl bash -c 'curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-setup'`

## Uninstall

```powershell
.\uninstall.ps1 -DryRun     # preview the teardown
.\uninstall.ps1             # run it (destructive groups are confirm-gated)
.\uninstall.ps1 -Yes        # non-interactive, accept every removal
.\uninstall.ps1 -Only agents
```

Groups (reverse order): `agents shell docker runtimes packages`.

Safe by design:
- **Never auto-removed**: your **git identity**, `git` itself, and the Nerd Font.
- **gajae-code (`gjc`) is kept** unless you pass `-WithGajae` (refused while running).
- Removing codex backs up `~/.codex/auth.json` first; `-KeepCodexHome` leaves it intact.
- Only the kit's own managed block is stripped from your PowerShell profile.

## Troubleshooting

- **`winget` not recognized** — install *App Installer* from the Microsoft Store
  ([link](https://apps.microsoft.com/detail/9nblggh4nns1)), then reopen PowerShell.
- **"running scripts is disabled on this system"** — run the local copy with
  `powershell -ExecutionPolicy Bypass -File .\install.ps1` (the installer then sets
  `RemoteSigned` for your user so it won't recur).
- **Autosuggestions don't appear** — you're likely on Windows PowerShell 5.1 with
  the old PSReadLine still loaded. Restart PowerShell once, or use **PowerShell 7**
  (`winget install Microsoft.PowerShell`) + **Windows Terminal**.
- **Behind a corporate proxy** — set `$env:HTTP_PROXY`/`$env:HTTPS_PROXY` before
  running; winget honors them. Some networks block winget's CDN — then install the
  few tools from your internal software portal instead.
- **Docker** — Docker Desktop is paid for larger orgs; prefer Docker/Podman inside
  WSL2 (see the Containers row). `wsl --install` needs virtualization enabled in BIOS.
- **Re-run anytime** — every step is idempotent; safe to run again after fixing a
  blocker (or use `-Only <step>` to redo just one).

## License

MIT — see [../LICENSE](../LICENSE).
