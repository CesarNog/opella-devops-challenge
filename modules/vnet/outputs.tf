output "vnet_id" {
  description = "The ID of the Virtual Network. Used to reference the VNET in peering, private endpoints, and other resources."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "The name of the Virtual Network."
  value       = azurerm_virtual_network.this.name
}

output "vnet_address_space" {
  description = "The address space of the Virtual Network."
  value       = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  description = "Map of subnet names to their IDs. Used to attach VMs, private endpoints, and other resources to specific subnets."
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}

output "subnet_address_prefixes" {
  description = "Map of subnet names to their address prefixes."
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.address_prefixes }
}

output "nsg_ids" {
  description = "Map of subnet names to their NSG IDs. Useful for adding additional rules or diagnostics."
  value       = { for name, nsg in azurerm_network_security_group.this : name => nsg.id }
}

output "ddos_protection_plan_id" {
  description = "The ID of the DDoS Protection Plan, if enabled."
  value       = var.enable_ddos_protection ? azurerm_network_ddos_protection_plan.this[0].id : null
}
