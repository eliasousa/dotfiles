#!/bin/sh

echo "Setting up your Mac..."

echo "Installing Brew..."
# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/eliasousa/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "Installing OhMyZsh..."
# Check for Oh My Zsh and install if we don't have it
if test ! $(which omz); then
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Update Homebrew recipes
brew update

echo "Installing Brew dependencies..."
# Install all our dependencies with bundle (See Brewfile)
brew tap homebrew/bundle
brew bundle

# echo "Starting brew services..."
# To have launchd start at login:
# brew services start mysql
# brew services start redis
# brew services start postgresql

echo "Setup asdf"
brew install asdf

echo "Adding development directories..."
# Create a Projects directory
mkdir $HOME/Projects
mkdir $HOME/Projects/syngenta
mkdir $HOME/Projects/personal

echo "Replacing .zshrc..."
# Removes .zshrc from $HOME (if it exists) and symlinks the .zshrc file from the .dotfiles
rm -rf $HOME/.zshrc
ln -s $HOME/.dotfiles/.zshrc $HOME/.zshrc

# Path to your dotfiles installation.
export DOTFILES=$HOME/.dotfiles

echo "Installing zsh plugins..."
# Clone oh-my-zsh plugins
sudo git clone https://github.com/zsh-users/zsh-autosuggestions "$DOTFILES/plugins/zsh-autosuggestions"
sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$DOTFILES/plugins/zsh-syntax-highlighting"

echo "Installing zsh spaceship theme..."
# Clone and setup oh-my-zsh theme
sudo git clone https://github.com/denysdovhan/spaceship-prompt.git "$DOTFILES/themes/spaceship-prompt"
sudo ln -s "$DOTFILES/themes/spaceship-prompt/spaceship.zsh-theme" "$DOTFILES/themes/spaceship.zsh-theme"

echo "Installing ASDF plugins..."
# Install ASDF plugins
asdf plugin add elixir
asdf plugin add erlang
asdf plugin add golang
asdf plugin add python
asdf plugin add nodejs

echo "Installing Herdr config..."
# Mods, layout and keys for Herdr (see herdr/README.md); skipped until Herdr has run once
[ -d "$HOME/.config/herdr-app" ] && sh "$DOTFILES/herdr/install.sh" || echo "Herdr not set up yet: run herdr/install.sh after opening Herdr once"
