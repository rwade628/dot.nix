# Per-tmux-session history. Inside a named tmux session, the live history list
# is $XDG_STATE_HOME/zsh/history/<session>; numeric (unnamed) sessions and
# shells outside tmux stay on the global $HISTFILE. Each command is saved to
# exactly one of the two. Alt-R searches the global file and autosuggestions
# fall back to it.

typeset -g _sh_global=$HISTFILE
typeset -g _sh_dir=${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history

# Re-evaluated every prompt so renames and join-pane move the shell along.
# -t $TMUX_PANE matters: without it tmux answers for the most recent client,
# which may be attached to a different session.
_sh_sync() {
  local s target=$_sh_global
  [[ -n $TMUX_PANE ]] && s=$(tmux display-message -p -t "$TMUX_PANE" '#S' 2>/dev/null)
  [[ -n $s && $s != <-> ]] && target=$_sh_dir/${s//\//_}
  [[ $target == $HISTFILE ]] && return
  # Push on top without popping; switches are rare (renames, join-pane), so
  # the stack stays shallow.
  [[ $target != $_sh_global ]] && mkdir -p $_sh_dir
  fc -p $target $HISTSIZE $SAVEHIST
}

# Switching happens at the prompt, so the first command typed after a rename
# still lands in the old session's file.
autoload -Uz add-zsh-hook
add-zsh-hook precmd _sh_sync

# Alt-R: fzf over the global file. SAVEHIST=0 keeps the temporary context
# read-only; -a pops it when the widget returns.
_sh_global_search() {
  fc -ap $_sh_global $HISTSIZE 0
  fzf_history_search
}
zle -N _sh_global_search
bindkey '^[r' _sh_global_search

# Autosuggestion fallback: the global file, cached until it changes.
zmodload -F zsh/stat b:zstat
typeset -ga _sh_global_cache
typeset -g _sh_global_stamp
_zsh_autosuggest_strategy_global_history() {
  [[ $HISTFILE == $_sh_global ]] && return
  emulate -L zsh
  setopt EXTENDED_GLOB
  local -A st
  zstat -H st $_sh_global 2>/dev/null || return
  if [[ $st[mtime]:$st[size] != $_sh_global_stamp ]]; then
    fc -ap $_sh_global $HISTSIZE 0
    _sh_global_cache=("${(@v)history}")
    _sh_global_stamp=$st[mtime]:$st[size]
  fi
  local prefix="${1//(#m)[\\*?[\]<>()|^~#]/\\$MATCH}"
  typeset -g suggestion="${_sh_global_cache[(r)$prefix*]}"
}
ZSH_AUTOSUGGEST_STRATEGY=(history global_history)
