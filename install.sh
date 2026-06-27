#!/usr/bin/env bash
#
# macos-starter-kit — install a complete macOS dev environment from scratch.
# From nothing → Xcode CLT, Homebrew, runtimes, shell, Docker, AI agents
# (gajae-code + lazycodex).
#
# Usage:
#   ./install.sh [options]
#   curl -fsSL https://raw.githubusercontent.com/Heoooooon/macos-starter-kit/main/install.sh | bash
#
# Options:
#   --dry-run        Show what would happen, change nothing.
#   --yes, -y        Non-interactive: accept defaults, never prompt.
#   --only  a,b,c    Run only these steps.
#   --skip  a,b,c    Run all steps except these.
#   --no-agents      Shortcut for --skip agents.
#   --list           List step ids and exit.
#   --help, -h       Show this help.
#
# Steps (in order): prereqs brew runtimes shell docker git agents
#
set -euo pipefail

REPO_URL="${STARTER_KIT_REPO:-https://github.com/Heoooooon/macos-starter-kit.git}"
REPO_BRANCH="${STARTER_KIT_BRANCH:-main}"
CLONE_DIR="${STARTER_KIT_DIR:-$HOME/.macos-starter-kit}"

# ---------------------------------------------------------------------------
# Resolve the repo root, or bootstrap by cloning (supports curl | bash).
# ---------------------------------------------------------------------------
resolve_root() {
  local src="${BASH_SOURCE[0]:-}"
  if [[ -n "$src" ]]; then
    local dir; dir="$(cd "$(dirname "$src")" 2>/dev/null && pwd || true)"
    if [[ -n "$dir" && -f "$dir/scripts/lib.sh" ]]; then
      echo "$dir"; return 0
    fi
  fi
  # Running piped from curl: clone (or update) and hand off.
  echo "==> Bootstrapping macos-starter-kit into $CLONE_DIR" >&2
  if ! command -v git >/dev/null 2>&1; then
    echo "==> git not found; triggering Xcode Command Line Tools install…" >&2
    xcode-select --install 2>/dev/null || true
    echo "Re-run this command after the Command Line Tools finish installing." >&2
    exit 1
  fi
  if [[ -d "$CLONE_DIR/.git" ]]; then
    git -C "$CLONE_DIR" pull --ff-only origin "$REPO_BRANCH" >&2 || true
  else
    git clone --branch "$REPO_BRANCH" --depth 1 "$REPO_URL" "$CLONE_DIR" >&2
  fi
  echo "$CLONE_DIR"
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

# ---------------------------------------------------------------------------
# Step registry
# ---------------------------------------------------------------------------
# Note: kept bash-3.2 compatible (macOS ships bash 3.2) — no associative arrays.
STEP_IDS=(prereqs brew runtimes shell docker git agents)

# step_file <id> -> the scripts/NN-*.sh filename for that step
step_file() {
  case "$1" in
    prereqs)  echo 01-prereqs.sh ;;
    brew)     echo 02-brew.sh ;;
    runtimes) echo 03-runtimes.sh ;;
    shell)    echo 04-shell.sh ;;
    docker)   echo 05-docker.sh ;;
    git)      echo 06-git.sh ;;
    agents)   echo 07-agents.sh ;;
    *) return 1 ;;
  esac
}
# function name for each step is always step_<id>

usage() { sed -n '2,28p' "$ROOT/install.sh" | sed 's/^# \{0,1\}//'; }

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
is_macos || die "This kit targets macOS only."
is_arm   || warn "Not Apple Silicon (arm64) — proceeding, but only tested on M-series."
[[ "$DRY_RUN" == "1" ]] && warn "DRY-RUN: no changes will be made."

printf '%s\n' "$_C_BOLD== macos-starter-kit ==$_C_RESET"
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
ok "Open a new terminal (or: source ~/.zshrc) to load everything."
[[ "$DRY_RUN" == "1" ]] && info "That was a dry run — re-run without --dry-run to apply."
exit 0
