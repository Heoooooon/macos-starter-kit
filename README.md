# macos-starter-kit

One command to take a **fresh MacBook** from nothing to a complete dev environment —
runtimes, shell, containers, and AI coding agents (**gajae-code** + **lazycodex**).

Built and tested on Apple Silicon (M-series), macOS.

📊 **[Visual install flow →](https://heoooooon.github.io/macos-starter-kit/)** (the 7 steps, in order)

## Quick start

```sh
curl -fsSL https://raw.githubusercontent.com/Heoooooon/macos-starter-kit/main/install.sh | bash
```

On a brand-new Mac with no `git`, this triggers the Xcode Command Line Tools install
first — re-run the same command once they finish.

Prefer to read before you run (recommended):

```sh
git clone https://github.com/Heoooooon/macos-starter-kit.git
cd macos-starter-kit
./install.sh --dry-run     # see exactly what it would do
./install.sh               # apply
```

## What you get

| Layer | Tools |
|---|---|
| **Base** | Xcode Command Line Tools, Homebrew |
| **CLI** | git, gh, jq, ripgrep, fd, fzf, bat, tree, wget, ast-grep |
| **Shell** | zsh + oh-my-zsh (+ autosuggestions, syntax-highlighting), **starship** prompt, JetBrainsMono Nerd Font |
| **Runtimes** | **mise** → node (LTS), python, go · **rustup** → rust + rust-analyzer · uv · bun |
| **Containers** | **Colima** + docker / compose / buildx (Docker Desktop not required) |
| **Git/GitHub** | identity (GitHub noreply email), HTTPS credential helper, sane defaults |
| **AI agents** | **gajae-code** (`gjc`), **codex**, **lazycodex** (OmO harness) |

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

Every step is **idempotent** — safe to re-run. `~/.zshrc`, `~/.zprofile`, the ghostty
config, and `~/.docker/config.json` are edited via clearly marked managed blocks that
get replaced (never duplicated) on re-runs. Existing files you own are preserved.

## Customize

- **Brew packages** — edit [`Brewfile`](./Brewfile), then `./install.sh --only brew`.
- **Runtime versions** — edit `MISE_TOOLS` in [`scripts/03-runtimes.sh`](./scripts/03-runtimes.sh).
- **Prompt** — [`config/starship.toml`](./config/starship.toml) (copied to `~/.config/` only if absent).
- **Shell block** — [`config/zshrc.block.sh`](./config/zshrc.block.sh).

## After install

1. **Open a new terminal** (or `source ~/.zshrc`) so PATH/prompt load.
2. **GitHub**: if `gh auth login` was skipped, run it once.
3. **Colima**: starts on demand — `colima start` (or `brew services start colima` to auto-start at login). It does **not** survive a reboot unless you enable the service.
4. **lazycodex**: launch `codex` once and **approve the OmO hooks** in the startup review; hooks never run before approval.

## Notes on the AI agents

- **gajae-code** (`gjc`) installs globally via **bun** (`bun add -g gajae-code`); its bin lives in `~/.bun/bin` (added to PATH by the shell block).
- **codex** (`@openai/codex`) installs globally via npm (mise-managed node).
- **lazycodex** is intentionally **never** installed globally — it always runs through `npx lazycodex-ai …` and layers the OmO harness onto codex.

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
- Only the kit's own managed blocks (`# >>> macos-starter-kit:* >>>`) are stripped from your dotfiles — hand-written lines are untouched.

## License

MIT — see [LICENSE](./LICENSE).
