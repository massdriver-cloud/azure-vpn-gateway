locals {
  token_response = var.network.auto ? jsondecode(data.http.token.0.response_body) : {}
  token          = lookup(local.token_response, "access_token", "")
}

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
