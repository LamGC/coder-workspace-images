FROM mcr.microsoft.com/devcontainers/base:ubuntu

USER root

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    build-essential \
    clang \
    cmake \
    gdb \
    strace \
    tcpdump \
    iproute2 \
    jq \
    fzf \
    zip \
    unzip \
    curl \
    ca-certificates \
    tmux \
    dnsutils \
    netcat-openbsd \
    httpie \
    git \
    git-lfs \
    lsof \
    libssl-dev \
    pkg-config \
    htop \
    valgrind \
    linux-tools-generic \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN install -m 0755 -d /etc/apt/keyrings\
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "Types: deb\nURIs: https://download.docker.com/linux/ubuntu\nSuites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")\nComponents: stable\nSigned-By: /etc/apt/keyrings/docker.asc" > /etc/apt/sources.list.d/docker.sources \
    && apt update \
    && apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Give the existing passwordless-sudo workspace user native su/su - access to
# root, without setting/unlocking root's password or trusting other users.
# Keep the distro's account/session checks and non-root-target authentication.
RUN groupadd --system workspace-su \
    && usermod --append --groups workspace-su vscode \
    && test "$(grep -Ec '^auth[[:space:]]+sufficient[[:space:]]+pam_rootok[.]so[[:space:]]*$' /etc/pam.d/su)" = 1 \
    && sed -i -E '/^auth[[:space:]]+sufficient[[:space:]]+pam_rootok[.]so[[:space:]]*$/a auth sufficient pam_wheel.so trust use_uid root_only group=workspace-su' /etc/pam.d/su

# Overlay repository-managed home defaults before capturing the workspace skeleton.
COPY --chown=vscode:vscode skel/ /home/vscode/
RUN chmod 0700 /home/vscode/.ssh \
    && chmod 0644 /home/vscode/.ssh/known_hosts

# Snapshot the image home directory before any volume mount can shadow it.
# /etc/workspace-skel is restored into $HOME by entrypoint.sh on first start.
RUN cp -rT /home/vscode /etc/workspace-skel \
    && chmod -R a+rX /etc/workspace-skel

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER vscode

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
