# RedScan Platform

Infrastructure, deployment, and platform operations for RedScan.

## Quick Start

```bash
# Deploy infrastructure
cd terraform
terraform init
terraform plan -var-file="environments/prod.tfvars"
terraform apply

# Deploy application
./scripts/deploy.sh deploy kubernetes prod

# Monitor deployment
kubectl get pods -n redscan
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
