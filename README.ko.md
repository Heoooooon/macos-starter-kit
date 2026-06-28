<div align="center">

<img src="./docs/banner.png" alt="macos-starter-kit" width="760" />

### 새 맥북을 명령어 한 줄로 완전한 개발 환경까지.

_런타임 · 셸 · 컨테이너 · AI 코딩 에이전트까지 — 설치부터 검증까지._

[![CI](https://github.com/Heoooooon/macos-starter-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/Heoooooon/macos-starter-kit/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/tag/Heoooooon/macos-starter-kit?label=release&sort=semver&color=2ea043)](https://github.com/Heoooooon/macos-starter-kit/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](./LICENSE)
[![Platform](https://img.shields.io/badge/macOS-Apple%20Silicon-000000?logo=apple&logoColor=white)](#)
[![Stars](https://img.shields.io/github/stars/Heoooooon/macos-starter-kit?style=flat&color=f0c000)](https://github.com/Heoooooon/macos-starter-kit/stargazers)

[English](./README.md) · **한국어** · [설치 흐름 ↗](https://heoooooon.github.io/macos-starter-kit/) · [Changelog](./CHANGELOG.md)

</div>

---

## 빠른 시작

```sh
curl -fsSL https://raw.githubusercontent.com/Heoooooon/macos-starter-kit/main/install.sh | bash
```

`git`도 없는 완전 새 맥에서는 먼저 Xcode Command Line Tools 설치가 뜹니다 —
설치가 끝나면 같은 명령어를 한 번 더 실행하세요.

실행 전에 내용을 먼저 보고 싶다면 (권장):

```sh
git clone https://github.com/Heoooooon/macos-starter-kit.git
cd macos-starter-kit
./install.sh --dry-run     # 무엇을 할지만 정확히 출력
./install.sh               # 실제 적용
```

## 무엇이 깔리나

| 계층 | 도구 |
|---|---|
| **기반** | Xcode Command Line Tools, Homebrew |
| **CLI** | git, gh, jq, ripgrep, fd, fzf, bat, tree, wget, ast-grep |
| **유지보수** | **Mole**(`mo`) — Mac 정리/삭제/분석/최적화/모니터링 |
| **셸** | zsh + oh-my-zsh (플러그인: git, npm, node, macos, autosuggestions, syntax-highlighting), **starship** 프롬프트, JetBrainsMono Nerd Font |
| **런타임** | **mise** → node(LTS), python, go · **rustup** → rust + rust-analyzer · uv · bun |
| **컨테이너** | **Colima** + docker / compose / buildx (Docker Desktop 불필요) |
| **Git/GitHub** | 신원(GitHub noreply 이메일), HTTPS 자격증명 도우미, 합리적 기본값 |
| **AI 에이전트** | **gajae-code**(`gjc`), **codex**, **lazycodex**(OmO), **Hermes Agent**(`hermes`, Nous Research) |

## 단계 & 옵션

단계는 이 순서로 실행됩니다:

```
prereqs  brew  runtimes  shell  docker  git  agents
```

```sh
./install.sh --dry-run          # 아무것도 안 바꾸고 출력만
./install.sh --yes              # 비대화형, 기본값으로 진행
./install.sh --only brew,shell  # 일부 단계만 실행
./install.sh --skip agents      # 특정 단계만 건너뜀
./install.sh --no-agents        # --skip agents 의 별칭
./install.sh --list             # 단계 id 목록 출력
```

모든 단계는 **멱등(idempotent)** — 몇 번을 돌려도 안전합니다. `~/.zshrc`, `~/.zprofile`,
`~/.docker/config.json`은 명확히 표시된 **마커 블록**으로만 편집되어
재실행 시 교체됩니다(중복 안 됨). 사용자가 소유한 기존 파일은 보존됩니다.

## 이미 도구가 깔린 맥에서 돌릴 때

이 키트는 **빈 맥**에 최적화돼 있지만, 반쯤 세팅된 맥에서 돌려도 안전합니다 —
설정을 절대 덮어쓰지 않습니다. 구체적으로:

- **기본적으로 비파괴적**: Homebrew·oh-my-zsh·`gjc`·`codex`는 이미 있으면 건너뜀.
  **git 신원**은 비어 있을 때만 설정(덮어쓰지 않음). `brew bundle`은 이미 깔린 건 스킵.
- **런타임은 주의할 예외.** node/python/go는 **mise**로 설치됩니다.
  이미 다른 방식(시스템 `.pkg`, `nvm`, `brew` 등)으로 node가 있어도, mise는 **자기 것을**
  설치하고 **PATH로 기존 것을 가립니다(shadow)** — 기존 것을 지우거나 옮기지 않습니다.
  결국 둘이 공존하고 새 셸에선 mise 것이 이깁니다. `runtimes` 단계는 비-mise 런타임을
  감지하면 경고를 출력합니다. `which -a node`로 확인하세요.
- **`~/.zshrc`를 손으로 편집했다면?** 키트가 자기 마커 블록을 추가하므로, 직접 넣은 줄
  (예: 본인의 `mise activate` / `starship init`)이 키트 것과 **함께** 실행됩니다 —
  무해하지만 중복입니다. 본인 줄을 마커 블록 안으로 옮기거나 중복을 제거하세요.
- **Docker Desktop이 이미 있다면?** Colima는 공존하지만 `docker` CLI와 컨텍스트를
  공유합니다. 혼란을 피하려면 하나를 고르세요(`docker context use`).

## 권한 (sudo)

스크립트는 **`sudo`를 직접 호출하지 않습니다.** 권한 상승이 필요한 곳은 딱 두 군데,
그것도 진짜 빈 맥에서만:

- **Homebrew 설치** — 공식 installer가 맥 비밀번호를 한 번 묻습니다
  (`prereqs` 단계, brew가 없을 때만).
- **Xcode Command Line Tools** — GUI 대화창에서 "설치"를 클릭 (없을 때만).

그 외 전부 **user 공간에서, sudo 없이** 실행됩니다: mise → `~/.local`, rustup →
`~/.rustup`, bun → `~/.bun`, Homebrew 패키지(설치 후), 그리고 dotfiles는 전부 `~`.
cmux 같은 cask를 `/Applications`에 설치할 때 비밀번호를 물을 수 있고, 앱을 처음
실행할 때 뜨는 Gatekeeper/권한 팝업은 정상입니다(설치가 아니라 사용 시점).
`gh auth login`은 본인 GitHub 계정 로그인이지 시스템 권한이 아닙니다. uninstall도
전부 user 공간입니다(Homebrew 자체는 절대 제거 안 함).

## 커스터마이즈

- **brew 패키지** — [`Brewfile`](./Brewfile) 편집 후 `./install.sh --only brew`.
- **런타임 버전** — [`scripts/03-runtimes.sh`](./scripts/03-runtimes.sh)의 `MISE_TOOLS` 편집.
- **프롬프트** — [`config/starship.toml`](./config/starship.toml) (없을 때만 `~/.config/`로 복사).
- **셸 블록** — [`config/zshrc.block.sh`](./config/zshrc.block.sh).

## 선택 설치: 생산성 앱

기본 키트는 **개발 도구 중심**으로 유지합니다. 다만 새 맥을 일상 작업용으로도 바로
쓰고 싶다면, 아래의 작고 엄선된 무료/오픈소스 앱을 추가로 설치하세요 — 의도적으로
최소한만 담았고, "추천 앱 모음"이 아닙니다:

```sh
brew bundle --file Brewfile.optional
# 또는 직접:
brew install --cask rectangle maccy
```

- **[Rectangle](https://github.com/rxhanson/Rectangle)** — 창 정리(스냅), Magnet 대체용 무료/오픈소스.
- **[Maccy](https://github.com/p0deje/Maccy)** — 클립보드 히스토리 관리, 무료/오픈소스.

> **기본(base) vs 옵션:** 기본 설치는 고정된 린한 개발 base이고, 새로 추가되는 비핵심
> 도구는 `Brewfile.optional`로 들어갑니다. [CONTRIBUTING.md](./CONTRIBUTING.md) 참고.

## 설치 후 할 일

1. **새 터미널 열기** (또는 `source ~/.zshrc`) → PATH/프롬프트 로드.
2. **GitHub**: `gh auth login`을 건너뛰었다면 한 번 실행.
3. **Colima**: 필요할 때 `colima start` (로그인 시 자동 시작은 `brew services start colima`).
   재부팅 후엔 서비스로 등록하지 않는 한 자동으로 안 뜹니다.
4. **lazycodex**: `codex`를 한 번 실행하고 startup review에서 **OmO 훅을 승인**하세요.
   승인 전엔 훅이 실행되지 않습니다.

## AI 에이전트 참고

- **gajae-code**(`gjc`)는 **bun**으로 전역 설치(`bun add -g gajae-code`)되며, 바이너리는
  `~/.bun/bin`에 있습니다(셸 블록이 PATH에 추가).
- **codex**(`@openai/codex`)는 npm으로 전역 설치(mise 관리 node).
- **lazycodex**는 의도적으로 **전역 설치하지 않습니다** — 항상 `npx lazycodex-ai …`로
  실행되며 codex 위에 OmO 하니스를 얹습니다.
- **Hermes Agent**(Nous Research)는 공식 원라이너
  (`curl …hermes-agent.nousresearch.com/install.sh | bash`)를 `--skip-setup`으로 설치합니다.
  Python/Node/Chromium을 자체 관리하고 `hermes`를 `~/.local/bin`에 링크합니다. 이 설치는
  **비치명적**(실패해도 경고만)이며 `HERMES=0 ./install.sh`로 건너뛸 수 있습니다.
  설치 후 `hermes setup --portal`로 설정하고 `hermes`로 시작하세요.

## 제거 (Uninstall)

키트가 설치한 모든 것을 의존성 역순으로 되돌립니다:

```sh
./uninstall.sh --dry-run     # 테어다운 미리보기
./uninstall.sh               # 실행 (위험 그룹은 confirm으로 물어봄)
./uninstall.sh --yes         # 비대화형, 모든 제거 자동 수락
./uninstall.sh --only agents # 한 그룹만 제거
```

그룹: `agents shell docker runtimes brew` (역순 실행).

안전 설계:
- **자동으로 절대 제거 안 함**: Homebrew, Xcode Command Line Tools, 그리고 **git 신원**.
- **gajae-code(`gjc`)는 보존** — `--with-gajae`를 줘야 제거(단, `gjc` 실행 중이면 거부).
- codex 제거 시 `~/.codex/auth.json`을 먼저 `~/`에 백업. `--keep-codex-home`을 주면
  `~/.codex`를 그대로 둠.
- Hermes 제거 시 `~/.local/bin/hermes` 심을 지우고, 확인 후 `~/.hermes`를 삭제.
- dotfiles에서는 키트 자신의 마커 블록(`# >>> macos-starter-kit:* >>>`)만 제거 —
  손으로 쓴 줄은 건드리지 않음.

## 버전 관리

릴리스는 태그(`vX.Y.Z`)로 관리하며 [SemVer](https://semver.org/)를 따릅니다 —
[CHANGELOG.md](./CHANGELOG.md) 참고. 설치본 버전은 `./install.sh --version`으로 확인.

`main` 대신 특정 릴리스로 고정해서 설치하기:

```sh
STARTER_KIT_BRANCH=v0.1.0 \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/Heoooooon/macos-starter-kit/v0.1.0/install.sh)"
```

## 크레딧 (Credits)

이 키트는 다른 분들의 훌륭한 오픈소스를 엮어놓은 것뿐입니다. 모든 공은 원작
프로젝트에 — 스타/후원 부탁드려요:

**기반 & CLI**
- [Homebrew](https://brew.sh) · [git](https://git-scm.com) · [GitHub CLI](https://github.com/cli/cli)
- [ripgrep](https://github.com/BurntSushi/ripgrep) · [fd](https://github.com/sharkdp/fd) · [fzf](https://github.com/junegunn/fzf) · [bat](https://github.com/sharkdp/bat)
- [jq](https://github.com/jqlang/jq) · [tree](https://gitlab.com/OldManProgrammer/unix-tree) · [wget](https://www.gnu.org/software/wget/) · [ast-grep](https://github.com/ast-grep/ast-grep)
- [Mole](https://github.com/tw93/Mole) — Mac 정리/삭제/분석/최적화

**런타임**
- [mise](https://github.com/jdx/mise) · [uv](https://github.com/astral-sh/uv) · [rustup](https://github.com/rust-lang/rustup) · [bun](https://github.com/oven-sh/bun)
- [Node.js](https://nodejs.org) · [Python](https://www.python.org) · [Go](https://go.dev) · [Rust](https://www.rust-lang.org) · [rust-analyzer](https://github.com/rust-lang/rust-analyzer)

**셸**
- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) · [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) · [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [Starship](https://github.com/starship/starship) · [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts) ([JetBrains Mono](https://github.com/JetBrains/JetBrainsMono))

**컨테이너 & 터미널**
- [Colima](https://github.com/abiosoft/colima) · [Docker CLI](https://github.com/docker/cli) · [Compose](https://github.com/docker/compose) · [Buildx](https://github.com/docker/buildx)
- [cmux](https://www.cmux.dev/) (Ghostty 기반; [Ghostty](https://github.com/ghostty-org/ghostty))

**AI 에이전트**
- [gajae-code](https://github.com/Yeachan-Heo/gajae-code) · [Codex](https://github.com/openai/codex) · [lazycodex / OmO](https://github.com/code-yeongyu/lazycodex) · [Hermes Agent](https://github.com/NousResearch/hermes-agent)

## 라이선스

MIT — [LICENSE](./LICENSE) 참고.
