#!/bin/bash

# Moondream Station Build and Deploy Script
set -e

# Configuration
IMAGE_NAME="moondream-station"
IMAGE_TAG="${IMAGE_TAG:-latest}"
REGISTRY="${REGISTRY:-localhost:5000}"  # Update this to your registry
NAMESPACE="moondream"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Function to build the Docker image
build_image() {
    log "Building Docker image..."
    
    if ! docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .; then
        error "Failed to build Docker image"
    fi
    
    # Tag for registry
    if [ "$REGISTRY" != "localhost:5000" ]; then
        docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    fi
    
    log "Image built successfully: ${IMAGE_NAME}:${IMAGE_TAG}"
}

# Function to push the image
push_image() {
    if [ "$REGISTRY" != "localhost:5000" ]; then
        log "Pushing image to registry: ${REGISTRY}"
        
        if ! docker push "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"; then
            error "Failed to push image to registry"
        fi
        
        log "Image pushed successfully"
    else
        warn "Skipping push for local registry"
    fi
}

# Function to deploy using kubectl
deploy_kubectl() {
    log "Deploying using kubectl..."
    
    # Update image in deployment if using registry
    if [ "$REGISTRY" != "localhost:5000" ]; then
        sed -i.bak "s|image: moondream-station:latest|image: ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}|g" k8s/deployment.yaml
    fi
    
    # Apply manifests
    if ! kubectl apply -k k8s/; then
        error "Failed to deploy with kubectl"
    fi
    
    # Restore original deployment file
    if [ -f "k8s/deployment.yaml.bak" ]; then
        mv k8s/deployment.yaml.bak k8s/deployment.yaml
    fi
    
    log "Deployment successful"
}

# Function to deploy using Helm
deploy_helm() {
    log "Deploying using Helm..."
    
    local helm_args=""
    if [ "$REGISTRY" != "localhost:5000" ]; then
        helm_args="--set image.repository=${REGISTRY}/${IMAGE_NAME} --set image.tag=${IMAGE_TAG}"
    fi
    
    if ! helm upgrade --install moondream-station ../charts/moondream \
        --namespace ${NAMESPACE} \
        --create-namespace \
        ${helm_args}; then
        error "Failed to deploy with Helm"
    fi
    
    log "Helm deployment successful"
}

# Function to check deployment status
check_status() {
    log "Checking deployment status..."
    
    echo "Pods in namespace ${NAMESPACE}:"
    kubectl get pods -n ${NAMESPACE}
    
    echo ""
    echo "Services in namespace ${NAMESPACE}:"
    kubectl get svc -n ${NAMESPACE}
    
    echo ""
    echo "PVCs in namespace ${NAMESPACE}:"
    kubectl get pvc -n ${NAMESPACE}
}

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS] COMMAND"
    echo ""
    echo "Commands:"
    echo "  build       Build the Docker image"
    echo "  push        Push the image to registry"
    echo "  deploy      Deploy using kubectl (raw manifests)"
    echo "  helm        Deploy using Helm"
    echo "  all         Build, push, and deploy"
    echo "  status      Check deployment status"
    echo ""
    echo "Options:"
    echo "  -r, --registry REGISTRY    Container registry (default: localhost:5000)"
    echo "  -t, --tag TAG              Image tag (default: latest)"
    echo "  -n, --namespace NAMESPACE  Kubernetes namespace (default: moondream)"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  REGISTRY      Container registry"
    echo "  IMAGE_TAG     Image tag"
    echo ""
    echo "Examples:"
    echo "  $0 build"
    echo "  $0 -r my-registry.com -t v1.0.0 all"
    echo "  $0 helm"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        build|push|deploy|helm|all|status)
            COMMAND="$1"
            shift
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Check if command is provided
if [ -z "$COMMAND" ]; then
    error "No command provided. Use -h for help."
fi

# Check if we're in the right directory
if [ ! -f "Dockerfile" ]; then
    error "Dockerfile not found. Please run this script from the moondream directory."
fi

# Check prerequisites
if ! command -v docker &> /dev/null; then
    error "Docker is not installed or not in PATH"
fi

if ! command -v kubectl &> /dev/null; then
    error "kubectl is not installed or not in PATH"
fi

# Execute command
case $COMMAND in
    build)
        build_image
        ;;
    push)
        push_image
        ;;
    deploy)
        deploy_kubectl
        check_status
        ;;
    helm)
        if ! command -v helm &> /dev/null; then
            error "Helm is not installed or not in PATH"
        fi
        deploy_helm
        check_status
        ;;
    all)
        build_image
        push_image
        deploy_kubectl
        check_status
        ;;
    status)
        check_status
        ;;
    *)
        error "Unknown command: $COMMAND"
        ;;
esac

log "Script completed successfully!"
