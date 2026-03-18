#!/bin/sh
set -eu

file="${1:-}"
line="${2:-1}"
col="${3:-1}"

if [ -z "$file" ]; then
	echo "Usage: lazygit-edit.sh <file> [line] [col]" >&2
	exit 1
fi

nvr_bin="${NVR_BIN:-}"
if [ -z "$nvr_bin" ]; then
	nvr_bin="$(command -v nvr 2>/dev/null || true)"
fi
if [ -z "$nvr_bin" ]; then
	echo "lazygit-edit: 'nvr' not found in PATH" >&2
	exit 1
fi

server="${NVIM:-${NVIM_LISTEN_ADDRESS:-}}"
if [ -z "$server" ]; then
	server="$($nvr_bin --serverlist 2>/dev/null | head -n1 || true)"
fi
if [ -z "$server" ]; then
	echo "lazygit-edit: could not determine Neovim server address" >&2
	exit 1
fi

cmd="call cursor(${line}, ${col})"

"$nvr_bin" --servername "$server" --nostart --remote-send '<C-\><C-n>'
"$nvr_bin" --servername "$server" --nostart --remote-tab-wait +"${cmd}" "$file"
