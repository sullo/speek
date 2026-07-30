#!/usr/bin/env bash
#
# install.sh - symlink speek.sh onto your PATH as `speek`.
#
# Usage:
#   ./install.sh              # installs to ~/.local/bin
#   PREFIX=/usr/local/bin ./install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local/bin}"

mkdir -p "${PREFIX}"
ln -sf "${SCRIPT_DIR}/speek.sh" "${PREFIX}/speek"
chmod +x "${SCRIPT_DIR}/speek.sh"

echo "installed: ${PREFIX}/speek -> ${SCRIPT_DIR}/speek.sh"

case ":${PATH}:" in
    *":${PREFIX}:"*)
        echo "you're all set — run 'speek' from anywhere"
        ;;
    *)
        echo
        echo "note: ${PREFIX} is not on your PATH. Add this to your ~/.zshrc or ~/.bashrc:"
        echo
        echo "    export PATH=\"${PREFIX}:\$PATH\""
        echo
        echo "then restart your shell (or 'source' the rc file)."
        ;;
esac
