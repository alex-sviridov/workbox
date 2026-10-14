#!/usr/bin/env bash
# Starts a detached tmux session "claude" running Claude Code in bypass-permissions mode,
# then keeps PID 1 alive for as long as that session exists.
set -euo pipefail

SESSION=claude
mkdir -p /work

tmux new-session -d -s "$SESSION" -x 220 -y 50 /usr/local/bin/claude-loop.sh

echo "tmux session '$SESSION' started. Attach with:"
echo "  kubectl -n claude exec -it deploy/claude -- tmux attach -t $SESSION"

while tmux has-session -t "$SESSION" 2>/dev/null; do sleep 5; done
echo "tmux session ended"
exit 1
