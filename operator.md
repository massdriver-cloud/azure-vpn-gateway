## Azure VPN Gateway

Azure VPN Gateway is a network gateway that connects your on-premises networks to Azure through site-to-site VPNs in a secure and scalable manner, ensuring encrypted communication over the public internet.

### Design Decisions

1. **DNS Resolver**: A DNS resolver is essential for resolving DNS requests within the virtual network. The configuration includes the DNS resolver and its corresponding inbound endpoint.
2. **Certificates**: The module provides the options for two types of VPN authentication - Certificate-based authentication and Azure Active Directory (AAD) authentication. For Certificate-based authentication, certificates are generated and stored in Azure Key Vault.
3. **CIDR Allocation**: The module automatically allocates CIDR blocks for the GatewaySubnet to ensure that there is no IP address conflict within the virtual network.
4. **Scalability**: The Azure VPN Gateway is configured for scalability with options for different SKUs and generations.
5. **Automation**: The module uses automated methods to determine and assign CIDR ranges for various subnets, reducing the chance of errors.

### Runbook

#### VPN Gateway Not Connecting

If the VPN Gateway is not connecting, verify the provisioning state and connection status.

**Check VPN gateway status**

```sh
az network vnet-gateway show --name <gateway-name> --resource-group <resource-group>
```

Expected output should show `provisioningState` as `Succeeded`.

#### DNS Resolution Issues

If you are facing DNS resolution issues within the virtual network, check the status of the DNS resolver and its inbound endpoint.

**Check private DNS resolver status**

```sh
az network private-dns resovler show --name <resolver-name> --resource-group <resource-group>
```

**Check inbound endpoint status**

```sh
az network private-dns resolver inbound-endpoint show --name <inbound-endpoint-name> --resource-group <resource-group>
```

Both commands should return `provisioningState` as `Succeeded`.

#### Certificate Issues for VPN Authentication

If there are issues related to certificate-based authentication:

**List certificates in Key Vault**

Use the Azure CLI to list and verify the VPN certificates in the Key Vault.

```sh
az keyvault certificate list --vault-name <key-vault-name>
```

Verify that the certificates `vpn-root-certificate` are listed and correctly configured.

**Get certificate details**

```sh
az keyvault certificate show --vault-name <key-vault-name> --name vpn-root-certificate
```

Ensure that the certificate data is correct and has not expired.

#### VPN Client Configuration Errors

If VPN clients are unable to connect:

**Check client configuration settings in Azure**

```sh
az network vnet-gateway vpn-client show --resource-group <resource-group> --name <gateway-name>
```

**Validate VPN Configuration script output**

```sh
# Assuming you have downloaded the VPN client configuration script
bash <vpn-client-script>.sh
```

Ensure that the configuration script runs without errors and the returned configuration matches the expected settings.

#### VLAN/IP Allocation Conflicts

If there are VLAN/IP allocation conflicts:

**Check all subnets within the VNet**

```sh
az network vnet subnet list --resource-group <resource-group> --vnet-name <vnet-name>
```

Review the address prefixes for any overlaps.

**Check available CIDRs within the address space**

```sh
# Use the utility available CIDR tool provided in the module, if available
utility-available-cidr --from-cidrs <address-space> --used-cidrs <used-cidrs> --mask <mask>
```
Expected output should provide a valid, non-overlapping CIDR range.

Ensure that all subnets and address spaces are appropriately allocated without conflicts.

