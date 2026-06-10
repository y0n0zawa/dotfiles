# Activate mise version manager
eval "$(~/.local/bin/mise activate zsh)"

# Initialize Homebrew environment variables (Apple Silicon: /opt/homebrew, Intel: /usr/local)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Enable YJIT (Just-In-Time compiler) for Ruby
MISE_RUBY_CONFIGURE_OPTS="--enable-yjit"

# Claude code
CLAUDE_CODE_NO_FLICKER=1
