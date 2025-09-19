# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "redscan"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

# Azure Configuration
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US 2"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "rg-redscan-prod"
}

# Azure Service Principal Configuration
# Note: These values should be set as environment variables in Terraform Cloud:
# - ARM_CLIENT_ID
# - ARM_CLIENT_SECRET  
# - ARM_SUBSCRIPTION_ID
# - ARM_TENANT_ID
# Do not set default values here for security reasons

# Static Web App Configuration
variable "static_web_app_name" {
  description = "Name of the Azure Static Web App"
  type        = string
  default     = "swa-redscan-prod"
}

variable "static_web_app_location" {
  description = "Location for Azure Static Web App"
  type        = string
  default     = "East US 2"
}

variable "static_web_app_sku" {
  description = "SKU for Azure Static Web App"
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard"], var.static_web_app_sku)
    error_message = "SKU must be either 'Free' or 'Standard'."
  }
}

# Storage Account Configuration
variable "storage_account_name" {
  description = "Name of the storage account for Terraform state"
  type        = string
  default     = "stredscanterraform"
}

# Key Vault Configuration
variable "key_vault_name" {
  description = "Name of the Azure Key Vault"
  type        = string
  default     = "kv-redscan-prod"
}

# Custom Domain (optional)
variable "custom_domain" {
  description = "Custom domain for the application"
  type        = string
  default     = ""
}

# API Keys (sensitive)
variable "groq_api_key" {
  description = "Groq API key for AI services"
  type        = string
  default     = ""
  sensitive   = true
}

variable "openrouter_api_key" {
  description = "OpenRouter API key for AI services"
  type        = string
  default     = ""
  sensitive   = true
}

variable "google_ai_studio_key" {
  description = "Google AI Studio API key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "together_api_key" {
  description = "Together AI API key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "huggingface_token" {
  description = "Hugging Face API token"
  type        = string
  default     = ""
  sensitive   = true
}

# Common Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "RedScan"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Owner       = "Security-Team"
  }
}

# GitHub Configuration
variable "github_repo_url" {
  description = "GitHub repository URL"
  type        = string
  default     = ""
}

variable "github_branch" {
  description = "GitHub branch for deployment"
  type        = string
  default     = "main"
}