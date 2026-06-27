#!/usr/bin/env bash
# 02-brew.sh — install everything in the Brewfile

step_brew() {
  step "Homebrew packages (Brewfile)"
  load_brew
  have brew || die "Homebrew not found — run the 'prereqs' step first."

  local brewfile="$ROOT/Brewfile"
  [[ -f "$brewfile" ]] || die "missing Brewfile at $brewfile"

  export HOMEBREW_NO_ENV_HINTS=1
  if [[ "$DRY_RUN" == "1" ]]; then
    info "[dry-run] brew bundle --file=$brewfile  (would install missing formulae/casks)"
    info "[dry-run] pending entries:"
    brew bundle check --file="$brewfile" --verbose 2>/dev/null | sed 's/^/    /' || true
    return 0
  fi

  run brew update --quiet || warn "brew update failed (continuing)"
  run brew bundle --no-lock --file="$brewfile"
  ok "Brewfile applied"
}
