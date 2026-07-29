source "$HOME/.cargo/env"

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.local/bin}"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export TMUX_HOME="$XDG_CONFIG_HOME/tmux"
export DOT_HOME="$HOME/.dotfiles"
export SRC_HOME="$HOME/src"
export DEV_HOME="$HOME/dev"

