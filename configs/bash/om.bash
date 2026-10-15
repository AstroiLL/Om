# Om shell helpers. Sourced from ~/.bashrc (install.sh adds the line).
# tmux layouts adapted from omacom/omarchy default/bash/fns/tmux (MIT).

# ---- aliases (Omarchy-style) ----
alias a='hermes'                       # default agent inline
alias g='git'
alias ih='tdl hermes'                  # IDE-like layout with Hermes
alias ihh='tdl hermes hermes'          # ... with two Hermes panes
alias hk='~/.local/share/om/scripts/om-keybinds --print'   # hotkey cheatsheet in the terminal

_om_editor() { printf '%s' "${EDITOR:-mc}"; }
_om_need_tmux() { [[ -n $TMUX ]] || { echo "Запусти tmux (t или Super+Alt+Enter)"; return 1; }; }

# tdl <agent> [<agent2>] — editor left, agent right (30%), shell bottom (15%)
tdl() {
  [[ -z $1 ]] && { echo "Usage: tdl <agent-cmd> [<agent2-cmd>]   e.g. tdl hermes"; return 1; }
  _om_need_tmux || return 1
  local dir="$PWD" editor_pane="$TMUX_PANE" ai_pane ai2_pane
  tmux rename-window -t "$editor_pane" "$(basename "$dir")"
  tmux split-window -v -p 15 -t "$editor_pane" -c "$dir"
  ai_pane=$(tmux split-window -h -p 30 -t "$editor_pane" -c "$dir" -P -F '#{pane_id}')
  if [[ -n $2 ]]; then
    ai2_pane=$(tmux split-window -v -t "$ai_pane" -c "$dir" -P -F '#{pane_id}')
    tmux send-keys -t "$ai2_pane" "$2" C-m
  fi
  tmux send-keys -t "$ai_pane" "$1" C-m
  tmux send-keys -t "$editor_pane" "$(_om_editor) ." C-m
  tmux select-pane -t "$editor_pane"
}

# tds [agent] — 2x2: editor | live git diff / shell | agent
tds() {
  _om_need_tmux || return 1
  local dir="$PWD" editor_pane="$TMUX_PANE" term_pane diff_pane ai_pane ai="${1:-hermes}"
  tmux rename-window -t "$editor_pane" "$(basename "$dir")"
  term_pane=$(tmux split-window -v -p 50 -t "$editor_pane" -c "$dir" -P -F '#{pane_id}')
  diff_pane=$(tmux split-window -h -p 50 -t "$editor_pane" -c "$dir" -P -F '#{pane_id}')
  ai_pane=$(tmux split-window -h -p 50 -t "$term_pane" -c "$dir" -P -F '#{pane_id}')
  tmux send-keys -t "$editor_pane" "$(_om_editor) ." C-m
  tmux send-keys -t "$diff_pane" "watch -c -n 2 'git -c color.ui=always status -sb; echo; git -c color.ui=always diff --stat; echo; git -c color.ui=always diff | head -80'" C-m
  tmux send-keys -t "$ai_pane" "$ai" C-m
  tmux select-pane -t "$editor_pane"
}

# tdlm <agent> [<agent2>] — one tdl window per subdirectory of $PWD (Alt+1/2/3... or prefix+N)
tdlm() {
  [[ -z $1 ]] && { echo "Usage: tdlm <agent-cmd> [<agent2-cmd>]"; return 1; }
  _om_need_tmux || return 1
  local base="$PWD" first=true dir pane
  tmux rename-session "$(basename "$base" | tr '.:' '--')"
  for dir in "$base"/*/; do
    [[ -d $dir ]] || continue
    dir="${dir%/}"
    if $first; then
      tmux send-keys -t "$TMUX_PANE" "cd '$dir' && tdl $1 $2" C-m; first=false
    else
      pane=$(tmux new-window -c "$dir" -P -F '#{pane_id}')
      tmux send-keys -t "$pane" "tdl $1 $2" C-m
    fi
  done
}

# tsl <count> <cmd> — tiled swarm of N panes running the same command (e.g. tsl 4 hermes)
tsl() {
  [[ -z $1 || -z $2 ]] && { echo "Usage: tsl <pane_count> <cmd>   e.g. tsl 4 hermes"; return 1; }
  _om_need_tmux || return 1
  local count="$1" cmd="$2" dir="$PWD" pane
  local -a panes=("$TMUX_PANE")
  tmux rename-window -t "$TMUX_PANE" "$(basename "$dir")"
  while (( ${#panes[@]} < count )); do
    pane=$(tmux split-window -h -t "${panes[-1]}" -c "$dir" -P -F '#{pane_id}')
    panes+=("$pane")
    tmux select-layout -t "${panes[0]}" tiled
  done
  for pane in "${panes[@]}"; do tmux send-keys -t "$pane" "$cmd" C-m; done
  tmux select-pane -t "${panes[0]}"
}

# ---- mc: Tokyo Night skin (matches Hyprland theme). Truecolor when the terminal supports it ----
case "${COLORTERM:-}" in
  truecolor|24bit) export MC_SKIN=tokyo-night16M ;;
  *)               export MC_SKIN=tokyo-night256 ;;
esac

# ssh inside tmux: name the tmux window after the server (ssh alias or host),
# restore automatic naming (mc, bash, ...) when the connection ends.
ssh() {
    if [[ -n $TMUX && -t 1 ]]; then
        local h
        h=$(command ssh -G "$@" 2>/dev/null </dev/null | awk '$1=="host"{print $2; exit}')
        h=${h%%.*}
        if [[ -n $h ]]; then
            tmux rename-window -t "$TMUX_PANE" "$h"
            command ssh "$@"; local rc=$?
            tmux set-option -w -t "$TMUX_PANE" automatic-rename on
            return $rc
        fi
    fi
    command ssh "$@"
}
