# Development Environment
environment         = "dev"
resource_group_name = "rg-redscan-dev"
static_web_app_name = "swa-redscan-dev"
key_vault_name      = "kv-redscan-dev"
storage_account_name = "stredscandevterraform"

common_tags = {
  Project     = "RedScan"
  Environment = "Development"
  ManagedBy   = "Terraform"
  Owner       = "Security-Team"
}