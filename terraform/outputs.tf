# Static Web App Outputs
output "static_web_app_url" {
  description = "URL of the deployed Static Web App"
  value       = "https://${azurerm_static_site.redscan_app.default_host_name}"
}

output "static_web_app_id" {
  description = "ID of the Static Web App"
  value       = azurerm_static_site.redscan_app.id
}

output "static_web_app_api_key" {
  description = "API key for Static Web App deployment"
  value       = azurerm_static_site.redscan_app.api_key
  sensitive   = true
}

# CDN Outputs
output "cdn_endpoint_url" {
  description = "CDN endpoint URL"
  value       = "https://${azurerm_cdn_endpoint.redscan.fqdn}"
}

# Key Vault Outputs
output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.redscan.vault_uri
}

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.redscan.id
}

# Application Insights
output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.redscan.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.redscan.connection_string
  sensitive   = true
}

# Resource Group
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.redscan.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.redscan.location
}

# Storage Account
output "terraform_state_storage_account" {
  description = "Storage account name for Terraform state"
  value       = azurerm_storage_account.terraform_state.name
}

output "terraform_state_container" {
  description = "Container name for Terraform state"
  value       = azurerm_storage_container.terraform_state.name
}