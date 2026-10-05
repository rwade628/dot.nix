# Per-tmux-session history. Inside a named tmux session, the live history list
# is $XDG_STATE_HOME/zsh/history/<session>; numeric (unnamed) sessions and
# shells outside tmux stay on the global $HISTFILE. Every command is also
# appended to the global file, which Alt-R searches and autosuggestions fall
# back to.

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

# Double-write: the normal save puts the line in the session file; a copy is
# appended to the global file from a subshell via fc -AI, so zsh still owns
# the file format and locking. The hook only stashes the line and precmd does
# the append: inside zshaddhistory, fc -AI silently writes nothing, and the
# documented `fc -p` trick stops the session context's incremental writes.
typeset -g _sh_pending
_sh_addhistory() {
  [[ $HISTFILE != $_sh_global && $1 != ' '* ]] && _sh_pending=${1%%$'\n'}
  return 0
}
_sh_flush() {
  [[ -z $_sh_pending ]] && return
  ( fc -p "" 10 10; print -sr -- $_sh_pending; fc -AI $_sh_global )
  _sh_pending=
}

# Only precmd switches: zsh undoes an fc -p made in zshaddhistory, so the
# first command typed after a rename still lands in the old session's file.
autoload -Uz add-zsh-hook
add-zsh-hook precmd _sh_flush
add-zsh-hook precmd _sh_sync
add-zsh-hook zshaddhistory _sh_addhistory

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
