#!/usr/bin/env bash
# lib.sh — macOS helpers for lazy-starter-kit.
# sourced by install.sh and every scripts/NN-*.sh step.
#
# OS-agnostic helpers (colors, run, ask/confirm, inject_block, …) live in
# lib/common.sh so the macOS and Linux kits share ONE copy. This file adds only
# the macOS-specific bits below. Resolve our own dir via BASH_SOURCE so sourcing
# works regardless of $ROOT / cwd.
_KIT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$_KIT_LIB_DIR/../lib/common.sh"

# ---------------------------------------------------------------------------
# macOS-specific predicates
# ---------------------------------------------------------------------------
is_macos()    { [[ "$(uname -s)" == "Darwin" ]]; }
is_arm()      { [[ "$(uname -m)" == "arm64" ]]; }

# brew_prefix — echo the Homebrew prefix for the current arch
brew_prefix() {
  if [[ -x /opt/homebrew/bin/brew ]]; then echo /opt/homebrew
  elif [[ -x /usr/local/bin/brew ]]; then echo /usr/local
  else echo /opt/homebrew; fi
}

# load brew into the current shell env (so steps see freshly-installed brew)
load_brew() {
  local p; p="$(brew_prefix)"
  [[ -x "$p/bin/brew" ]] && eval "$("$p/bin/brew" shellenv)"
}
