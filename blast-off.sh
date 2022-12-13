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

# Install Vim Plugins
vim +PluginInstall +qall

# Install Tmux Manager
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install Fira Code Retina Font 
curl -L -O https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/FiraCode/Retina/complete/Fira%20Code%20Retina%20Nerd%20Font%20Complete.ttf
mv Fira%20Code%20Retina%20Nerd%20Font%20Complete.ttf ~/Library/Fonts/FiraCode-Retina-NerdFont-Complete.ttf
