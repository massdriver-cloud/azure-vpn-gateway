locals {
  token_response = var.network.auto ? jsondecode(data.http.token.0.response_body) : {}
  token          = lookup(local.token_response, "access_token", "")
}

/* Gateway subnet configuration recommendations: https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-about-vpn-gateway-settings#gwsub

Recommends /27 for gateway subnet.

What this is IaC is doing is looking at subnets within the VNet to find a /27 CIDR range that isn't being used, and then using it. It's also creating a VPN address pool to associate with the VNet gateway to give IP addresses to VPN client users. The address pool isn't related to subnets, it just needs to be in a CIDR range that doesn't conflict with other VNets. */

resource "utility_available_cidr" "gateway" {
  count      = var.network.auto ? 1 : 0
  from_cidrs = data.azurerm_virtual_network.lookup.address_space
  used_cidrs = flatten([for subnet in data.azurerm_subnet.lookup : subnet.address_prefixes])
  mask       = 27
}

data "http" "token" {
  count  = var.network.auto ? 1 : 0
  url    = "https://login.microsoftonline.com/${var.azure_service_principal.data.tenant_id}/oauth2/token"
  method = "POST"

  request_body = "grant_type=Client_Credentials&client_id=${var.azure_service_principal.data.client_id}&client_secret=${var.azure_service_principal.data.client_secret}&resource=https://management.azure.com/"
}

data "http" "vnets" {
  count  = var.network.auto ? 1 : 0
  url    = "https://management.azure.com/subscriptions/${var.azure_service_principal.data.subscription_id}/providers/Microsoft.Network/virtualNetworks?api-version=2022-07-01"
  method = "GET"

  request_headers = {
    "Authorization" = "Bearer ${local.token}"
  }
}

data "jq_query" "vnet_cidrs" {
  count = var.network.auto ? 1 : 0
  data  = data.http.vnets.0.response_body
  query = "[.value[].properties.addressSpace.addressPrefixes[]]"
}

resource "utility_available_cidr" "pool" {
  count      = var.network.auto ? 1 : 0
  from_cidrs = ["10.0.0.0/8", "172.16.0.0/20", "192.168.0.0/16"]
  used_cidrs = jsondecode(data.jq_query.vnet_cidrs.0.result)
  mask       = var.network.mask
}
