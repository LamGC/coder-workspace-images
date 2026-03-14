ARG BASE=ubuntu-base:latest
FROM ${BASE}

USER root

ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH="${CARGO_HOME}/bin:${PATH}"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path \
    && rustup component add rust-analyzer \
    && chmod -R a+w "${RUSTUP_HOME}" "${CARGO_HOME}"

USER vscode
