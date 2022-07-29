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

# Pipefy
# Docker Compose
dc_up_pipefy() {
  c pipefy-workspace/pipefy-core;
  docker-compose -f docker-compose.yml up -d;
}

dc_down_pipefy(){
  c pipefy-workspace/pipefy-core;
  docker-compose -f docker-compose.yml down;
}

# Run
run_pipe_server() {
  c pipefy-workspace/pipefy-core;
  bin/rails server -p 3010
}

run_pipe_sidekiq() {
  c pipefy-workspace/pipefy-core;
  bin/sidekiq -C config/sidekiq.yml
}

run_pipeui() {
  c pipefy-workspace/pipeui;
  yarn install && yarn start
}

# Apple Silicon
alias a="arch -x86_64"
alias ibrew="arch -x86_64 brew"
