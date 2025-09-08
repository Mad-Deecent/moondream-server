FROM python:3.11-slim

LABEL org.opencontainers.image.source=https://github.com/Mad-Deecent/moondream-station-helm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    libglib2.0-0 \
    libgl1-mesa-glx \
    libgomp1 \
    libglib2.0-dev \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1000 moondream

WORKDIR /app

# Copy requirements and install Python dependencies
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ ./app/

# Create cache directory for models
RUN mkdir -p /root/.cache/huggingface && \
    chown -R moondream:moondream /app && \
    chown -R moondream:moondream /root/.cache

USER moondream

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Set environment variables
ENV RELOAD=false

# Run the FastAPI application
CMD ["python", "-m", "app.app"]