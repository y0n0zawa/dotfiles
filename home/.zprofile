# Initialize Homebrew environment variables
eval "$(/opt/homebrew/bin/brew shellenv)"

# Activate mise version manager
eval "$(mise activate zsh)"

# Enable YJIT (Just-In-Time compiler) for Ruby
MISE_RUBY_CONFIGURE_OPTS="--enable-yjit"
