# claude-profile-manager

> A tool for managing Claude Code accounts as profiles and running different accounts simultaneously per session

Saves multiple Claude Code accounts (work/personal, team/Max plan, etc.) as profiles and switches with a single `cpm <name>` command.  
Switches instantly without `claude auth logout` / `claude auth login`, and multiple terminals can run different accounts simultaneously.

---

## How It Works

Uses the `CLAUDE_CONFIG_DIR` environment variable to set an independent directory per session.  
Each profile uses a `~/.claude-<name>/` directory — only credentials are isolated per profile; settings, memory, and history are shared via `~/.claude/`.

```
~/.claude/                  ← settings, memory, history (shared)
~/.claude-work/             ← work profile (isolated credentials)
~/.claude-personal/         ← personal profile (isolated credentials)
```

Running `cpm work` in Terminal A and `cpm personal` in Terminal B allows both sessions to operate with different accounts simultaneously.

---

## Supported Platforms

| Platform | Supported |
|----------|-----------|
| macOS | ✓ |
| Linux | ✓ |
| WSL2 | ✓ |

---

## Prerequisites

| Item | Requirement |
|------|-------------|
| Claude Code | Installed and logged in |
| python3 | 3.6 or higher |
| Shell | zsh or bash |
| macOS | sudo access |

---

## Installation

### curl (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/wonseok-han/claude-profile-manager/main/install.sh | bash
```

### Homebrew

```bash
brew tap wonseok-han/claude-profile-manager
brew install claude-profile-manager
```

Shell integration is not installed automatically — add it to your rc file manually:

```bash
# zsh (~/.zshrc)
source $(brew --prefix)/share/claude-profile-manager/claude-profile-manager.zsh

# bash (~/.bashrc)
source $(brew --prefix)/share/claude-profile-manager/claude-profile-manager.bash
```

### git clone

```bash
git clone https://github.com/wonseok-han/claude-profile-manager.git
cd claude-profile-manager
bash install.sh
```

### macOS Install Path

Installs to `/usr/local/bin/` and requires sudo.

### Linux / WSL Install Path

Installs to `~/.local/bin/` without sudo.

---

## Initial Setup

After installation, reload your shell and run the wizard.

```bash
source ~/.zshrc   # or source ~/.bashrc
cpm setup
```

```
  ┌─────────────────────────────────────────────┐
  │  claude-profile-manager setup               │
  │  Claude Code multi-account session manager  │
  └─────────────────────────────────────────────┘

  Step 1/2  Save your current logged-in account as the first profile.
            Profile name (e.g. work, personal): work

  Step 2/2  Would you like to add another Claude account? (y/N): y
            New profile name: personal
  ...
  ─────────────────────────────────────────────
  Setup complete!

  cpm status      Show profile status
  cpm <name>      Run Claude with that account
```

---

## Commands

### Basic Usage

```bash
cpm              # Show profile status (runs default claude if none)
cpm work         # Switch to work profile and run claude
cpm personal     # Switch to personal profile and run claude
cpm work -r      # Resume session
```

### Profile Management

| Command | Description |
|---------|-------------|
| `cpm create <name>` | Create a new profile and log in immediately |
| `cpm clone <name>` | Clone the current account into a new profile |
| `cpm refresh <name>` | Refresh expired credentials without re-login |
| `cpm rename <old> <new>` | Rename a profile |
| `cpm remove <name>` | Delete a profile |

### `cpm status` — Profile Overview

```bash
cpm status
```

```
  profile              account
  ─────────────────────────────────────────────────
  ✓  work              work@company.com
  ✓  personal          me@gmail.com
  ✗  test              (login required)
```

### Other Commands

| Command | Description |
|---------|-------------|
| `cpm setup` | Interactive initial setup wizard |
| `cpm doctor` | Check environment and authentication status |
| `cpm statusline` | Set up profile name display in Claude Code statusline |
| `cpm uninstall` | Remove claude-profile-manager from system |
| `cpm help` | Print help |

### Profile Name Rules

Only letters, numbers, `_`, `.`, and `-` are allowed; maximum 64 characters. Names starting with `-` are not allowed.

---

## Structure

```
claude-profile-manager/
├── install.sh                        # Installation script (supports curl and git clone)
├── README.md
├── LICENSE
├── Formula/
│   └── claude-profile-manager.rb    # Homebrew Formula
└── src/
    ├── claude-profile-manager        # Main bash script
    ├── claude-profile-manager.zsh   # zsh shell integration (alias cpm + completion)
    ├── claude-profile-manager.bash  # bash shell integration (alias cpm + completion)
    └── statusline-command.sh        # Claude Code statusline script
```

---

## Security

Each profile directory is created with `700` permissions.  
Credential files (`.credentials.json`, `.claude.json`) are stored with `600` permissions.  
This tool is designed for **single-user environments**.  
Not recommended for shared machines, multi-user servers, or remote SSH environments.

---

## References

- [jean-claude](https://github.com/MikeVeerman/jean-claude) — multi-account approach using the `CLAUDE_CONFIG_DIR` environment variable.
- [claude-switch](https://github.com/Mamdouh66/claude-switch) — initial Keychain-based approach.
