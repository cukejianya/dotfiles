# Shared helpers for the blast-off scripts. Source this file; do not run it.
# ~/.dotfiles-work/install.sh has a copy, because it runs before this repo
# exists. Keep the two in sync.
#
# Every script in one run writes to the same two files in
# ${XDG_STATE_HOME:-~/.local/state}/blast-off/:
#   <time>.log          everything shown on screen
#   <time>.errors.log   one entry for each failed step, with the end of the log
# latest.log and latest.errors.log point to the newest run.
#
# A failed step does not stop the run, except through die. Use die only when
# the steps after it cannot work.

failures=()

# Start the logs, then run this script again under `script`, which records
# everything and keeps a terminal for prompts (gh, sudo, installers). Does
# nothing if a parent script started the logs. Call it before any other step.
blast_off_log_start() {
  if [[ -n "${BLAST_OFF_LOG:-}" ]]; then
    if [[ "${BLAST_OFF_TOP:-}" == pending ]]; then
      BLAST_OFF_IS_TOP=1
      export BLAST_OFF_TOP=done
    fi
    return 0
  fi
  local dir stamp
  dir="${XDG_STATE_HOME:-$HOME/.local/state}/blast-off"
  stamp=$(date +%Y%m%d-%H%M%S)
  mkdir -p "$dir"
  export BLAST_OFF_LOG="$dir/$stamp.log"
  export BLAST_OFF_ERRORS="$dir/$stamp.errors.log"
  export BLAST_OFF_TOP=pending
  : > "$BLAST_OFF_ERRORS"
  ln -sfn "$BLAST_OFF_LOG" "$dir/latest.log"
  ln -sfn "$BLAST_OFF_ERRORS" "$dir/latest.errors.log"
  # -t 0 writes the log at once, so an error entry includes the latest output.
  if [[ "$(uname -s)" == Darwin ]]; then
    exec script -q -t 0 -a "$BLAST_OFF_LOG" "$BASH" "$0" "$@"
  else
    exec script -q -f -a -c "$(printf '%q ' "$BASH" "$0" "$@")" "$BLAST_OFF_LOG"
  fi
}

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

# Record a failure: on screen, and in the errors log with the end of the log.
record_failure() {
  local desc="$1" rc="${2:-1}"
  failures+=("$desc (exit $rc)")
  printf '\033[1;31mFAILED: %s (exit %s)\033[0m\n' "$desc" "$rc" >&2
  [[ -n "${BLAST_OFF_ERRORS:-}" ]] || return 0
  {
    printf '=== FAILED: %s (exit %s) in %s at %s\n' "$desc" "$rc" "${0##*/}" "$(date '+%F %T')"
    printf -- '--- last lines of %s:\n' "$BLAST_OFF_LOG"
    tail -n 60 "$BLAST_OFF_LOG" 2>/dev/null | perl -pe 's/\e\[[0-9;?]*[A-Za-z]//g; s/\r//g'
    echo
  } >> "$BLAST_OFF_ERRORS"
}

# run <description> <command...>: run a command or function in a subshell with
# set -e. On failure, record it and continue. Changes to variables, PATH, or
# the current directory do not reach the caller, so do those outside run.
run() {
  local desc="$1" rc before after
  shift
  before=$(failure_count)
  set +e
  ( set -e; "$@" )
  rc=$?
  set -e
  if (( rc != 0 )); then
    after=$(failure_count)
    if (( after > before )); then
      # A child script already recorded its failures. Count this step, but do
      # not repeat them in the errors log.
      failures+=("$desc (exit $rc)")
      printf '\033[1;31mFAILED: %s (failures listed above)\033[0m\n' "$desc" >&2
    else
      record_failure "$desc" "$rc"
    fi
  fi
  return 0
}

# Number of failures recorded in the errors log so far, by any script.
failure_count() {
  if [[ -n "${BLAST_OFF_ERRORS:-}" && -f "$BLAST_OFF_ERRORS" ]]; then
    grep -c '^=== FAILED' "$BLAST_OFF_ERRORS" || true
  else
    echo 0
  fi
}

# die <reason>: record the failure and stop, because later steps cannot work.
die() {
  record_failure "$1 (cannot continue)" 1
  finish
}

# finish: if this script started the run, list every failure of the run with
# the log paths. Exit 1 if this script, or a script it ran, failed.
finish() {
  local all=""
  [[ -n "${BLAST_OFF_ERRORS:-}" ]] && all=$(grep '^=== FAILED' "$BLAST_OFF_ERRORS" 2>/dev/null || true)
  if [[ -n "${BLAST_OFF_IS_TOP:-}" ]]; then
    echo
    if [[ -n "$all" ]]; then
      echo "Setup finished with failures:"
      printf '%s\n' "$all" | sed 's/^=== FAILED: /  - /'
      echo "Errors: $BLAST_OFF_ERRORS"
    fi
    echo "Full log: $BLAST_OFF_LOG"
  fi
  if (( ${#failures[@]} > 0 )); then
    exit 1
  fi
  exit 0
}
