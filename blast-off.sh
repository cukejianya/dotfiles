#!/usr/bin/env bash
#
# Set up a computer from this repo. Safe to run again after a failure.
#
# Usage: ./blast-off.sh [--work | --no-work]
#
# Order:
#   1. blast-off.<os>.sh   OS packages (brew or pacman) and OS settings
#   2. generic setup       symlinks, directories, node, tmux, nvim, shell
#   3. work overlay        ~/.dotfiles-work/blast-off.sh, when this is a work
#                          computer. That repo is private and holds all work
#                          config. See .githooks/leak-check.
set -euo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$DOT" != "$HOME/.dotfiles" ]]; then
  echo "Clone this repo to ~/.dotfiles, then run it from there:" >&2
  echo "  git clone git@github.com:cukejianya/dotfiles.git ~/.dotfiles" >&2
  exit 1
fi

work=""
for arg in "$@"; do
  case "$arg" in
    --work) work=yes ;;
    --no-work) work=no ;;
    *) echo "usage: $0 [--work | --no-work]" >&2; exit 2 ;;
  esac
done

# Ask first, so the long install below runs unattended.
if [[ -z "$work" ]]; then
  if [[ -t 0 ]]; then
    read -rp "Is this a work computer? [y/N] " reply
    [[ "$reply" == [yY]* ]] && work=yes || work=no
  else
    work=no
  fi
fi

case "$(uname -s)" in
  Darwin) os=mac ;;
  Linux) os=linux ;;
  *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

# Move a real file or directory out of the way, then symlink.
link() {
  local target="$1" dest="$2"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    echo "Backing up $dest to $dest.bak"
    mv "$dest" "$dest.bak"
  fi
  ln -sfn "$target" "$dest"
}

###############################################################################
# 1. OS                                                                       #
###############################################################################
step "OS setup ($os)"
os_script="$DOT/blast-off.$os.sh"
if [[ ! -f "$os_script" ]]; then
  echo "$os_script does not exist yet. See docs/blast-off-linux.md." >&2
  exit 1
fi
bash "$os_script"

# Same values as config/zsh/.zshenv. That file is zsh, so do not source it here.
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_BIN_HOME="$HOME/.local/bin"
export PATH="/opt/homebrew/bin:$XDG_BIN_HOME:$PATH"

###############################################################################
# 2. Generic                                                                  #
###############################################################################
step "qutebrowser theme"
catppuccin="$DOT/config/qutebrowser/catppuccin"
[[ -d "$catppuccin" ]] \
  || git clone --depth 1 https://github.com/catppuccin/qutebrowser.git "$catppuccin"

step "Symlinks"
mkdir -p "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_BIN_HOME"
link "$DOT/config" "$XDG_CONFIG_HOME"
link "$DOT/config/zsh/.zshenv" "$HOME/.zshenv"
link "$DOT/.gitconfig" "$HOME/.gitconfig"
for script in "$DOT"/bin/*; do
  [[ -f "$script" ]] && link "$script" "$XDG_BIN_HOME/$(basename "$script")"
done

step "Git hooks"
# Block commits and pushes that leak work data or secrets.
git -C "$DOT" config core.hooksPath .githooks

step "Directories"
mkdir -p "$HOME/dev" "$HOME/src" "$HOME/screenshots"

step "Node (fnm)"
eval "$(fnm env --shell bash)"
fnm install --lts
fnm default lts-latest
npm install -g tldr

step "tmux plugin manager"
tpm="$XDG_CONFIG_HOME/tmux/plugins/tpm"
[[ -d "$tpm" ]] || git clone https://github.com/tmux-plugins/tpm "$tpm"

step "Neovim plugins"
nvim --headless "+Lazy! restore" +qa

step "Spicetify"
[[ -x "$HOME/.spicetify/spicetify" ]] \
  || curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh

step "Login shell"
if [[ "$(basename "$SHELL")" != zsh ]]; then
  chsh -s "$(command -v zsh)"
fi

###############################################################################
# 3. Work                                                                     #
###############################################################################
if [[ "$work" == yes ]]; then
  step "Work setup"
  work_dir="$HOME/.dotfiles-work"
  if [[ ! -f "$work_dir/blast-off.sh" ]]; then
    echo "Clone your private work overlay to $work_dir, then run this script again." >&2
    exit 1
  fi
  bash "$work_dir/blast-off.sh"
fi

step "Done"
echo "Open a new terminal. In tmux, press prefix + I to install tmux plugins."
