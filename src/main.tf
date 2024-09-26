locals {
  split_vnet_id       = split("/", var.azure_virtual_network.data.infrastructure.id)
  vnet_name           = element(local.split_vnet_id, length(local.split_vnet_id) - 1)
  vnet_resource_group = element(local.split_vnet_id, index(local.split_vnet_id, "resourceGroups") + 1)
  pool_cidr           = var.network.auto ? utility_available_cidr.pool[0].result : var.network.pool_cidr
}

resource "azurerm_public_ip" "main" {
  name                = var.md_metadata.name_prefix
  resource_group_name = local.vnet_resource_group
  location            = var.azure_virtual_network.specs.azure.region
  allocation_method   = "Static"
  sku                 = "Standard"
  sku_tier            = "Regional"
  tags                = var.md_metadata.default_tags
}

resource "azurerm_virtual_network_gateway" "main" {
  name                       = var.md_metadata.name_prefix
  resource_group_name        = local.vnet_resource_group
  location                   = var.azure_virtual_network.specs.azure.region
  sku                        = var.gateway.sku
  generation                 = var.gateway.generation
  private_ip_address_enabled = true
  type                       = "Vpn"
  vpn_type                   = "RouteBased"
  tags                       = var.md_metadata.default_tags

  ip_configuration {
    subnet_id                     = azurerm_subnet.gateway.id
    public_ip_address_id          = azurerm_public_ip.main.id
    private_ip_address_allocation = "Dynamic"
  }

  dynamic "vpn_client_configuration" {
    for_each = var.gateway.auth_type == "Certificate" ? toset(["Certificate"]) : []
    content {
      address_space        = [local.pool_cidr]
      vpn_auth_types       = ["Certificate"]
      vpn_client_protocols = ["IkeV2", "OpenVPN"]
      root_certificate {
        name             = "VpnRootCertificate"
        public_cert_data = base64encode(tls_self_signed_cert.root_certificate[0].cert_pem)
      }
    }
  }

  dynamic "vpn_client_configuration" {
    for_each = var.gateway.auth_type == "AAD" ? toset(["AAD"]) : []
    content {
      address_space        = [local.pool_cidr]
      vpn_auth_types       = ["AAD"]
      vpn_client_protocols = ["OpenVPN"]
      aad_tenant           = "https://login.microsoftonline.com/${var.azure_service_principal.data.tenant_id}/"
      # This is the audience Client ID for the Azure VPN App
      aad_audience = "41b23e61-6c1e-4545-b367-cd054e0ed4b4"
      aad_issuer   = "https://sts.windows.net/${var.azure_service_principal.data.tenant_id}/"
    }
  }
}
