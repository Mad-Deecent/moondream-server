# Moondream FastAPI Service

A lightweight FastAPI wrapper around the Moondream transformers implementation, providing clean REST API endpoints for vision-language model capabilities.

This replaces the complex Moondream Station binary with a simple, maintainable Python service that exposes the core Moondream capabilities through a REST API.

## Project Structure

```
moondream-station-helm/
├── app/                    # FastAPI application
│   ├── __init__.py        # Package initialization
│   ├── app.py             # Main FastAPI application
│   ├── requirements.txt   # Python dependencies
│   └── test_api.py        # API test suite
├── charts/                # Helm chart for Kubernetes deployment
│   ├── templates/         # Kubernetes manifests
│   ├── Chart.yaml         # Helm chart metadata
│   └── values.yaml        # Default configuration values
├── Dockerfile             # Container image definition
├── Makefile               # Build and deployment automation
└── README.md              # This file
```

## Quick Start

### Using Makefile (Recommended)

```bash
# Show all available commands
make help

# Install dependencies and run locally
make install
make run

# Or run in Docker with volume mounting (models cached locally)
make docker-run

# Run with hot reloading for development
make run-dev
```

### Manual Commands

#### Run with Docker

```bash
docker build -t moondream-api .
docker run -p 8080:8080 -v moondream-api-models:/root/.cache/huggingface moondream-api
```

#### Run Locally

```bash
pip install -r app/requirements.txt
python -m app.app
```

The service will be available at `http://localhost:8080`

## Important Notes

### Docker on macOS

When running in Docker on macOS, the service will automatically use CPU mode since Docker doesn't support MPS (Metal Performance Shaders) passthrough yet. This is normal and expected behavior.

- **Local development**: Uses MPS for GPU acceleration on Apple Silicon
- **Docker**: Falls back to CPU mode automatically
- **Linux with NVIDIA GPU**: Uses CUDA when available

## Model Pre-loading for Kubernetes

To eliminate lengthy startup times when pods are rescheduled, the Helm chart includes a model pre-loading feature:

### How it Works

1. **Kubernetes Job** downloads the model to a PersistentVolumeClaim during installation
2. **Application pods** mount the same PVC, accessing pre-downloaded models instantly
3. **No startup delay** when pods move between nodes

### Usage

```bash
# Install with model pre-loading (recommended)
make helm-install-with-models

# Monitor the download progress
make helm-job-status
make helm-job-logs

# Regular install (models downloaded at runtime)
make helm-install
```

### Configuration

Customize model pre-loading in `values.yaml`:

```yaml
modelCache:
  enabled: true
  accessMode: ReadWriteMany # RWM for rolling deployments
  size: 20Gi
  existingClaim: ""
  modelRevision: "2025-06-21" # Optional, defaults to latest
```

## Makefile Commands

The project includes a comprehensive Makefile for easy development and deployment:

### Development

- `make install` - Install Python dependencies
- `make run` - Run the application locally
- `make run-dev` - Run with hot reloading
- `make test` - Run API test suite
- `make dev-setup` - Set up development environment

### Docker

- `make build` - Build Docker image
- `make docker-run` - Run in Docker with volume mounting
- `make docker-run-dev` - Run in Docker with hot reloading
- `make docker-stop` - Stop Docker containers
- `make docker-logs` - View container logs
- `make docker-volume-create` - Create Docker volume for model caching
- `make docker-volume-info` - Show volume information
- `make docker-volume-rm` - Remove Docker volume

### Kubernetes

- `make helm-install` - Install Helm chart
- `make helm-install-with-models` - Install with model pre-loading
- `make helm-uninstall` - Uninstall Helm chart
- `make helm-upgrade` - Upgrade Helm chart
- `make helm-job-status` - Check model download job status
- `make helm-job-logs` - View model download job logs

### Utilities

- `make status` - Show service status
- `make health` - Check service health
- `make clean` - Clean up resources
- `make help` - Show all available commands

## API Endpoints

The service provides the following endpoints:

- `GET /health` - Health check
- `GET /v1` - API info
- `POST /v1/caption` - Generate image captions
- `POST /v1/query` - Answer questions about images
- `POST /v1/detect` - Detect objects in images
- `POST /v1/point` - Locate objects in images

### Example Usage

```bash
# Health check
curl http://localhost:8080/health

# Generate caption
curl -X POST "http://localhost:8080/v1/caption" \
  -F "image=@your_image.jpg" \
  -F "length=short"

# Ask a question
curl -X POST "http://localhost:8080/v1/query" \
  -F "image=@your_image.jpg" \
  -F "question=What do you see in this image?"

# Detect objects
curl -X POST "http://localhost:8080/v1/detect" \
  -F "image=@your_image.jpg" \
  -F "object_name=person"

# Point to objects
curl -X POST "http://localhost:8080/v1/point" \
  -F "image=@your_image.jpg" \
  -F "object_name=car"
```

### Deploy to Kubernetes

```bash
helm install moondream-station oci://ghcr.io/mad-deecent/charts/moondream-station \
  --namespace moondream --create-namespace
```

Or install from source:

```bash
git clone https://github.com/Mad-Deecent/moondream-station-helm.git
cd moondream-station-helm
helm install moondream-station ./charts --namespace moondream --create-namespace
```

## Configuration

### GPU Support

To deploy on GPU nodes, configure node selection in your values:

```yaml
nodeSelector:
  nvidia.com/gpu.product: "NVIDIA-GeForce-RTX-3060"
```

### Resource Requirements

Default configuration requests 1 GPU and 2GB memory. Adjust based on your needs:

```yaml
resources:
  requests:
    cpu: 1000m
    memory: 2Gi
    nvidia.com/gpu: 1
  limits:
    cpu: 4000m
    memory: 8Gi
    nvidia.com/gpu: 1
```

### Custom namespace

```bash
helm install moondream-station ./charts \
  --namespace <my-namespace> \
  --create-namespace
```

## Support

For issues related to the Helm chart or containerization, open an issue in this repository.

For Moondream Station itself, visit [moondream.ai](https://moondream.ai) or their official documentation.
