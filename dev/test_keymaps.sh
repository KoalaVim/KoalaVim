#!/bin/sh
#
# Runs the keymap invariant test (dev/test_keymaps.lua) in both flavors through `kv`, the same way the pre-commit hook
# does: the env name is derived from the checkout path (~/.local/share/kvim-envs/<env>/lazy/KoalaVim).
#
# Usage: dev/test_keymaps.sh [koala] [lazyvim]    (default: both)
# Env:   KM_TEST_ENV=<env>     override the derived env name
#        KV=<path>             the kv binary (default: kv)
#        KM_TEST_LENIENT=1     an installed server that doesn't attach is a warning
#        KM_TEST_TIMEOUT=<s>   per flavor run (default: 900)

set -u

DEV_DIR="$(cd "$(dirname "$0")" && pwd)"
KV_ENV="${KM_TEST_ENV:-$(basename "$(dirname "$(dirname "$(dirname "$DEV_DIR")")")")}"
# **TMP FIX** Windows kv uses "<env>-data" directory names
case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) KV_ENV="${KV_ENV%-data}" ;; esac
KV="${KV:-kv}"
TIMEOUT="${KM_TEST_TIMEOUT:-900}"

if [ "$#" -gt 0 ]; then
	FLAVORS="$*"
else
	FLAVORS="koala lazyvim"
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/kvim-keymaps-test.XXXXXX")" || exit 1
WORK_NAME="$(basename "$WORK")"

cleanup() {
	rm -rf "$WORK"
	# Files that were named after the temp cwd: sessions (`KOALA_NO_SESSION=1` prevents them, this is the safety net)
	# and the per-file logs of language servers (e.g. lua-language-server's `libexec/log`)
	for base in "$HOME/.local/share/kvim-envs" "$HOME/.local/state/kvim-envs" "$HOME/.cache/kvim-envs"; do
		[ -d "$base" ] && find "$base" -maxdepth 8 \( -name lazy -o -name lazy-rocks -o -name site -o -name snacks \) -prune \
			-o -name "*${WORK_NAME}*" -exec rm -rf {} + 2>/dev/null
	done
}
trap cleanup EXIT
trap 'exit 130' INT TERM

status=0
for flavor in $FLAVORS; do
	case "$flavor" in
	koala) conf='{}' ;;
	lazyvim) conf='{"flavor":"lazyvim"}' ;;
	*)
		echo "test-keymaps: unknown flavor '$flavor'" >&2
		exit 2
		;;
	esac

	# A user conf of our own, so ~/.kvim.conf doesn't affect the run
	run_dir="$WORK/$flavor"
	mkdir -p "$run_dir"
	printf '%s\n' "$conf" >"$run_dir/kvim.conf"
	out="$run_dir/report.txt"
	log="$run_dir/nvim.log"

	echo "== test-keymaps: env=$KV_ENV flavor=$flavor =="

	# KOALA_NO_SESSION: no session is saved for the temp cwd on exit
	(
		cd "$run_dir" || exit 1
		env -u KOALA_MODE -u KOALA_ARGS -u KOALA_NO_SESSION -u KOALA_RESTART -u KOALA_ENV -u KOALA_KVIM_CONF \
			-u KV_ENV -u NVIM -u NVIM_APPNAME -u NVIM_LISTEN_ADDRESS -u MYVIMRC \
			KOALA_NO_SESSION=1 \
			KM_TEST_DIR="$run_dir" KM_TEST_OUT="$out" KM_TEST_FLAVOR="$flavor" \
			"$KV" --env "$KV_ENV" --cfg "$run_dir/kvim.conf" -- --headless "+luafile $DEV_DIR/test_keymaps.lua" \
			>"$log" 2>&1 &
		pid=$!
		i=0
		while kill -0 "$pid" 2>/dev/null; do
			if [ "$i" -ge "$TIMEOUT" ]; then
				pkill -P "$pid" 2>/dev/null
				kill "$pid" 2>/dev/null
				echo "test-keymaps: timed out after ${TIMEOUT}s" >&2
				break
			fi
			sleep 1
			i=$((i + 1))
		done
		wait "$pid" 2>/dev/null
	)

	if [ -f "$out" ] && [ "$(tail -n 1 "$out")" = "RESULT: PASS" ]; then
		cat "$out"
	else
		status=1
		if [ -f "$out" ]; then
			cat "$out"
		else
			echo "FAIL: no report was written (nvim crashed or timed out), output:"
		fi
		sed 's/^/  | /' "$log" | tail -n 40
	fi
	echo
done

if [ "$status" -eq 0 ]; then
	echo "test-keymaps: PASS ($FLAVORS)"
else
	echo "test-keymaps: FAIL" >&2
fi
exit "$status"
