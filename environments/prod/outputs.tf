output "resource_group_name" {
  description = "Name of the resource group."
  value       = azurerm_resource_group.this.name
}

output "vnet_id" {
  description = "ID of the Virtual Network."
  value       = module.vnet.vnet_id
}

output "vnet_name" {
  description = "Name of the Virtual Network."
  value       = module.vnet.vnet_name
}

output "subnet_ids" {
  description = "Map of subnet names to IDs."
  value       = module.vnet.subnet_ids
}

output "vm_private_ip" {
  description = "Private IP address of the Virtual Machine."
  value       = azurerm_network_interface.vm.private_ip_address
}

output "storage_account_name" {
  description = "Name of the Storage Account."
  value       = azurerm_storage_account.this.name
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint URL for the Storage Account."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "key_vault_uri" {
  description = "URI of the Key Vault."
  value       = azurerm_key_vault.this.vault_uri
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault."
  value       = azurerm_key_vault.this.id
}
