# Moondream Station Kubernetes Deployment

This directory contains all the necessary files to containerize and deploy Moondream Station in a Kubernetes cluster with GPU support.

## Overview

Moondream Station is a powerful vision-language model that can run locally. This deployment setup containerizes the station and makes it available as a scalable service in Kubernetes.

## Files Structure

```
moondream/
├── Dockerfile                 # Container image definition
├── k8s/                      # Raw Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── pvc.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── README.md                 # This file
```

## Prerequisites

1. **Kubernetes cluster** with GPU support
2. **NVIDIA GPU Operator** installed in the cluster
3. **Docker** or **Podman** for building images
4. **kubectl** configured to access your cluster
5. **GPU nodes** with proper labeling and taints

## Building the Container Image

1. Build the Docker image:

```bash
cd moondream
docker build -t moondream-station:latest .
```

2. Tag and push to your container registry:

```bash
docker tag moondream-station:latest your-registry/moondream-station:latest
docker push your-registry/moondream-station:latest
```

3. Update the image reference in your deployment files.

## Deployment Options

### Option 1: Using Raw Kubernetes Manifests

1. Review and modify the configuration in `k8s/`:

   - Update `nodeSelector` in `deployment.yaml` to match your GPU nodes
   - Adjust `storageClassName` in `pvc.yaml` to match your cluster
   - Modify resource requests/limits as needed

2. Deploy using kustomize:

```bash
kubectl apply -k k8s/
```

3. Or deploy individual files:

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/pvc.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### Option 2: Using Helm Chart (Recommended)

See `../charts/moondream/README.md` for Helm deployment instructions.

## GPU Configuration

The deployment assumes:

- GPU nodes are labeled with `accelerator: nvidia-tesla-gpu`
- GPU nodes are tainted with `nvidia.com/gpu=:NoSchedule`
- NVIDIA Device Plugin is running in the cluster

Adjust the `nodeSelector` and `tolerations` in the deployment files to match your cluster's GPU configuration.

## Storage Requirements

- **Model Storage**: 10Gi persistent volume for model downloads
- **Shared Memory**: 2Gi for ML workload optimization
- **Storage Class**: Update `pvc.yaml` to use your cluster's fast SSD storage class

## Networking

The service exposes Moondream Station on port 8080:

- **Internal Access**: `moondream-station-service.moondream.svc.cluster.local:8080`
- **External Access**: Configure LoadBalancer or Ingress as needed

## Monitoring

The deployment includes health checks:

- **Readiness Probe**: `/health` endpoint (starts after 30s)
- **Liveness Probe**: `/health` endpoint (starts after 60s)

## Troubleshooting

1. **Pod not scheduling**: Check GPU node labels and taints
2. **Container crashes**: Check logs with `kubectl logs -n moondream deployment/moondream-station`
3. **Storage issues**: Verify storage class and PVC status
4. **GPU not available**: Ensure NVIDIA Device Plugin is running

## Scaling

For horizontal scaling, consider:

- Using multiple replicas (though GPU availability may limit this)
- Implementing proper load balancing
- Setting up pod disruption budgets

## Security

The deployment runs as non-root user (UID 1000) with minimal privileges:

- No privilege escalation
- All capabilities dropped
- Read-only root filesystem disabled (required for model storage)
