#!/bin/bash

# Terraform Deployment Script for RedScan Security Platform
# Usage: ./deploy.sh <environment> [action]
# Examples:
#   ./deploy.sh dev plan
#   ./deploy.sh prod apply
#   ./deploy.sh dev destroy

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"
REQUIRED_TOOLS=("terraform" "az")

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

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool is not installed or not in PATH"
            exit 1
        fi
    done
    
    # Check if logged into Azure
    if ! az account show &> /dev/null; then
        log_error "Not logged into Azure. Run 'az login' first."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

validate_environment() {
    local env=$1
    if [[ ! "$env" =~ ^(dev|prod)$ ]]; then
        log_error "Invalid environment: $env. Must be 'dev' or 'prod'"
        exit 1
    fi
}

setup_backend() {
    local env=$1
    log_info "Setting up Terraform backend for $env environment..."
    
    # Create backend configuration
    cat > "$TERRAFORM_DIR/backend.conf" << EOF
resource_group_name  = "rg-terraform-state"
storage_account_name = "stterraformstate$(date +%s | tail -c 8)"
container_name       = "terraform-state"
key                  = "redscan-${env}.tfstate"
EOF
    
    log_success "Backend configuration created"
}

terraform_init() {
    local env=$1
    log_info "Initializing Terraform for $env environment..."
    
    cd "$TERRAFORM_DIR"
    terraform init -backend-config="backend.conf"
    
    log_success "Terraform initialized"
}

terraform_plan() {
    local env=$1
    log_info "Planning Terraform deployment for $env environment..."
    
    cd "$TERRAFORM_DIR"
    terraform plan \
        -var-file="environments/${env}.tfvars" \
        -out="${env}.tfplan"
    
    log_success "Terraform plan completed"
}

terraform_apply() {
    local env=$1
    log_info "Applying Terraform deployment for $env environment..."
    
    cd "$TERRAFORM_DIR"
    if [[ -f "${env}.tfplan" ]]; then
        terraform apply "${env}.tfplan"
    else
        log_warning "No plan file found. Running plan and apply..."
        terraform apply \
            -var-file="environments/${env}.tfvars" \
            -auto-approve
    fi
    
    log_success "Terraform apply completed"
    
    # Display outputs
    log_info "Deployment outputs:"
    terraform output
}

terraform_destroy() {
    local env=$1
    log_warning "This will destroy all resources in the $env environment!"
    read -p "Are you sure? (yes/no): " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        log_info "Destroying Terraform deployment for $env environment..."
        
        cd "$TERRAFORM_DIR"
        terraform destroy \
            -var-file="environments/${env}.tfvars" \
            -auto-approve
        
        log_success "Terraform destroy completed"
    else
        log_info "Destroy cancelled"
    fi
}

show_help() {
    cat << EOF
Terraform Deployment Script for RedScan Security Platform

Usage: $0 <environment> [action]

Environments:
  dev     - Development environment
  prod    - Production environment

Actions:
  init     - Initialize Terraform
  plan     - Create execution plan
  apply    - Apply changes (default)
  destroy  - Destroy all resources
  help     - Show this help

Examples:
  $0 dev plan           # Plan dev deployment
  $0 prod apply         # Apply prod deployment
  $0 dev destroy        # Destroy dev environment

Prerequisites:
  - Azure CLI installed and logged in
  - Terraform installed
  - Required Azure permissions

Environment Variables (optional):
  TF_VAR_groq_api_key           - Groq API key
  TF_VAR_openrouter_api_key     - OpenRouter API key
  TF_VAR_google_ai_studio_key   - Google AI Studio key

EOF
}

# Main script
main() {
    local environment=$1
    local action=${2:-apply}
    
    if [[ "$environment" == "help" ]] || [[ "$environment" == "--help" ]] || [[ "$environment" == "-h" ]]; then
        show_help
        exit 0
    fi
    
    if [[ -z "$environment" ]]; then
        log_error "Environment is required"
        show_help
        exit 1
    fi
    
    validate_environment "$environment"
    check_prerequisites
    
    case "$action" in
        init)
            setup_backend "$environment"
            terraform_init "$environment"
            ;;
        plan)
            setup_backend "$environment"
            terraform_init "$environment"
            terraform_plan "$environment"
            ;;
        apply)
            setup_backend "$environment"
            terraform_init "$environment"
            terraform_plan "$environment"
            terraform_apply "$environment"
            ;;
        destroy)
            setup_backend "$environment"
            terraform_init "$environment"
            terraform_destroy "$environment"
            ;;
        help)
            show_help
            ;;
        *)
            log_error "Invalid action: $action"
            show_help
            exit 1
            ;;
    esac
    
    log_success "Script completed successfully"
}

# Run main function with all arguments
main "$@"