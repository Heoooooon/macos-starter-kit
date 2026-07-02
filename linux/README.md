<div align="center">

### One command turns a fresh Linux box into a complete dev environment.

_Build tools · CLI · runtimes · shell · containers · and AI coding agents — installed and verified._

**[← Back to repo root](../README.md)** · [macOS kit](../README.md) · [Windows kit](../windows/README.md)

</div>

---

> **🇰🇷 한국어 빠른 시작** — 터미널을 열고 아래 한 줄을 붙여넣고 Enter:
> ```sh
> curl -fsSL https://raw.githubusercontent.com/Heoooooon/lazy-starter-kit/main/linux/install.sh | bash
> ```
> apt·dnf·pacman·zypper를 자동 감지합니다 (glibc 배포판; Alpine/musl 미지원). (한국어 전체 안내: [저장소 메인 README](../README.md#-linux-설치))

## Quick start

```sh
curl -fsSL https://raw.githubusercontent.com/Heoooooon/lazy-starter-kit/main/linux/install.sh | bash
```

Prefer to read before you run (recommended):

```sh
git clone https://github.com/Heoooooon/lazy-starter-kit.git
cd lazy-starter-kit/linux
./install.sh --dry-run     # see exactly what it would do
./install.sh               # apply
```

**Supported distros** (auto-detected package manager): Debian/Ubuntu (`apt`),
Fedora/RHEL (`dnf`/`yum`), Arch (`pacman`), openSUSE (`zypper`) — all **glibc**.
Alpine/musl (`apk`) is **not supported** (upstream node, ast-grep and bun ship
no musl builds). Verified end-to-end on Ubuntu, Fedora, openSUSE and Arch.

## What you get

| Layer | Tools |
|---|---|
| **Base** | compiler/build tools, `git`, `curl`, `wget`, `unzip`, `zsh` (via your distro's package manager) |
| **CLI** | ripgrep, fd, bat, fzf, jq, tree, **gh** (GitHub CLI) |
| **Shell** | zsh + oh-my-zsh (plugins: git, npm, node, autosuggestions, syntax-highlighting), **starship** prompt |
| **Runtimes** | **mise** → node (LTS), python, go, **ast-grep** · **rustup** → rust + rust-analyzer · **uv** · **bun** |
| **Containers** | **Docker Engine** + compose/buildx (official `get.docker.com`, opt-in) |
| **Git/GitHub** | identity (GitHub noreply email), HTTPS credential helper, sane defaults |
| **AI agents** | **gajae-code** (`gjc`), **codex**, **lazycodex** (OmO), **Hermes Agent** (`hermes`, Nous Research) |

## Steps & flags

Steps run in this order:

```
prereqs  packages  runtimes  shell  docker  git  agents
```

```sh
./install.sh --dry-run             # change nothing, just print
./install.sh --yes                 # non-interactive, accept defaults
./install.sh --only packages,shell # run a subset
./install.sh --skip agents         # run all but one
./install.sh --no-agents           # alias for --skip agents
./install.sh --list                # print step ids
```

Every step is **idempotent** — safe to re-run. `~/.zshrc` is edited via clearly
marked managed blocks (`# >>> lazy-starter-kit:* >>>`) that get replaced (never
duplicated) on re-runs. Existing files you own are preserved.

## Design notes

- **No Homebrew.** Plain CLI utilities come from your distro's package manager;
  the "moving target" developer tools (mise, starship, uv, bun, rustup) are
  installed from their **official user-space installers** into `$HOME`, so the
  kit works the same across every distro and needs **no root** for them.
- **sudo** is only used for system packages (`prereqs`, CLI utilities, Docker).
  On a rootless box without `sudo`, those installs are skipped with a warning;
  the user-space tools still install fine.
- **Debian/Ubuntu quirks**: `fd`/`bat` ship as `fdfind`/`batcat` — the shell
  block aliases them back to `fd`/`bat` automatically.
- **Runtimes shadow, never replace.** node/python/go from another source (system
  package, `nvm`, `asdf`) are left alone; mise installs its own and wins on PATH.
  Verify with `which -a node`.
- **Docker** is opt-in (confirm-gated): the official `get.docker.com` script
  installs docker-ce + compose + buildx and adds you to the `docker` group
  (effective after re-login).

## Uninstall

```sh
./uninstall.sh --dry-run     # preview the teardown
./uninstall.sh               # run it (destructive groups are confirm-gated)
./uninstall.sh --yes         # non-interactive, accept every removal
./uninstall.sh --only agents # remove just one group
```

Groups (reverse order): `agents shell docker runtimes packages`.

Safe by design:
- **Never auto-removed**: your **git identity**, and the compiler/build tools.
- **gajae-code (`gjc`) is kept** unless you pass `--with-gajae`.
- Removing codex backs up `~/.codex/auth.json` first; `--keep-codex-home` leaves
  `~/.codex` intact.
- Only the kit's own managed blocks are stripped from `~/.zshrc`.

## Troubleshooting

- **No `sudo` / not root** — system packages (build tools, CLI utils, Docker) are
  skipped with a warning, but the per-user tools (mise, starship, uv, bun, rustup)
  still install fine into `$HOME`.
- **`fd` / `bat` "command not found"** — on Debian/Ubuntu they're `fdfind`/`batcat`;
  the shell block aliases them back once you open a new shell.
- **Python install slow or failing** — the kit forces mise's **precompiled** Python
  (`MISE_PYTHON_COMPILE=0`), so no source build. If your CPU/arch has no prebuilt
  release, install dev headers (`build-essential libssl-dev zlib1g-dev libffi-dev`)
  and re-run `--only runtimes`.
- **`docker: permission denied`** — log out/in (or `newgrp docker`) so your new
  `docker` group membership applies.
- **`gh` not found** — a few distros lack it in default repos; the kit adds GitHub's
  apt repo on Debian/Ubuntu. Elsewhere install your distro's `gh`/`github-cli`.
- **Re-run anytime** — every step is idempotent (use `--only <step>` to redo one).

## License

MIT — see [../LICENSE](../LICENSE).
