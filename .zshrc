# Path to your dotfiles installation.
export DOTFILES=$HOME/.dotfiles

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="robbyrussell"

# Would you like to use another custom folder than $ZSH/custom?
ZSH_CUSTOM=$DOTFILES

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# plugins=(git git-extras history-substring-search z zsh-syntax-highlighting zsh-autosuggestions)

# Activate Oh-My-Zsh
source $ZSH/oh-my-zsh.sh

# Editor
export EDITOR="code -w"

# Rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

export TILLER_NAMESPACE="tiller"

# Set Spaceship ZSH as a prompt
autoload -U promptinit; promptinit
prompt spaceship

#Autocomplete
source $ZSH/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

. $HOME/.asdf/asdf.sh

. $HOME/.asdf/completions/asdf.bash
