# Environment: claude-box

You are running inside an isolated Kubernetes pod, as user `node` (uid 1000), with permissions bypassed.

- Working directory: `/work` (persistent). Home: `/home/node` (persistent). `/tmp` is scratch and is wiped on restart.
- Everything else on the filesystem is part of the image. It is read-only in the default mode, and in sudo mode
  your changes there are lost on restart.
- Network: outbound HTTPS (443) to the public internet only. No LAN, no cluster services, no plain HTTP, no ping.

## Preinstalled
bash, tmux, git, gh, curl, wget, jq, yq, ripgrep (rg), fd, fzf, bat, tree, vim, nano,
gcc/g++/make/cmake/autotools, python3 + pip + venv + pipx + uv, node 24 + npm,
zip/unzip/7z/xz/zstd, file, xxd, binutils (objdump, readelf, strings, nm), gdb, strace, lsof,
sqlite3, shellcheck, htop.

## Installing more tools (no root needed, persists across restarts)
- Python CLI: `uv tool install <pkg>` or `pipx install <pkg>`. Python lib: `pip install --user <pkg>` (goes to ~/.local),
  or a project venv: `uv venv && uv pip install ...`
- Node CLI: `npm install -g <pkg>` (prefix is ~/.local)
- Rust: `curl -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path`, then `cargo install <crate>`
- Go: download a release tarball into ~/.local/go, then `go install ...`
- Prebuilt binaries: put them in `~/.local/bin` (already on PATH)
- System packages (`sudo apt-get install`) work only if the pod runs in sudo mode, and they don't survive a restart.
  Prefer the user-space options above. Tell the user which apt packages should be added to the image permanently.
