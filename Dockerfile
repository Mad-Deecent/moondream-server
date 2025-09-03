FROM ubuntu:22.04

# Install curl and other dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Download and extract Moondream Station
RUN curl -L "https://depot.moondream.ai/station/md_station_ubuntu.tar.gz" -o md_station_ubuntu.tar.gz \
    && tar --no-same-owner -xzf md_station_ubuntu.tar.gz \
    && rm md_station_ubuntu.tar.gz \
    && chmod +x moondream_station

# Create a non-root user
RUN useradd -m -u 1000 moondream
RUN chown -R moondream:moondream /app

# Create data directory for models and persistent data
RUN mkdir -p /data/.local/share/MoondreamStation \
    && chown -R moondream:moondream /data

USER moondream

# Set environment variables
ENV HOME=/data
ENV XDG_DATA_HOME=/data/.local/share

# Expose the default port (we'll need to verify this)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run the application
CMD ["./moondream_station"]
