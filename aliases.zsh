# Shortcuts
alias copyssh="pbcopy < $HOME/.ssh/id_rsa.pub"
alias reloadcli="source $HOME/.zshrc"

# Git
alias commit="git add . && git commit -m"
alias gst="git status"
alias gco="git checkout"
alias gd="git diff"
alias gl="git log --oneline --decorate --color"

# Open code path
c() { cd ~/Projects/jaya/$1; }
_c() { _files  -W ~/Projects/jaya -/; }
compdef _c c
