# Set PATH, MANPATH, etc., for Homebrew.
eval "$(/opt/homebrew/bin/brew shellenv)"
#
## --- Path configuration ---
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# For pkg-config to find zlib you may need to set:
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} /usr/local/opt/zlib/lib/pkgconfig"
export PATH="$PATH/usr/local/sbin"
export PATH="$PATH:/usr/local/opt/php@7.2/bin"
export PATH=":$PATH:/usr/local/opt/php@7.2/sbin"

# Add RUST bin to PATH
export PATH="$PATH:$HOME/.cargo/bin"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

## --- Constants ---
# Add Java HOME environment 
export JAVA_HOME="/Users/chinedumu/.sdkman/candidates/java/current"

# ssh
export SSH_HOME="~/.ssh"

# workscript
export WORKSCRIPTS="$HOME/development/work-scripts"

if [ -f ~/.zprofile.local ]; then
  source ~/.zprofile.local
fi
