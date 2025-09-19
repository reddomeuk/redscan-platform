# Production Environment
environment         = "prod"
resource_group_name = "rg-redscan-prod"
static_web_app_name = "swa-redscan-prod"
key_vault_name      = "kv-redscan-prod"
storage_account_name = "stredscanprodterraform"
static_web_app_sku  = "Standard"

common_tags = {
  Project     = "RedScan"
  Environment = "Production"
  ManagedBy   = "Terraform"
  Owner       = "Security-Team"
  CostCenter  = "Security"
}