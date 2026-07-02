#!/usr/bin/env bash
# lib.sh — Linux helpers for lazy-starter-kit.
# sourced by install.sh and every scripts/NN-*.sh step.
#
# OS-agnostic helpers (colors, run, ask/confirm, inject_block, …) live in
# lib/common.sh so the macOS and Linux kits share ONE copy. This file adds only
# the Linux-specific bits below. Resolve our own dir via BASH_SOURCE so sourcing
# works regardless of $ROOT / cwd. It must come first: the SUDO/PM setup and
# pm_* helpers below rely on have()/confirm() from common.sh.
_KIT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$_KIT_LIB_DIR/../../lib/common.sh"

# ---------------------------------------------------------------------------
# Linux-specific predicate
# ---------------------------------------------------------------------------
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

# can_sudo — true when system package installs can actually escalate:
#   * we are root, OR
#   * sudo exists AND we can obtain privileges (cached creds / NOPASSWD, or a
#     tty to prompt on). A non-interactive box where `sudo -n true` fails cannot
#     escalate, so callers should skip system packages instead of aborting.
can_sudo() {
  [[ "${EUID:-$(id -u)}" -eq 0 ]] && return 0
  [[ -n "$SUDO" ]] || return 1
  sudo -n true >/dev/null 2>&1 && return 0   # passwordless / cached creds
  is_tty                                      # otherwise we need a tty to prompt
}

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
    apt)    run $SUDO apt-get update -y || true ;;
    dnf)    run $SUDO dnf -y makecache || true ;;
    yum)    run $SUDO yum -y makecache || true ;;
    # Arch: a full -Syu is required — installing after a bare -Sy is a
    # partial upgrade (unsupported, can break glibc/openssl mismatches). We
    # therefore never do a bare -Sy. A full upgrade touches the whole system,
    # so it's confirm-gated (auto-yes under --yes, declined non-interactively).
    # Declined path: skip the refresh entirely and let the later `pacman -S`
    # installs run against the CURRENT sync DBs — this avoids the partial-
    # upgrade hazard at the cost of possibly-staler package versions.
    pacman)
      if confirm "Arch requires a full system upgrade (pacman -Syu) before installing. Run it now?"; then
        run $SUDO pacman -Syu --noconfirm || true
      else
        warn "skipping 'pacman -Syu' — installs will use the current sync DBs (no partial-upgrade refresh)"
      fi ;;
    zypper) run $SUDO zypper --non-interactive refresh || true ;;
    apk)    run $SUDO apk update || true ;;
    *)      warn "no supported package manager detected" ;;
  esac
}

# pm_install PKG...  — install one or more system packages (non-interactive)
pm_install() {
  [[ $# -gt 0 ]] || return 0
  pm_refresh   # refresh the package index once (no-op after the first call)
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
