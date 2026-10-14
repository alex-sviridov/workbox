#!/usr/bin/env bash
# Runs inside the tmux session. Keeps Claude Code running; offers a shell between runs.
cd /work || exit 1
while true; do
  # shellcheck disable=SC2086  # CLAUDE_EXTRA_ARGS is intentionally word-split
  claude --dangerously-skip-permissions ${CLAUDE_EXTRA_ARGS:-}
  echo
  echo "[claude exited] Enter = restart now, s = bash shell (exit it to restart). Auto-restart in 10s."
  ans=""
  read -r -t 10 ans || true
  if [[ "$ans" == "s" ]]; then bash -l; fi
done
