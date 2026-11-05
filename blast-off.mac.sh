#!/usr/bin/env bash
#
# macOS setup: Homebrew, packages, and system settings.
# blast-off.sh runs this file. You can also run it on its own.
#
# A failed step is recorded and the next step runs. See blast-off.lib.sh for
# the logs. The only stop: Homebrew is missing, because later steps need it.
set -euo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=blast-off.lib.sh
source "$DOT/blast-off.lib.sh"
blast_off_log_start "$@"

###############################################################################
# Homebrew                                                                    #
###############################################################################
step "Homebrew"
install_homebrew() {
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}
[[ -x /opt/homebrew/bin/brew ]] || run "Install Homebrew" install_homebrew
[[ -x /opt/homebrew/bin/brew ]] || die "Homebrew is not installed"
eval "$(/opt/homebrew/bin/brew shellenv)"

step "Homebrew packages"
run "brew bundle (packages/Brewfile)" brew bundle --file="$DOT/packages/Brewfile"

###############################################################################
# System settings                                                             #
###############################################################################
step "System settings"
run "Disable the 'open this application?' dialog" \
  defaults write com.apple.LaunchServices LSQuarantine -bool false
run "Disable the crash reporter" \
  defaults write com.apple.CrashReporter DialogType -string "none"
run "Restart automatically after a freeze" \
  sudo systemsetup -setrestartfreeze on
run "Better Bluetooth audio quality" \
  defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40
run "Create ~/screenshots" mkdir -p "$HOME/screenshots"
run "Save screenshots to ~/screenshots" \
  defaults write com.apple.screencapture location -string "$HOME/screenshots"
run "Finder: show hidden files" \
  defaults write com.apple.finder AppleShowAllFiles -bool true
run "Dock: hide recent applications" \
  defaults write com.apple.dock show-recents -bool false
run "Calendar: week starts on Monday" \
  defaults write com.apple.iCal "first day of week" -int 1
run "Activity Monitor: show all processes" \
  defaults write com.apple.ActivityMonitor ShowCategory -int 0
run "Activity Monitor: sort by CPU" \
  defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
run "Activity Monitor: sort descending" \
  defaults write com.apple.ActivityMonitor SortDirection -int 0

# Optional steps: an error here only means it is already done or not needed.
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist 2>/dev/null || true
for app in Dock Finder SystemUIServer; do
  killall "$app" &>/dev/null || true
done

###############################################################################
# App paths that differ on macOS                                              #
###############################################################################
# qutebrowser on macOS reads ~/.qutebrowser, not ~/.config/qutebrowser.
run "Link ~/.qutebrowser" ln -sfn "$HOME/.config/qutebrowser" "$HOME/.qutebrowser"

###############################################################################
# Secrets                                                                     #
###############################################################################
# Cache the KeePassXC database password in the macOS keychain, so the shell
# can unlock secrets without a prompt (see bin/secret). Prompts once.
store_vault_password() {
  if ! security find-generic-password -a "$USER" -s keepassxc-db &>/dev/null; then
    echo "Enter the KeePassXC database password:"
    security add-generic-password -a "$USER" -s keepassxc-db -w
  fi
}
step "Vault password in the keychain"
run "Store the vault master password in the keychain" store_vault_password

finish
