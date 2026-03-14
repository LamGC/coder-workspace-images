ARG BASE=ubuntu-base:latest
FROM ${BASE}

USER root

ENV GOROOT=/usr/local/go
ENV GOPATH=/home/vscode/go
ENV PATH="${GOROOT}/bin:${GOPATH}/bin:${PATH}"

RUN GO_VERSION=$(curl -fsSL https://go.dev/VERSION?m=text | head -1 | sed 's/go//') \
    && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz

USER vscode
