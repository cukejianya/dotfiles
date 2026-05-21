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

# Install OhMyZSH
sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Symbolic Links                                                              #
ln -s $PWD/.vimrc ~/.vimrc
ln -sf $PWD/.zshrc ~/.zshrc
ln -sf $PWD/.config ~/.config
ln -s $PWD/.tmux.conf ~/.tmux.conf
ln -sf $PWD/.gitconfig ~/.gitconfig

# Install NVM
curl -fsSL https://fnm.vercel.app/install | bash
source ~/.zshrc

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
mkdir ~/dev ~/screenshot
ln -s ~/screenshots ~/Desktop/screenshots

# Install Tmux Plugin Manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install Spicetify
curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh

