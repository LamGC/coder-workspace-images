ARG BASE=ubuntu-base:latest
FROM ${BASE}

USER root

ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH="${DOTNET_ROOT}:${PATH}"
ENV DOTNET_NOLOGO=true
ENV DOTNET_CLI_TELEMETRY_OPTOUT=true

RUN curl -sSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
    && chmod +x /tmp/dotnet-install.sh \
    && /tmp/dotnet-install.sh --channel 8.0 --install-dir "${DOTNET_ROOT}" \
    && /tmp/dotnet-install.sh --channel 10.0 --install-dir "${DOTNET_ROOT}" \
    && ln -sf "${DOTNET_ROOT}/dotnet" /usr/local/bin/dotnet \
    && rm /tmp/dotnet-install.sh

USER vscode
