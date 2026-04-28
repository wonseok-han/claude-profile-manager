# claude-profile-manager.bash — bash shell integration
# Add the following line to ~/.bashrc or ~/.bash_profile to activate:
#   source /usr/local/share/claude-profile-manager/claude-profile-manager.bash

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
# bash completion
# ────────────────────────────────────────────
_claude_profile_manager_completions() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"

  local commands="create clone status rename remove setup doctor statusline help"
  local profiles=""
  if command -v claude-profile-manager >/dev/null 2>&1; then
    profiles=$(command claude-profile-manager list 2>/dev/null || true)
  fi

  if [ "$COMP_CWORD" -eq 1 ]; then
    local candidates="$commands $profiles"
    COMPREPLY=($(compgen -W "$candidates" -- "$cur"))
  elif [ "$COMP_CWORD" -eq 2 ]; then
    case "$prev" in
      remove|rename)
        COMPREPLY=($(compgen -W "$profiles" -- "$cur"))
        ;;
    esac
  fi
}

complete -F _claude_profile_manager_completions 'cpm'
