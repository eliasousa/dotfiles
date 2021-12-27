#!/bin/sh

echo "Setting up your Mac..."

echo "Installing Brew..."
# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Installing Brew for rosetta..."
# Check for Homebrew and install if we don't have it
if test ! $(which arch -x86_64 brew); then
  arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Installing OhMyZsh..."
# Check for Oh My Zsh and install if we don't have it
if test ! $(which omz); then
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
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

echo "Setup asdf for rosetta"
arch -x86_64 brew install asdf

echo "Adding development directories..."
# Create a Projects directory
mkdir $HOME/Projects
mkdir $HOME/Projects/jaya
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

echo "Setting up mackup..."
# Symlink the Mackup config file to the home directory
ln -s $HOME/.dotfiles/.mackup.cfg $HOME/.mackup.cfg

echo "Installing ASDF plugins..."
# Install ASDF plugins
arch -x86_64 asdf plugin-add ruby # via rosetta
arch -x86_64 asdf plugin-add nodejs # via rosetta
# asdf plugin-add elixir
# asdf plugin-add erlang
