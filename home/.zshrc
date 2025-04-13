# Set option
setopt nonomatch

# Load zprofile
if [ -f ~/.zprofile ]; then
    source ~/.zprofile
fi

# ============================================================================
# Git Repository Management
# ============================================================================

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

# ============================================================================
# Command History Management
# ============================================================================

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

# ============================================================================
# GitHub Integration
# ============================================================================

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
