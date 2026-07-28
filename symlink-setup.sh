#!/usr/bin/env bash
#
# Creates symlinks in ~/.local/bin for personal/work scripts
# Usage: ./link-work-scripts.sh
#

set -euo pipefail

BIN_DIR="$HOME/.local/bin"
WORK_DIR="$HOME/development/work-scripts"

mkdir -p "$BIN_DIR"

# Define mapping of link names to targets
declare -A LINKS=(

  # Work Scripts
  [cm]="$WORK_DIR/generate-commit-message.sh"
  [cpr]="$WORK_DIR/generate-pr.sh"
  [cycle-through-windows]="$WORK_DIR/cycle-through-windows.sh"
  [end-the-day.sh]="$WORK_DIR/end-the-day"
  [notes]="$WORK_DIR/notes"
  [ns]="$WORK_DIR/create_session"
  [open-google-meet]="$WORK_DIR/open-google-meets"
  [sp]="$WORK_DIR/switch-pane"
  [ss]="$WORK_DIR/switch_session"
  [start-the-day.sh]="$WORK_DIR/start-the-day"
  [sw]="$WORK_DIR/switch_session"
  [wt]="$WORK_DIR/wt"
  [claude-sessions]="$WORK_DIR/claude-sessions"
  [gcal-events]="$WORK_DIR/gcal-events"
  [git-stack]="$WORK_DIR/git-stack"
  [refresh-ads-api]="$WORK_DIR/refresh-ads-api"

  # Dev
  [uuid-to-bits]="$HOME/development/uuid-to-bits/uuid-to-bits.sh"
  [greet]="$HOME/development/greet/greet"

  #
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

