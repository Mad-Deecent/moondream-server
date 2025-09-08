# Moondream FastAPI Service Makefile

# Variables
APP_NAME := moondream-api
APP_VERSION := latest
DOCKER_IMAGE := $(APP_NAME):$(APP_VERSION)
DOCKER_CONTAINER := $(APP_NAME)-container
PORT := 8080
MODEL_CACHE_DIR := $(HOME)/.cache/moondream-models
MODEL_VOLUME := $(APP_NAME)-models

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

.PHONY: help install build run run-dev stop clean test lint format docker-build docker-run docker-stop docker-clean helm-install helm-uninstall

# Default target
help: ## Show this help message
	@echo "$(BLUE)Moondream FastAPI Service$(NC)"
	@echo "$(BLUE)========================$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Quick start:$(NC)"
	@echo "  make install    # Install dependencies"
	@echo "  make run        # Run locally"
	@echo "  make docker-run # Run in Docker with volume mounting"

install: ## Install Python dependencies
	@echo "$(BLUE)Installing Python dependencies...$(NC)"
	pip install -r app/requirements.txt
	@echo "$(GREEN)✅ Dependencies installed$(NC)"

build: ## Build the Docker image
	@echo "$(BLUE)Building Docker image...$(NC)"
	docker build -t $(DOCKER_IMAGE) .
	@echo "$(GREEN)✅ Docker image built: $(DOCKER_IMAGE)$(NC)"

run: ## Run the application locally
	@echo "$(BLUE)Starting Moondream FastAPI service locally...$(NC)"
	@echo "$(YELLOW)Service will be available at: http://localhost:$(PORT)$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	python -m app.app

run-dev: ## Run the application locally with hot reloading
	@echo "$(BLUE)Starting Moondream FastAPI service with hot reloading...$(NC)"
	@echo "$(YELLOW)Service will be available at: http://localhost:$(PORT)$(NC)"
	@echo "$(YELLOW)Press Ctrl+C to stop$(NC)"
	RELOAD=true python -m app.app

stop: ## Stop any running local processes
	@echo "$(BLUE)Stopping local processes...$(NC)"
	@pkill -f "python -m app.app" || true
	@echo "$(GREEN)✅ Local processes stopped$(NC)"

test: ## Run the API test suite
	@echo "$(BLUE)Running API test suite...$(NC)"
	python -m app.test_api
	@echo "$(GREEN)✅ Tests completed$(NC)"

lint: ## Run code linting
	@echo "$(BLUE)Running code linting...$(NC)"
	@if command -v flake8 >/dev/null 2>&1; then \
		flake8 app/ --max-line-length=100 --ignore=E203,W503; \
	else \
		echo "$(YELLOW)flake8 not installed, skipping linting$(NC)"; \
	fi

format: ## Format code with black
	@echo "$(BLUE)Formatting code...$(NC)"
	@if command -v black >/dev/null 2>&1; then \
		black app/ --line-length=100; \
	else \
		echo "$(YELLOW)black not installed, skipping formatting$(NC)"; \
	fi

docker-build: build ## Build Docker image (alias for build)

docker-volume-create: ## Create Docker volume for model caching
	@echo "$(BLUE)Creating Docker volume for model caching...$(NC)"
	@docker volume create $(MODEL_VOLUME) 2>/dev/null || echo "$(YELLOW)Volume $(MODEL_VOLUME) already exists$(NC)"
	@echo "$(GREEN)✅ Volume $(MODEL_VOLUME) ready$(NC)"

docker-run: docker-volume-create ## Run the application in Docker with volume mounting
	@echo "$(BLUE)Starting Moondream FastAPI service in Docker...$(NC)"
	@echo "$(YELLOW)Service will be available at: http://localhost:$(PORT)$(NC)"
	@echo "$(YELLOW)Models will be cached in Docker volume: $(MODEL_VOLUME)$(NC)"
	docker run -d \
		--name $(DOCKER_CONTAINER) \
		-p $(PORT):8080 \
		-v $(MODEL_VOLUME):/root/.cache/huggingface \
		-e RELOAD=false \
		$(DOCKER_IMAGE)
	@echo "$(GREEN)✅ Container started: $(DOCKER_CONTAINER)$(NC)"
	@echo "$(YELLOW)View logs with: docker logs -f $(DOCKER_CONTAINER)$(NC)"

docker-run-dev: docker-volume-create ## Run the application in Docker with hot reloading and volume mounting
	@echo "$(BLUE)Starting Moondream FastAPI service in Docker with hot reloading...$(NC)"
	@echo "$(YELLOW)Service will be available at: http://localhost:$(PORT)$(NC)"
	@echo "$(YELLOW)Models will be cached in Docker volume: $(MODEL_VOLUME)$(NC)"
	@echo "$(YELLOW)Note: For development, use 'make run-dev' for hot reloading$(NC)"
	docker run -d \
		--name $(DOCKER_CONTAINER)-dev \
		-p $(PORT):8080 \
		-v $(MODEL_VOLUME):/root/.cache/huggingface \
		-e RELOAD=false \
		$(DOCKER_IMAGE)
	@echo "$(GREEN)✅ Development container started: $(DOCKER_CONTAINER)-dev$(NC)"
	@echo "$(YELLOW)View logs with: docker logs -f $(DOCKER_CONTAINER)-dev$(NC)"

docker-stop: ## Stop Docker container
	@echo "$(BLUE)Stopping Docker container...$(NC)"
	@docker stop $(DOCKER_CONTAINER) $(DOCKER_CONTAINER)-dev 2>/dev/null || true
	@docker rm $(DOCKER_CONTAINER) $(DOCKER_CONTAINER)-dev 2>/dev/null || true
	@echo "$(GREEN)✅ Docker containers stopped and removed$(NC)"

docker-logs: ## Show Docker container logs
	@echo "$(BLUE)Showing Docker container logs...$(NC)"
	@docker logs -f $(DOCKER_CONTAINER) 2>/dev/null || docker logs -f $(DOCKER_CONTAINER)-dev 2>/dev/null || echo "$(RED)No running containers found$(NC)"

docker-shell: ## Open shell in Docker container
	@echo "$(BLUE)Opening shell in Docker container...$(NC)"
	@docker exec -it $(DOCKER_CONTAINER) /bin/bash 2>/dev/null || docker exec -it $(DOCKER_CONTAINER)-dev /bin/bash 2>/dev/null || echo "$(RED)No running containers found$(NC)"

docker-volume-rm: ## Remove Docker volume for model caching
	@echo "$(BLUE)Removing Docker volume...$(NC)"
	@docker volume rm $(MODEL_VOLUME) 2>/dev/null || echo "$(YELLOW)Volume $(MODEL_VOLUME) not found$(NC)"
	@echo "$(GREEN)✅ Volume removed$(NC)"

docker-volume-info: ## Show Docker volume information
	@echo "$(BLUE)Docker Volume Information$(NC)"
	@echo "$(BLUE)========================$(NC)"
	@docker volume ls | grep $(APP_NAME) || echo "$(YELLOW)No volumes found for $(APP_NAME)$(NC)"
	@echo ""
	@if docker volume inspect $(MODEL_VOLUME) >/dev/null 2>&1; then \
		echo "$(GREEN)Volume $(MODEL_VOLUME) exists$(NC)"; \
		docker volume inspect $(MODEL_VOLUME) | jq '.[0] | {Name: .Name, Mountpoint: .Mountpoint, CreatedAt: .CreatedAt}'; \
	else \
		echo "$(YELLOW)Volume $(MODEL_VOLUME) does not exist$(NC)"; \
	fi

docker-clean: docker-stop ## Stop and remove Docker containers and images
	@echo "$(BLUE)Cleaning up Docker resources...$(NC)"
	@docker rmi $(DOCKER_IMAGE) 2>/dev/null || true
	@echo "$(GREEN)✅ Docker resources cleaned$(NC)"

docker-build-push: ## Build and push Docker image to GHCR for amd64
	@echo "$(BLUE)Building and pushing Docker image to GHCR...$(NC)"
	@echo "$(YELLOW)Building for amd64 platform...$(NC)"
	docker buildx build --platform linux/amd64 \
		-t ghcr.io/mad-deecent/moondream-station-helm:latest \
		-t ghcr.io/mad-deecent/moondream-station-helm:$(APP_VERSION) \
		--push .
	@echo "$(GREEN)✅ Docker image built and pushed to GHCR$(NC)"

helm-install: ## Install the Helm chart
	@echo "$(BLUE)Installing Helm chart...$(NC)"
	helm install moondream-station ./charts --namespace moondream --create-namespace
	@echo "$(GREEN)✅ Helm chart installed$(NC)"

helm-uninstall: ## Uninstall the Helm chart
	@echo "$(BLUE)Uninstalling Helm chart...$(NC)"
	helm uninstall moondream-station --namespace moondream
	@echo "$(GREEN)✅ Helm chart uninstalled$(NC)"

helm-upgrade: ## Upgrade the Helm chart
	@echo "$(BLUE)Upgrading Helm chart...$(NC)"
	helm upgrade moondream-station ./charts --namespace moondream
	@echo "$(GREEN)✅ Helm chart upgraded$(NC)"

helm-install-with-models: ## Install Helm chart with model pre-loading enabled
	@echo "$(BLUE)Installing Helm chart with model pre-loading...$(NC)"
	helm install moondream-station ./charts --namespace moondream --create-namespace \
		--set modelCache.enabled=true
	@echo "$(GREEN)✅ Helm chart installed with model pre-loading$(NC)"
	@echo "$(YELLOW)Monitor model download: kubectl logs -n moondream job/moondream-station-model-download$(NC)"

helm-job-status: ## Check status of model download job
	@echo "$(BLUE)Checking model download job status...$(NC)"
	@kubectl get job -n moondream -l app.kubernetes.io/component=model-download || echo "$(YELLOW)No model download jobs found$(NC)"
	@echo ""
	@kubectl get pods -n moondream -l app.kubernetes.io/component=model-download || echo "$(YELLOW)No model download pods found$(NC)"

helm-job-logs: ## Show logs from model download job
	@echo "$(BLUE)Showing model download job logs...$(NC)"
	@kubectl logs -n moondream -l app.kubernetes.io/component=model-download --tail=50 || echo "$(YELLOW)No logs found$(NC)"

clean: docker-clean ## Clean up all resources
	@echo "$(BLUE)Cleaning up local resources...$(NC)"
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -delete
	@echo "$(GREEN)✅ Local resources cleaned$(NC)"

status: ## Show status of services
	@echo "$(BLUE)Service Status$(NC)"
	@echo "$(BLUE)=============$(NC)"
	@echo ""
	@echo "$(GREEN)Local processes:$(NC)"
	@pgrep -f "python -m app.app" >/dev/null && echo "  ✅ Local service running" || echo "  ❌ Local service not running"
	@echo ""
	@echo "$(GREEN)Docker containers:$(NC)"
	@docker ps --filter "name=$(DOCKER_CONTAINER)" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  ❌ No Docker containers running"
	@echo ""
	@echo "$(GREEN)Helm releases:$(NC)"
	@helm list --namespace moondream 2>/dev/null || echo "  ❌ No Helm releases found"

# Development helpers
dev-setup: install ## Set up development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@if ! command -v black >/dev/null 2>&1; then \
		echo "$(YELLOW)Installing black for code formatting...$(NC)"; \
		pip install black; \
	fi
	@if ! command -v flake8 >/dev/null 2>&1; then \
		echo "$(YELLOW)Installing flake8 for code linting...$(NC)"; \
		pip install flake8; \
	fi
	@echo "$(GREEN)✅ Development environment ready$(NC)"

# Health check
health: ## Check service health
	@echo "$(BLUE)Checking service health...$(NC)"
	@curl -s http://localhost:$(PORT)/health | jq . 2>/dev/null || echo "$(RED)Service not responding$(NC)"
