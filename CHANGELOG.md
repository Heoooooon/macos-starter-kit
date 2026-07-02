# Changelog

All notable changes to **lazy-starter-kit** are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project aims to follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added
- **Linux kit** (`linux/`): the same 7-step, idempotent, dry-run-first installer
  for Linux. Auto-detects the package manager (apt · dnf/yum · pacman · zypper)
  for base/CLI tools and installs the developer toolchain (mise, starship,
  uv, bun, rustup) from official user-space installers — no Homebrew, no root for
  the per-user tools. Steps: `prereqs packages runtimes shell docker git agents`.
  Includes `uninstall.sh` and a dedicated README.
- **Windows kit** (`windows/`): a PowerShell installer (`install.ps1`, 5.1+/7+)
  using **winget** for packages plus **mise**/**rustup** for runtimes. Wires up a
  managed PowerShell profile block (starship, PSReadLine, PSFzf, bun/cargo PATH),
  Docker Desktop (opt-in), git identity, and the AI agents (gajae-code, codex,
  lazycodex; Hermes via WSL2). Includes `uninstall.ps1` and a README.
- **CI**: added `lint-linux` (shellcheck + `bash -n`) and `lint-windows`
  (PowerShell parse + PSScriptAnalyzer) jobs.
- **Docs**: root README now links all three platform kits (macOS at root,
  `linux/`, `windows/`).
- **Real end-to-end CI on all three OSes**: `windows-latest` (Server 2025) and
  `ubuntu-latest` install→verify→uninstall jobs, alongside the existing macOS one.
  Agents (gajae-code + codex) are covered on Linux and Windows.
- **Verified end-to-end on Ubuntu, Fedora, openSUSE and Arch** (glibc). Alpine/
  musl is explicitly **unsupported** (upstream node/ast-grep/bun have no musl builds).
- **CI distro matrix**: Fedora, Arch and openSUSE Tumbleweed now run the full
  install→verify→uninstall e2e in containers on every change (previously
  Ubuntu-only in CI).
- **Release automation**: pushing a `v*` tag creates a GitHub Release with
  auto-generated notes.
- **Repo hygiene**: `SECURITY.md` (reporting + supply-chain scope), GitHub issue
  forms (bug/feature), PR template, and Dependabot for GitHub Actions.

### Security
- GitHub Actions are pinned to full commit SHAs (checkout bumped to v7 / Node 24).
- The oh-my-zsh bootstrap installer is pinned to a reviewed commit instead of
  `master`; the get.docker.com script is downloaded to a temp file and sanity-
  checked instead of being piped straight into a root shell.
- README now states the supply-chain tradeoff plainly (upstream installers over
  HTTPS, npm/bun packages at latest) and links SECURITY.md.

### Changed
- **Windows**: winget installs prefer per-user (`--scope user`) and fall back to
  the default scope, so standard (non-admin) accounts install more; a summary
  lists any packages that still need admin. `-Only`/`-Skip` now accept comma
  lists (`-Only packages,shell`). PSReadLine is upgraded to 2.2+ for inline
  autosuggestions, plus CompletionPredictor + Tab menu + history search.
- **Linux**: Python uses mise's **precompiled** builds (`MISE_PYTHON_COMPILE=0`);
  `fd`/`bat` get real command symlinks on Debian/Ubuntu; oh-my-zsh plugin clones
  retry and are non-fatal; pacman refresh uses `-Syu` (avoids partial-upgrade
  breakage on Arch).

### Fixed
- **Rename** `macos-starter-kit` → `lazy-starter-kit` across code, URLs, managed-
  block tags, and clone dir; installs/uninstalls migrate legacy `macos-starter-kit:*`
  blocks so re-runs stay duplicate-free.
- `set -e` bug: `load_local_bins` aborted the Linux install when the mise shims
  dir did not exist yet.
- **Config safety (all OSes)**: managed-block editing now refuses to touch a file
  with an unmatched `>>>`/`<<<` marker (previously everything below a lone marker
  could be deleted) and makes a one-time `<file>.lazy-starter-kit.bak` backup
  before the first edit of an existing file.
- **Windows / PowerShell 5.1**: native commands with `2>$null` no longer kill the
  installer under `$ErrorActionPreference='Stop'` (e.g. `gh auth status` when not
  logged in); profile edits preserve the file's original encoding/BOM (Korean
  comments survive); `irm … | iex` no longer closes the terminal on exit; the
  profile block is written to (and removed from) **both** the 5.1 and PS 7
  profiles; session PATH updates merge instead of replacing.
- **Linux**: a box without usable sudo now skips system packages with one clear
  warning and still installs the user-space tools (previously the whole run
  aborted); `pacman -Syu` is confirm-gated instead of upgrading the system
  unprompted; the gh apt-repo setup and `$USER` expansion can no longer abort
  the install; `pm_install` lazily refreshes the package index so
  `--only packages` works on a fresh machine.
- **Non-interactive honesty**: `--yes`/`-Yes` no longer launches the interactive
  `gh auth login` / lazycodex wizards, and no longer auto-installs Docker Desktop
  on Windows (licensing); dry-run output now previews steps it previously skipped
  silently and no longer claims "backed up" without copying.
- **Uninstall**: codex is detected/removed with plain `npm -g` (previously missed
  unless mise managed node); Windows winget uninstalls no longer report "removed"
  when they failed.
- **CLI polish**: unknown `--only`/`--skip` (`-Only`/`-Skip`) step ids now fail
  loudly instead of silently doing nothing; `--help` no longer leaks code lines;
  `-V/--version` documented; the macOS Xcode CLT wait is bounded (~30 min) instead
  of spinning forever; `cat`→`bat` now actually works on Windows (alias precedence).

## [0.1.0] - 2026-06-27

First public release. One command turns a fresh MacBook into a complete dev
environment, verified end-to-end (install → uninstall) on a clean macOS VM
and on every push via GitHub Actions.

### Added
- **Installer** (`install.sh`): 7 idempotent, dependency-ordered steps —
  `prereqs → brew → runtimes → shell → docker → git → agents`. Bootstraps via
  `curl … | bash` (self-clones, then re-execs). Flags: `--dry-run`, `--yes`,
  `--only`, `--skip`, `--no-agents`, `--list`, `--version`, `--help`.
- **prereqs**: Xcode Command Line Tools + Homebrew.
- **brew** (`Brewfile`): git, gh, jq, ripgrep, fd, fzf, bat, tree, wget,
  ast-grep, **mole**, starship, mise, uv, rustup, bun, colima, docker (+compose
  /buildx), JetBrainsMono Nerd Font, and the **cmux** terminal.
- **runtimes**: node (LTS), python, go via **mise**; rust + rust-analyzer via
  **rustup**. Warns when a non-mise runtime is already installed (shadowing).
- **shell**: oh-my-zsh + plugins `(git npm node macos)` + zsh-autosuggestions +
  zsh-syntax-highlighting, starship prompt, managed `~/.zshrc` block.
- **docker**: Colima + docker CLI plugin wiring (Docker Desktop not required).
- **git**: identity (GitHub noreply email), HTTPS credential helper, sane
  defaults — only fills empty values, never clobbers.
- **agents**: gajae-code (`gjc`), codex, lazycodex (OmO), and Hermes Agent
  (`hermes`, skippable with `HERMES=0`).
- **Uninstaller** (`uninstall.sh`): reverse-order teardown, confirm-gated,
  `--with-gajae` / `--keep-codex-home`. Never auto-removes Homebrew, Xcode CLT,
  or your git identity.
- **Docs**: English + Korean READMEs, GitHub Pages install-flow page,
  Permissions and "running on a Mac that already has tools" sections.
- **CI**: GitHub Actions — shellcheck/syntax, macOS dry-run, and a real
  install→uninstall integration job; weekly schedule to catch upstream drift.
- **Versioning**: `VERSION` file, `--version` flag, this changelog.

### Fixed
- `brew bundle`: dropped the removed `--no-lock` flag (use `brew bundle install`).
- agents: `mise reshim` after the global codex install so its shim is on PATH.
- uninstall: `brew autoremove` to sweep orphaned transitive deps (e.g. node@24).
- dry-run: `brew`/`runtimes` steps degrade gracefully on a bare machine instead
  of aborting when prerequisite tools aren't installed yet.

[Unreleased]: https://github.com/Heoooooon/lazy-starter-kit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Heoooooon/lazy-starter-kit/releases/tag/v0.1.0
