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
c() { cd ~/Projects/jaya/$1; }
_c() { _files  -W ~/Projects/jaya -/; }
compdef _c c

# Docker Compose OpsLevel
dc_up_opslevel() {
  c OpsLevel;
  docker-compose -f ./docker-compose/opslevel.yml up -d;
}

dc_down_opslevel(){
  c OpsLevel;
  docker-compose -f ./docker-compose/opslevel.yml down;
}

# Apple Silicon
alias a="arch -x86_64"
alias ibrew="arch -x86_64 brew"
