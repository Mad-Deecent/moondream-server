# Moondream Station Helm Chart

A Kubernetes Helm chart for deploying [Moondream Station](https://moondream.ai/station), a vision-language model inference server, as a containerized service.

This is an extension of the official Moondream Station that allows you to run it as a Docker container and easily deploy it to Kubernetes clusters.

## Quick Start

### Run with Docker

```bash
docker run -p 2020:2020 ghcr.io/mad-deecent/moondream-station-helm:latest
```

The service will be available at `http://localhost:2020/v1`

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
