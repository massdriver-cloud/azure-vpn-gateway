# resource "massdriver_artifact" "xml" {
#   field                = "xml"
#   provider_resource_id = azurerm_virtual_network_gateway.main.id
#   name                 = "Azure VPN Configuration Profile for ${var.md_metadata.name_prefix}"
#   artifact = jsonencode(
#     {
#       # data = {
#       #   # This should match the aws-rds-arn.json schema file
#       #   arn = "aws::..."
#       # }
#       # specs = {
#       #   # Any existing spec in ./specs
#       #   # aws = {}
#       # }
#     }
#   )
# }
