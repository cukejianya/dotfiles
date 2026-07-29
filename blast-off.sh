mv $PWD ~/.dotfiles
###############################################################################
# General Installations                                                       #
###############################################################################

#Install homebrew
export HOMEBREW_INSTALL_FROM_API=1
/bin/bash -c \
  "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

#Install bundler
sudo gem install bundler

# Install brew and casks
brew bundle

# Source env vars
source $PWD/config/zsh/.zshenv

# Symbolic Links                                                              #
ln -s $PWD/.vimrc ~/.vimrc
ln -sf $ZDOTDIR/.zshenv ~/.zshenv
ln -sf $PWD/config ~/.config

# Install FNM 
curl -fsSL https://fnm.vercel.app/install | bash

# Install NPM modules
npm install -g tldr

cd ./packages

# Instal Java Debug
git clone https://github.com/microsoft/java-debug.git
cd ../java-debug
./mvnw clean install
cd ../

#Install Vscode Java Test
git clone https://github.com/microsoft/vscode-java-test.git
cd ../vscode-java-test
npm install
cd ../../

# Remove Unnecessary folder
sudo rm -rf ~/Documents ~/Movies ~/Music

# Make Development and Screenshot folder
mkdir ~/dev ~/screenshot ~/src
ln -s ~/screenshots ~/Desktop/screenshots

# Install Tmux Plugin Manager
git clone https://github.com/tmux-plugins/tpm $XDG_CONFIG_DIR/tmux/plugins/tpm

# Install Spicetify
curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh

# Install Qutebrowser theme
case "$OSTYPE" in
linux* | *bsd*)
  git clone https://github.com/catppuccin/qutebrowser.git ~/.config/qutebrowser/catppuccin
  ;;
darwin*)
  git clone https://github.com/catppuccin/qutebrowser.git ~/.qutebrowser/catppuccin
  ;;
esac
