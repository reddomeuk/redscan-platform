# RedScan Platform

Infrastructure, deployment, and platform operations for RedScan using **Terraform Cloud**.

## Quick Start

### 🏗️ **Terraform Cloud Setup**
1. Set up Terraform Cloud workspaces (see `TERRAFORM_CLOUD_GUIDE.md`)
2. Configure Azure credentials in Terraform Cloud
3. Connect GitHub repository to workspaces

### 🚀 **Deployment**
```bash
# Automatic deployments via Terraform Cloud
git push origin main  # Triggers production deployment

# Manual deployment (if needed)
./scripts/deploy.sh deploy kubernetes prod

# Monitor deployment
kubectl get pods -n redscan
```

### 🔧 **Local Development**
```bash
# Test Terraform changes locally
cd terraform
terraform init
terraform plan -var-file="environments/dev.tfvars"
```

## Structure

- `terraform/` - Infrastructure as Code
- `kubernetes/` - Kubernetes manifests
- `docker/` - Docker configurations
- `scripts/` - Deployment and management scripts
- `monitoring/` - Observability configuration
- `security/` - Security policies

## Related Repositories

- [redscan-application](../redscan-application) - Application code
- [redscan-documentation](../redscan-documentation) - Documentation
