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

# ghq のフルパスを「前半=淡色 / owner=シアン / repo=黄」に色分けする (fzf --ansi 用)
function _ghq_fzf_color() {
  sed -E $'s#^(.*)/([^/]+)/([^/]+)$#\033[2m\\1/\033[0m\033[1;36m\\2\033[0m\033[2m/\033[0m\033[1;33m\\3\033[0m#'
}

# 履歴行を色分けする: コマンド=緑 / オプション=シアン / 演算子=マゼンタ / パス=青 (fzf --ansi 用)
# ANSI を挿入するだけで他の文字は変えないため、fzf --ansi が剥がすと元コマンドに一致 (実行は壊れない)
function _hist_fzf_color() {
  perl -pe 's{(^\s*\S+)|(--?\w[\w-]*)|(\|\||&&|[|;&><]+)|(\S*/\S*)}{defined($1)?"\033[1;32m$1\033[0m":defined($2)?"\033[36m$2\033[0m":defined($3)?"\033[1;35m$3\033[0m":"\033[34m$4\033[0m"}ge'
}

# Select and navigate to a git repository
# Usage: g
# Description: ghq 管理リポジトリを fzf (色付きパス) で選んで cd する
function g() {
  local selected_repo
  selected_repo=$(ghq list -p | _ghq_fzf_color | fzf --ansi --reverse --query "$LBUFFER")
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
# - Uses fzf (--ansi) for interactive selection
# - Places selected command in the current prompt
# - Press Enter to execute the selected command
function r() {
  local selected_command
  selected_command=$(history -n 1 | tail -n +1 | awk '!a[$0]++' | _hist_fzf_color | fzf --ansi --reverse)
  
  if [ -n "$selected_command" ]; then
    print -z "$selected_command"
  fi
}

# Open GitHub repository in browser
# Usage: h
# Description: ghq 管理リポジトリを fzf (色付きパス) で選んで hub browse する
function h() {
  local selected_path
  selected_path=$(ghq list -p | _ghq_fzf_color | fzf --ansi --reverse --query "$LBUFFER")
  if [ -n "$selected_path" ]; then
    hub browse "$(print -r -- "$selected_path" | rev | cut -d "/" -f -2 | rev)"
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
# Ctrl+r / Ctrl+g でランチャー起動 (いずれも fzf 色付き, r / g 相当)
# (typed の r / g / h コマンドはそのまま併用可)
# ──────────────────────────────────────────────────────────────

# Ctrl+r: コマンド履歴を fzf (色付き) で検索し、選んだものを入力行へ展開する (r 相当)
function _zle_fzf_history() {
  local selected
  selected=$(history -n 1 | tail -n +1 | awk '!a[$0]++' | _hist_fzf_color | fzf --ansi --reverse --query "$LBUFFER")
  if [[ -n "$selected" ]]; then
    BUFFER="$selected"
    CURSOR=$#BUFFER
  fi
  zle reset-prompt
}
zle -N _zle_fzf_history
bindkey '^R' _zle_fzf_history

# Ctrl+g: ghq 管理のリポジトリを fzf (色付きパス) で選んで cd する (g 相当)
function _zle_ghq_cd() {
  local selected
  selected=$(ghq list -p | _ghq_fzf_color | fzf --ansi --reverse --query "$LBUFFER")
  if [[ -n "$selected" ]]; then
    BUFFER="cd ${(q)selected}"
    zle accept-line
  else
    zle reset-prompt
  fi
}
zle -N _zle_ghq_cd
bindkey '^G' _zle_ghq_cd

# cmd+ctrl+h: ghq 管理のリポジトリを fzf (色付き) で選んで hub browse する (h 相当)
# Ctrl+h は Backspace(^H) と衝突するため cmd+ctrl+h を使用。
# cmux(内蔵 Ghostty)が cmd+ctrl+h を ESC[102~ に変換して送る (~/.config/ghostty/config)
function _zle_ghq_browse() {
  local selected owner_repo
  selected=$(ghq list -p | _ghq_fzf_color | fzf --ansi --reverse --query "$LBUFFER")
  if [[ -n "$selected" ]]; then
    owner_repo=$(print -r -- "$selected" | rev | cut -d "/" -f -2 | rev)
    BUFFER="hub browse ${(q)owner_repo}"
    zle accept-line
  else
    zle reset-prompt
  fi
}
zle -N _zle_ghq_browse
bindkey '\e[102~' _zle_ghq_browse
