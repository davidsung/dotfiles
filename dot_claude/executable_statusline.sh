#!/bin/bash
# Claude Code status line (Catppuccin Mocha colours, Nerd Font icons).
# Claude Code pipes session JSON on stdin; each printed line is one status row.
#   Line 1: model · effort | folder | git branch (+ dirty marker) | worktree
#   Line 2: context bar + % of window | session cost | duration | lines +/-
# Docs: https://code.claude.com/docs/en/statusline

input=$(cat)

# One jq call. Fields are joined with the ASCII unit separator (not tabs): `read` merges
# runs of whitespace separators, which would shift every field after an empty one.
IFS=$'\x1f' read -r model effort cwd worktree ctx_pct ctx_size cost dur_ms added removed < <(
  jq -r '[
    .model.display_name // "Claude",
    .effort.level // "",
    .workspace.current_dir // .cwd // "",
    .workspace.git_worktree // "",
    (.context_window.used_percentage // 0 | floor),
    .context_window.context_window_size // 0,
    .cost.total_cost_usd // 0,
    .cost.total_duration_ms // 0,
    .cost.total_lines_added // 0,
    .cost.total_lines_removed // 0
  ] | map(tostring) | join("\u001f")' <<<"$input"
)

# Catppuccin Mocha (truecolor)
c() { printf '\033[38;2;%sm' "$1"; }
MAUVE=$(c "203;166;247"); BLUE=$(c "137;180;250"); GREEN=$(c "166;227;161")
YELLOW=$(c "249;226;175"); PEACH=$(c "250;179;135"); RED=$(c "243;139;168")
TEAL=$(c "148;226;213"); DIM=$(c "108;112;134"); RESET=$'\033[0m'
SEP="${DIM} │ ${RESET}"

# --- Line 1 ---
line1="${MAUVE}󰚩 ${model}${RESET}"
[[ -n $effort ]] && line1+="${DIM} · ${effort}${RESET}"

dir_name=${cwd##*/}; [[ -z $dir_name ]] && dir_name="/"
line1+="${SEP}${BLUE} ${dir_name}${RESET}"

if [[ -n $cwd ]] && branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null); then
  dirty=""
  if ! git -C "$cwd" --no-optional-locks diff --quiet --ignore-submodules 2>/dev/null ||
     ! git -C "$cwd" --no-optional-locks diff --cached --quiet --ignore-submodules 2>/dev/null; then
    dirty="${PEACH}*"
  fi
  line1+="${SEP}${GREEN} ${branch}${dirty}${RESET}"
fi
[[ -n $worktree ]] && line1+="${SEP}${TEAL}󰙅 ${worktree}${RESET}"

# --- Line 2 ---
pct=${ctx_pct:-0}
if   (( pct >= 80 )); then bar_color=$RED
elif (( pct >= 50 )); then bar_color=$YELLOW
else                       bar_color=$GREEN
fi
width=10; filled=$(( pct * width / 100 )); (( filled > width )) && filled=$width
printf -v full  '%*s' "$filled" ''; printf -v empty '%*s' "$(( width - filled ))" ''
bar="${bar_color}${full// /▰}${DIM}${empty// /▱}${RESET}"

size_label=""
if (( ctx_size >= 1000000 )); then size_label=" of $(( ctx_size / 1000000 ))M"
elif (( ctx_size >= 1000 )); then size_label=" of $(( ctx_size / 1000 ))k"
fi
line2="${bar} ${bar_color}${pct}%${RESET}${DIM}${size_label}${RESET}"

line2+="${SEP}${YELLOW}$(printf '$%.2f' "$cost")${RESET}"

mins=$(( dur_ms / 60000 ))
if (( mins >= 60 )); then dur="$(( mins / 60 ))h $(printf '%02d' $(( mins % 60 )))m"; else dur="${mins}m"; fi
line2+="${SEP}${DIM}󰔟 ${dur}${RESET}"

if (( added > 0 || removed > 0 )); then
  line2+="${SEP}${GREEN}+${added}${RESET} ${RED}−${removed}${RESET}"
fi

printf '%s\n%s\n' "$line1" "$line2"
