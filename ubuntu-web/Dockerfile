ARG BASE=ubuntu-base:latest
FROM ${BASE}

USER root

# Install Node.js LTS via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install global package managers
RUN npm install -g yarn pnpm

USER vscode
