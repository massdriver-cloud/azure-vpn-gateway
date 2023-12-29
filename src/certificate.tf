locals {
  max_length        = 24
  alphanumeric_name = substr(replace(var.md_metadata.name_prefix, "/[^a-z0-9]/", ""), 0, local.max_length)
}

# This is trying to generate the certificates needed for Azure VPN. Not quite working yet.
# Still trying to figure out how to create the certificate pair for public/private key.
# Also need to figure out a way to make the certificates downloadable through the artifact.

resource "azurerm_resource_group" "certificate" {
  count    = var.gateway.auth_type == "Certificate" ? 1 : 0
  name     = var.md_metadata.name_prefix
  location = var.azure_virtual_network.specs.azure.region
  tags     = var.md_metadata.default_tags
}

data "azurerm_client_config" "certificate" {
  count = var.gateway.auth_type == "Certificate" ? 1 : 0
}

resource "tls_private_key" "root_certificate" {
  count     = var.gateway.auth_type == "Certificate" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "root_certificate" {
  count                 = var.gateway.auth_type == "Certificate" ? 1 : 0
  private_key_pem       = file(tls_private_key.root_certificate[0].private_key_pem)
  is_ca_certificate     = true
  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "code_signing",
    "server_auth",
    "client_auth",
    "digital_signature",
    "key_encipherment",
  ]
}

# resource "local_file" "ca-certificate" {
#   count           = var.gateway.auth_type == "Certificate" ? 1 : 0
#   content         = tls_self_signed_cert.root_certificate.cert_pem
#   filename        = "./certificates/ca.pem"
#   file_permission = "0666"
# }

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

  certificate {
    contents = tls_self_signed_cert.root_certificate[0].cert_pem
  }

  # certificate_policy {
  #   issuer_parameters {
  #     name = "Self"
  #   }

  #   key_properties {
  #     exportable = true
  #     key_type   = "RSA"
  #     key_size   = 2048
  #     reuse_key  = false
  #   }

  #   lifetime_action {
  #     action {
  #       action_type = "AutoRenew"
  #     }

  #     trigger {
  #       days_before_expiry = 30
  #     }
  #   }

  #   secret_properties {
  #     content_type = "application/x-pem-file"
  #   }

  #   x509_certificate_properties {
  #     extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

  #     key_usage = [
  #       "cRLSign",
  #       "dataEncipherment",
  #       "digitalSignature",
  #       "keyAgreement",
  #       "keyCertSign",
  #       "keyEncipherment",
  #     ]

  #     subject            = "CN=RootCertificate"
  #     validity_in_months = 12
  #   }
  # }
  depends_on = [azurerm_key_vault.certificate]
}

resource "tls_cert_request" "client_certificate" {
  count           = var.gateway.auth_type == "Certificate" ? 1 : 0
  private_key_pem = azurerm_key_vault_certificate.certificate[0].certificate_data_base64
}

resource "tls_locally_signed_cert" "client_certificate" {
  count                 = var.gateway.auth_type == "Certificate" ? 1 : 0
  cert_request_pem      = tls_cert_request.client_certificate[0].cert_request_pem
  ca_private_key_pem    = azurerm_key_vault_certificate.certificate[0].certificate_data_base64
  ca_cert_pem           = tls_self_signed_cert.root_certificate[0].cert_pem
  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "client_auth"
  ]
}
