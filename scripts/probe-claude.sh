#!/usr/bin/env bash
#
# probe-claude.sh — tmux harness for driving Claude Code through the
# elicitation schema probes and capturing what its UI renders.
#
# This script is Claude-Code-specific on purpose: its interaction model
# differs from Codex's, so each client gets its own script rather than one
# generic harness that has to branch on the client.
#
#   CLAUDE CODE INTERACTION MODEL
#   -----------------------------
#   1. There is NO separate tool-approval prompt for the elicitation — the
#      form itself IS the interaction.
#   2. The elicitation form renders ALL fields at once in one panel, with a
#      `❯` cursor on the active row. Navigate rows with Up/Down.
#   3. A text field is answered by typing into it while focused (it then
#      shows a `✔`); `field <text>` types the value then presses Down to
#      move to the next row.
#   4. Below the last field is an `Accept   Decline` row. After answering
#      the last field, the cursor is already on that row — `accept` presses
#      Enter (on Accept). `decline` moves Right to Decline, then Enter.
#   5. Integer and number fields are plain typed fields — `field` handles
#      them (type the digits, move Down).
#   6. A boolean field is a checkbox; `toggle` presses Space then Down.
#   7. A single-enum field shows `▸ not set` ("→ to expand"). `pick <n>`
#      presses Right to expand the radio list, Down to the n-th option,
#      Space to select (which collapses it), then Down to the next field.
#   8. A multi-enum field shows a checkbox list. `check <total> <index...>`
#      presses Right to expand, Space-toggles the given 1-based options,
#      then walks past the last option to collapse onto the next field.
#
# Usage:
#   scripts/probe-claude.sh start             Launch Claude Code in tmux
#   scripts/probe-claude.sh send <text...>    Type a prompt + Enter
#   scripts/probe-claude.sh field <text>      Type a text/number field, move Down
#   scripts/probe-claude.sh toggle            Space-toggle a boolean, move Down
#   scripts/probe-claude.sh pick <index>      Select the n-th single-enum option
#   scripts/probe-claude.sh check <total> <index...>  Toggle multi-enum options
#   scripts/probe-claude.sh accept            Press Enter on the Accept row
#   scripts/probe-claude.sh decline           Move to Decline, press Enter
#   scripts/probe-claude.sh keys <keys...>    Raw tmux send-keys passthrough
#   scripts/probe-claude.sh capture <label>   capture-pane -> captures/claude/<label>.txt
#   scripts/probe-claude.sh wait [seconds]    Sleep (defaults tuned for Claude Code)
#   scripts/probe-claude.sh stop              Kill the tmux session
#   scripts/probe-claude.sh status            Show session state
#
# Driving one probe:
#   scripts/probe-claude.sh start
#   scripts/probe-claude.sh wait boot
#   scripts/probe-claude.sh send 'Use the elicit-http MCP server. Call its probe-01-text-only tool now. Nothing else.'
#   scripts/probe-claude.sh wait call
#   scripts/probe-claude.sh capture probe-01-form
#   scripts/probe-claude.sh field 'Jane Doe'
#   scripts/probe-claude.sh field 'ok'
#   scripts/probe-claude.sh accept
#   scripts/probe-claude.sh wait result
#   scripts/probe-claude.sh capture probe-01-result
#   scripts/probe-claude.sh stop

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SESSION="probe-claude"
CAPTURE_DIR="${ROOT}/captures/claude"

# Claude-Code-tuned default waits (seconds). Claude often "thinks" before the
# tool call lands, so the call wait is longer than Codex's.
WAIT_BOOT=14
WAIT_CALL=24
WAIT_RESULT=8
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
        tmux send-keys -t "$SESSION" "claude" Enter
        echo "started '$SESSION' — give Claude Code time to boot ($0 wait boot)"
        ;;

    send)
        require_session
        [ "$#" -gt 0 ] || die "send needs prompt text"
        tmux send-keys -t "$SESSION" -l "$*"
        sleep 1
        tmux send-keys -t "$SESSION" Enter
        echo "sent prompt to '$SESSION'"
        ;;

    field)
        require_session
        [ "$#" -gt 0 ] || die "field needs a value"
        # Claude text field: type into the focused row, then Down to the next.
        tmux send-keys -t "$SESSION" -l "$*"
        sleep 1
        tmux send-keys -t "$SESSION" Down
        echo "filled field, moved down: $*"
        ;;

    accept)
        require_session
        # After the last `field`, the cursor sits on the Accept/Decline row.
        tmux send-keys -t "$SESSION" Enter
        echo "pressed Accept"
        ;;

    decline)
        require_session
        # Accept is leftmost on the row; Right moves to Decline.
        tmux send-keys -t "$SESSION" Right
        sleep 1
        tmux send-keys -t "$SESSION" Enter
        echo "pressed Decline"
        ;;

    toggle)
        require_session
        # Claude boolean field: Space toggles the checkbox, Down to next field.
        tmux send-keys -t "$SESSION" Space
        sleep 1
        tmux send-keys -t "$SESSION" Down
        echo "toggled boolean, moved down"
        ;;

    pick)
        require_session
        IDX="${1:-}"
        case "$IDX" in
            ''|*[!0-9]*) die "pick needs a positive 1-based option index" ;;
        esac
        [ "$IDX" -ge 1 ] || die "pick index must be >= 1"
        # Claude single-enum: Right expands the radio list (cursor on option
        # 1), Down moves, Space selects + collapses, Down to the next field.
        tmux send-keys -t "$SESSION" Right
        sleep 1
        i=1
        while [ "$i" -lt "$IDX" ]; do
            tmux send-keys -t "$SESSION" Down
            sleep 1
            i=$((i + 1))
        done
        tmux send-keys -t "$SESSION" Space
        sleep 1
        tmux send-keys -t "$SESSION" Down
        echo "picked option $IDX, moved down"
        ;;

    check)
        require_session
        TOTAL="${1:-}"
        case "$TOTAL" in
            ''|*[!0-9]*) die "check needs <total-options> <index...>" ;;
        esac
        shift
        [ "$#" -gt 0 ] || die "check needs at least one option index"
        # Claude multi-enum: Right expands the checkbox list (cursor on option
        # 1). Space toggles each wanted option; the list stays expanded. After
        # toggling, walk to the last option and press Down once more — that
        # collapses the list and moves to the next field.
        tmux send-keys -t "$SESSION" Right
        sleep 1
        cur=1
        for idx in $(printf '%s\n' "$@" | sort -n); do
            case "$idx" in
                ''|*[!0-9]*) die "check option index must be a positive integer" ;;
            esac
            [ "$idx" -le "$TOTAL" ] || die "check index $idx exceeds total $TOTAL"
            while [ "$cur" -lt "$idx" ]; do
                tmux send-keys -t "$SESSION" Down
                sleep 1
                cur=$((cur + 1))
            done
            tmux send-keys -t "$SESSION" Space
            sleep 1
        done
        while [ "$cur" -lt "$TOTAL" ]; do
            tmux send-keys -t "$SESSION" Down
            sleep 1
            cur=$((cur + 1))
        done
        tmux send-keys -t "$SESSION" Down
        echo "checked options [$*] of $TOTAL, moved down"
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
