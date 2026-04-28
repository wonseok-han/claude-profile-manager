#!/usr/bin/env bash
# install.sh — claude-profile-manager installation script
# Supports macOS, Linux, WSL
# curl install: curl -fsSL https://raw.githubusercontent.com/USER/claude-profile-manager/main/install.sh | bash
# git clone install: bash install.sh

set -e

GITHUB_REPO="https://raw.githubusercontent.com/USER/claude-profile-manager/main"

if [ -t 1 ]; then
  COLOR_BOLD="\033[1m"
  COLOR_DIM="\033[2m"
  COLOR_RED="\033[0;31m"
  COLOR_GREEN="\033[0;32m"
  COLOR_YELLOW="\033[0;33m"
  COLOR_CYAN="\033[0;36m"
  COLOR_RESET="\033[0m"
else
  COLOR_BOLD=""
  COLOR_DIM=""
  COLOR_RED=""
  COLOR_GREEN=""
  COLOR_YELLOW=""
  COLOR_CYAN=""
  COLOR_RESET=""
fi

_error() {
  printf "  ${COLOR_RED}✗ %s${COLOR_RESET}\n" "$1" >&2
}

_success() {
  printf "  ${COLOR_GREEN}✓ %s${COLOR_RESET}\n" "$1"
}

# ────────────────────────────────────────────
# Platform detection
# ────────────────────────────────────────────
_detect_platform() {
  case "$(uname -s)" in
    Darwin) printf 'macos' ;;
    Linux)
      if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
        printf 'wsl'
      else
        printf 'linux'
      fi
      ;;
    *) printf 'unknown' ;;
  esac
}

PLATFORM="$(_detect_platform)"

# ────────────────────────────────────────────
# Install path resolution
# ────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)" || SCRIPT_DIR="$(pwd)"
SRC_DIR="$SCRIPT_DIR/src"

if [ "$PLATFORM" = "macos" ]; then
  BIN_DEST="/usr/local/bin/claude-profile-manager"
  SHARE_DEST="/usr/local/share/claude-profile-manager"
  NEED_SUDO=true
else
  BIN_DEST="$HOME/.local/bin/claude-profile-manager"
  SHARE_DEST="$HOME/.local/share/claude-profile-manager"
  NEED_SUDO=false
fi

ZSHRC_BEGIN="# BEGIN claude-profile-manager"
ZSHRC_END="# END claude-profile-manager"

echo ""
printf "  ${COLOR_CYAN}┌──────────────────────────────────────┐${COLOR_RESET}\n"
printf "  ${COLOR_CYAN}│${COLOR_RESET}  ${COLOR_BOLD}claude-profile-manager${COLOR_RESET} install      ${COLOR_CYAN}│${COLOR_RESET}\n"
printf "  ${COLOR_CYAN}│${COLOR_RESET}  ${COLOR_DIM}Platform: %-26s${COLOR_RESET}${COLOR_CYAN}│${COLOR_RESET}\n" "$PLATFORM"
printf "  ${COLOR_CYAN}└──────────────────────────────────────┘${COLOR_RESET}\n"
echo ""

# ────────────────────────────────────────────
# curl mode: download files from GitHub
# ────────────────────────────────────────────
_TEMP_DIR=""

_cleanup() {
  [ -n "$_TEMP_DIR" ] && rm -rf "$_TEMP_DIR"
}
trap _cleanup EXIT

if [ ! -f "$SRC_DIR/claude-profile-manager" ]; then
  if ! command -v curl >/dev/null 2>&1; then
    _error "curl not found. Install via git clone:"
    printf "    ${COLOR_CYAN}git clone https://github.com/USER/claude-profile-manager.git${COLOR_RESET}\n" >&2
    printf "    ${COLOR_CYAN}cd claude-profile-manager && bash install.sh${COLOR_RESET}\n" >&2
    exit 1
  fi

  printf "  ${COLOR_BOLD}Downloading files from GitHub...${COLOR_RESET}\n"
  _TEMP_DIR=$(mktemp -d)
  mkdir -p "$_TEMP_DIR/src"

  _files=(
    "src/claude-profile-manager"
    "src/claude-profile-manager.zsh"
    "src/claude-profile-manager.bash"
    "src/statusline-command.sh"
  )

  for _f in "${_files[@]}"; do
    _fname="${_f##*/}"
    if curl -fsSL "$GITHUB_REPO/$_f" -o "$_TEMP_DIR/src/$_fname"; then
      _success "$_fname"
    else
      _error "Failed to download $_fname"
      exit 1
    fi
  done

  SRC_DIR="$_TEMP_DIR/src"
  echo ""
fi

# ────────────────────────────────────────────
# Source file verification
# ────────────────────────────────────────────
for _required in claude-profile-manager claude-profile-manager.zsh claude-profile-manager.bash statusline-command.sh; do
  if [ ! -f "$SRC_DIR/$_required" ]; then
    _error "'$SRC_DIR/$_required' not found."
    exit 1
  fi
done

# ────────────────────────────────────────────
# sudo handling (macOS only)
# ────────────────────────────────────────────
if [ "$NEED_SUDO" = true ]; then
  printf "  ${COLOR_YELLOW}sudo privileges are required for installation.${COLOR_RESET}\n"
  sudo -v || { _error "Failed to obtain sudo privileges."; exit 1; }
  _run() { sudo "$@"; }
else
  _run() { "$@"; }
fi

# ────────────────────────────────────────────
# Directory setup
# ────────────────────────────────────────────
if [ "$NEED_SUDO" = true ]; then
  [ -d "/usr/local/bin" ]   || sudo mkdir -p /usr/local/bin
  [ -d "/usr/local/share" ] || sudo mkdir -p /usr/local/share
else
  mkdir -p "$HOME/.local/bin"
  mkdir -p "$HOME/.local/share"
fi

# ────────────────────────────────────────────
# Main script installation
# ────────────────────────────────────────────
printf "  ${COLOR_BOLD}Installing main script...${COLOR_RESET}\n"
_run rm -f "$BIN_DEST"
_run cp "$SRC_DIR/claude-profile-manager" "$BIN_DEST"
_run chmod 755 "$BIN_DEST"
_success "$BIN_DEST"

# ────────────────────────────────────────────
# Shell integration and statusline file installation
# ────────────────────────────────────────────
printf "  ${COLOR_BOLD}Installing shell integration files...${COLOR_RESET}\n"
_run mkdir -p "$SHARE_DEST"

_run rm -f "$SHARE_DEST/claude-profile-manager.zsh"
_run cp "$SRC_DIR/claude-profile-manager.zsh" "$SHARE_DEST/claude-profile-manager.zsh"
_run chmod 644 "$SHARE_DEST/claude-profile-manager.zsh"
_success "claude-profile-manager.zsh"

_run rm -f "$SHARE_DEST/claude-profile-manager.bash"
_run cp "$SRC_DIR/claude-profile-manager.bash" "$SHARE_DEST/claude-profile-manager.bash"
_run chmod 644 "$SHARE_DEST/claude-profile-manager.bash"
_success "claude-profile-manager.bash"

_run rm -f "$SHARE_DEST/statusline-command.sh"
_run cp "$SRC_DIR/statusline-command.sh" "$SHARE_DEST/statusline-command.sh"
_run chmod 755 "$SHARE_DEST/statusline-command.sh"
_success "statusline-command.sh"

# ────────────────────────────────────────────
# Linux/WSL: auto-add PATH
# ────────────────────────────────────────────
if [ "$NEED_SUDO" = false ]; then
  PATH_EXPORT='export PATH="$HOME/.local/bin:$PATH"'
  for _rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$_rc" ] || continue
    if ! grep -qF '.local/bin' "$_rc" 2>/dev/null; then
      printf '\n# claude-profile-manager: local bin path\n%s\n' "$PATH_EXPORT" >> "$_rc"
      _success "PATH added: $_rc"
    fi
  done
  unset _rc
  export PATH="$HOME/.local/bin:$PATH"
fi

# ────────────────────────────────────────────
# Shell integration rc file registration
# ────────────────────────────────────────────
echo ""
_success "Installation complete!"
echo ""

_detect_shell() {
  basename "${SHELL:-bash}"
}
CURRENT_SHELL="$(_detect_shell)"

_add_to_rc() {
  local rc_file="$1"
  local source_line="$2"

  if grep -qF "$ZSHRC_BEGIN" "$rc_file" 2>/dev/null; then
    printf "  ${COLOR_DIM}%s already has integration settings.${COLOR_RESET}\n" "$rc_file"
    return
  fi

  printf "  ${COLOR_DIM}──────────────────────────────────────────────────${COLOR_RESET}\n"
  printf "  The following needs to be added to ${COLOR_BOLD}%s${COLOR_RESET}:\n" "$rc_file"
  echo ""
  printf "    ${COLOR_DIM}%s${COLOR_RESET}\n" "$ZSHRC_BEGIN"
  printf "    ${COLOR_CYAN}%s${COLOR_RESET}\n" "$source_line"
  printf "    ${COLOR_DIM}%s${COLOR_RESET}\n" "$ZSHRC_END"
  echo ""
  printf "  ${COLOR_DIM}──────────────────────────────────────────────────${COLOR_RESET}\n"
  echo ""

  printf "  Add automatically now? (y/N): "
  read -r auto_add
  auto_add="${auto_add%% *}"
  case "$auto_add" in
    [yY]|[yY][eE][sS])
      {
        printf '\n%s\n' "$ZSHRC_BEGIN"
        printf '%s\n' "$source_line"
        printf '%s\n' "$ZSHRC_END"
      } >> "$rc_file"
      _success "Added to $rc_file!"
      ;;
    *)
      printf "  ${COLOR_DIM}Add manually to %s then apply.${COLOR_RESET}\n" "$rc_file"
      ;;
  esac
}

if [ -f "$HOME/.zshrc" ] || [ "$CURRENT_SHELL" = "zsh" ]; then
  printf "  ${COLOR_BOLD}[ zsh integration ]${COLOR_RESET}\n"
  _add_to_rc "$HOME/.zshrc" "source $SHARE_DEST/claude-profile-manager.zsh"
  echo ""
fi

if [ "$PLATFORM" != "macos" ] || [ "$CURRENT_SHELL" = "bash" ]; then
  printf "  ${COLOR_BOLD}[ bash integration ]${COLOR_RESET}\n"
  BASHRC="$HOME/.bashrc"
  if [ "$PLATFORM" = "macos" ] && [ ! -f "$BASHRC" ]; then
    BASHRC="$HOME/.bash_profile"
  fi
  _add_to_rc "$BASHRC" "source $SHARE_DEST/claude-profile-manager.bash"
  echo ""
fi

printf "  ${COLOR_BOLD}Next steps:${COLOR_RESET}\n"
printf "    1. Reload shell:    ${COLOR_CYAN}source ~/.zshrc${COLOR_RESET}  or  ${COLOR_CYAN}source ~/.bashrc${COLOR_RESET}\n"
printf "    2. Initial setup:   ${COLOR_CYAN}cpm setup${COLOR_RESET}\n"
printf "    3. Switch account:  ${COLOR_CYAN}cpm <profile-name>${COLOR_RESET}\n"
echo ""
