# Moondream Station Helm Chart

A Helm chart for deploying Moondream Station vision-language model server on Kubernetes with GPU support.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- GPU-enabled nodes with NVIDIA GPU Operator
- Persistent Volume provisioner support in the underlying infrastructure

## Installing the Chart

To install the chart with the release name `moonstream-server`:

```bash
helm install moonstream-server ./charts/moondream
```

The command deploys Moondream Station on the Kubernetes cluster in the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

> **Tip**: List all releases using `helm list`

## Uninstalling the Chart

To uninstall/delete the `moonstream-server` deployment:

```bash
helm delete moonstream-server
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Parameters

### Global parameters

| Name               | Description                             | Value |
| ------------------ | --------------------------------------- | ----- |
| `replicaCount`     | Number of Moondream Station replicas    | `1`   |
| `nameOverride`     | String to partially override chart name | `""`  |
| `fullnameOverride` | String to fully override chart name     | `""`  |

### Image parameters

| Name               | Description                                        | Value               |
| ------------------ | -------------------------------------------------- | ------------------- |
| `image.repository` | Moondream Station image repository                 | `moonstream-server` |
| `image.tag`        | Moondream Station image tag (overrides appVersion) | `"latest"`          |
| `image.pullPolicy` | Moondream Station image pull policy                | `Always`            |

### GPU Configuration

| Name               | Description                     | Value                                                           |
| ------------------ | ------------------------------- | --------------------------------------------------------------- |
| `gpu.enabled`      | Enable GPU support              | `true`                                                          |
| `gpu.count`        | Number of GPUs to request       | `1`                                                             |
| `gpu.nodeSelector` | Node selector for GPU nodes     | `{accelerator: nvidia-tesla-gpu}`                               |
| `gpu.tolerations`  | Tolerations for GPU node taints | `[{key: nvidia.com/gpu, operator: Exists, effect: NoSchedule}]` |

### Service parameters

| Name                      | Description                          | Value          |
| ------------------------- | ------------------------------------ | -------------- |
| `service.type`            | Kubernetes Service type              | `ClusterIP`    |
| `service.port`            | Service port                         | `8080`         |
| `externalService.enabled` | Enable external LoadBalancer service | `false`        |
| `externalService.type`    | External service type                | `LoadBalancer` |

### Persistence parameters

| Name                       | Description                         | Value           |
| -------------------------- | ----------------------------------- | --------------- |
| `persistence.enabled`      | Enable persistent volume            | `true`          |
| `persistence.storageClass` | Storage class for persistent volume | `"fast-ssd"`    |
| `persistence.accessMode`   | Access mode for persistent volume   | `ReadWriteOnce` |
| `persistence.size`         | Size of persistent volume           | `10Gi`          |

### Resource Configuration

| Name                                | Description    | Value   |
| ----------------------------------- | -------------- | ------- |
| `resources.requests.cpu`            | CPU request    | `1000m` |
| `resources.requests.memory`         | Memory request | `2Gi`   |
| `resources.requests.nvidia.com/gpu` | GPU request    | `1`     |
| `resources.limits.cpu`              | CPU limit      | `4000m` |
| `resources.limits.memory`           | Memory limit   | `8Gi`   |
| `resources.limits.nvidia.com/gpu`   | GPU limit      | `1`     |

### Application Configuration

| Name                           | Description             | Value       |
| ------------------------------ | ----------------------- | ----------- |
| `config.host`                  | Bind host               | `"0.0.0.0"` |
| `config.port`                  | Bind port               | `8080`      |
| `config.logLevel`              | Log level               | `"info"`    |
| `config.maxConcurrentRequests` | Max concurrent requests | `10`        |

### Probe Configuration

| Name                                   | Description                       | Value     |
| -------------------------------------- | --------------------------------- | --------- |
| `probes.readiness.enabled`             | Enable readiness probe            | `true`    |
| `probes.readiness.path`                | Readiness probe path              | `/health` |
| `probes.readiness.initialDelaySeconds` | Initial delay for readiness probe | `30`      |
| `probes.liveness.enabled`              | Enable liveness probe             | `true`    |
| `probes.liveness.path`                 | Liveness probe path               | `/health` |
| `probes.liveness.initialDelaySeconds`  | Initial delay for liveness probe  | `60`      |

## Example Usage

### Basic Installation

```bash
helm install my-moondream ./charts/moondream
```

### Installation with Custom Values

```bash
helm install my-moondream ./charts/moondream \
  --set image.repository=my-registry/moonstream-server \
  --set image.tag=v1.0.0 \
  --set resources.requests.memory=4Gi \
  --set persistence.size=20Gi
```

### Installation with External Access

```bash
helm install my-moondream ./charts/moondream \
  --set externalService.enabled=true \
  --set externalService.type=LoadBalancer
```

### Installation with Ingress

```yaml
# values-ingress.yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  hosts:
    - host: moondream.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: moondream-tls
      hosts:
        - moondream.example.com
```

```bash
helm install my-moondream ./charts/moondream -f values-ingress.yaml
```

## Upgrading

To upgrade the chart:

```bash
helm upgrade my-moondream ./charts/moondream
```

## Troubleshooting

### GPU Issues

If the pod is not scheduling on GPU nodes:

1. Verify GPU nodes are properly labeled:

```bash
kubectl get nodes -l accelerator=nvidia-tesla-gpu
```

2. Check GPU device plugin is running:

```bash
kubectl get pods -n kube-system -l name=nvidia-device-plugin-daemonset
```

3. Verify GPU resources are available:

```bash
kubectl describe nodes <gpu-node-name>
```

### Storage Issues

If persistent volume is not being created:

1. Check available storage classes:

```bash
kubectl get storageclass
```

2. Update the `persistence.storageClass` value to match your cluster.

### Image Pull Issues

If the image cannot be pulled:

1. Ensure the image exists in your registry
2. Configure `imagePullSecrets` if using a private registry
3. Check the image tag is correct

## Values File Example

```yaml
# Custom values for production deployment
replicaCount: 1

image:
  repository: my-registry.com/moonstream-server
  tag: "v1.2.0"
  pullPolicy: IfNotPresent

resources:
  requests:
    cpu: 2000m
    memory: 4Gi
    nvidia.com/gpu: 1
  limits:
    cpu: 8000m
    memory: 16Gi
    nvidia.com/gpu: 1

persistence:
  enabled: true
  storageClass: "fast-ssd"
  size: 50Gi

externalService:
  enabled: true
  type: LoadBalancer

config:
  logLevel: "debug"
  maxConcurrentRequests: 20

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: ai.mycompany.com
      paths:
        - path: /moondream
          pathType: Prefix

podDisruptionBudget:
  enabled: true
  minAvailable: 1
```
