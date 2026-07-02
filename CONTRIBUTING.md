# Contributing

Thanks for your interest! This kit has a deliberately tight scope. Reading this
first saves everyone time.

## Scope: base vs. optional

The kit is split into two tiers, and **where a tool goes is the first question
for any addition**:

- **Base** — the default install (`install.sh` + [`Brewfile`](./Brewfile) + the
  `scripts/` steps). This is the **current, frozen, lean set**: prereqs, core dev
  CLI, runtimes (mise/rustup), shell, containers, Git/GitHub, and the AI coding
  agents. The base stays focused on **"a fresh Mac → a working dev environment."**
  It should grow slowly and only for things nearly everyone setting up a dev Mac
  needs.

- **Optional** — opt-in extras in [`Brewfile.optional`](./Brewfile.optional),
  installed only on purpose (`brew bundle --file Brewfile.optional`). **New
  additions that aren't core dev tooling go here** — daily-use apps, niche tools,
  personal preferences. This keeps the base from drifting into a "recommended
  apps" dump.

Rule of thumb:

| Is it... | Goes in |
|---|---|
| A tool ~every dev Mac needs (compiler, runtime, shell, VCS, container, agent) | **Base** |
| A nice-to-have / GUI / daily-use / opinionated pick | **Optional** |

PRs that add non-core tools to the base will be asked to move them to
`Brewfile.optional`.

## Ground rules for changes

- **bash 3.2 compatible** — macOS ships bash 3.2; no associative arrays,
  `mapfile`, `${x,,}`, etc. (`bash -n` must pass under `/bin/bash`).
- **Idempotent & non-destructive** — re-running must be safe; never clobber a
  user's existing config (fill empty values, use the managed-block markers).
- **shellcheck clean** — `shellcheck -x -S warning -e SC2154 install.sh uninstall.sh lib/common.sh scripts/*.sh`.
- **Shared helpers live in `lib/common.sh`** — the OS-agnostic bash helpers
  (colors, `run`, `ask`/`confirm`, `inject_block`, …) are shared by the macOS
  (`scripts/lib.sh`) and Linux (`linux/scripts/lib.sh`) kits, which source it and
  add only their OS-specific bits. Fix shared behavior in `lib/common.sh` so it
  can't land in only one tree.
- **Preview first** — verify with `./install.sh --dry-run` (and `--dry-run` for
  uninstall).
- **CI must pass** — lint + macOS dry-run + a real install→uninstall run.
- **Versioning** — user-visible changes bump [`VERSION`](./VERSION) and get a
  note in [`CHANGELOG.md`](./CHANGELOG.md) (SemVer).

## Proposing an addition

Open an issue describing the tool, why it belongs in **base** vs **optional**,
and its license (prefer free/open-source). Small, well-scoped PRs welcome.
