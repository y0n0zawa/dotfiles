# Set option
setopt nonomatch

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Peco
function peco-ghq() {
  local selected_dir=$(ghq list -p | peco --query "$LBUFFER")
  if [ -n "$selected_dir" ]; then
    BUFFER="cd ${selected_dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N peco-ghq
bindkey '^G' peco-ghq

function peco-hub() {
  local selected_repo=$(ghq list -p | peco --query "$LBUFFER" | rev | cut -d "/" -f -2 | rev)
  echo $selected_repo
  if [ -n "$selected_repo" ]; then
    BUFFER="hub browse ${selected_repo}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N peco-hub
bindkey '^H' peco-hub

function peco-history-selection() {
  BUFFER=`history -n 1 | tail -r  | awk '!a[$0]++' | peco`
  CURSOR=$#BUFFER
  zle reset-prompt
}
zle -N peco-history-selection
bindkey '^R' peco-history-selection

# anyenv
if [ -d $HOME/.anyenv ] ; then
  export PATH="$HOME/.anyenv/bin:$PATH"
  eval "$(anyenv init -)"
fi

# golang
export GOENV_DISABLE_GOPATH=1
export GO111MODULE=on
export GOPATH=${HOME}/dev
export GOROOT=${HOME}/.anyenv/envs/goenv/versions/`goenv version`
PATH=$GOPATH/bin:$PATH

# nvim
XDG_CONFIG_HOME=~/.config

# auto suggestions
source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"


# asdf plugin
. /usr/local/opt/asdf/libexec/asdf.sh
. ~/.asdf/plugins/java/set-java-home.zsh

