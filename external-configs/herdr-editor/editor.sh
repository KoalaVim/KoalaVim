#!/usr/bin/env bash
set -euo pipefail

finish() {
	trap - EXIT HUP INT TERM
	vim_quote() {
		local value=$1
		value=${value//\'/\'\'}
		printf "'%s'" "$value"
	}
	local expr="v:lua.require('KoalaVim.utils.ai.mux_editor').finish($(vim_quote "$KOALA_EDITOR_PIPE"), $(vim_quote "$KOALA_EDITOR_AGENT"), $(vim_quote "${HERDR_PANE_ID:-}"), $(vim_quote "$KOALA_EDITOR_RESTORE_ZOOM"), $(vim_quote "$KOALA_EDITOR_FLOATING"))"
	if "$KOALA_EDITOR_NVIM" --server "$KOALA_EDITOR_HOST" --remote-expr "$expr" >/dev/null 2>&1; then
		return
	fi
	# The original editor proxy is waiting on this FIFO. Never block Herdr's
	# process teardown if the host or reader has disappeared.
	if [[ -p "$KOALA_EDITOR_PIPE" ]]; then
		(printf 'done\n' > "$KOALA_EDITOR_PIPE") &
	fi
	if [[ "$KOALA_EDITOR_RESTORE_ZOOM" == 1 ]]; then
		"$KOALA_EDITOR_HERDR" pane zoom "$KOALA_EDITOR_AGENT" --on >/dev/null 2>&1 || true
	else
		"$KOALA_EDITOR_HERDR" agent focus "$KOALA_EDITOR_AGENT" >/dev/null 2>&1 || true
	fi
}
trap finish EXIT
trap 'exit 1' HUP INT TERM

# Start an independent editor, not a child attached to the host's RPC server.
unset NVIM NVIM_LISTEN_ADDRESS NVIM_LOG_FILE KOALA_MODE KOALA_ARGS KOALA_RESTART
"$KOALA_EDITOR_NVIM" -u "$KOALA_EDITOR_CONFIG" -i NONE -n \
	--cmd 'lua vim.g.koala_mux_editor = true' \
	-c 'lua dofile(vim.env.KOALA_EDITOR_INIT)' -- "$KOALA_EDITOR_FILE"
