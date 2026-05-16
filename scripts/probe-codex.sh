#!/usr/bin/env bash
#
# probe-codex.sh — tmux harness for driving the Codex CLI through the
# elicitation schema probes and capturing what its UI renders.
#
# This script is Codex-specific on purpose: its interaction model differs
# from Claude Code's, so each client gets its own script rather than one
# generic harness that has to branch on the client.
#
#   CODEX INTERACTION MODEL
#   -----------------------
#   1. A tool call first shows a *separate* approval prompt:
#          1. Allow   2. Allow for this session   3. Always allow   4. Cancel
#      Choose it with a digit + Enter. `approve` sends "1 Enter".
#   2. The elicitation form then renders ONE field at a time
#      ("Field 1/N"). A text field is answered by typing the value and
#      pressing Enter; Enter advances to the next field and submits after
#      the last one. `answer <text>` does type + Enter.
#   3. Enum and boolean fields render as a numbered list with the cursor on
#      option 1; Down moves the cursor and Enter selects + advances.
#      `pick <n>` selects the n-th option (1-based; boolean is 1=True 2=False).
#   4. Integer, number, and multi-enum fields do NOT render an editable form
#      in Codex — the call returns immediately with empty content. There is
#      nothing to drive for those.
#
# Usage:
#   scripts/probe-codex.sh start             Launch Codex in tmux
#   scripts/probe-codex.sh send <text...>    Type a prompt + Enter
#   scripts/probe-codex.sh approve           Choose "Allow" on a tool prompt
#   scripts/probe-codex.sh answer <text>     Type a text field value + Enter
#   scripts/probe-codex.sh pick <index>      Select the n-th enum/boolean option
#   scripts/probe-codex.sh keys <keys...>    Raw tmux send-keys passthrough
#   scripts/probe-codex.sh capture <label>   capture-pane -> captures/codex/<label>.txt
#   scripts/probe-codex.sh wait [seconds]    Sleep (defaults tuned for Codex)
#   scripts/probe-codex.sh stop              Kill the tmux session
#   scripts/probe-codex.sh status            Show session state
#
# Driving one probe:
#   scripts/probe-codex.sh start
#   scripts/probe-codex.sh wait boot
#   scripts/probe-codex.sh send 'Use the elicit-http server. Call its probe-01-text-only tool now. Nothing else.'
#   scripts/probe-codex.sh wait call
#   scripts/probe-codex.sh capture probe-01-approval
#   scripts/probe-codex.sh approve
#   scripts/probe-codex.sh wait form
#   scripts/probe-codex.sh capture probe-01-form
#   scripts/probe-codex.sh answer 'Jane Doe'
#   scripts/probe-codex.sh answer 'ok'
#   scripts/probe-codex.sh wait result
#   scripts/probe-codex.sh capture probe-01-result
#   scripts/probe-codex.sh stop

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SESSION="probe-codex"
CAPTURE_DIR="${ROOT}/captures/codex"

# Codex-tuned default waits (seconds). Named so callers say what they wait for.
WAIT_BOOT=13
WAIT_CALL=16
WAIT_FORM=6
WAIT_RESULT=6
WAIT_DEFAULT=3

die() { echo "error: $*" >&2; exit 1; }
session_exists() { tmux has-session -t "$SESSION" 2>/dev/null; }
require_session() {
    session_exists || die "no tmux session '$SESSION' — run: $0 start"
}

COMMAND="${1:-}"
shift 2>/dev/null || true

case "$COMMAND" in
    start)
        session_exists && die "session '$SESSION' already running — run: $0 stop"
        tmux new-session -d -s "$SESSION" -x 200 -y 50 -c "$ROOT"
        tmux send-keys -t "$SESSION" "codex" Enter
        echo "started '$SESSION' — give Codex time to boot ($0 wait boot)"
        ;;

    send)
        require_session
        [ "$#" -gt 0 ] || die "send needs prompt text"
        tmux send-keys -t "$SESSION" -l "$*"
        sleep 1
        tmux send-keys -t "$SESSION" Enter
        echo "sent prompt to '$SESSION'"
        ;;

    approve)
        require_session
        # Codex tool-approval prompt: option 1 is "Allow".
        tmux send-keys -t "$SESSION" "1"
        sleep 1
        tmux send-keys -t "$SESSION" Enter
        echo "approved tool call (Allow)"
        ;;

    answer)
        require_session
        [ "$#" -gt 0 ] || die "answer needs a value"
        # Codex text field: type the value, Enter submits + advances.
        tmux send-keys -t "$SESSION" -l "$*"
        sleep 1
        tmux send-keys -t "$SESSION" Enter
        echo "answered field: $*"
        ;;

    pick)
        require_session
        IDX="${1:-}"
        case "$IDX" in
            ''|*[!0-9]*) die "pick needs a positive 1-based option index" ;;
        esac
        [ "$IDX" -ge 1 ] || die "pick index must be >= 1"
        # Codex enum/boolean field: a numbered list with the cursor on
        # option 1. Down moves the cursor; Enter selects and advances.
        i=1
        while [ "$i" -lt "$IDX" ]; do
            tmux send-keys -t "$SESSION" Down
            sleep 1
            i=$((i + 1))
        done
        tmux send-keys -t "$SESSION" Enter
        echo "picked option $IDX"
        ;;

    keys)
        require_session
        [ "$#" -gt 0 ] || die "keys needs at least one key argument"
        tmux send-keys -t "$SESSION" "$@"
        echo "sent keys to '$SESSION': $*"
        ;;

    capture)
        require_session
        LABEL="${1:-capture}"
        mkdir -p "$CAPTURE_DIR"
        OUT="${CAPTURE_DIR}/${LABEL}.txt"
        # Trim the blank padding capture-pane adds below the last drawn line.
        tmux capture-pane -t "$SESSION" -p \
            | awk 'NF{last=NR} {line[NR]=$0} END{for(i=1;i<=last;i++) print line[i]}' \
            > "$OUT"
        echo "--- ${OUT} ---"
        cat "$OUT"
        ;;

    wait)
        case "${1:-}" in
            boot)   SECS=$WAIT_BOOT ;;
            call)   SECS=$WAIT_CALL ;;
            form)   SECS=$WAIT_FORM ;;
            result) SECS=$WAIT_RESULT ;;
            ''|*[!0-9]*) SECS=$WAIT_DEFAULT ;;
            *)      SECS="$1" ;;
        esac
        sleep "$SECS"
        echo "waited ${SECS}s"
        ;;

    stop)
        require_session
        tmux kill-session -t "$SESSION"
        echo "stopped '$SESSION'"
        ;;

    status)
        if session_exists; then
            echo "session '$SESSION' is running"
            tmux list-panes -t "$SESSION" -F '  pane #{pane_index}: #{pane_width}x#{pane_height}'
        else
            echo "session '$SESSION' is not running"
        fi
        ;;

    *)
        die "unknown command '${COMMAND:-}' — see header of $0 for usage"
        ;;
esac
