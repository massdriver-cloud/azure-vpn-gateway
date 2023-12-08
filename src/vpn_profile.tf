# This is trying to generate the VPN profile for Azure. It's not working yet.

# locals {
#   profile_token_response = jsondecode(data.http.profile_token.response_body)
#   profile_token          = lookup(local.profile_token_response, "access_token", "")
# }

# data "http" "profile_token" {
#   url    = "https://login.microsoftonline.com/${var.azure_service_principal.data.tenant_id}/oauth2/token"
#   method = "POST"

#   request_body = "grant_type=Client_Credentials&client_id=${var.azure_service_principal.data.client_id}&client_secret=${var.azure_service_principal.data.client_secret}&resource=https://management.azure.com/"
# }

# data "http" "profile" {
#   url    = "https://management.azure.com/subscriptions/${var.azure_service_principal.data.subscription_id}/resourceGroups/${local.vnet_resource_group}/providers/Microsoft.Network/virtualNetworkGateways/${var.md_metadata.name_prefix}/generatevpnprofile?api-version=2023-05-01"
#   method = "POST"

#   request_headers = {
#     "Authorization" = "Bearer ${local.profile_token}"
#   }
# }

# resource "local_file" "profile" {
#   filename   = "azurevpnconfig.xml"
#   content    = data.http.profile.response_body
#   depends_on = [azurerm_virtual_network_gateway.main]
# }

# output "profile" {
#   value      = local_file.profile.content
#   depends_on = [azurerm_virtual_network_gateway.main]
# }
