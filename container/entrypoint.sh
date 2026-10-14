#!/usr/bin/env bash
# 1. Registers REA with Claude Code and installs its skill (idempotent, runs every start so an
#    upgraded image re-pins the registration and refreshes the skill).
# 2. Starts a detached tmux session "claude" running Claude Code in bypass-permissions mode,
#    then keeps PID 1 alive for as long as that session exists.
set -euo pipefail

SESSION=claude
mkdir -p /work/samples "$HOME/.local/bin" "$HOME/.local/share" "$HOME/.claude"

# First run on a fresh home volume: give bash a sane prompt + completion.
if [[ ! -f "$HOME/.bashrc" ]]; then
  cat >"$HOME/.bashrc" <<'EOF'
[ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
PS1='\[\e[32m\]workbox\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ '
alias ll='ls -alF'
EOF
fi

# REA: MCP registration in ~/.claude.json + skill in ~/.claude/skills/reverse-engineer-anything.
# Non-fatal: if it fails, Claude Code still starts; check ~/rea-setup.log.
[[ -f "$HOME/.claude.json" ]] || echo '{}' >"$HOME/.claude.json"
if rea setup --yes --client claude_code --format json >"$HOME/rea-setup.log" 2>&1; then
  echo "[rea] setup ok ($(rea --version))"
else
  echo "[rea] WARNING: setup failed, see ~/rea-setup.log"
fi
if rea doctor --format json >"$HOME/rea-doctor.json" 2>&1 \
   && jq -e '.providerInspections[] | select(.id=="ghidra") | .available' "$HOME/rea-doctor.json" >/dev/null; then
  echo "[rea] Ghidra provider ready"
else
  echo "[rea] WARNING: Ghidra provider not ready, see ~/rea-doctor.json"
fi

tmux new-session -d -s "$SESSION" -x 220 -y 50 /usr/local/bin/claude-loop.sh

echo "tmux session '$SESSION' started. Attach with:"
echo "  kubectl -n workbox exec -it deploy/workbox -- tmux attach -t $SESSION"

while tmux has-session -t "$SESSION" 2>/dev/null; do sleep 5; done
echo "tmux session ended"
exit 1
