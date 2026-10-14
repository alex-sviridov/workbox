# Environment: workbox

You are running inside an isolated Kubernetes pod, as user `node` (uid 1000), with permissions bypassed.

- Working directory: `/work` (persistent). Home: `/home/node` (persistent). `/tmp` is scratch and is wiped on restart.
- Everything else on the filesystem is read-only. There is no root and no sudo; apt is unavailable.
- Network: outbound HTTPS (443) to the public internet only. No LAN, no cluster services, no plain HTTP, no ping.

## Reverse engineering: REA + Ghidra
- The `rea` MCP server is registered, with the `reverse-engineer-anything` skill. Use them for binary analysis.
  The same features are available from the shell as `rea <command>` (see `rea --help`).
- The deep-analysis provider is Ghidra 12.1.4 (headless, read-only, one ephemeral project per session).
  It handles native Windows PE (.exe/.dll, x86 and x86-64), ELF, Mach-O and more.
- .NET assemblies: use REA's managed-code tools (`inspect-managed-*`). They read metadata and CIL without Ghidra.
- Samples live in `/work/samples`. Always pass absolute paths.
- The first Ghidra query on a binary runs a full import and auto-analysis. It can take minutes on large files,
  so it is not hung. Later queries in the same session are fast.
- Analysis is static only. There is no Wine and no Windows, so never try to run the target binaries.
- Readiness check: `rea doctor --format json`. Startup logs: `~/rea-setup.log`, `~/rea-doctor.json`.

## Preinstalled
bash, tmux, git, gh, curl, wget, jq, yq, ripgrep (rg), fd, fzf, bat, tree, vim, nano,
gcc/g++/make/cmake/autotools, python3 + pip + venv + pipx + uv, node 24 + npm, JDK 21,
zip/unzip/7z/xz/zstd, file, xxd, binutils (objdump, readelf, strings, nm), gdb, strace, lsof,
sqlite3, shellcheck, htop.

## Installing more tools (no root needed, persists across restarts)
- Python CLI: `uv tool install <pkg>` or `pipx install <pkg>`. Python lib: `pip install --user <pkg>` (goes to ~/.local),
  or a project venv: `uv venv && uv pip install ...`
- Node CLI: `npm install -g <pkg>` (prefix is ~/.local)
- Rust: `curl -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path`, then `cargo install <crate>`
- Go: download a release tarball into ~/.local/go, then `go install ...`
- Prebuilt binaries: put them in `~/.local/bin` (already on PATH)
- If a tool can only be installed via apt, tell the user which package to add to the image's Dockerfile.
