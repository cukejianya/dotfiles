#!/usr/bin/env bash
#
# macOS setup: Homebrew, packages, and system settings.
# blast-off.sh runs this file. You can also run it on its own.
set -euo pipefail

DOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

###############################################################################
# Homebrew                                                                    #
###############################################################################
if [[ ! -x /opt/homebrew/bin/brew ]]; then
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
brew bundle --file="$DOT/packages/Brewfile"

###############################################################################
# System settings                                                             #
###############################################################################
# Disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable the crash reporter
defaults write com.apple.CrashReporter DialogType -string "none"

# Restart automatically if the computer freezes
sudo systemsetup -setrestartfreeze on

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# Save screenshots to ~/screenshots
mkdir -p "$HOME/screenshots"
defaults write com.apple.screencapture location -string "$HOME/screenshots"

# Finder: show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Don't show recently used applications in the Dock
defaults write com.apple.dock show-recents -bool false

# Week starts on Monday
defaults write com.apple.iCal "first day of week" -int 1

# Activity Monitor: show all processes, sort by CPU
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# Enable the locate command
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist 2>/dev/null || true

# Apply the settings
for app in Dock Finder SystemUIServer; do
  killall "$app" &>/dev/null || true
done

###############################################################################
# App paths that differ on macOS                                              #
###############################################################################
# qutebrowser on macOS reads ~/.qutebrowser, not ~/.config/qutebrowser.
ln -sfn "$HOME/.config/qutebrowser" "$HOME/.qutebrowser"

###############################################################################
# Secrets                                                                     #
###############################################################################
# Cache the KeePassXC database password in the macOS keychain, so the shell
# can unlock secrets without a prompt (see bin/secret). Prompts once.
if ! security find-generic-password -a "$USER" -s keepassxc-db &>/dev/null; then
  echo "Enter the KeePassXC database password:"
  security add-generic-password -a "$USER" -s keepassxc-db -w
fi
