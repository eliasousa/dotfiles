# Make sure coreutils are loaded before system commands
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"

# Openssl
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"

# grep
export PATH="/opt/homebrew/opt/grep/libexec/gnubin:$PATH"

# unzip
export PATH="/opt/homebrew/opt/unzip/bin:$PATH"

# krew
export PATH="/Users/eliasousa/.krew/bin:$PATH"

# Load custom commands
export PATH="$DOTFILES/bin:$PATH"
