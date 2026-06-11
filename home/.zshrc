# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

setopt nonomatch

# History (Warp 風補完の土台: 共有履歴・重複除去・先読み strategy)
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt share_history hist_ignore_dups hist_ignore_space extended_history
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Claude Code: 推論の深さを常に最大に設定
# export CLAUDE_CODE_EFFORT_LEVEL=max

# Load zprofile
if [ -f ~/.zprofile ]; then
    source ~/.zprofile
fi

# Load local file
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Select and navigate to a git repository
# Usage: g
# Description: Select and navigate to a git repository using ghq and peco
# - Lists all repositories managed by ghq
# - Uses peco for interactive selection
# - Changes directory to the selected repository
function g() {
  local selected_repo=$(ghq list -p | peco --query "$LBUFFER")
  if [ -n "$selected_repo" ]; then
    cd "$selected_repo"
  fi
}

# Select and checkout a git branch
# Usage: b
# Description: Select and checkout a git branch using fzf
# - Sorts branches by commit date (newest first)
# - Uses fzf for interactive selection
# - Automatically checks out the selected branch
function b() {
  local branch=$(git branch --sort=-committerdate | fzf --reverse)
  if [ -n "$branch" ]; then
    git checkout $(echo $branch | sed 's/^[ *]*//')
  fi
}

# Search and select from command history
# Usage: r
# Description: Search and select from command history
# - Removes duplicate commands
# - Uses peco for interactive selection
# - Places selected command in the current prompt
# - Press Enter to execute the selected command
function r() {
  local selected_command
  selected_command=$(history -n 1 | tail -n +1 | awk '!a[$0]++' | peco)
  
  if [ -n "$selected_command" ]; then
    print -z "$selected_command"
  fi
}

# Open GitHub repository in browser
# Usage: h
# Description: Open GitHub repository in browser using hub
# - Selects repository from ghq list using peco
# - Extracts repository name from full path
# - Opens repository in default browser using hub browse
function h() {
  local selected_repo=$(ghq list -p | peco --query "$LBUFFER" | rev | cut -d "/" -f -2 | rev)
  if [ -n "$selected_repo" ]; then
    hub browse "$selected_repo"
  fi
}

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# carapace: 多シェル補完ブリッジ (compinit 後・sheldon source 前に初期化)
if command -v carapace >/dev/null; then
  export CARAPACE_BRIDGES='zsh,bash,fish'
  source <(carapace _carapace)
fi
# fzf-tab 用の補完スタイル
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' switch-group '<' '>'

# Sheldon
eval "$(sheldon source)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ──────────────────────────────────────────────────────────────
# Ctrl+r / Ctrl+g で peco ランチャー (r / g 相当) を起動する
# (typed の r / g / h コマンドはそのまま併用可)
# ──────────────────────────────────────────────────────────────

# Ctrl+r: コマンド履歴を peco で検索し、選んだものを入力行へ展開する (r 相当)
function _zle_peco_history() {
  local selected
  selected=$(history -n 1 | tail -n +1 | awk '!a[$0]++' | peco)
  if [[ -n "$selected" ]]; then
    BUFFER="$selected"
    CURSOR=$#BUFFER
  fi
  zle reset-prompt
}
zle -N _zle_peco_history
bindkey '^R' _zle_peco_history

# Ctrl+g: ghq 管理のリポジトリを peco で選んで cd する (g 相当)
function _zle_ghq_cd() {
  local selected
  selected=$(ghq list -p | peco --query "$LBUFFER")
  if [[ -n "$selected" ]]; then
    BUFFER="cd ${(q)selected}"
    zle accept-line
  else
    zle reset-prompt
  fi
}
zle -N _zle_ghq_cd
bindkey '^G' _zle_ghq_cd

# cmd+ctrl+h: ghq 管理のリポジトリを peco で選んで hub browse する (h 相当)
# Ctrl+h は Backspace(^H) と衝突するため cmd+ctrl+h を使用。
# cmux(内蔵 Ghostty)が cmd+ctrl+h を ESC[102~ に変換して送る (~/.config/ghostty/config)
function _zle_ghq_browse() {
  local selected
  selected=$(ghq list -p | peco --query "$LBUFFER" | rev | cut -d "/" -f -2 | rev)
  if [[ -n "$selected" ]]; then
    BUFFER="hub browse ${(q)selected}"
    zle accept-line
  else
    zle reset-prompt
  fi
}
zle -N _zle_ghq_browse
bindkey '\e[102~' _zle_ghq_browse
