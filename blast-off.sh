mv $PWD ~/.dotfiles
###############################################################################
# General Installations                                                       #
###############################################################################

#Install bundler
 sudo gem install bundler

# Install brew and casks
 bundle install && brew bundle

# Install OhMyZSH
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

# Symbolic Links                                                              #
ln -s $PWD/.vimrc ~/.vimrc
ln -sf $PWD/.zshrc ~/.zshrc
ln -s $PWD/.tmux.conf ~/.tmux.conf
ln -sf $PWD/.ssh_config ~/.ssh/config

# Install NVM
sh -c "$(curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh)"
nvm install --lts
nvm use --lts

# Install NPM modules
npm install -g tldr
npm install -g expo

# Install Vundle
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

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

# Install Monaco Nerd Font
git clone https://github.com/Karmenzind/monaco-nerd-fonts.git

