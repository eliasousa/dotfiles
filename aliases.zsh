# Shortcuts
alias copyssh="pbcopy < $HOME/.ssh/id_rsa.pub"
alias reloadcli="source $HOME/.zshrc"
alias c="clear"

# Directories
alias dotfiles="cd $DOTFILES"
alias library="cd $HOME/Library"

# Git
alias commit="git add . && git commit -m"
alias gcommit="git add . && git commit"
alias gst="git status"
alias gc="git checkout"
alias gd="git diff"
alias gl="git log --oneline --decorate --color"

# Open code path
c() { cd ~//Projects/jaya/$1; }
_c() { _files  -W ~/Projects/jaya -/; }
compdef _c c
