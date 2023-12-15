locals {
  split_vnet_id       = split("/", var.azure_virtual_network.data.infrastructure.id)
  vnet_name           = element(local.split_vnet_id, length(local.split_vnet_id) - 1)
  vnet_resource_group = element(local.split_vnet_id, index(local.split_vnet_id, "resourceGroups") + 1)
}

data "azurerm_virtual_network" "lookup" {
  name                = local.vnet_name
  resource_group_name = local.vnet_resource_group
}

data "azurerm_subnet" "lookup" {
  for_each             = toset(data.azurerm_virtual_network.lookup.subnets)
  name                 = each.key
  virtual_network_name = local.vnet_name
  resource_group_name  = local.vnet_resource_group
}

resource "utility_available_cidr" "dns_resolver" {
  from_cidrs = data.azurerm_virtual_network.lookup.address_space
  used_cidrs = flatten([for subnet in data.azurerm_subnet.lookup : subnet.address_prefixes])
  mask       = 28
}

# DNS resolver is required as this is the component that resolves DNS requests.
# Without this, only way to connect to resources is using private IP address.
# https://learn.microsoft.com/en-us/azure/architecture/example-scenario/networking/azure-dns-private-resolver

resource "azurerm_private_dns_resolver" "dns_resolver" {
  name                = var.md_metadata.name_prefix
  resource_group_name = local.vnet_resource_group
  location            = var.azure_virtual_network.specs.azure.region
  virtual_network_id  = var.azure_virtual_network.data.infrastructure.id
  tags                = var.md_metadata.default_tags
}

resource "azurerm_subnet" "dns_resolver" {
  name                 = "inbounddns"
  resource_group_name  = local.vnet_resource_group
  virtual_network_name = local.vnet_name
  address_prefixes     = [utility_available_cidr.dns_resolver.result]

  delegation {
    name = "Microsoft.Network.dnsResolvers"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
      name    = "Microsoft.Network/dnsResolvers"
    }
  }
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "dns_resolver" {
  name                    = "${var.md_metadata.name_prefix}-inbounddns"
  private_dns_resolver_id = azurerm_private_dns_resolver.dns_resolver.id
  location                = var.azure_virtual_network.specs.azure.region
  tags                    = var.md_metadata.default_tags

  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.dns_resolver.id
  }
}
