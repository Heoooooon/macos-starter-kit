#!/usr/bin/env bash
#
# lazy-starter-kit — install a complete Linux dev environment from scratch.
# From a fresh box → build tools, CLI, runtimes, shell, Docker, AI agents
# (gajae-code + codex + lazycodex + Hermes).
#
# Usage:
#   ./install.sh [options]
#   curl -fsSL https://raw.githubusercontent.com/Heoooooon/lazy-starter-kit/main/linux/install.sh | bash
#
# Options:
#   --dry-run        Show what would happen, change nothing.
#   --yes, -y        Non-interactive: accept defaults, never prompt.
#   --only  a,b,c    Run only these steps.
#   --skip  a,b,c    Run all steps except these.
#   --no-agents      Shortcut for --skip agents.
#   --list           List step ids and exit.
#   --version, -V    Print the kit version and exit.
#   --help, -h       Show this help.
#
# Steps (in order): prereqs packages runtimes shell docker git agents
#
# Supported package managers: apt · dnf/yum · pacman · zypper (glibc distros).
# Alpine/musl (apk) is not supported (upstream node/ast-grep/bun lack musl builds).
#
set -euo pipefail

REPO_URL="${STARTER_KIT_REPO:-https://github.com/Heoooooon/lazy-starter-kit.git}"
REPO_BRANCH="${STARTER_KIT_BRANCH:-main}"
CLONE_DIR="${STARTER_KIT_DIR:-$HOME/.lazy-starter-kit}"

# ---------------------------------------------------------------------------
# Resolve the repo root (the linux/ dir), or bootstrap by cloning (curl | bash).
# ---------------------------------------------------------------------------
resolve_root() {
  local src="${BASH_SOURCE[0]:-}"
  if [[ -n "$src" ]]; then
    local dir; dir="$(cd "$(dirname "$src")" 2>/dev/null && pwd || true)"
    if [[ -n "$dir" && -f "$dir/scripts/lib.sh" ]]; then
      echo "$dir"; return 0
    fi
  fi
  # Running piped from curl: clone (or update) and hand off to linux/install.sh.
  echo "==> Bootstrapping lazy-starter-kit into $CLONE_DIR" >&2
  if ! command -v git >/dev/null 2>&1; then
    echo "==> git not found. Install git first (e.g. sudo apt-get install -y git), then re-run." >&2
    exit 1
  fi
  if [[ -d "$CLONE_DIR/.git" ]]; then
    git -C "$CLONE_DIR" pull --ff-only origin "$REPO_BRANCH" >&2 || true
  else
    git clone --branch "$REPO_BRANCH" --depth 1 "$REPO_URL" "$CLONE_DIR" >&2
  fi
  echo "$CLONE_DIR/linux"
}

ROOT="$(resolve_root)"
# Resolve this script's own absolute path (empty when piped from curl).
SELF=""
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)/$(basename "${BASH_SOURCE[0]}")"
fi
# If we bootstrapped (cloned), hand off to the cloned copy with the original args.
if [[ "$SELF" != "$ROOT/install.sh" && -f "$ROOT/install.sh" ]]; then
  exec bash "$ROOT/install.sh" "$@"
fi

# shellcheck source=scripts/lib.sh
source "$ROOT/scripts/lib.sh"

KIT_VERSION="$(cat "$ROOT/../VERSION" 2>/dev/null || echo dev)"

# ---------------------------------------------------------------------------
# Step registry
# ---------------------------------------------------------------------------
STEP_IDS=(prereqs packages runtimes shell docker git agents)

# step_file <id> -> the scripts/NN-*.sh filename for that step
step_file() {
  case "$1" in
    prereqs)  echo 01-prereqs.sh ;;
    packages) echo 02-packages.sh ;;
    runtimes) echo 03-runtimes.sh ;;
    shell)    echo 04-shell.sh ;;
    docker)   echo 05-docker.sh ;;
    git)      echo 06-git.sh ;;
    agents)   echo 07-agents.sh ;;
    *) return 1 ;;
  esac
}

usage() { sed -n '2,21p' "$ROOT/install.sh" | sed 's/^# \{0,1\}//'; }

# ---------------------------------------------------------------------------
# Arg parsing
# ---------------------------------------------------------------------------
ONLY=""; SKIP=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   export DRY_RUN=1 ;;
    -y|--yes)    export ASSUME_YES=1 ;;
    --only)      ONLY="${2:-}"; shift ;;
    --only=*)    ONLY="${1#*=}" ;;
    --skip)      SKIP="${2:-}"; shift ;;
    --skip=*)    SKIP="${1#*=}" ;;
    --no-agents) SKIP="${SKIP:+$SKIP,}agents" ;;
    --list)      printf '%s\n' "${STEP_IDS[@]}"; exit 0 ;;
    -V|--version) echo "lazy-starter-kit $KIT_VERSION"; exit 0 ;;
    -h|--help)   usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

# Build the active step list honouring --only / --skip
selected() {
  local id keep
  for id in "${STEP_IDS[@]}"; do
    if [[ -n "$ONLY" ]]; then
      [[ ",$ONLY," == *",$id,"* ]] && echo "$id"
    else
      keep=1
      [[ -n "$SKIP" && ",$SKIP," == *",$id,"* ]] && keep=0
      [[ "$keep" == 1 ]] && echo "$id"
    fi
  done
}

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
is_linux || die "This kit targets Linux only (macOS users: use the repo root install.sh)."
[[ "$DRY_RUN" == "1" ]] && warn "DRY-RUN: no changes will be made."

printf '%s\n' "$_C_BOLD== lazy-starter-kit v$KIT_VERSION ==$_C_RESET"
info "steps: $(selected | tr '\n' ' ')"

# ---------------------------------------------------------------------------
# Execute
# ---------------------------------------------------------------------------
for id in $(selected); do
  file="$ROOT/scripts/$(step_file "$id")"
  fn="step_$id"
  [[ -f "$file" ]] || die "missing step file: $file"
  # shellcheck disable=SC1090
  source "$file"
  "$fn"
done

step "Done."
if [[ "$DRY_RUN" == "1" ]]; then
  info "That was a dry run — re-run without --dry-run to apply."
else
  step "Next steps"
  info "1) Open a NEW terminal (or: source ~/.zshrc) so PATH + prompt load."
  if command -v gh >/dev/null 2>&1 && ! gh auth status >/dev/null 2>&1; then
    info "2) Sign in to GitHub:  gh auth login   (also sets your git identity)"
  fi
  if command -v docker >/dev/null 2>&1 && ! id -nG 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
    info "3) Docker: log out/in (or run 'newgrp docker') so group access applies."
  fi
  info "Set your terminal font to 'JetBrainsMono Nerd Font' for prompt icons."
fi
exit 0
