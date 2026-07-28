#Install homebrew
export HOMEBREW_INSTALL_FROM_API=1
/bin/bash -c \
  "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

#Install bundler
sudo gem install bundler

# Install brew and casks
brew bundle
