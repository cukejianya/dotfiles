#!/usr/bin/env zsh
set -euo pipefail

repo_dir="${0:A:h:h}"
sandbox=$(mktemp -d)
trap 'rm -rf "$sandbox"' EXIT
mkdir -p "$sandbox/bin" "$sandbox/cache" "$sandbox/notes"

fail() {
  print -u2 "FAIL: $1"
  exit 1
}

assert_equal() {
  [[ "$1" == "$2" ]] || fail "expected '$2', got '$1'"
}

cat > "$sandbox/bin/aerospace" <<'EOF'
#!/usr/bin/env zsh
case "$1" in
  list-windows)
    if [[ " $* " == *" --focused "* ]]; then
      cat "$TEST_FOCUS"
    elif [[ -f "$TEST_POPUP" ]]; then
      print "99|quick-notes|$(<"$TEST_POPUP")"
    fi
    ;;
  list-workspaces)
    cat "$TEST_WORKSPACE"
    ;;
  layout)
    print -r -- "$*" >> "$TEST_ACTIONS"
    ;;
  move-node-to-workspace)
    print -r -- "$*" >> "$TEST_ACTIONS"
    print -r -- "${@: -1}" > "$TEST_POPUP"
    ;;
  focus)
    print -r -- "$*" >> "$TEST_ACTIONS"
    print -r -- "$3" > "$TEST_FOCUS"
    ;;
  workspace)
    print -r -- "$*" >> "$TEST_ACTIONS"
    print -r -- "${@: -1}" > "$TEST_WORKSPACE"
    ;;
  *)
    exit 1
    ;;
esac
EOF

cat > "$sandbox/bin/kitty" <<'EOF'
#!/usr/bin/env zsh
sleep "${TEST_KITTY_DELAY:-0}"
print -r -- "$*" >> "$TEST_KITTY_CALLS"
print N > "$TEST_POPUP"
EOF

cat > "$sandbox/bin/daily-note" <<'EOF'
#!/bin/sh
if [ "${1:-}" = "--path" ]; then
  printf '%s\n' "${TEST_NOTE_PATH:-/tmp/today.md}"
fi
exit 0
EOF

cat > "$sandbox/bin/nvim" <<'EOF'
#!/bin/sh
if [ -n "${NVIM_ARGS_FILE:-}" ]; then
  printf '%s\n' "$@" > "$NVIM_ARGS_FILE"
fi
EOF

cat > "$sandbox/bin/position-quick-notes" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$TEST_POSITION_CALLS"
EOF

chmod +x "$sandbox/bin"/*

export PATH="$sandbox/bin:/usr/bin:/bin"
export QUICK_NOTES_CACHE_DIR="$sandbox/cache"
export QUICK_NOTES_DISABLE_NOTIFICATION=true
export QUICK_NOTES_POSITION_COMMAND="$sandbox/bin/position-quick-notes"
export QUICK_NOTES_KITTY_COMMAND="$sandbox/bin/kitty"
export TEST_FOCUS="$sandbox/focus"
export TEST_WORKSPACE="$sandbox/workspace"
export TEST_POPUP="$sandbox/popup"
export TEST_ACTIONS="$sandbox/actions"
export TEST_KITTY_CALLS="$sandbox/kitty-calls"
export TEST_POSITION_CALLS="$sandbox/position-calls"

print 42 > "$TEST_FOCUS"
print J > "$TEST_WORKSPACE"
: > "$TEST_ACTIONS"

# An absent popup starts once on the current workspace.
"$repo_dir/bin/quick-notes"
assert_equal "$(<"$TEST_POPUP")" J
assert_equal "$(<"$TEST_FOCUS")" 99
assert_equal "$(wc -l < "$TEST_KITTY_CALLS" | tr -d ' ')" 1
grep -Fq -- '--title quick-notes' "$TEST_KITTY_CALLS" || fail "Kitty title is missing"
grep -Fq -- 'daily-note --edit quick-capture' "$TEST_KITTY_CALLS" || fail "daily note command is missing"
grep -Fqx 'quick-notes 60 70 15 185 50 50' "$TEST_POSITION_CALLS" || fail "popup geometry is incorrect"

# A focused popup hides and restores the previous window.
"$repo_dir/bin/quick-notes"
assert_equal "$(<"$TEST_POPUP")" N
assert_equal "$(<"$TEST_FOCUS")" 42

# A hidden popup returns without another Kitty process.
"$repo_dir/bin/quick-notes"
assert_equal "$(<"$TEST_POPUP")" J
assert_equal "$(<"$TEST_FOCUS")" 99
assert_equal "$(wc -l < "$TEST_KITTY_CALLS" | tr -d ' ')" 1

# A visible popup without focus receives focus.
print 42 > "$TEST_FOCUS"
"$repo_dir/bin/quick-notes"
assert_equal "$(<"$TEST_POPUP")" J
assert_equal "$(<"$TEST_FOCUS")" 99
assert_equal "$(wc -l < "$TEST_KITTY_CALLS" | tr -d ' ')" 1

cat > "$sandbox/notes/template.md" <<'EOF'
# Month Daily

## Quick Capture
- 

## Meetings
EOF

export DAILY_NOTES_DIR="$sandbox/notes"
export DAILY_NOTE_EDITOR=nvim
export NVIM_ARGS_FILE="$sandbox/nvim-args"

"$repo_dir/bin/daily-note" --edit quick-capture >/dev/null
note=$(find "$sandbox/notes" -name '*_daily.md' -type f)
[[ -f "$note" ]] || fail "daily note was not created"
grep -Fqx '+/^## Quick Capture$/' "$NVIM_ARGS_FILE" || fail "capture search is missing"
grep -Fqx '+normal! j$' "$NVIM_ARGS_FILE" || fail "capture cursor action is missing"

print 'preserve me' >> "$note"
"$repo_dir/bin/daily-note" --edit quick-capture >/dev/null
grep -Fqx 'preserve me' "$note" || fail "existing daily note was replaced"

# Concurrent creators cannot replace a note that another process created.
mkdir "$sandbox/race-notes"
cp "$sandbox/notes/template.md" "$sandbox/race-notes/template.md"
cat > "$sandbox/bin/gcal-events" <<'EOF'
#!/bin/sh
sleep "${GCAL_DELAY:-0}"
EOF
chmod +x "$sandbox/bin/gcal-events"
GCAL_DELAY=0.3 DAILY_NOTES_DIR="$sandbox/race-notes" "$repo_dir/bin/daily-note" >/dev/null &
slow_creator=$!
sleep 0.05
GCAL_DELAY=0 DAILY_NOTES_DIR="$sandbox/race-notes" "$repo_dir/bin/daily-note" >/dev/null
race_note=$(find "$sandbox/race-notes" -name '*_daily.md' -type f)
print 'concurrent capture' >> "$race_note"
wait "$slow_creator"
grep -Fqx 'concurrent capture' "$race_note" || fail "concurrent creation replaced the daily note"

# Empty focus data clears an old previous-window identifier.
print N > "$TEST_POPUP"
: > "$TEST_FOCUS"
print J > "$TEST_WORKSPACE"
print 123 > "$sandbox/cache/previous-window"
"$repo_dir/bin/quick-notes"
[[ ! -f "$sandbox/cache/previous-window" ]] || fail "stale previous window was retained"
"$repo_dir/bin/quick-notes"
assert_equal "$(<"$TEST_POPUP")" N
assert_equal "$(<"$TEST_WORKSPACE")" J

# A popup on another visible workspace receives focus without a move.
print P > "$TEST_POPUP"
print 42 > "$TEST_FOCUS"
print J > "$TEST_WORKSPACE"
"$repo_dir/bin/quick-notes"
assert_equal "$(<"$TEST_POPUP")" P
assert_equal "$(<"$TEST_FOCUS")" 99

# A date refresh rejects a note without the capture heading.
export TEST_NOTE_PATH="$sandbox/today.md"
print '# No capture section' > "$TEST_NOTE_PATH"
print N > "$TEST_POPUP"
print 42 > "$TEST_FOCUS"
print J > "$TEST_WORKSPACE"
print 1900-01-01 > "$sandbox/cache/current-date"
python3 - "$sandbox/cache/nvim.sock" <<'PY' &
import socket
import sys
import time

server = socket.socket(socket.AF_UNIX)
server.bind(sys.argv[1])
server.listen()
time.sleep(10)
PY
socket_pid=$!
for _ in {1..20}; do
  [[ -S "$sandbox/cache/nvim.sock" ]] && break
  sleep 0.05
done
if "$repo_dir/bin/quick-notes" 2>/dev/null; then
  fail "date refresh accepted a note without Quick Capture"
fi
assert_equal "$(<"$sandbox/cache/current-date")" 1900-01-01
print $'# Today\n\n## Quick Capture\n- ' > "$TEST_NOTE_PATH"
"$repo_dir/bin/quick-notes"
assert_equal "$(<"$sandbox/cache/current-date")" "$(date +%F)"
kill "$socket_pid" 2>/dev/null || true
wait "$socket_pid" 2>/dev/null || true

# Concurrent actions start only one Kitty process.
rm -f "$TEST_POPUP" "$sandbox/cache/current-date" "$sandbox/cache/nvim.sock"
print 42 > "$TEST_FOCUS"
print J > "$TEST_WORKSPACE"
: > "$TEST_KITTY_CALLS"
export TEST_KITTY_DELAY=0.2
"$repo_dir/bin/quick-notes" &
first_action=$!
sleep 0.02
"$repo_dir/bin/quick-notes" &
second_action=$!
wait "$first_action"
wait "$second_action"
assert_equal "$(wc -l < "$TEST_KITTY_CALLS" | tr -d ' ')" 1

# The kernel lock becomes available after an abrupt process exit.
abrupt_lock="$sandbox/abrupt.lock"
/usr/bin/lockf -k "$abrupt_lock" sleep 10 &
lock_process=$!
sleep 0.05
kill -KILL "$lock_process"
wait "$lock_process" 2>/dev/null || true
/usr/bin/lockf -k -s -t 0 "$abrupt_lock" true \
  || fail "lock remained active after process death"

print 'PASS: quick-notes'
