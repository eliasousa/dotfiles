#!/bin/sh

echo "Setting up your Mac..."

echo "Installing Brew..."
# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update Homebrew recipes
brew update

echo "Installing Brew dependencies..."
# Install all our dependencies with bundle (See Brewfile)
brew tap homebrew/bundle
brew bundle

echo "Starting brew services..."
# To have launchd start at login:
brew services start mysql
brew services start redis
# brew services start postgresql

echo "Installing OhMyZsh..."
# Install OhMyZsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

echo "Adding development directories..."
# Create a Projects directory
mkdir $HOME/Projects
mkdir $HOME/Projects/jaya
mkdir $HOME/Projects/personal

echo "Replacing .zshrc..."
# Removes .zshrc from $HOME (if it exists) and symlinks the .zshrc file from the .dotfiles
rm -rf $HOME/.zshrc
ln -s $HOME/.dotfiles/.zshrc $HOME/.zshrc

echo "Installing zsh plugins..."
# Clone oh-my-zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions "$DOTFILES/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$DOTFILES/plugins/zsh-syntax-highlighting"

echo "Installing zsh spaceship theme..."
# Clone and setup oh-my-zsh theme
git clone https://github.com/denysdovhan/spaceship-prompt.git "$DOTFILES/themes/spaceship-prompt"
ln -s "$DOTFILES/themes/spaceship-prompt/spaceship.zsh-theme" "$DOTFILES/themes/spaceship.zsh-theme"

echo "Setting up mackup..."
# Symlink the Mackup config file to the home directory
ln -s $HOME/.dotfiles/.mackup.cfg $HOME/.mackup.cfg

# echo "Setting macOS preferences..."
# Set macOS preferences
# We will run this last because this will reload the shell
# source .macos

echo "Installing ASDF plugins..."
# Install ASDF plugins
asdf plugin-add ruby
asdf plugin-add nodejs
# asdf plugin-add elixir
# asdf plugin-add erlang
