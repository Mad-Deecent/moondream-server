# Moondream FastAPI Service

A lightweight FastAPI wrapper around the Moondream transformers implementation, providing clean REST API endpoints for vision-language model capabilities.

This replaces the complex Moondream Station binary with a simple, maintainable Python service that exposes the core Moondream capabilities through a REST API.

## Project Structure

```
moondream-server/
├── app/                   # FastAPI application
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

1. **Kubernetes Job** downloads the model to a shared PersistentVolumeClaim during installation
2. **Application pods** mount the same PVC, accessing pre-downloaded models instantly
3. **No startup delay** when pods move between nodes or restart

### Configuration

The model pre-loading is configured under the unified `persistence` section in `values.yaml`:

```yaml
persistence:
  enabled: true
  storageClass: "" # Storage class for PVC
  accessMode: ReadWriteMany # RWM for rolling deployments and model sharing
  size: 20Gi
  existingClaim: "" # Optional: use existing PVC instead of creating new one

  modelCache:
    enabled: true # Download models to the PVC
    modelRevision: "2025-06-21" # Model version to download
    waitForCache: true # Wait for model download job to complete before starting pods
```

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

### Testing

Run the comprehensive test suite:

```bash
# Test all endpoints with a real image
python app/test_api.py
```

The test suite downloads a real image from Unsplash and tests all API endpoints to ensure proper functionality.

### Deploy to Kubernetes

```bash
helm install moondream-station oci://ghcr.io/mad-deecent/charts/moondream-station \
  --namespace moondream --create-namespace
```

Or install from source:

```bash
git clone https://github.com/Mad-Deecent/moondream-server.git
cd moondream-server
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
