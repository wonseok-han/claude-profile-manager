#!/usr/bin/env bash
# install.sh — claude-profile-manager installation script
# Supports macOS, Linux, WSL
# curl install: curl -fsSL https://raw.githubusercontent.com/USER/claude-profile-manager/main/install.sh | bash
# git clone install: bash install.sh

set -e

GITHUB_REPO="https://raw.githubusercontent.com/USER/claude-profile-manager/main"

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

echo "======================================"
echo "  claude-profile-manager install"
echo "  Platform: $PLATFORM"
echo "======================================"
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
    echo "Error: curl not found. Install via git clone:" >&2
    echo "  git clone https://github.com/USER/claude-profile-manager.git" >&2
    echo "  cd claude-profile-manager && bash install.sh" >&2
    exit 1
  fi

  echo "Downloading files from GitHub..."
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
      echo "  ✓ $_fname"
    else
      echo "Error: failed to download $_fname" >&2
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
    echo "Error: '$SRC_DIR/$_required' not found." >&2
    exit 1
  fi
done

# ────────────────────────────────────────────
# sudo handling (macOS only)
# ────────────────────────────────────────────
if [ "$NEED_SUDO" = true ]; then
  echo "sudo privileges are required for installation."
  sudo -v || { echo "Error: failed to obtain sudo privileges." >&2; exit 1; }
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
echo "Installing main script..."
_run rm -f "$BIN_DEST"
_run cp "$SRC_DIR/claude-profile-manager" "$BIN_DEST"
_run chmod 755 "$BIN_DEST"
echo "  Installed: $BIN_DEST"

# ────────────────────────────────────────────
# Shell integration and statusline file installation
# ────────────────────────────────────────────
echo "Installing shell integration files..."
_run mkdir -p "$SHARE_DEST"

_run rm -f "$SHARE_DEST/claude-profile-manager.zsh"
_run cp "$SRC_DIR/claude-profile-manager.zsh" "$SHARE_DEST/claude-profile-manager.zsh"
_run chmod 644 "$SHARE_DEST/claude-profile-manager.zsh"
echo "  Installed: $SHARE_DEST/claude-profile-manager.zsh"

_run rm -f "$SHARE_DEST/claude-profile-manager.bash"
_run cp "$SRC_DIR/claude-profile-manager.bash" "$SHARE_DEST/claude-profile-manager.bash"
_run chmod 644 "$SHARE_DEST/claude-profile-manager.bash"
echo "  Installed: $SHARE_DEST/claude-profile-manager.bash"

_run rm -f "$SHARE_DEST/statusline-command.sh"
_run cp "$SRC_DIR/statusline-command.sh" "$SHARE_DEST/statusline-command.sh"
_run chmod 755 "$SHARE_DEST/statusline-command.sh"
echo "  Installed: $SHARE_DEST/statusline-command.sh"

# ────────────────────────────────────────────
# Linux/WSL: auto-add PATH
# ────────────────────────────────────────────
if [ "$NEED_SUDO" = false ]; then
  PATH_EXPORT='export PATH="$HOME/.local/bin:$PATH"'
  for _rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$_rc" ] || continue
    if ! grep -qF '.local/bin' "$_rc" 2>/dev/null; then
      printf '\n# claude-profile-manager: local bin path\n%s\n' "$PATH_EXPORT" >> "$_rc"
      echo "  PATH added: $_rc"
    fi
  done
  unset _rc
  export PATH="$HOME/.local/bin:$PATH"
fi

# ────────────────────────────────────────────
# Shell integration rc file registration
# ────────────────────────────────────────────
echo ""
echo "Installation complete!"
echo ""

_detect_shell() {
  basename "${SHELL:-bash}"
}
CURRENT_SHELL="$(_detect_shell)"

_add_to_rc() {
  local rc_file="$1"
  local source_line="$2"

  if grep -qF "$ZSHRC_BEGIN" "$rc_file" 2>/dev/null; then
    echo "  $rc_file already has integration settings."
    return
  fi

  echo "────────────────────────────────────────────────────"
  echo "  The following needs to be added to $rc_file:"
  echo ""
  echo "    $ZSHRC_BEGIN"
  echo "    $source_line"
  echo "    $ZSHRC_END"
  echo ""
  echo "────────────────────────────────────────────────────"
  echo ""

  printf "Add automatically now? (y/N): "
  read -r auto_add
  auto_add="${auto_add%% *}"
  case "$auto_add" in
    [yY]|[yY][eE][sS])
      {
        printf '\n%s\n' "$ZSHRC_BEGIN"
        printf '%s\n' "$source_line"
        printf '%s\n' "$ZSHRC_END"
      } >> "$rc_file"
      echo "  Added to $rc_file!"
      ;;
    *)
      echo "  Add manually to $rc_file then apply."
      ;;
  esac
}

if [ -f "$HOME/.zshrc" ] || [ "$CURRENT_SHELL" = "zsh" ]; then
  echo "[ zsh integration ]"
  _add_to_rc "$HOME/.zshrc" "source $SHARE_DEST/claude-profile-manager.zsh"
  echo ""
fi

if [ "$PLATFORM" != "macos" ] || [ "$CURRENT_SHELL" = "bash" ]; then
  echo "[ bash integration ]"
  BASHRC="$HOME/.bashrc"
  if [ "$PLATFORM" = "macos" ] && [ ! -f "$BASHRC" ]; then
    BASHRC="$HOME/.bash_profile"
  fi
  _add_to_rc "$BASHRC" "source $SHARE_DEST/claude-profile-manager.bash"
  echo ""
fi

echo "Next steps:"
echo "  1. Reload shell:    source ~/.zshrc  or  source ~/.bashrc"
echo "  2. Initial setup:   cpm setup"
echo "  3. Switch account:  cpm <profile-name>"
echo ""
