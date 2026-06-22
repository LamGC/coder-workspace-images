ARG BASE=ubuntu-base:latest
FROM ${BASE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

ENV SDKMAN_DIR=/home/vscode/.sdkman
ENV JAVA_HOME="${SDKMAN_DIR}/candidates/java/current"
ENV PATH="${SDKMAN_DIR}/candidates/java/current/bin:${SDKMAN_DIR}/candidates/maven/current/bin:${SDKMAN_DIR}/candidates/gradle/current/bin:${PATH}"

ARG JAVA_VERSION=""
ARG MAVEN_VERSION=""
ARG GRADLE_VERSION=""

USER vscode

RUN curl -fsSL "https://get.sdkman.io" | bash \
    && source "${SDKMAN_DIR}/bin/sdkman-init.sh" \
    && sed -i "s/sdkman_auto_answer=false/sdkman_auto_answer=true/" "${SDKMAN_DIR}/etc/config" \
    && if [ -n "${JAVA_VERSION}" ]; then sdk install java "${JAVA_VERSION}"; else sdk install java; fi \
    && if [ -n "${MAVEN_VERSION}" ]; then sdk install maven "${MAVEN_VERSION}"; else sdk install maven; fi \
    && if [ -n "${GRADLE_VERSION}" ]; then sdk install gradle "${GRADLE_VERSION}"; else sdk install gradle; fi \
    && sdk flush archives \
    && sdk flush temp


RUN for rc in /home/vscode/.bashrc /home/vscode/.zshrc; do \
        touch "${rc}"; \
        grep -q "sdkman-init.sh" "${rc}" || printf "\nexport SDKMAN_DIR=\"/home/vscode/.sdkman\"\n[[ -s \"/home/vscode/.sdkman/bin/sdkman-init.sh\" ]] && source \"/home/vscode/.sdkman/bin/sdkman-init.sh\"\n" >> "${rc}"; \
    done

USER root

# Refresh workspace skeleton after installing into /home/vscode so persisted volumes receive SDKMAN on first start.
RUN cp -rT /home/vscode /etc/workspace-skel \
    && chmod -R a+rX /etc/workspace-skel

USER vscode
