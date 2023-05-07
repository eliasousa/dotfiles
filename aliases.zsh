# Shortcuts
alias copyssh="pbcopy < $HOME/.ssh/id_ed25519.pub"
alias reloadcli="source $HOME/.zshrc"
alias dotfiles="cd ~/.dotfiles"

# Git
alias gst="git status"
alias gco="git checkout"
alias gp="git pull"
alias gl="git log --oneline --decorate --color"

# Open code path
c() { cd ~/Projects/hatch/$1; }
_c() { _files  -W ~/Projects/hatch -/; }
compdef _c c

# Apple Silicon
alias a="arch -x86_64"
alias ibrew="arch -x86_64 brew"
