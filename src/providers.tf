terraform {
  required_version = ">= 1.0"
  required_providers {
    massdriver = {
      source  = "massdriver-cloud/massdriver"
      version = "~> 1.0"
    }
    utility = {
      source = "massdriver-cloud/utility"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    jq = {
      source  = "massdriver-cloud/jq"
      version = "~> 0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}

  client_id       = var.azure_authentication.client_id
  tenant_id       = var.azure_authentication.tenant_id
  client_secret   = var.azure_authentication.client_secret
  subscription_id = var.azure_authentication.subscription_id
}
