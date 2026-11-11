# Shortcuts
alias copyssh="pbcopy < $HOME/.ssh/id_ed25519.pub"
alias reloadcli="source $HOME/.zshrc"
alias dotfiles="cd ~/.dotfiles"

# Git
alias gst="git status"
alias gco="git checkout"

# Open code path
c() { cd ~/Projects/syngenta/$1; }
_c() { _files  -W ~/Projects/syngenta -/; }
compdef _c c

# Apple Silicon
alias a="arch -x86_64"
alias ibrew="arch -x86_64 brew"

alias ssh-omarchy="tailscale ssh eliasousa@omarchy -t byobu"

# Docker Compose aliases
dc() { docker compose "$@" }
alias dc-up="docker compose up -d --wait"
alias dc-down="docker compose down"
dc-claude() { docker compose exec "$1" bash -ic claude }
dc-copilot() { docker compose exec "$1" bash -ic copilot }

alias aws-login-syngenta="aws sso login --sso-session syngenta-sso"
