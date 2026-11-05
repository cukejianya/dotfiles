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
#
# A failed step is recorded and the next step runs. At the end, the script
# lists every failure. Logs: ~/.local/state/blast-off/ (see blast-off.lib.sh).
# The run stops only when later steps cannot work: wrong repo path, unknown
# OS, or failed symlinks.
set -euo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$DOT" != "$HOME/.dotfiles" ]]; then
  echo "Clone this repo to ~/.dotfiles, then run it from there:" >&2
  echo "  git clone https://github.com/cukejianya/dotfiles.git ~/.dotfiles" >&2
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

# shellcheck source=blast-off.lib.sh
source "$DOT/blast-off.lib.sh"
blast_off_log_start "$@"

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
  *) die "Unsupported OS: $(uname -s)" ;;
esac

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
[[ -f "$os_script" ]] || die "$os_script does not exist yet. See docs/blast-off-linux.md"
run "OS setup ($os_script)" bash "$os_script"

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
qutebrowser_theme() {
  local catppuccin="$DOT/config/qutebrowser/catppuccin"
  [[ -d "$catppuccin" ]] \
    || git clone --depth 1 https://github.com/catppuccin/qutebrowser.git "$catppuccin"
}
step "qutebrowser theme"
run "qutebrowser theme" qutebrowser_theme

symlinks() {
  mkdir -p "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_STATE_HOME" "$XDG_BIN_HOME"
  link "$DOT/config" "$XDG_CONFIG_HOME"
  link "$DOT/config/zsh/.zshenv" "$HOME/.zshenv"
  link "$DOT/.gitconfig" "$HOME/.gitconfig"
  local script
  for script in "$DOT"/bin/*; do
    if [[ -f "$script" ]]; then
      link "$script" "$XDG_BIN_HOME/$(basename "$script")"
    fi
  done
}
step "Symlinks"
run "Symlinks" symlinks
# Every later step, and the work overlay, uses these links.
[[ -L "$XDG_CONFIG_HOME" && -L "$HOME/.gitconfig" ]] || die "Symlinks are missing"

step "Git hooks"
# Block commits and pushes that leak work data or secrets.
run "Git hooks" git -C "$DOT" config core.hooksPath .githooks

step "Directories"
run "Directories" mkdir -p "$HOME/dev" "$HOME/src" "$HOME/screenshots"

node_lts() {
  fnm install --lts
  fnm default lts-latest
  npm install -g tldr
}
step "Node (fnm)"
if command -v fnm >/dev/null; then
  # eval must run in this shell (it sets PATH), so it cannot use run.
  if fnm_env=$(fnm env --shell bash) && eval "$fnm_env"; then
    run "Node LTS and tldr" node_lts
  else
    record_failure "Node: fnm env failed"
  fi
else
  record_failure "Node: fnm is not installed"
fi

google_java_format() {
  # nvim's formatter.lua reads this path. Keep the version in sync.
  local version=1.36.1
  local sha256=25b400f003089d23cc5320cdaf1a16cabee19b8aa3434d0ff021b3d9f42154b4
  local jar="$XDG_DATA_HOME/google-java-format/google-java-format-$version-all-deps.jar"
  [[ -f "$jar" ]] && return 0
  mkdir -p "$(dirname "$jar")"
  curl -fsSL -o "$jar.tmp" \
    "https://github.com/google/google-java-format/releases/download/v$version/google-java-format-$version-all-deps.jar"
  echo "$sha256  $jar.tmp" | shasum -a 256 -c -
  mv "$jar.tmp" "$jar"
}
step "google-java-format"
run "google-java-format" google_java_format

tmux_plugin_manager() {
  local tpm="$XDG_CONFIG_HOME/tmux/plugins/tpm"
  [[ -d "$tpm" ]] || git clone https://github.com/tmux-plugins/tpm "$tpm"
}
step "tmux plugin manager"
run "tmux plugin manager" tmux_plugin_manager

step "Neovim plugins"
run "Neovim plugins" nvim --headless "+Lazy! restore" +qa

spicetify() {
  [[ -x "$HOME/.spicetify/spicetify" ]] \
    || curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh
}
step "Spicetify"
run "Spicetify" spicetify

login_shell() {
  if [[ "$(basename "$SHELL")" != zsh ]]; then
    chsh -s "$(command -v zsh)"
  fi
}
step "Login shell"
run "Login shell" login_shell

###############################################################################
# 3. Work                                                                     #
###############################################################################
if [[ "$work" == yes ]]; then
  step "Work setup"
  work_dir="$HOME/.dotfiles-work"
  if [[ -f "$work_dir/blast-off.sh" ]]; then
    run "Work setup ($work_dir/blast-off.sh)" bash "$work_dir/blast-off.sh"
  else
    record_failure "Work setup: clone your private work overlay to $work_dir"
  fi
fi

step "Done"
echo "Open a new terminal. In tmux, press prefix + I to install tmux plugins."
finish
