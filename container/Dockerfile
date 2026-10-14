# workbox: isolated, always-running Claude Code (bypass-permissions mode) with a full toolbox,
# plus REA + Ghidra for static reverse engineering of Windows executables.
#
#   docker build --platform linux/amd64 -t workbox:3 .
#
# Base: the full (non-slim) node image = Debian trixie "buildpack-deps" with gcc, make, git, curl,
# python3 and the usual dev headers already present.
FROM node:24-trixie

ARG CLAUDE_CODE_VERSION=2.1.296
ARG REA_VERSION=6.5.0
# REA's Ghidra provider is verified with exactly Ghidra 12.1.4 + JDK 21.
ARG GHIDRA_VERSION=12.1.4
ARG GHIDRA_BUILD_DATE=20260921
ARG GHIDRA_SHA256=ddac49f903da9d5bac833e5cc79395098b9c33cfd3279be5f31bd00387d2d4db
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      # shell & session
      bash-completion tmux tini less man-db \
      # editors & viewers
      vim nano bat tree \
      # search & text
      ripgrep fd-find fzf jq yq gawk \
      # build
      build-essential cmake pkg-config autoconf automake libtool \
      # python
      python3-full python3-pip python3-venv pipx \
      # vcs & network clients
      git git-lfs gh openssh-client curl wget rsync netcat-openbsd dnsutils \
      # archives
      zip unzip 7zip xz-utils zstd bzip2 \
      # binaries & debugging (REA can also drive objdump and gdb)
      file xxd binutils gdb strace lsof \
      # system & misc (procps "ps" is required by REA's process supervisor)
      procps psmisc htop sqlite3 shellcheck locales \
      # Ghidra needs a full 64-bit JDK 21 (REA's doctor checks for javac)
      openjdk-21-jdk-headless \
 && rm -rf /var/lib/apt/lists/* \
 # Debian names some tools differently
 && ln -s /usr/bin/batcat /usr/local/bin/bat \
 && ln -s /usr/bin/fdfind /usr/local/bin/fd

# Ghidra (official release zip, checked against the SHA-256 published on the release page)
RUN set -eux; \
    curl -fsSL -o /tmp/ghidra.zip \
      "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${GHIDRA_VERSION}_build/ghidra_${GHIDRA_VERSION}_PUBLIC_${GHIDRA_BUILD_DATE}.zip"; \
    echo "${GHIDRA_SHA256}  /tmp/ghidra.zip" | sha256sum -c -; \
    unzip -q /tmp/ghidra.zip -d /opt; \
    rm /tmp/ghidra.zip; \
    test -x "/opt/ghidra_${GHIDRA_VERSION}_PUBLIC/support/analyzeHeadless"; \
    test -x "/opt/ghidra_${GHIDRA_VERSION}_PUBLIC/Ghidra/Features/Decompiler/os/linux_x86_64/decompile"

# uv (fast Python package/env manager) system-wide
RUN pip install --break-system-packages --no-cache-dir uv

# Claude Code + REA, pinned
RUN npm install --global --no-fund --no-audit \
      "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
      "rea-agents@${REA_VERSION}" \
 && npm cache clean --force

COPY --chmod=0644 tmux.conf /etc/tmux.conf
COPY --chmod=0644 CLAUDE.md /etc/claude-code/CLAUDE.md
COPY --chmod=0755 entrypoint.sh claude-loop.sh /usr/local/bin/

# Everything the agent installs without root goes under $HOME (a persistent volume).
ENV HOME=/home/node \
    LANG=C.UTF-8 \
    TERM=xterm-256color \
    TMUX_TMPDIR=/tmp \
    SHELL=/bin/bash \
    NPM_CONFIG_PREFIX=/home/node/.local \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    PIPX_HOME=/home/node/.local/share/pipx \
    PIPX_BIN_DIR=/home/node/.local/bin \
    UV_TOOL_BIN_DIR=/home/node/.local/bin \
    CARGO_HOME=/home/node/.cargo \
    RUSTUP_HOME=/home/node/.rustup \
    GOPATH=/home/node/go \
    PATH=/home/node/.local/bin:/home/node/.cargo/bin:/home/node/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    DISABLE_AUTOUPDATER=1 \
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

# REA + Ghidra
#  - REA_GHIDRA_STARTUP_TIMEOUT_MS: import + full auto-analysis deadline (REA default 330 s; big binaries need more)
#  - GHIDRA_HEADLESS_MAXMEM: Ghidra JVM heap (REA default 2G); keep well below the pod memory limit
#  - MCP_TOOL_TIMEOUT: how long Claude Code waits for one MCP tool call (the first Ghidra query is slow)
ENV GHIDRA_INSTALL_DIR=/opt/ghidra_${GHIDRA_VERSION}_PUBLIC \
    JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 \
    REA_ANALYSIS_PROVIDER=ghidra \
    REA_GHIDRA_STARTUP_TIMEOUT_MS=900000 \
    GHIDRA_HEADLESS_MAXMEM=1G \
    MCP_TOOL_TIMEOUT=1200000 \
    REA_VERSION=${REA_VERSION}

# Claude Code refuses --dangerously-skip-permissions as root, so run as the image's "node" user.
USER 1000:1000
WORKDIR /work

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
