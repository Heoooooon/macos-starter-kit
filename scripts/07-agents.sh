#!/usr/bin/env bash
# 07-agents.sh — AI coding agents: gajae-code (gjc), codex, lazycodex (OmO)

step_agents() {
  step "AI agents: gajae-code + codex + lazycodex"
  load_brew
  load_mise
  export PATH="$HOME/.bun/bin:$PATH"   # bun global bins (gjc) live here

  # --- gajae-code (gjc) via bun -----------------------------------------
  if have bun; then
    if have gjc; then
      ok "gajae-code present (gjc $(gjc --version 2>/dev/null | head -1))"
    else
      info "Installing gajae-code (bun add -g gajae-code)…"
      run bun add -g gajae-code
    fi
  else
    warn "bun not found — skipping gajae-code (install bun via the 'brew' step)"
  fi

  # --- codex (base harness that lazycodex extends) ----------------------
  if ! have npm; then
    warn "npm not found — skipping codex + lazycodex (run the 'runtimes' step first)"
    return 0
  fi
  if have codex; then
    ok "codex present ($(codex --version 2>/dev/null | head -1))"
  else
    info "Installing @openai/codex (npm -g)…"
    run npm install -g @openai/codex
  fi

  # --- lazycodex (OmO agent harness for codex) --------------------------
  # No global install by design — always run via npx.
  if [[ "$DRY_RUN" == "1" ]]; then
    info "[dry-run] npx --yes lazycodex-ai install"
  elif is_tty; then
    info "Installing lazycodex (npx lazycodex-ai install)…"
    npx --yes lazycodex-ai install || warn "lazycodex installer did not complete"
  else
    info "Installing lazycodex (non-interactive, autonomous)…"
    npx --yes lazycodex-ai install --no-tui --codex-autonomous || \
      warn "lazycodex installer did not complete"
  fi
  info "lazycodex: on first 'codex' launch, APPROVE the omo hooks in the startup review."
}
