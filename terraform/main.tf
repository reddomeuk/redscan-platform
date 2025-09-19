# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "redscan" {
  name     = var.resource_group_name
  location = var.location

  tags = var.common_tags
}

# Storage Account for Terraform State (Not needed with Terraform Cloud)
# resource "azurerm_storage_account" "terraform_state" {
#   name                     = var.storage_account_name
#   resource_group_name      = azurerm_resource_group.redscan.name
#   location                = azurerm_resource_group.redscan.location
#   account_tier             = "Standard"
#   account_replication_type = "LRS"
#   
#   blob_properties {
#     versioning_enabled = true
#   }
#
#   tags = var.common_tags
# }

# resource "azurerm_storage_container" "terraform_state" {
#   name                  = "terraform-state"
#   storage_account_name  = azurerm_storage_account.terraform_state.name
#   container_access_type = "private"
# }

# Static Web App
resource "azurerm_static_site" "redscan_app" {
  name                = var.static_web_app_name
  resource_group_name = azurerm_resource_group.redscan.name
  location           = var.static_web_app_location
  sku_tier           = var.static_web_app_sku
  sku_size           = var.static_web_app_sku

  tags = var.common_tags
}

# Custom Domain (optional)
resource "azurerm_static_site_custom_domain" "redscan_domain" {
  count           = var.custom_domain != "" ? 1 : 0
  static_site_id  = azurerm_static_site.redscan_app.id
  domain_name     = var.custom_domain
  validation_type = "cname-delegation"
}

# Application Insights for monitoring
resource "azurerm_application_insights" "redscan" {
  name                = "${var.static_web_app_name}-insights"
  location            = azurerm_resource_group.redscan.location
  resource_group_name = azurerm_resource_group.redscan.name
  application_type    = "web"
  retention_in_days   = 90

  tags = var.common_tags
}

# Key Vault for secrets management
resource "azurerm_key_vault" "redscan" {
  name                = var.key_vault_name
  location            = azurerm_resource_group.redscan.location
  resource_group_name = azurerm_resource_group.redscan.name
  tenant_id          = data.azurerm_client_config.current.tenant_id
  sku_name           = "standard"

  purge_protection_enabled = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]
  }

  tags = var.common_tags
}

# Store API keys in Key Vault
resource "azurerm_key_vault_secret" "groq_api_key" {
  count        = var.groq_api_key != "" ? 1 : 0
  name         = "groq-api-key"
  value        = var.groq_api_key
  key_vault_id = azurerm_key_vault.redscan.id
}

resource "azurerm_key_vault_secret" "openrouter_api_key" {
  count        = var.openrouter_api_key != "" ? 1 : 0
  name         = "openrouter-api-key"
  value        = var.openrouter_api_key
  key_vault_id = azurerm_key_vault.redscan.id
}

resource "azurerm_key_vault_secret" "google_ai_key" {
  count        = var.google_ai_studio_key != "" ? 1 : 0
  name         = "google-ai-studio-key"
  value        = var.google_ai_studio_key
  key_vault_id = azurerm_key_vault.redscan.id
}

# CDN Profile for global distribution
resource "azurerm_cdn_profile" "redscan" {
  name                = "${var.static_web_app_name}-cdn"
  location            = azurerm_resource_group.redscan.location
  resource_group_name = azurerm_resource_group.redscan.name
  sku                = "Standard_Microsoft"

  tags = var.common_tags
}

resource "azurerm_cdn_endpoint" "redscan" {
  name                = "${var.static_web_app_name}-endpoint"
  profile_name        = azurerm_cdn_profile.redscan.name
  location            = azurerm_resource_group.redscan.location
  resource_group_name = azurerm_resource_group.redscan.name

  origin {
    name      = "primary"
    host_name = azurerm_static_site.redscan_app.default_host_name
  }

  optimization_type = "GeneralWebDelivery"

  # Security headers
  delivery_rule {
    name  = "security-headers"
    order = 1

    request_uri_condition {
      operator     = "Any"
      match_values = []
    }

    modify_response_header_action {
      action = "Append"
      name   = "X-Content-Type-Options"
      value  = "nosniff"
    }

    modify_response_header_action {
      action = "Append" 
      name   = "X-Frame-Options"
      value  = "DENY"
    }

    modify_response_header_action {
      action = "Append"
      name   = "X-XSS-Protection" 
      value  = "1; mode=block"
    }

    modify_response_header_action {
      action = "Append"
      name   = "Strict-Transport-Security"
      value  = "max-age=31536000; includeSubDomains"
    }
  }

  tags = var.common_tags
}