#!/usr/bin/env bash
#
# speek.sh - peek at the last N lines of every GNU screen session
# without attaching to it. Uses `screen -X hardcopy` to snapshot each
# session's scrollback buffer to a temp file, then tails it.
#
# Usage:
#   ./speek.sh [lines]
#   ./speek.sh 50
#
# Notes:
#   - "lines" defaults to 20.
#   - Sessions owned by the current user are attempted even if dead;
#     screen's own hardcopy call fails for those and is reported as such.
#   - hardcopy captures the scrollback buffer size configured for that
#     session (see `scrollback` / `defscrollback` in screen), so very
#     old output may not be available if the buffer is small.

set -euo pipefail

# Screen's scrollback can contain raw bytes from a program's alternate
# charset / line-drawing output that aren't valid UTF-8. Force a
# byte-clean locale so sed/tail don't choke on "illegal byte sequence".
export LC_ALL=C

LINES="${1:-20}"

if ! [[ "${LINES}" =~ ^[0-9]+$ ]]; then
    echo "error: lines must be a non-negative integer, got '${LINES}'" >&2
    exit 1
fi

if ! command -v screen >/dev/null 2>&1; then
    echo "error: screen is not installed" >&2
    exit 1
fi

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/speek.XXXXXX")"
trap 'rm -rf "$WORKDIR"' EXIT

# Parse `screen -ls` output for session names (e.g. "86133.ttys006.ranger3").
# screen -ls exits 1 when sessions exist (non-zero is its "normal" status),
# so don't let `set -e` kill us on that. Using a while-read loop (not
# mapfile) for compatibility with the ancient bash 3.2 shipped on macOS.
sessions=()
while IFS= read -r line; do
    sessions+=("$line")
done < <(screen -ls 2>/dev/null | awk -F'[[:space:]]+' '/^[[:space:]]*[0-9]+\./{print $2}')

if [ "${#sessions[@]}" -eq 0 ]; then
    echo "no screen sessions found"
    exit 0
fi

for s in "${sessions[@]}"; do
    echo "===== ${s} ====="

    # Session names come from parsing `screen -ls` output; sanitize before
    # building a filesystem path from them so nothing but the safe
    # PID/name characters screen actually uses can influence the path.
    safe_name="${s//[^A-Za-z0-9._-]/_}"
    outfile="${WORKDIR}/${safe_name}.hardcopy"

    if ! screen -S "${s}" -X hardcopy -h "${outfile}" 2>/dev/null; then
        echo "(could not capture: session busy, dead, or needs multiuser access)"
        echo
        continue
    fi

    # give screen a beat to flush the file
    for _ in 1 2 3 4 5; do
        [ -s "${outfile}" ] && break
        sleep 0.1
    done

    if [ -s "${outfile}" ]; then
        # hardcopy pads unused rows with blank lines at both ends of the
        # buffer; strip those so `tail` lands on real content.
        awk '{l[NR]=$0} END{n=NR; while(n>0 && l[n] ~ /^[ \t]*$/) n--; for(i=1;i<=n;i++) print l[i]}' "${outfile}" \
            | sed -e '/./,$!d' \
            | tail -n "${LINES}"
    else
        echo "(empty or unreadable)"
    fi
    echo
done
