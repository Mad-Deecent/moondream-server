FROM ubuntu:22.04 AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    wget \
    bash \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /app

# Download and extract Moondream Station
RUN curl -L "https://depot.moondream.ai/station/md_station_ubuntu.tar.gz" -o md_station_ubuntu.tar.gz \
    && tar --no-same-owner -xzf md_station_ubuntu.tar.gz \
    && rm md_station_ubuntu.tar.gz \
    && chmod +x moondream_station

RUN useradd -m -u 1000 moondream
RUN mkdir -p /data/.local/share/MoondreamStation \
    && chown -R moondream:moondream /data \
    && chown -R moondream:moondream /app

USER moondream

ENV HOME=/data
ENV XDG_DATA_HOME=/data/.local/share

# Run the bootstrap process to install all dependencies
# This will complete when all dependencies are installed and the server starts
RUN timeout 120 ./moondream_station --verbose || echo "Bootstrap completed or timed out"
RUN ls -la /data/.local/share/MoondreamStation/ && \
    ls -la /data/.local/share/MoondreamStation/py_versions/ && \
    ls -la /data/.local/share/MoondreamStation/.venv/

FROM ubuntu:22.04 AS deploy
LABEL org.opencontainers.image.source=https://github.com/Mad-Deecent/moondream-station-helm
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 moondream

WORKDIR /app
RUN mkdir -p /data/.local/share/MoondreamStation \
    && chown -R moondream:moondream /data \
    && chown -R moondream:moondream /app

COPY --from=builder --chown=moondream:moondream /app/ /app/
COPY --from=builder --chown=moondream:moondream /data/.local/share/MoondreamStation/ /data/.local/share/MoondreamStation/

USER moondream

ENV HOME=/data
ENV XDG_DATA_HOME=/data/.local/share

EXPOSE 2020

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:2020/v1 || exit 1

# Run the application
CMD ["./moondream_station"]