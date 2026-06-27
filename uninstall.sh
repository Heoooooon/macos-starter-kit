#!/usr/bin/env bash
#
# macos-starter-kit — uninstaller. Reverses what install.sh set up, in reverse
# dependency order, idempotently. Destructive groups are confirm-gated.
#
# What it NEVER removes automatically (too system-wide / your data):
#   - Homebrew itself, Xcode Command Line Tools
#   - your git identity / config
#   - gajae-code (gjc) unless you pass --with-gajae
#
# Usage:
#   ./uninstall.sh [options]
#
# Options:
#   --dry-run          Show what would happen, change nothing.
#   --yes, -y          Non-interactive: accept every removal prompt.
#   --only  a,b,c      Run only these groups.
#   --skip  a,b,c      Run all groups except these.
#   --with-gajae       Also remove gajae-code (gjc). Refused if gjc is running.
#   --keep-codex-home  Keep ~/.codex (config/auth/sessions) when removing codex.
#   --list             List group ids and exit.
#   --help, -h         Show this help.
#
# Groups (reverse order): agents shell docker runtimes brew
#
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$SELF_DIR"
# shellcheck source=scripts/lib.sh
source "$ROOT/scripts/lib.sh"

: "${WITH_GAJAE:=0}"
: "${KEEP_CODEX_HOME:=0}"

GROUP_IDS=(agents shell docker runtimes brew)
usage() { sed -n '2,30p' "$ROOT/uninstall.sh" | sed 's/^# \{0,1\}//'; }

# ---------------------------------------------------------------------------
# agents — codex + lazycodex (+ optionally gajae-code)
# ---------------------------------------------------------------------------
undo_agents() {
  step "Remove AI agents (codex + lazycodex)"
  load_brew; load_mise
  export PATH="$HOME/.bun/bin:$PATH"

  # codex (npm global under mise node)
  if have npm && mise exec -- npm ls -g --depth=0 2>/dev/null | grep -q '@openai/codex'; then
    info "Uninstalling @openai/codex…"
    run mise exec -- npm uninstall -g @openai/codex
    have mise && run mise reshim
  else
    info "codex npm package not installed"
  fi

  # lazycodex npx cache
  local d found=0
  for d in "$HOME"/.npm/_npx/*/node_modules/lazycodex-ai; do
    [[ -e "$d" ]] || continue
    found=1
    run rm -rf "$(dirname "$(dirname "$d")")"
  done
  [[ "$found" == 1 ]] && ok "cleared lazycodex npx cache" || info "no lazycodex npx cache"

  # ~/.codex home (config, auth, sessions, omo plugin)
  if [[ -d "$HOME/.codex" && "$KEEP_CODEX_HOME" != "1" ]]; then
    if confirm "Remove ~/.codex (codex home: config, auth, sessions, omo plugin)?"; then
      if [[ -f "$HOME/.codex/auth.json" ]]; then
        local bak; bak="$HOME/codex-auth-backup-$(date +%Y%m%d-%H%M%S).json"
        run cp -p "$HOME/.codex/auth.json" "$bak" && ok "backed up auth.json -> ${bak/#$HOME/~}"
      fi
      run rm -rf "$HOME/.codex"
    else
      info "kept ~/.codex"
    fi
  fi
  if [[ -d "$HOME/.cache/codex-runtimes" ]]; then
    if confirm "Remove ~/.cache/codex-runtimes (downloaded codex runtime, large)?"; then
      run rm -rf "$HOME/.cache/codex-runtimes"
    else
      info "kept ~/.cache/codex-runtimes"
    fi
  fi

  # gajae-code (gjc) — protected by default
  if [[ "$WITH_GAJAE" == "1" ]]; then
    if pgrep -f '/.bun/bin/gjc' >/dev/null 2>&1; then
      warn "gjc is RUNNING — refusing to remove gajae-code (close the session, then re-run)"
    elif have gjc; then
      info "Removing gajae-code…"
      run bun remove -g gajae-code
    else
      info "gajae-code not installed"
    fi
  else
    info "Keeping gajae-code (pass --with-gajae to remove)"
  fi
}

# ---------------------------------------------------------------------------
# shell — managed blocks + (optional) oh-my-zsh / starship.toml
# ---------------------------------------------------------------------------
undo_shell() {
  step "Revert shell configuration"
  remove_block "$HOME/.zshrc"            "macos-starter-kit:main"
  remove_block "$HOME/.zshrc"            "macos-starter-kit:ohmyzsh"
  remove_block "$HOME/.zprofile"         "macos-starter-kit:brew"
  remove_block "$HOME/.config/ghostty/config" "macos-starter-kit:ghostty"

  if [[ -f "$HOME/.config/starship.toml" ]]; then
    if confirm "Remove ~/.config/starship.toml?"; then run rm -f "$HOME/.config/starship.toml"
    else info "kept starship.toml"; fi
  fi
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    if confirm "Remove ~/.oh-my-zsh (framework + plugins)?"; then run rm -rf "$HOME/.oh-my-zsh"
    else info "kept oh-my-zsh"; fi
  fi
}

# ---------------------------------------------------------------------------
# docker — Colima VM + docker plugin config entry
# ---------------------------------------------------------------------------
undo_docker() {
  step "Remove containers (Colima VM + docker config entry)"
  load_brew
  if have colima && colima list 2>/dev/null | grep -q colima; then
    if confirm "Stop and delete the Colima VM (containers & images lost)?"; then
      run colima stop || true
      run colima delete --force || true
    else
      info "kept Colima VM"
    fi
  else
    info "no Colima VM"
  fi

  local cfg="$HOME/.docker/config.json" pdir; pdir="$(brew_prefix)/lib/docker/cli-plugins"
  if [[ -f "$cfg" ]] && have jq && grep -q cliPluginsExtraDirs "$cfg" 2>/dev/null; then
    if [[ "$DRY_RUN" == "1" ]]; then
      info "[dry-run] would remove $pdir from $cfg"
    else
      local tmp; tmp="$(mktemp)"
      jq --arg d "$pdir" '(.cliPluginsExtraDirs) |= (map(select(. != $d)))' "$cfg" > "$tmp" && mv "$tmp" "$cfg"
      ok "removed plugin dir from docker config"
    fi
  fi
}

# ---------------------------------------------------------------------------
# runtimes — mise tools + rustup
# ---------------------------------------------------------------------------
undo_runtimes() {
  step "Remove language runtimes (mise node/python/go + rustup)"
  load_brew
  if have mise; then
    if confirm "Remove mise-managed node/python/go (versions + global config entries)?"; then
      if [[ "$DRY_RUN" == "1" ]]; then
        info "[dry-run] mise uninstall node python go ; mise rm -g node python go"
      else
        mise uninstall node python go 2>/dev/null || true
        local t; for t in node python go; do mise rm -g "$t" 2>/dev/null || true; done
        ok "removed mise runtimes"
      fi
    else
      info "kept mise runtimes"
    fi
  fi
  if have rustup; then
    if confirm "Uninstall Rust (rustup self uninstall)?"; then
      if [[ "$DRY_RUN" == "1" ]]; then info "[dry-run] rustup self uninstall -y"
      else rustup self uninstall -y || true; ok "rust uninstalled"; fi
    else
      info "kept rust/rustup"
    fi
  fi
}

# ---------------------------------------------------------------------------
# brew — uninstall everything listed in the Brewfile
# ---------------------------------------------------------------------------
undo_brew() {
  step "Uninstall Homebrew packages listed in the Brewfile"
  load_brew
  have brew || { warn "brew not found"; return 0; }
  local bf="$ROOT/Brewfile"
  [[ -f "$bf" ]] || { warn "no Brewfile at $bf"; return 0; }

  if ! confirm "Uninstall all formulae/casks in the Brewfile? (Homebrew itself stays)"; then
    info "kept brew packages"; return 0
  fi
  local f
  for f in $(grep -E '^brew "' "$bf" | sed -E 's/^brew "([^"]+)".*/\1/'); do
    run brew uninstall "$f" 2>/dev/null || warn "skip $f (missing, in use, or has dependents)"
  done
  for f in $(grep -E '^cask "' "$bf" | sed -E 's/^cask "([^"]+)".*/\1/'); do
    run brew uninstall --cask "$f" 2>/dev/null || warn "skip cask $f"
  done
  ok "Brewfile packages processed"
}

# ---------------------------------------------------------------------------
# Arg parsing
# ---------------------------------------------------------------------------
ONLY=""; SKIP=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)         export DRY_RUN=1 ;;
    -y|--yes)          export ASSUME_YES=1 ;;
    --only)            ONLY="${2:-}"; shift ;;
    --only=*)          ONLY="${1#*=}" ;;
    --skip)            SKIP="${2:-}"; shift ;;
    --skip=*)          SKIP="${1#*=}" ;;
    --with-gajae)      export WITH_GAJAE=1 ;;
    --keep-codex-home) export KEEP_CODEX_HOME=1 ;;
    --list)            printf '%s\n' "${GROUP_IDS[@]}"; exit 0 ;;
    -h|--help)         usage; exit 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
  shift
done

selected() {
  local id keep
  for id in "${GROUP_IDS[@]}"; do
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
# Run
# ---------------------------------------------------------------------------
is_macos || die "macOS only."
[[ "$DRY_RUN" == "1" ]] && warn "DRY-RUN: no changes will be made."

printf '%s\n' "$_C_BOLD== macos-starter-kit · uninstall ==$_C_RESET"
info "groups: $(selected | tr '\n' ' ')"
warn "Homebrew, Xcode CLT, and your git identity are left untouched (remove manually if desired)."

for id in $(selected); do
  "undo_$id"
done

step "Uninstall complete."
ok "Restart your terminal. To fully reset prereqs, remove Homebrew/Xcode CLT manually."
[[ "$DRY_RUN" == "1" ]] && info "That was a dry run — re-run without --dry-run to apply."
exit 0
