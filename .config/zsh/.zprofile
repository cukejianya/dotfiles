export XDG_CONFIG_HOME="$HOME/.config"
export DEV_HOME="$HOME/dev"

addToPath() {
    if [[ "$PATH" != *"$1"* ]]; then
        export PATH=$PATH:$1
    fi
}

addToPathFront() {
    if [[ ! -z "$2" ]] || [[ "$PATH" != *"$1"* ]]; then
        export PATH=$1:$PATH
    fi
}

# Set PATH, MANPATH, etc., for Homebrew.
eval "$(/opt/homebrew/bin/brew shellenv)"
#
## --- Path configuration ---
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# For pkg-config to find zlib you may need to set:
export PKG_CONFIG_PATH="${PKG_CONFIG_PATH} /usr/local/opt/zlib/lib/pkgconfig"
addToPath "/usr/local/sbin"
addToPath "/usr/local/opt/php@7.2/bin"
addToPath "/usr/local/opt/php@7.2/sbin"

# Add RUST bin to PATH
addToPath "$HOME/.cargo/bin"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
addToPath "$HOME/.rvm/bin"

## --- Constants ---
# Add Java HOME environment 
export JAVA_HOME="$HOME/.sdkman/candidates/java/current"

# ssh
export SSH_HOME="~/.ssh"

# workscript
export WORKSCRIPTS="$HOME/development/work-scripts"

# pi
export PI_CODING_AGENT_DIR="$XDG_CONFIG_HOME/pi/agent"

if [ -f ~/.zprofile.local ]; then
  source $ZDOTDIR/.zprofile.local
fi

if [ -f ~/.zshenv ]; then
  source $ZDOTDIR/.zshenv
fi
