# Test harness for init.sh (mirrors install.sh layout).
#
# Build once, then iterate by bind-mounting the install tree if needed:
#   docker build -t init-scripts .
#   docker run --rm -it init-scripts

FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive \
    DEV=/root/dev \
    PROJECTS=/root/dev/Projects \
    BASH_INIT=/root/.local/bin/init.sh

COPY .devcontainer/ /tmp/.devcontainer/
RUN if [ -x /tmp/.devcontainer/bootstrap/bootstrap.sh ]; then \
      /tmp/.devcontainer/bootstrap/bootstrap.sh; \
    fi \
  && rm -rf /tmp/.devcontainer

RUN apt-get update \
  && apt-get install -y --no-install-recommends git \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/.local/bin /root/dev/Projects \
  && cp /etc/skel/.bashrc /root/.bashrc \
  && printf '%s\n' \
    '' \
    '# INIT (managed by init-scripts install.sh)' \
    'export DEV="/root/dev"' \
    'export PROJECTS="/root/dev/Projects"' \
    'export BASH_INIT="/root/.local/bin/init.sh"' \
    'export PATH="/root/.local/bin:${PATH}"' \
    'source "${BASH_INIT}/init.sh"' \
    '# END INIT (managed by init-scripts install.sh)' \
    >> /root/.bashrc

COPY bin/ /root/.local/bin/
COPY init.sh/ /root/.local/bin/init.sh/
RUN find /root/.local/bin/init.sh -maxdepth 1 -type l -delete \
  && chmod +x /root/.local/bin/use-module

WORKDIR /root/dev/Projects

CMD ["bash"]
