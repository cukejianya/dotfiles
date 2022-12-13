###############################################################################
# General macOS Setup                                                         #
###############################################################################

# Disable 2 finger swipe for Brave Browser
defaults write com.brave.Browser AppleEnableSwipeNavigateWithScrolls -bool false

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable the crash reporter
defaults write com.apple.CrashReporter DialogType -string "none"

# Restart automatically if the computer freezes
sudo systemsetup -setrestartfreeze on

# Disable Notification Center and remove the menu bar icon
launchctl unload -w
/System/Library/LaunchAgents/com.apple.notificationcenterui.plist 2> /dev/null

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# Save screenshots to the desktop
defaults write com.apple.screencapture location -string "${HOME}/Screenshots"

# Finder: show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Don't show recently used applications in the Dock
defaults write com.Apple.Dock show-recents -bool false

# Week starts on monday
defaults write com.apple.iCal "first day of week" -int 1

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort Activity Monitor results by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# Enable the locate command
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.locate.plist

# Kill affected applications                                                  #
for app in "Address Book" "Dock" "Finder" "Mail" "SystemUIServer"; do
  killall "${app}" &> /dev/null
done

