# workbox: isolated, always-running Claude Code (bypass-permissions mode) with a full toolbox.
#
#   docker build --platform linux/amd64 -t workbox:2 .
#   docker build --platform linux/amd64 --build-arg WITH_SUDO=true -t workbox:2-sudo .
#
# Base: the full (non-slim) node image = Debian trixie "buildpack-deps" with gcc, make, git, curl,
# python3 and the usual dev headers already present.
FROM node:24-trixie

ARG CLAUDE_CODE_VERSION=2.1.296
ARG WITH_SUDO=false
ENV DEBIAN_FRONTEND=noninteractive

# apt over HTTPS: the pod's egress policy only allows port 443.
RUN sed -i 's|http://|https://|g' /etc/apt/sources.list.d/debian.sources

RUN apt-get update && apt-get install -y --no-install-recommends \
      # shell & session
      bash-completion tmux tini sudo less man-db \
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
      # binaries & debugging
      file xxd binutils gdb strace lsof \
      # system & misc
      procps psmisc htop sqlite3 shellcheck locales \
 && rm -rf /var/lib/apt/lists/* \
 # Debian names some tools differently
 && ln -s /usr/bin/batcat /usr/local/bin/bat \
 && ln -s /usr/bin/fdfind /usr/local/bin/fd

# uv (fast Python package/env manager) system-wide
RUN pip install --break-system-packages --no-cache-dir uv

RUN npm install --global --no-fund --no-audit "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
 && npm cache clean --force

# Optional passwordless sudo for the "node" user (only effective with the sudo pod settings).
RUN if [ "$WITH_SUDO" = "true" ]; then \
      echo 'node ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/node && chmod 0440 /etc/sudoers.d/node; \
    fi

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

# Claude Code refuses --dangerously-skip-permissions as root, so run as the image's "node" user.
USER 1000:1000
WORKDIR /work

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]