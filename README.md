# Moondream Station Helm Chart

A Kubernetes Helm chart for deploying [Moondream Station](https://moondream.ai/station), a vision-language model inference server.

## Features

- **Fast startup**: Multi-stage Docker build with pre-installed dependencies
- **GPU support**: Optimized for NVIDIA GPU nodes with configurable node selection
- **Production ready**: Includes health checks, resource limits, and security contexts
- **Flexible deployment**: Support for both kubectl and Helm deployment methods

## Quick Start

### Prerequisites

- Kubernetes cluster with GPU nodes (recommended)
- Helm 3.x
- kubectl configured for your cluster

### Installation

1. Clone this repository:

```bash
git clone https://github.com/Mad-Deecent/moondream-station-helm.git
cd moondream-station-helm
```

2. Deploy using Helm:

```bash
helm install moondream-station ./charts --namespace moondream --create-namespace
```

3. Check the deployment:

```bash
kubectl get pods -n moondream
```

### Using the Build Script

The repository includes a convenient build and deploy script:

```bash
# Build and deploy everything
./build-and-deploy.sh all

# Just build the image
./build-and-deploy.sh build

# Deploy using Helm
./build-and-deploy.sh helm

# Check deployment status
./build-and-deploy.sh status
```

## Configuration

### GPU Node Selection

To target specific GPU nodes, update the `nodeSelector` in `charts/values.yaml`:

```yaml
nodeSelector:
  nvidia.com/gpu.memory: "12288" # Target GPUs with 12GB memory
  nvidia.com/gpu.product: "NVIDIA-GeForce-RTX-3060" # Target specific GPU model
```

### Resource Requirements

Default resource requests and limits:

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

### Private Registry

If using a private registry, configure image pull secrets:

```yaml
imagePullSecrets:
  - name: your-registry-secret
```

Create the secret:

```bash
kubectl create secret docker-registry your-registry-secret \
  --docker-server=ghcr.io \
  --docker-username=your-username \
  --docker-password=your-token \
  --namespace=your-namespace
```

## Architecture

The Docker image uses a multi-stage build process:

1. **Builder stage**: Downloads and installs all dependencies (Python, conda, packages)
2. **Deploy stage**: Copies the pre-built environment for fast startup

This eliminates the 60+ second bootstrap process that would otherwise happen on every container start.

## Development

### Building Custom Images

```bash
# Build for AMD64 (most Kubernetes clusters)
docker buildx build --platform linux/amd64 -t your-repo/moondream-station:latest .

# Build and push
docker push your-repo/moondream-station:latest
```

### Customizing the Chart

Key configuration files:

- `charts/values.yaml` - Default values and configuration
- `charts/templates/deployment.yaml` - Kubernetes Deployment template
- `charts/templates/service.yaml` - Kubernetes Service template
- `Dockerfile` - Multi-stage container build

## Troubleshooting

### Pod Stuck in Pending

Check if your cluster has GPU nodes and if node selectors match:

```bash
kubectl describe pod <pod-name> -n <namespace>
kubectl get nodes --show-labels | grep nvidia.com/gpu
```

### Image Pull Errors

Ensure you have the correct image pull secrets configured if using a private registry.

### Startup Issues

Check the container logs:

```bash
kubectl logs <pod-name> -n <namespace>
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with your Kubernetes cluster
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues related to:

- **Helm chart**: Open an issue in this repository
- **Moondream Station**: Visit [moondream.ai](https://moondream.ai) or their documentation
- **Kubernetes/GPU setup**: Consult your cluster documentation
