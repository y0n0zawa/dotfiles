# Initialize Homebrew environment variables (Apple Silicon: /opt/homebrew, Intel: /usr/local)
# brew を先に通すことで、PATH 上の mise (brew/公式どちらでも) を動的に発見できる
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Activate mise version manager (パスを固定せず動的に解決)
# 1) PATH 上の mise を優先  2) 公式インストーラ既定の ~/.local/bin を fallback
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
elif [ -x "$HOME/.local/bin/mise" ]; then
  eval "$("$HOME/.local/bin/mise" activate zsh)"
fi

# Enable YJIT (Just-In-Time compiler) for Ruby
MISE_RUBY_CONFIGURE_OPTS="--enable-yjit"

# Claude code
CLAUDE_CODE_NO_FLICKER=1
