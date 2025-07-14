mv $PWD ~/.dotfiles
###############################################################################
# General Installations                                                       #
###############################################################################

#Install homebrew
export HOMEBREW_INSTALL_FROM_API=1
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

#Install bundler
 sudo gem install bundler

# Install brew and casks
brew bundle

# Install OhMyZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Symbolic Links                                                              #
ln -s $PWD/.vimrc ~/.vimrc
ln -sf $PWD/.zshrc ~/.zshrc
ln -sf $PWD/.config ~/.config
ln -s $PWD/.tmux.conf ~/.tmux.conf
ln -sf $PWD/.ssh_config ~/.ssh/config
ln -sf $PWD/.gitconfig ~/.gitconfig

# Install NVM
sh -c "$(curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh)"
source ~/.zshrc
nvm install --lts
nvm use --lts

# Install NPM modules
npm install -g tldr

# Install SDK
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Install LSP Servers
yarn global add yaml-language-server

# Install Java
sdk install maven
sdk install java 17.0.4-amzn
sdk install java 11.0.17-amzn
sdk default java 17.0.4-amzn

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

# Install Vundle
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall

# Remove Unnecessary folder
sudo rm -rf ~/Documents ~/Movies ~/Music

# Make Development and Screenshot folder
mkdir ~/Development ~/Screenshots
ln -s ~/Screenshots ~/Desktop/Screenshots

# Create ssh key
ssh-keygen -t ed25519 -C "cukejianya@gmail.com"
ssh-add

# Install Nvim Plugins
vim +PackerInstall +qall

# Install Tmux Manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install Spicetify
curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh

# Install Fira Code Retina Font 
curl -L -O https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Retina/complete/Fira%20Code%20Retina%20Nerd%20Font%20Complete.ttf
mv Fira%20Code%20Retina%20Nerd%20Font%20Complete.ttf ~/Library/Fonts/FiraCode-Retina-NerdFont-Complete.ttf
