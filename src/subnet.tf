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

# Name of subnet must be GatewaySubnet or Azure VPN Gateway will not work.
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = local.vnet_resource_group
  virtual_network_name = local.vnet_name
  address_prefixes     = [utility_available_cidr.gateway[0].result]
}
