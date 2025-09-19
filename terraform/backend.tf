# Terraform Cloud Backend Configuration
# This file configures Terraform to use Terraform Cloud for remote state management

terraform {
  cloud {
    organization = "reddome"
    
    workspaces {
      tags = ["redscan"]
    }
  }
  
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Azure Provider Configuration
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Azure AD Provider Configuration
provider "azuread" {}

# Environment-specific workspace selection
# This will be automatically handled by Terraform Cloud based on branch triggers