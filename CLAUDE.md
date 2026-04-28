# claude-profile-manager

Claude Code multi-account profile manager. Manages multiple Claude Code accounts as profiles via `CLAUDE_CONFIG_DIR`, enabling simultaneous sessions with different accounts across terminals.

## Project Overview

Pure bash CLI tool (no build step, no dependencies beyond bash/python3). Users install via `curl | bash`, `brew`, or `git clone`, then use `cpm <profile>` to switch accounts.

### Architecture

```
src/
├── claude-profile-manager        # Main CLI (bash). Subcommands: create, clone, rename, remove, status, setup, doctor, statusline
├── claude-profile-manager.zsh    # zsh shell integration (alias cpm + completion)
├── claude-profile-manager.bash   # bash shell integration (alias cpm + completion)
└── statusline-command.sh         # Claude Code statusline script (Dracula theme, reads JSON from stdin)
install.sh                        # Installer for curl/git-clone (handles macOS/Linux/WSL, sudo, rc file injection)
Formula/claude-profile-manager.rb # Homebrew formula
```

Each profile lives at `~/.claude-<name>/`. Credentials (`.credentials.json`, `.claude.json`) are isolated per profile; everything else is symlinked to `~/.claude/`.

### Key Design Decisions

- `CLAUDE_CONFIG_DIR` is set **only for the claude subprocess** (`CLAUDE_CONFIG_DIR="$dir" command claude`), not exported to the parent shell. There is no global "active profile" — each terminal session is independent.
- macOS: credentials come from Keychain (`security find-generic-password`). Linux: copied from `~/.claude/.credentials.json`.
- Profile directories get `700` permissions; credential files get `600`.

## Shell Environment

scm_breeze is installed — `git` is aliased and causes `_safe_eval` errors. Always use `/usr/bin/git` absolute path.

HEREDOC commit messages (`-m "$(cat <<'EOF'...)"`) do not work in this environment. Use temp file approach: write to `/tmp/commit_msg.txt` then `git commit -F /tmp/commit_msg.txt`.

## Git Workflow

```
main ← develop ← feat/*, fix/*, refactor/*
```

- Feature branches branch off `develop`, PR back to `develop`
- Release: changelog created on `develop`, PR to `main`, merge, tag on `main`
- Tag push triggers GitHub Actions → automatic GitHub Release from `changelogs/v{version}.md`

### Branching Rules

| Branch | Purpose | PR Target |
|--------|---------|-----------|
| `main` | Production, releases | — |
| `develop` | Integration | `main` (release only) |
| `feat/*` | New features | `develop` |
| `fix/*` | Bug fixes | `develop` |
| `refactor/*` | Refactoring | `develop` |

### Commit Convention

Conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `ci:`, `perf:`, `style:`

### Release Flow

1. `/changelog` → analyze commits, determine version (semver), create `changelogs/v{version}.md`, commit to `develop`
2. `/pr` (on develop) → create `develop → main` Release PR
3. Merge PR → GitHub Actions automatically: detect new changelog → create tag → create GitHub Release

### Changelogs

Each release gets its own file in `changelogs/`:
```
changelogs/
├── v0.1.0.md
├── v0.2.0.md
└── v0.3.0.md
```

These are the **source of record** for release notes. GitHub Release body is generated from these files automatically.

## Claude Code Commands

| Command | Description |
|---------|-------------|
| `/commit` | Stage check → commit message → commit (no approval step, no push) |
| `/pr` | Auto-detect base branch → generate title/body → create PR via `gh` |
| `/changelog` | Analyze commits → determine version → create `changelogs/v{version}.md` → commit to develop |

## Testing

No test framework. Manual testing only:
- `bash install.sh` on macOS/Linux
- `cpm setup`, `cpm create`, `cpm clone`, `cpm status`, `cpm doctor`
- Verify symlinks and credential isolation in profile directories

## Language

All user-facing text (README, CLI output, comments) is in **English**. The `docs/` directory may contain Korean documents. Claude Code command files (`.claude/commands/`) are written in Korean (instructions for Claude).
