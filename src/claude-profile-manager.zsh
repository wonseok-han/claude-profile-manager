# claude-profile-manager.zsh — zsh shell integration
# Add the following line to ~/.zshrc to activate:
#   source /usr/local/share/claude-profile-manager/claude-profile-manager.zsh

# ────────────────────────────────────────────
# Core function definition
# ────────────────────────────────────────────
_claude_profile_manager_fn() {
  local cmd="${1:-}"

  case "$cmd" in
    "")
      local _profiles
      _profiles=$(command claude-profile-manager list 2>/dev/null)
      if [ -n "$_profiles" ]; then
        command claude-profile-manager status
      else
        command claude
      fi
      ;;
    status|list|create|clone|remove|rename|doctor|setup|statusline|help|--help|-h)
      command claude-profile-manager "$@"
      ;;
    *)
      local profile_dir="$HOME/.claude-${cmd}"
      if [ ! -d "$profile_dir" ]; then
        echo "Error: profile '${cmd}' not found." >&2
        echo "  To create: cpm create ${cmd}" >&2
        return 1
      fi
      CLAUDE_CONFIG_DIR="$profile_dir" command claude "${@:2}"
      ;;
  esac
}

# ────────────────────────────────────────────
# Register alias
# ────────────────────────────────────────────
alias cpm='_claude_profile_manager_fn'

# ────────────────────────────────────────────
# zsh completion
# ────────────────────────────────────────────
_claude_profile_manager_completions() {
  local state

  _arguments \
    '1: :->command' \
    '2: :->arg' \
    && return 0

  case "$state" in
    command)
      local -a profiles
      local -a builtins

      if command -v claude-profile-manager >/dev/null 2>&1; then
        profiles=(${(f)"$(command claude-profile-manager list 2>/dev/null)"})
      fi

      builtins=(
        'create:Create a new profile and log in immediately'
        'clone:Clone the current account into a new profile'
        'status:Show all profiles'
        'rename:Rename a profile'
        'remove:Delete a profile'
        'setup:Interactive initial setup wizard'
        'doctor:Check environment info'
        'statusline:Configure Claude Code statusline'
        'help:Print help'
      )

      _describe 'profiles' profiles
      _describe 'commands' builtins
      ;;
    arg)
      case "${words[2]}" in
        remove|rename)
          local -a profiles
          if command -v claude-profile-manager >/dev/null 2>&1; then
            profiles=(${(f)"$(command claude-profile-manager list 2>/dev/null)"})
          fi
          _describe 'profiles' profiles
          ;;
        create|clone)
          _message 'profile name'
          ;;
      esac
      ;;
  esac
}

if (( ${+functions[compdef]} )); then
  compdef '_claude_profile_manager_completions' 'cpm'
fi
