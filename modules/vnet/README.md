# Azure VNET Module

Reusable Terraform module for provisioning an Azure Virtual Network with subnets, Network Security Groups, and optional DDoS protection.

## Features

- Configurable address space and DNS servers
- Dynamic subnet creation with per-subnet NSG rules
- Service endpoint support per subnet
- Subnet delegation support (e.g., for App Service, Container Instances)
- Optional DDoS Protection Plan
- Consistent tagging across all resources

## Documentation

This README is auto-generated using [terraform-docs](https://terraform-docs.io/).
Run `make docs` or `terraform-docs markdown table modules/vnet --output-file README.md --output-mode inject` to regenerate.

<!-- BEGIN_TF_DOCS -->


## Usage

```hcl
module "vnet" {
  source = "../../modules/vnet"

  vnet_name           = "my-vnet"
  resource_group_name = "my-rg"
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    web = {
      address_prefixes = ["10.0.1.0/24"]
      nsg_rules        = []
    }
  }

  tags = {
    environment = "dev"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.80.0, < 5.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.80.0, < 5.0.0 |

## Resources

| Name | Type |
|------|------|
| [azurerm_network_ddos_protection_plan.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_ddos_protection_plan) | resource |
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_space"></a> [address\_space](#input\_address\_space) | List of address spaces (CIDR blocks) for the VNET. | `list(string)` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the VNET (e.g., eastus, westeurope). | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Name of the resource group where the VNET will be created. | `string` | n/a | yes |
| <a name="input_vnet_name"></a> [vnet\_name](#input\_vnet\_name) | Name of the Virtual Network. | `string` | n/a | yes |
| <a name="input_dns_servers"></a> [dns\_servers](#input\_dns\_servers) | Custom DNS servers for the VNET. Empty list uses Azure-provided DNS. | `list(string)` | `[]` | no |
| <a name="input_enable_ddos_protection"></a> [enable\_ddos\_protection](#input\_enable\_ddos\_protection) | Enable DDoS Protection Plan for the VNET. Incurs additional cost. | `bool` | `false` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Map of subnet configurations. Each subnet supports:<br/>- address\_prefixes: list of CIDR blocks<br/>- nsg\_rules: optional list of NSG rules (priority, direction, access, protocol, source/dest port ranges, source/dest address prefixes)<br/>- service\_endpoints: optional list of service endpoints (e.g., Microsoft.Storage)<br/>- delegation: optional service delegation block | <pre>map(object({<br/>    address_prefixes  = list(string)<br/>    service_endpoints = optional(list(string), [])<br/>    delegation = optional(object({<br/>      name = string<br/>      service_delegation = object({<br/>        name    = string<br/>        actions = list(string)<br/>      })<br/>    }), null)<br/>    nsg_rules = optional(list(object({<br/>      name                       = string<br/>      priority                   = number<br/>      direction                  = string<br/>      access                     = string<br/>      protocol                   = string<br/>      source_port_range          = string<br/>      destination_port_range     = string<br/>      source_address_prefix      = string<br/>      destination_address_prefix = string<br/>    })), [])<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources created by this module. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ddos_protection_plan_id"></a> [ddos\_protection\_plan\_id](#output\_ddos\_protection\_plan\_id) | The ID of the DDoS Protection Plan, if enabled. |
| <a name="output_nsg_ids"></a> [nsg\_ids](#output\_nsg\_ids) | Map of subnet names to their NSG IDs. Useful for adding additional rules or diagnostics. |
| <a name="output_subnet_address_prefixes"></a> [subnet\_address\_prefixes](#output\_subnet\_address\_prefixes) | Map of subnet names to their address prefixes. |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | Map of subnet names to their IDs. Used to attach VMs, private endpoints, and other resources to specific subnets. |
| <a name="output_vnet_address_space"></a> [vnet\_address\_space](#output\_vnet\_address\_space) | The address space of the Virtual Network. |
| <a name="output_vnet_id"></a> [vnet\_id](#output\_vnet\_id) | The ID of the Virtual Network. Used to reference the VNET in peering, private endpoints, and other resources. |
| <a name="output_vnet_name"></a> [vnet\_name](#output\_vnet\_name) | The name of the Virtual Network. |
<!-- END_TF_DOCS -->
