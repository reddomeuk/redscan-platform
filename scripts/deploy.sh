#!/bin/bash

# RedScan Modular Deployment Script
# Supports Docker Compose and Kubernetes deployments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM=${1:-docker}
ENVIRONMENT=${2:-production}
ACTION=${3:-deploy}

# Available modules
MODULES=(
    "core-dashboard"
    "ai-assistant"
    "compliance"
    "network-security"
    "asset-management"
    "api-gateway"
)

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
RedScan Modular Deployment Script

Usage: $0 <platform> <environment> <action> [options]

Platforms:
  docker     - Deploy using Docker Compose
  kubernetes - Deploy to Kubernetes cluster
  azure      - Deploy to Azure Container Instances

Environments:
  development - Development environment
  staging     - Staging environment
  production  - Production environment

Actions:
  deploy     - Deploy all modules
  update     - Update specific modules
  scale      - Scale specific modules
  rollback   - Rollback to previous version
  destroy    - Remove all resources

Options:
  --module <name>     - Target specific module
  --replicas <num>    - Set replica count
  --dry-run          - Show what would be deployed

Examples:
  $0 docker production deploy
  $0 kubernetes production update --module ai-assistant
  $0 docker development scale --module core-dashboard --replicas 3
  $0 kubernetes production rollback --module ai-assistant

EOF
}

check_prerequisites() {
    log_info "Checking prerequisites for $PLATFORM deployment..."
    
    case $PLATFORM in
        docker)
            if ! command -v docker &> /dev/null; then
                log_error "Docker is not installed"
                exit 1
            fi
            if ! command -v docker-compose &> /dev/null; then
                log_error "Docker Compose is not installed"
                exit 1
            fi
            ;;
        kubernetes)
            if ! command -v kubectl &> /dev/null; then
                log_error "kubectl is not installed"
                exit 1
            fi
            if ! kubectl cluster-info &> /dev/null; then
                log_error "No active Kubernetes cluster found"
                exit 1
            fi
            ;;
        azure)
            if ! command -v az &> /dev/null; then
                log_error "Azure CLI is not installed"
                exit 1
            fi
            if ! az account show &> /dev/null; then
                log_error "Not logged into Azure"
                exit 1
            fi
            ;;
    esac
    
    log_success "Prerequisites check passed"
}

build_images() {
    log_info "Building container images..."
    
    for module in "${MODULES[@]}"; do
        log_info "Building $module..."
        
        if [[ -f "modules/$module/Dockerfile" ]]; then
            docker build -f "modules/$module/Dockerfile" -t "redscan/$module:latest" .
        elif [[ -f "shared/$module/Dockerfile" ]]; then
            docker build -f "shared/$module/Dockerfile" -t "redscan/$module:latest" .
        else
            log_warning "No Dockerfile found for $module"
        fi
    done
    
    log_success "All images built successfully"
}

deploy_docker() {
    log_info "Deploying to Docker Compose..."
    
    # Set environment variables
    export ENVIRONMENT=$ENVIRONMENT
    export COMPOSE_PROJECT_NAME="redscan-$ENVIRONMENT"
    
    # Create environment file
    cat > .env << EOF
# RedScan Environment Configuration
ENVIRONMENT=$ENVIRONMENT
JWT_SECRET=$(openssl rand -base64 32)
GROQ_API_KEY=${GROQ_API_KEY:-}
OPENROUTER_API_KEY=${OPENROUTER_API_KEY:-}
GOOGLE_AI_STUDIO_KEY=${GOOGLE_AI_STUDIO_KEY:-}
DATABASE_URL=${DATABASE_URL:-postgres://redscan:password@postgres:5432/redscan}
GRAFANA_PASSWORD=${GRAFANA_PASSWORD:-admin}
EOF
    
    # Deploy with Docker Compose
    docker-compose -f docker-compose.modular.yml up -d
    
    log_success "Docker deployment completed"
    log_info "Services available at:"
    log_info "  - Main Application: http://localhost"
    log_info "  - API Gateway: http://localhost:8080"
    log_info "  - Grafana: http://localhost:3001"
    log_info "  - Prometheus: http://localhost:9090"
}

deploy_kubernetes() {
    log_info "Deploying to Kubernetes..."
    
    # Create namespace if it doesn't exist
    kubectl create namespace redscan --dry-run=client -o yaml | kubectl apply -f -
    
    # Create secrets
    kubectl create secret generic ai-secrets \
        --from-literal=groq-api-key="${GROQ_API_KEY:-}" \
        --from-literal=openrouter-api-key="${OPENROUTER_API_KEY:-}" \
        --from-literal=google-ai-studio-key="${GOOGLE_AI_STUDIO_KEY:-}" \
        --namespace=redscan \
        --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl create secret generic auth-secrets \
        --from-literal=jwt-secret="$(openssl rand -base64 32)" \
        --namespace=redscan \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy applications
    kubectl apply -f infrastructure/kubernetes/redscan-platform.yaml
    
    # Wait for deployments
    kubectl wait --for=condition=available --timeout=300s deployment --all -n redscan
    
    log_success "Kubernetes deployment completed"
    
    # Show service URLs
    kubectl get ingress -n redscan
}

scale_module() {
    local module=$1
    local replicas=$2
    
    log_info "Scaling $module to $replicas replicas..."
    
    case $PLATFORM in
        docker)
            docker-compose -f docker-compose.modular.yml up -d --scale "$module=$replicas"
            ;;
        kubernetes)
            kubectl scale deployment "$module" --replicas="$replicas" -n redscan
            ;;
    esac
    
    log_success "$module scaled to $replicas replicas"
}

update_module() {
    local module=$1
    
    log_info "Updating $module..."
    
    # Build new image
    if [[ -f "modules/$module/Dockerfile" ]]; then
        docker build -f "modules/$module/Dockerfile" -t "redscan/$module:latest" .
    fi
    
    case $PLATFORM in
        docker)
            docker-compose -f docker-compose.modular.yml up -d "$module"
            ;;
        kubernetes)
            kubectl rollout restart deployment "$module" -n redscan
            kubectl rollout status deployment "$module" -n redscan
            ;;
    esac
    
    log_success "$module updated successfully"
}

rollback_module() {
    local module=$1
    
    log_info "Rolling back $module..."
    
    case $PLATFORM in
        kubernetes)
            kubectl rollout undo deployment "$module" -n redscan
            kubectl rollout status deployment "$module" -n redscan
            ;;
        *)
            log_error "Rollback only supported for Kubernetes platform"
            exit 1
            ;;
    esac
    
    log_success "$module rolled back successfully"
}

destroy_deployment() {
    log_warning "This will destroy all RedScan resources!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        case $PLATFORM in
            docker)
                docker-compose -f docker-compose.modular.yml down -v
                docker system prune -f
                ;;
            kubernetes)
                kubectl delete namespace redscan
                ;;
        esac
        
        log_success "All resources destroyed"
    else
        log_info "Destroy cancelled"
    fi
}

monitor_health() {
    log_info "Checking service health..."
    
    case $PLATFORM in
        docker)
            docker-compose -f docker-compose.modular.yml ps
            ;;
        kubernetes)
            kubectl get pods -n redscan
            kubectl top pods -n redscan 2>/dev/null || log_warning "Metrics server not available"
            ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --module)
            MODULE_TARGET="$2"
            shift 2
            ;;
        --replicas)
            REPLICA_COUNT="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Main execution
main() {
    if [[ "$ACTION" == "help" ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    check_prerequisites
    
    case $ACTION in
        deploy)
            build_images
            case $PLATFORM in
                docker)
                    deploy_docker
                    ;;
                kubernetes)
                    deploy_kubernetes
                    ;;
                azure)
                    log_error "Azure deployment not yet implemented"
                    exit 1
                    ;;
            esac
            ;;
        update)
            if [[ -n "$MODULE_TARGET" ]]; then
                update_module "$MODULE_TARGET"
            else
                log_error "Module name required for update"
                exit 1
            fi
            ;;
        scale)
            if [[ -n "$MODULE_TARGET" ]] && [[ -n "$REPLICA_COUNT" ]]; then
                scale_module "$MODULE_TARGET" "$REPLICA_COUNT"
            else
                log_error "Module name and replica count required for scaling"
                exit 1
            fi
            ;;
        rollback)
            if [[ -n "$MODULE_TARGET" ]]; then
                rollback_module "$MODULE_TARGET"
            else
                log_error "Module name required for rollback"
                exit 1
            fi
            ;;
        destroy)
            destroy_deployment
            ;;
        health)
            monitor_health
            ;;
        *)
            log_error "Invalid action: $ACTION"
            show_help
            exit 1
            ;;
    esac
    
    log_success "Operation completed successfully"
}

# Run main function
main "$@"