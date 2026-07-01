#!/usr/bin/env bash
# 01-prereqs.sh — base toolchain: compiler, git, curl, zsh, unzip …

step_prereqs() {
  step "Prerequisites: base build tools + git/curl/zsh"

  [[ -n "$PM" ]] || die "no supported package manager found (need apt/dnf/yum/pacman/zypper/apk)"
  info "distro: $(distro_id)   package manager: $PM"
  if [[ "$PM" == "apk" ]]; then
    warn "Alpine/musl is NOT supported: upstream node, ast-grep and bun ship no"
    warn "musl builds, so the 'runtimes'/'agents' steps will fail. Use a glibc"
    warn "distro (Debian/Ubuntu, Fedora/RHEL, Arch, openSUSE). Continuing best-effort…"
  fi
  [[ -z "$SUDO" && "${EUID:-$(id -u)}" -ne 0 ]] && \
    warn "not root and sudo missing — system package installs may fail"

  pm_refresh

  # Base packages differ per family. build tools + the essentials the later
  # steps and tool installers (rustup, mise, oh-my-zsh) depend on.
  case "$PM" in
    apt)
      pm_install build-essential curl wget git ca-certificates unzip zip \
                 zsh procps file xz-utils ;;
    dnf|yum)
      pm_install curl wget git ca-certificates unzip zip zsh procps-ng file xz
      # @development-tools provides gcc/make; group install syntax varies
      run $SUDO "$PM" -y groupinstall "Development Tools" 2>/dev/null \
        || pm_try gcc gcc-c++ make ;;
    pacman)
      pm_install base-devel curl wget git ca-certificates unzip zip zsh procps-ng file xz ;;
    zypper)
      pm_install -t pattern devel_basis 2>/dev/null || pm_try gcc gcc-c++ make
      pm_install curl wget git ca-certificates unzip zip zsh procps file xz ;;
    apk)
      pm_install build-base curl wget git ca-certificates unzip zip zsh procps file xz bash ;;
  esac

  have git  && ok "git present ($(git --version 2>/dev/null | awk '{print $3}'))" || warn "git still missing"
  have curl && ok "curl present" || warn "curl still missing"
  ok "base prerequisites ready"
}
