<div align="center">

<img src="./docs/banner.png" alt="lazy-starter-kit" width="760" />

### One command turns a fresh MacBook into a complete dev environment.

_Runtimes · shell · containers · and AI coding agents — installed and verified._

[![CI](https://github.com/Heoooooon/lazy-starter-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/Heoooooon/lazy-starter-kit/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/tag/Heoooooon/lazy-starter-kit?label=release&sort=semver&color=2ea043)](https://github.com/Heoooooon/lazy-starter-kit/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![Platform](https://img.shields.io/badge/macOS-Apple%20Silicon-000000?logo=apple&logoColor=white)](#)
[![Stars](https://img.shields.io/github/stars/Heoooooon/lazy-starter-kit?style=flat&color=f0c000)](https://github.com/Heoooooon/lazy-starter-kit/stargazers)

[한국어](./README.md) · **English** · [Install flow ↗](https://heoooooon.github.io/lazy-starter-kit/) · [Changelog](./CHANGELOG.md)

**Platforms:** **macOS** (this page) · [Linux](./linux/README.md) · [Windows](./windows/README.md)

</div>

---

## Quick start

```sh
curl -fsSL https://raw.githubusercontent.com/Heoooooon/lazy-starter-kit/main/install.sh | bash
```

On a brand-new Mac with no `git`, this triggers the Xcode Command Line Tools install
first — re-run the same command once they finish.

Prefer to read before you run (recommended):

```sh
git clone https://github.com/Heoooooon/lazy-starter-kit.git
cd lazy-starter-kit
./install.sh --dry-run     # see exactly what it would do
./install.sh               # apply
```

## Linux & Windows

This repo ships parallel kits for the other two platforms — same 7-step,
idempotent, `--dry-run`-first philosophy, adapted to each OS's native tooling:

| Platform | Package base | One-liner |
|---|---|---|
| **Linux** ([`linux/`](./linux/README.md)) | apt · dnf/yum · pacman · zypper (glibc) + official tool installers | `curl -fsSL https://raw.githubusercontent.com/Heoooooon/lazy-starter-kit/main/linux/install.sh \| bash` |
| **Windows** ([`windows/`](./windows/README.md)) | winget + mise/rustup | `irm https://raw.githubusercontent.com/Heoooooon/lazy-starter-kit/main/windows/install.ps1 \| iex` |

Each is self-contained under its directory (`install`, `uninstall`, `scripts/`,
`config/`) so you can clone and run just the one you need. The macOS kit below
stays at the repo root.

## What you get

| Layer | Tools |
|---|---|
| **Base** | Xcode Command Line Tools, Homebrew |
| **CLI** | git, gh, jq, ripgrep, fd, fzf, bat, tree, wget, ast-grep |
| **Maintenance** | **Mole** (`mo`) — clean / uninstall / analyze / optimize / monitor your Mac |
| **Shell** | zsh + oh-my-zsh (plugins: git, npm, node, macos, autosuggestions, syntax-highlighting), **starship** prompt, JetBrainsMono Nerd Font |
| **Runtimes** | **mise** → node (LTS), python, go · **rustup** → rust + rust-analyzer · uv · bun |
| **Containers** | **Colima** + docker / compose / buildx (Docker Desktop not required) |
| **Git/GitHub** | identity (GitHub noreply email), HTTPS credential helper, sane defaults |
| **AI agents** | **gajae-code** (`gjc`), **codex**, **lazycodex** (OmO), **Hermes Agent** (`hermes`, Nous Research) |

## Steps & flags

Steps run in this order:

```
prereqs  brew  runtimes  shell  docker  git  agents
```

```sh
./install.sh --dry-run          # change nothing, just print
./install.sh --yes              # non-interactive, accept defaults
./install.sh --only brew,shell  # run a subset
./install.sh --skip agents      # run all but one
./install.sh --no-agents        # alias for --skip agents
./install.sh --list             # print step ids
```

Every step is **idempotent** — safe to re-run. `~/.zshrc`, `~/.zprofile`, and
`~/.docker/config.json` are edited via clearly marked managed blocks that
get replaced (never duplicated) on re-runs. Existing files you own are preserved.

## Running on a Mac that already has tools

The kit is built for a **fresh machine**, but it's safe to run on a partially
set-up one — it never overwrites your config. Specifics:

- **Non-destructive by default**: Homebrew/oh-my-zsh/`gjc`/`codex` are skipped if
  already present; your **git identity** is only set when empty (never clobbered);
  `brew bundle` skips formulae you already have.
- **Runtimes are the exception to watch.** node/python/go are installed via **mise**.
  If you already have node from another source (system `.pkg`, `nvm`, `brew`, …),
  mise installs **its own** and **shadows yours via PATH** — it does *not* remove or
  migrate the old one. You'll end up with both; mise's wins in new shells. The
  `runtimes` step now prints a warning when it detects a non-mise runtime. Verify
  with `which -a node`.
- **Hand-edited `~/.zshrc`?** The kit appends its own marked block, so lines you
  added by hand (e.g. your own `mise activate` / `starship init`) will run *in
  addition* to the kit's — harmless but redundant. Move your lines into the managed
  block, or remove the duplicates.
- **Docker Desktop already installed?** Colima coexists but shares the `docker` CLI
  and contexts; pick one to avoid confusion (`docker context use`).

## Permissions

The scripts **never call `sudo` themselves.** Elevated access is needed in exactly
two places, and only on a truly fresh machine:

- **Homebrew install** — the official installer prompts for your Mac password once
  (`prereqs` step, only when brew is missing).
- **Xcode Command Line Tools** — a GUI dialog you click "Install" on (only when missing).

Everything else runs in **user space, no sudo**: mise → `~/.local`, rustup →
`~/.rustup`, bun → `~/.bun`, Homebrew packages (after setup), and all dotfiles in
`~`. Installing a cask like cmux into `/Applications` may prompt for your password,
and first-launch Gatekeeper/permission prompts are normal (on use, not install).
`gh auth login` is your GitHub account sign-in, not a system permission. Uninstall is
also fully user-space (Homebrew itself is never removed).

## Customize

- **Brew packages** — edit [`Brewfile`](./Brewfile), then `./install.sh --only brew`.
- **Runtime versions** — edit `MISE_TOOLS` in [`scripts/03-runtimes.sh`](./scripts/03-runtimes.sh).
- **Prompt** — [`config/starship.toml`](./config/starship.toml) (copied to `~/.config/` only if absent).
- **Shell block** — [`config/zshrc.block.sh`](./config/zshrc.block.sh).

## Optional productivity apps

The default kit stays focused on **developer tools**. If you also want a more
comfortable daily macOS setup, install this small, curated set of free/open-source
apps — it's intentionally minimal, not a "recommended apps" dump:

```sh
brew bundle --file Brewfile.optional
# or directly:
brew install --cask rectangle maccy
```

- **[Rectangle](https://github.com/rxhanson/Rectangle)** — window snapping, a free/open-source Magnet alternative.
- **[Maccy](https://github.com/p0deje/Maccy)** — clipboard history manager, free/open-source.

> **Base vs. optional:** the default install is the frozen, lean dev base; new
> non-core tools go into `Brewfile.optional`. See [CONTRIBUTING.md](./CONTRIBUTING.md).

## After install

1. **Open a new terminal** (or `source ~/.zshrc`) so PATH/prompt load.
2. **GitHub**: if `gh auth login` was skipped, run it once.
3. **Colima**: starts on demand — `colima start` (or `brew services start colima` to auto-start at login). It does **not** survive a reboot unless you enable the service.
4. **lazycodex**: launch `codex` once and **approve the OmO hooks** in the startup review; hooks never run before approval.

## Notes on the AI agents

- **gajae-code** (`gjc`) installs globally via **bun** (`bun add -g gajae-code`); its bin lives in `~/.bun/bin` (added to PATH by the shell block).
- **codex** (`@openai/codex`) installs globally via npm (mise-managed node).
- **lazycodex** is intentionally **never** installed globally — it always runs through `npx lazycodex-ai …` and layers the OmO harness onto codex.
- **Hermes Agent** (Nous Research) installs via its official one-liner (`curl …hermes-agent.nousresearch.com/install.sh | bash`) with `--skip-setup`. It self-manages Python/Node/Chromium and links `hermes` into `~/.local/bin`. The install is **non-fatal** (a failure only warns) and can be skipped with `HERMES=0 ./install.sh`. After install, run `hermes setup --portal`, then `hermes`.

## Uninstall

Reverse everything the kit set up, in reverse dependency order:

```sh
./uninstall.sh --dry-run     # preview the teardown
./uninstall.sh               # run it (destructive groups are confirm-gated)
./uninstall.sh --yes         # non-interactive, accept every removal
./uninstall.sh --only agents # remove just one group
```

Groups: `agents shell docker runtimes brew` (run in reverse).

Safe by design:
- **Never auto-removed**: Homebrew, Xcode Command Line Tools, and your **git identity**.
- **gajae-code (`gjc`) is kept** unless you pass `--with-gajae` (refused while `gjc` is running).
- Removing codex backs up `~/.codex/auth.json` to `~/` first; pass `--keep-codex-home` to leave `~/.codex` intact.
- Removing Hermes deletes its `~/.local/bin/hermes` shim and (after confirming) `~/.hermes`.
- Only the kit's own managed blocks (`# >>> lazy-starter-kit:* >>>`) are stripped from your dotfiles — hand-written lines are untouched.

## Versioning

Released versions are tagged (`vX.Y.Z`) and follow [SemVer](https://semver.org/);
see [CHANGELOG.md](./CHANGELOG.md). Check your copy with `./install.sh --version`.

Pin the installer to a release instead of `main`:

```sh
STARTER_KIT_BRANCH=v0.1.0 \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/Heoooooon/lazy-starter-kit/v0.1.0/install.sh)"
```

## Credits

This kit just wires together other people's great open-source work. All credit to
the upstream projects — please star/support them:

**Base & CLI**
- [Homebrew](https://brew.sh) · [git](https://git-scm.com) · [GitHub CLI](https://github.com/cli/cli)
- [ripgrep](https://github.com/BurntSushi/ripgrep) · [fd](https://github.com/sharkdp/fd) · [fzf](https://github.com/junegunn/fzf) · [bat](https://github.com/sharkdp/bat)
- [jq](https://github.com/jqlang/jq) · [tree](https://gitlab.com/OldManProgrammer/unix-tree) · [wget](https://www.gnu.org/software/wget/) · [ast-grep](https://github.com/ast-grep/ast-grep)
- [Mole](https://github.com/tw93/Mole) — Mac clean/uninstall/analyze/optimize

**Runtimes**
- [mise](https://github.com/jdx/mise) · [uv](https://github.com/astral-sh/uv) · [rustup](https://github.com/rust-lang/rustup) · [bun](https://github.com/oven-sh/bun)
- [Node.js](https://nodejs.org) · [Python](https://www.python.org) · [Go](https://go.dev) · [Rust](https://www.rust-lang.org) · [rust-analyzer](https://github.com/rust-lang/rust-analyzer)

**Shell**
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) · [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) · [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [Starship](https://github.com/starship/starship) · [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) ([JetBrains Mono](https://github.com/JetBrains/JetBrainsMono))

**Containers & terminal**
- [Colima](https://github.com/abiosoft/colima) · [Docker CLI](https://github.com/docker/cli) · [Compose](https://github.com/docker/compose) · [Buildx](https://github.com/docker/buildx)
- [cmux](https://www.cmux.dev/) (Ghostty-based; [Ghostty](https://github.com/ghostty-org/ghostty))

**AI agents**
- [gajae-code](https://github.com/Yeachan-Heo/gajae-code) · [Codex](https://github.com/openai/codex) · [lazycodex / OmO](https://github.com/code-yeongyu/lazycodex) · [Hermes Agent](https://github.com/NousResearch/hermes-agent)

## License

MIT — see [LICENSE](./LICENSE).
