# Plan: claude-profile-manager

## Executive Summary

| 항목 | 내용 |
|------|------|
| Feature | claude-profile-manager (cpm) |
| 시작일 | 2026-04-28 |
| 기반 | claude-accounts-switch (CLAUDE_CONFIG_DIR 방식) |

### Value Delivered

| 관점 | 내용 |
|------|------|
| Problem | claude-accounts-switch는 회사 GitLab에 종속된 설치 방식이었고, UX가 거칠었음 |
| Solution | curl/brew 설치 지원 + prefix `cpm` + 초기 셋업·UI 전면 개선 |
| Function UX Effect | 누구나 한 줄로 설치 가능하고, 첫 사용 진입 장벽을 낮춤 |
| Core Value | 개인 오픈소스로 Claude Code 멀티 계정 세션을 가장 쉽게 쓸 수 있는 도구 |

---

## 1. 배경 및 목표

### 1.1 배경

`claude-accounts-switch`(사내 프로젝트)에서 핵심 아키텍처를 그대로 가져오되,
완전한 개인 오픈소스 프로젝트로 재개발한다.

- **아키텍처 유지**: `CLAUDE_CONFIG_DIR` 기반 세션별 독립 계정
- **플랫폼 유지**: macOS / Linux / WSL 모두 지원
- **코드 유지**: 순수 shell script (bash)

### 1.2 변경 범위

| 영역 | 변경 내용 |
|------|----------|
| prefix | `cas` → `cpm` |
| 설치 방식 | git clone 전용 → **curl** + **brew** + git clone |
| 초기 셋업 플로우 | 단순 create/clone 안내 → **대화형 위저드** |
| UI | 출력 디자인 전면 정리 |

---

## 2. 설치 방식 설계

### 2.1 curl 설치 (핵심)

```bash
curl -fsSL https://raw.githubusercontent.com/<user>/claude-profile-manager/main/install.sh | bash
```

- `install.sh`이 GitHub raw URL에서 바로 실행 가능하도록 설계
- 스크립트 내부에서 나머지 파일(main script, shell integrations)을 curl로 추가 다운로드
- macOS: `/usr/local/bin/`, Linux/WSL: `~/.local/bin/`

### 2.2 brew 설치

```bash
brew tap <user>/claude-profile-manager
brew install claude-profile-manager
# 또는 한 줄로
brew install <user>/claude-profile-manager/claude-profile-manager
```

- **별도 레포 불필요** — 동일 레포에 `Formula/` 디렉토리 추가
- Formula 파일: `Formula/claude-profile-manager.rb`
- Formula는 GitHub release tarball을 참조

### 2.3 git clone (유지)

```bash
git clone https://github.com/<user>/claude-profile-manager.git
cd claude-profile-manager && bash install.sh
```

---

## 3. UX 개선 설계

### 3.1 prefix: `cpm`

모든 명령어 alias 및 자동완성이 `cpm`으로 변경된다.

```bash
cpm                  # 프로필 없이 claude 실행
cpm work             # work 프로필로 claude 실행
cpm status           # 프로필 현황
cpm create <name>    # 새 프로필 생성
```

### 3.2 초기 셋업 위저드 (`cpm setup`)

기존: 단순 안내 출력 수준
개선: **단계별 대화형 위저드**

```
┌─────────────────────────────────────────────┐
│  claude-profile-manager 초기 설정           │
│  Claude Code 멀티 계정 세션 관리 도구       │
└─────────────────────────────────────────────┘

Step 1/3  현재 로그인된 계정을 첫 번째 프로필로 저장합니다.
  프로필 이름을 입력하세요 (예: work, personal): work
  ✓ 'work' 프로필 생성 완료

Step 2/3  두 번째 계정을 추가하시겠습니까? (y/N): y
  새 계정 이름을 입력하세요: personal
  → 'cpm create personal'을 실행합니다...

Step 3/3  설정이 완료되었습니다!
  cpm work      → work 계정으로 Claude 실행
  cpm personal  → personal 계정으로 Claude 실행
  cpm status    → 프로필 현황 확인
```

### 3.3 UI 개선 포인트

**`cpm status` 출력 개선**

```
  profile        account
  ────────────────────────────────────
  ✓  work         work@company.com
  ✗  personal     (로그인 필요)
```

- 현재 활성 세션 프로필 강조 표시 (CLAUDE_CONFIG_DIR 기반)
- 컬럼 정렬 및 색상 일관성

**`cpm help` 출력 개선**

- 명령어 그룹핑 (기본 사용 / 프로필 관리 / 기타)
- 예시 포함

**에러 메시지 개선**

- 맥락 있는 오류 안내 (다음 명령어 힌트 포함)

---

## 4. 명령어 구조 (최종)

| 명령 | 설명 |
|------|------|
| `cpm [profile]` | 프로필로 claude 실행 (없으면 기본 실행) |
| `cpm create <name>` | 새 계정용 프로필 생성 + 로그인 |
| `cpm clone <name>` | 현재 계정으로 프로필 복제 |
| `cpm rename <old> <new>` | 프로필 이름 변경 |
| `cpm remove <name>` | 프로필 삭제 |
| `cpm status` | 프로필 현황 |
| `cpm list` | 프로필 목록 (스크립트용) |
| `cpm setup` | 대화형 초기 설정 위저드 |
| `cpm doctor` | 환경 확인 |
| `cpm statusline` | Claude Code statusline 설정 |
| `cpm help` | 도움말 |

---

## 5. 파일 구조

```
claude-profile-manager/
├── install.sh                      # curl 설치 지원 (파일 자동 다운로드)
├── README.md
├── LICENSE
└── src/
    ├── claude-profile-manager      # 메인 bash 스크립트
    ├── claude-profile-manager.zsh  # zsh 통합 (alias cpm + 자동완성)
    ├── claude-profile-manager.bash # bash 통합 (alias cpm + 자동완성)
    └── statusline-command.sh       # Claude Code statusline 스크립트
```

brew Formula (동일 레포):
```
claude-profile-manager/
└── Formula/
    └── claude-profile-manager.rb
```

---

## 6. 구현 순서

1. **프로젝트 기반 설정** — 디렉토리 구조, LICENSE 확인
2. **메인 스크립트 이식** — `claude-accounts-switch` → `claude-profile-manager`, `cas` → `cpm`
3. **셸 통합 파일 이식** — zsh/bash completion + alias `cpm`
4. **statusline 스크립트 이식** — cpm prefix 반영
5. **초기 셋업 위저드 구현** — `cmd_setup()` 전면 재작성
6. **UI 개선** — status/help/error 출력 정리
7. **curl 설치 지원** — `install.sh` 개선 (파일 다운로드 로직 추가)
8. **brew Formula 작성** — homebrew-tap 레포 생성
9. **README 작성** — curl/brew/git 설치 모두 안내
10. **최종 검증** — doctor, create, clone, status, statusline 동작 확인

---

## 7. 성공 기준

- [ ] `curl -fsSL .../install.sh | bash` 한 줄로 설치 완료
- [ ] `brew install <user>/tap/claude-profile-manager` 동작
- [ ] `cpm setup` 위저드로 5분 안에 첫 프로필 설정 완료
- [ ] `cpm work` / `cpm personal` 동시 세션에서 각각 다른 계정 사용 확인
- [ ] macOS / Linux / WSL 모두 정상 동작
