#!/bin/sh
# Claude Code status line — Dracula theme
# Line 1: ctx bar │ 5h bar │ 7d bar
# Line 2: [profile ❯] model ❯ project ❯ branch

input=$(cat)

# --- Extract values from JSON ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_hour_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_hour_resets=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_day_resets=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# --- Git branch ---
git_branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
fi

# --- Project name (home-relative path) ---
project_name=""
if [ -n "$cwd" ]; then
  _home="$HOME"
  case "$cwd" in
    "$_home"/*) project_name="~/$(printf '%s' "${cwd#$_home/}")" ;;
    *)          project_name="$cwd" ;;
  esac
fi

# --- Progress bar helper (10 chars) ---
make_bar() {
  _pct="$1"
  _filled=$(awk "BEGIN { printf \"%d\", ($_pct / 100) * 10 }")
  [ "$_pct" -gt 0 ] && [ "$_filled" -eq 0 ] && _filled=1
  _empty=$(( 10 - _filled ))
  _bar=""
  _i=0
  while [ "$_i" -lt "$_filled" ]; do _bar="${_bar}█"; _i=$(( _i + 1 )); done
  _i=0
  while [ "$_i" -lt "$_empty" ]; do _bar="${_bar}─"; _i=$(( _i + 1 )); done
  printf '%s' "$_bar"
}

# --- Dracula palette (true color) ---
D_GREEN='\033[38;2;80;250;123m'       # #50fa7b
D_ORANGE='\033[38;2;255;184;108m'     # #ffb86c
D_RED='\033[38;2;255;85;85m'          # #ff5555
D_CYAN='\033[38;2;139;233;253m'       # #8be9fd
D_PINK='\033[38;2;255;121;198m'       # #ff79c6
D_PURPLE='\033[38;2;189;147;249m'     # #bd93f9
D_YELLOW='\033[38;2;241;250;140m'     # #f1fa8c
D_FG='\033[38;2;248;248;242m'         # #f8f8f2 foreground
D_COMMENT='\033[38;2;98;114;164m'     # #6272a4 comment (dim)
RESET='\033[0m'

SEP="$(printf "${D_COMMENT} ❯ ${RESET}")"
SEP1="$(printf "${D_COMMENT} │ ${RESET}")"

# --- Dynamic color by percentage ---
pct_color() {
  _pct="$1"
  if [ "$_pct" -gt 75 ]; then
    printf '%s' "$D_RED"
  elif [ "$_pct" -ge 50 ]; then
    printf '%s' "$D_ORANGE"
  else
    printf '%s' "$D_GREEN"
  fi
}

# --- Context bar ---
progress_bar=""
pct_int=""
if [ -n "$used_pct" ]; then
  pct_int=$(printf "%.0f" "$used_pct" 2>/dev/null || echo "$used_pct")
  progress_bar=$(make_bar "$pct_int")
fi

# --- 5-hour rate limit ---
five_hour_bar=""
five_hour_int=""
if [ -n "$five_hour_pct" ]; then
  five_hour_int=$(printf "%.0f" "$five_hour_pct" 2>/dev/null || echo "$five_hour_pct")
  five_hour_bar=$(make_bar "$five_hour_int")
fi

# --- 7-day rate limit ---
seven_day_bar=""
seven_day_int=""
if [ -n "$seven_day_pct" ]; then
  seven_day_int=$(printf "%.0f" "$seven_day_pct" 2>/dev/null || echo "$seven_day_pct")
  seven_day_bar=$(make_bar "$seven_day_int")
fi

line1=""
line2=""

# Line 1: ctx │ 5h │ 7d
_empty_bar="──────────"
if [ -n "$progress_bar" ]; then
  _color=$(pct_color "$pct_int")
  line1="${line1}$(printf "${D_FG}ctx ${RESET}${_color}%s${RESET}${D_FG} ${pct_int}%%${RESET}" "$progress_bar")"
else
  line1="${line1}$(printf "${D_COMMENT}ctx %s --%${RESET}" "$_empty_bar")"
fi
if [ -n "$five_hour_bar" ]; then
  _color=$(pct_color "$five_hour_int")
  _5h_label="⏱ 5h"
  [ -n "$five_hour_resets" ] && _5h_label="⏱ $(date -r "$five_hour_resets" "+%H:%M" 2>/dev/null)"
  line1="${line1}${SEP1}$(printf "${D_FG}%s ${RESET}${_color}%s${RESET}${D_FG} ${five_hour_int}%% used${RESET}" "$_5h_label" "$five_hour_bar")"
else
  line1="${line1}${SEP1}$(printf "${D_COMMENT}⏱ -- %s --%%  used${RESET}" "$_empty_bar")"
fi
if [ -n "$seven_day_bar" ]; then
  _color=$(pct_color "$seven_day_int")
  _7d_label="📅 7d"
  [ -n "$seven_day_resets" ] && _7d_label="📅 $(date -r "$seven_day_resets" "+%m/%d" 2>/dev/null)"
  line1="${line1}${SEP1}$(printf "${D_FG}%s ${RESET}${_color}%s${RESET}${D_FG} ${seven_day_int}%% used${RESET}" "$_7d_label" "$seven_day_bar")"
else
  line1="${line1}${SEP1}$(printf "${D_COMMENT}📅 -- %s --%%  used${RESET}" "$_empty_bar")"
fi

# --- cpm profile (from CLAUDE_CONFIG_DIR) ---
cpm_profile=""
if [ -n "$CLAUDE_CONFIG_DIR" ]; then
  _dir="${CLAUDE_CONFIG_DIR%/}"
  _basename="${_dir##*/}"
  cpm_profile="${_basename#.claude-}"
fi

# Line 2: [profile ❯] model ❯ project ❯ branch
_model_display="${model:-loading...}"
line2=""
if [ -n "$cpm_profile" ]; then
  line2="$(printf "${D_YELLOW}👤 %s${RESET}" "$cpm_profile")"
  line2="${line2}${SEP}"
fi
line2="${line2}$(printf "${D_PURPLE}◆ %s${RESET}" "$_model_display")"
if [ -n "$project_name" ]; then
  line2="${line2}${SEP}$(printf "${D_CYAN}📁 %s${RESET}" "$project_name")"
fi
if [ -n "$git_branch" ]; then
  line2="${line2}${SEP}$(printf "${D_PINK}⎇ %s${RESET}" "$git_branch")"
fi

_cols=$(tput cols 2>/dev/null || echo 80)
divider="$(printf "${D_COMMENT}%${_cols}s${RESET}" | tr ' ' '─')"
printf "%b\n%b\n%b\n%b\n%b\n" "$divider" "$line1" "$divider" "$line2" "$divider"
