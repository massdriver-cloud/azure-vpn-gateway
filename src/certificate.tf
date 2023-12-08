locals {
  max_length        = 24
  alphanumeric_name = substr(replace(var.md_metadata.name_prefix, "/[^a-z0-9]/", ""), 0, local.max_length)
}

resource "azurerm_resource_group" "certificate" {
  count    = var.gateway.auth_type == "Certificate" ? 1 : 0
  name     = var.md_metadata.name_prefix
  location = var.azure_virtual_network.specs.azure.region
  tags     = var.md_metadata.default_tags
}

data "azurerm_client_config" "certificate" {
  count = var.gateway.auth_type == "Certificate" ? 1 : 0
}

resource "azurerm_key_vault" "certificate" {
  count                           = var.gateway.auth_type == "Certificate" ? 1 : 0
  name                            = local.alphanumeric_name
  resource_group_name             = azurerm_resource_group.certificate[0].name
  location                        = var.azure_virtual_network.specs.azure.region
  sku_name                        = "standard"
  public_network_access_enabled   = true
  purge_protection_enabled        = true
  soft_delete_retention_days      = 7
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  tenant_id                       = var.azure_service_principal.data.tenant_id
  tags                            = var.md_metadata.default_tags

  access_policy {
    tenant_id = var.azure_service_principal.data.tenant_id
    object_id = data.azurerm_client_config.certificate[0].object_id

    certificate_permissions = [
      "Get",
      "List",
      "Create",
      "Import",
      "Update",
      "Delete",
      "Recover",
      "Restore"
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set"
    ]
  }


  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

resource "azurerm_key_vault_certificate" "certificate" {
  count        = var.gateway.auth_type == "Certificate" ? 1 : 0
  name         = "vpn-root-certificate"
  key_vault_id = azurerm_key_vault.certificate[0].id
  tags         = var.md_metadata.default_tags

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_type   = "RSA"
      key_size   = 2048
      reuse_key  = false
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pem-file"
    }

    x509_certificate_properties {
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject            = "CN=VPN Root Certificate"
      validity_in_months = 12
    }
  }
  depends_on = [azurerm_key_vault.certificate]
}
