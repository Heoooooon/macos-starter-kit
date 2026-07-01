#!/usr/bin/env bash
# lib.sh — shared helpers for lazy-starter-kit
# sourced by install.sh and every scripts/NN-*.sh step.

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
  _C_RESET=$'\033[0m'; _C_DIM=$'\033[2m'; _C_RED=$'\033[31m'
  _C_GREEN=$'\033[32m'; _C_YELLOW=$'\033[33m'; _C_BLUE=$'\033[34m'; _C_BOLD=$'\033[1m'
else
  _C_RESET=''; _C_DIM=''; _C_RED=''; _C_GREEN=''; _C_YELLOW=''; _C_BLUE=''; _C_BOLD=''
fi

step()  { printf '\n%s==>%s %s%s%s\n' "$_C_BLUE$_C_BOLD" "$_C_RESET" "$_C_BOLD" "$*" "$_C_RESET"; }
info()  { printf '%s  •%s %s\n' "$_C_DIM" "$_C_RESET" "$*"; }
ok()    { printf '%s  ✓%s %s\n' "$_C_GREEN" "$_C_RESET" "$*"; }
warn()  { printf '%s  !%s %s\n' "$_C_YELLOW" "$_C_RESET" "$*" >&2; }
err()   { printf '%s  ✗%s %s\n' "$_C_RED" "$_C_RESET" "$*" >&2; }
die()   { err "$*"; exit 1; }

# ---------------------------------------------------------------------------
# Environment flags (exported by install.sh)
# ---------------------------------------------------------------------------
: "${DRY_RUN:=0}"    # 1 = print actions, do not execute
: "${ASSUME_YES:=0}" # 1 = never prompt, take defaults

# run CMD...  — execute, or just print under DRY_RUN
run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '%s  [dry-run]%s %s\n' "$_C_DIM" "$_C_RESET" "$*"
    return 0
  fi
  "$@"
}

# ---------------------------------------------------------------------------
# Predicates
# ---------------------------------------------------------------------------
have()        { command -v "$1" >/dev/null 2>&1; }
is_tty()      { [[ -t 0 ]]; }
is_linux()    { [[ "$(uname -s)" == "Linux" ]]; }

# ---------------------------------------------------------------------------
# Privilege escalation — pick sudo only when needed & available
# ---------------------------------------------------------------------------
# SUDO is "" when we are root or when sudo is missing; system package installs
# use "$SUDO" so a rootless/CI environment degrades gracefully.
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  SUDO=""
elif have sudo; then
  SUDO="sudo"
else
  SUDO=""
fi

# ---------------------------------------------------------------------------
# Distro / package-manager detection
# ---------------------------------------------------------------------------
# PM is one of: apt dnf yum pacman zypper apk  (empty if unknown)
detect_pm() {
  if have apt-get;  then echo apt
  elif have dnf;    then echo dnf
  elif have yum;    then echo yum
  elif have pacman; then echo pacman
  elif have zypper; then echo zypper
  elif have apk;    then echo apk
  else echo ""; fi
}
PM="$(detect_pm)"

# distro_id — the ID= field from /etc/os-release (ubuntu, debian, fedora, arch…)
distro_id() {
  [[ -r /etc/os-release ]] || { echo unknown; return; }
  # shellcheck disable=SC1091
  ( . /etc/os-release; echo "${ID:-unknown}" )
}

# pm_refresh — update the package index once (best effort)
_PM_REFRESHED=0
pm_refresh() {
  [[ "$_PM_REFRESHED" == "1" ]] && return 0
  _PM_REFRESHED=1
  case "$PM" in
    apt)    run $SUDO apt-get update -y ;;
    dnf)    run $SUDO dnf -y makecache || true ;;
    yum)    run $SUDO yum -y makecache || true ;;
    # Arch: a full -Syu is required — installing after a bare -Sy is a
    # partial upgrade (unsupported, can break glibc/openssl mismatches).
    pacman) run $SUDO pacman -Syu --noconfirm ;;
    zypper) run $SUDO zypper --non-interactive refresh || true ;;
    apk)    run $SUDO apk update ;;
    *)      warn "no supported package manager detected" ;;
  esac
}

# pm_install PKG...  — install one or more system packages (non-interactive)
pm_install() {
  [[ $# -gt 0 ]] || return 0
  case "$PM" in
    apt)    run $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@" ;;
    dnf)    run $SUDO dnf install -y "$@" ;;
    yum)    run $SUDO yum install -y "$@" ;;
    pacman) run $SUDO pacman -S --needed --noconfirm "$@" ;;
    zypper) run $SUDO zypper --non-interactive install --no-recommends "$@" ;;
    apk)    run $SUDO apk add "$@" ;;
    *)      warn "cannot install ($*): unknown package manager"; return 1 ;;
  esac
}

# pm_try PKG...  — best-effort install; a failure only warns (used for optional
# CLI tools whose package name may not exist on every distro).
pm_try() {
  pm_install "$@" || warn "could not install via $PM: $* (skipping)"
}

# pm_remove PKG...  — remove system packages (used by the uninstaller)
pm_remove() {
  [[ $# -gt 0 ]] || return 0
  case "$PM" in
    apt)    run $SUDO env DEBIAN_FRONTEND=noninteractive apt-get remove -y "$@" || true ;;
    dnf)    run $SUDO dnf remove -y "$@" || true ;;
    yum)    run $SUDO yum remove -y "$@" || true ;;
    pacman) run $SUDO pacman -Rns --noconfirm "$@" || true ;;
    zypper) run $SUDO zypper --non-interactive remove "$@" || true ;;
    apk)    run $SUDO apk del "$@" || true ;;
  esac
}

# load user-local bins for the current process, so freshly-installed tools
# (mise, starship, uv, bun, cargo) are visible to later steps immediately.
load_local_bins() {
  export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.bun/bin:$PATH"
  [[ -d "$HOME/.local/share/mise/shims" ]] && export PATH="$HOME/.local/share/mise/shims:$PATH"
  return 0   # never fail under `set -e` (trailing test may be false)
}

# load mise shims into PATH for the current process
load_mise() {
  have mise && eval "$(mise activate bash --shims)" 2>/dev/null || true
  export PATH="$HOME/.local/share/mise/shims:$PATH"
}

# ---------------------------------------------------------------------------
# Prompts
# ---------------------------------------------------------------------------
# ask "Question?" "default"  -> echoes the answer (default under ASSUME_YES / no tty)
ask() {
  local q="$1" def="${2:-}"
  if [[ "$ASSUME_YES" == "1" ]] || ! is_tty; then echo "$def"; return; fi
  local ans; read -r -p "$q " ans || true
  echo "${ans:-$def}"
}

# confirm "Question?"  -> yes(0)/no(1).
#   --yes (ASSUME_YES): always yes.  non-interactive without --yes: decline.
confirm() {
  local q="$1"
  [[ "$ASSUME_YES" == "1" ]] && return 0
  is_tty || return 1
  local ans; read -r -p "$q [Y/n] " ans || true
  [[ -z "$ans" || "$ans" =~ ^[Yy] ]]
}

# ---------------------------------------------------------------------------
# Managed-block injection — idempotent insert/replace between markers
# inject_block <file> <tag> <<<"content"   (content read from stdin)
# Re-running replaces the block; never duplicates.
# ---------------------------------------------------------------------------
inject_block() {
  local file="$1" tag="$2"
  local begin="# >>> ${tag} >>>"
  local end="# <<< ${tag} <<<"
  local content; content="$(cat)"

  if [[ "$DRY_RUN" == "1" ]]; then
    if [[ -f "$file" ]] && grep -qF "$begin" "$file"; then
      info "[dry-run] would update '$tag' block in ${file/#$HOME/~}"
    else
      info "[dry-run] would add '$tag' block to ${file/#$HOME/~}"
    fi
    return 0
  fi

  run mkdir -p "$(dirname "$file")"
  [[ -f "$file" ]] || : > "$file"

  local tmp; tmp="$(mktemp)"
  # copy everything outside the existing block
  awk -v b="$begin" -v e="$end" '
    $0==b {skip=1} skip && $0==e {skip=0; next} !skip {print}
  ' "$file" > "$tmp"

  {
    cat "$tmp"
    printf '%s\n%s\n%s\n' "$begin" "$content" "$end"
  } > "$file"
  rm -f "$tmp"
  ok "wrote '$tag' block -> ${file/#$HOME/~}"
}

# remove_block <file> <tag>  — delete a managed block (markers + content). Idempotent.
remove_block() {
  local file="$1" tag="$2"
  local begin="# >>> ${tag} >>>"
  local end="# <<< ${tag} <<<"
  [[ -f "$file" ]] || { info "no ${file/#$HOME/~} (skip '$tag')"; return 0; }
  grep -qF "$begin" "$file" || { info "no '$tag' block in ${file/#$HOME/~}"; return 0; }
  if [[ "$DRY_RUN" == "1" ]]; then
    info "[dry-run] would remove '$tag' block from ${file/#$HOME/~}"
    return 0
  fi
  local tmp; tmp="$(mktemp)"
  awk -v b="$begin" -v e="$end" '
    $0==b {skip=1} skip && $0==e {skip=0; next} !skip {print}
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
  ok "removed '$tag' block from ${file/#$HOME/~}"
}
