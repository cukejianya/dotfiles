#!/usr/bin/env bash
#
# Creates symlinks in ~/.local/bin for personal/work scripts
# Usage: ./link-work-scripts.sh
#

set -euo pipefail

source 
BIN_DIR="$HOME/.local/bin"
WORK_DIR="$DEV_HOME/work-scripts"


mkdir -p "$BIN_DIR"

# Define mapping of link names to targets
declare -A LINKS=(

  # Work Scripts
  [cycle-through-windows]="$WORK_DIR/cycle-through-windows.sh"
  [open-google-meet]="$WORK_DIR/open-google-meets"
  [gcal-events]="$WORK_DIR/gcal-events"

  # Dev
  [uuid-to-bits]="$HOME/development/uuid-to-bits/uuid-to-bits.sh"
  [greet]="$DEV_HOME/greet/greet"

  # Dotfiles
  [claude-sessions]="$DOT_DIR/claude-sessions"
  [cm]="$DOT_DIR/generate-commit-message.sh"
  [cpr]="$DOT_DIR/generate-pr.sh"
  [end-the-day.sh]="$DOT_DIR/end-the-day"
  [git-stack]="$DOT_DIR/git-stack"
  [notes]="$DOT_DIR/notes"
  [ns]="$DOT_DIR/create_session"
  [refresh-ads-api]="$DOT_DIR/refresh-ads-api"
  [secret]="$DOT_DIR/bin/secret"
  [sp]="$DOT_DIR/switch-pane"
  [ss]="$DOT_DIR/switch_session"
  [start-the-day.sh]="$DOT_DIR/start-the-day"
  [sw]="$DOT_DIR/switch_session"
  [wt]="$DOT_DIR/wt"
)

echo "🔗 Creating symlinks in $BIN_DIR ..."

for link in "${!LINKS[@]}"; do
  target="${LINKS[$link]}"
  dest="$BIN_DIR/$link"

  if [[ -e "$dest" || -L "$dest" ]]; then
    echo "↺ Updating existing link: $link"
    rm -f "$dest"
  fi

  if [[ -f "$target" || -x "$target" ]]; then
    ln -s "$target" "$dest"
    echo "✅ Linked $link → $target"
  else
    echo "⚠️  Target not found: $target (skipping)"
  fi
done

echo "✨ Done! Make sure ~/.local/bin is in your PATH."

