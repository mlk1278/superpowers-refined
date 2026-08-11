# Thin per-project layer over boxcar-base:latest.
# Built ONLY when this project has a non-trivial Dockerfile.local.sh.
# Otherwise launch.sh uses the base image directly.

ARG BASE_IMAGE=boxcar-base:latest
FROM ${BASE_IMAGE}

# ── Project-specific build steps (runs as root) ──────────────────────────────
# Add project image setup here: apt packages, global tools, etc.
# This file is committed to the project and preserved by devcontainer-init --update.
USER root
RUN --mount=type=bind,source=.,target=/src \
    --mount=type=bind,source=.devcontainer,target=/devcontainer-src \
    if [ -f /devcontainer-src/Dockerfile.local.sh ]; then \
        cd /src && bash /devcontainer-src/Dockerfile.local.sh; \
    fi

USER ${SANDBOX_DEFAULT_UID}:${SANDBOX_DEFAULT_GID}
