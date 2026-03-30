package terraform

import rego.v1

# Deny resources without required tags
deny contains msg if {
	resource := input.planned_values.root_module.resources[_]
	resource.type != "tls_private_key"
	resource.type != "azurerm_role_assignment"
	resource.type != "azurerm_subnet_network_security_group_association"
	resource.type != "azurerm_storage_container"
	resource.type != "azurerm_key_vault_secret"
	resource.type != "azurerm_subnet"
	tags := object.get(resource.values, "tags", {})
	required := {"environment", "project", "managed_by"}
	missing := required - {key | tags[key]}
	count(missing) > 0
	msg := sprintf("%s '%s' is missing required tags: %v", [resource.type, resource.name, missing])
}

# Deny storage accounts without TLS 1.2
deny contains msg if {
	resource := input.planned_values.root_module.resources[_]
	resource.type == "azurerm_storage_account"
	resource.values.min_tls_version != "TLS1_2"
	msg := sprintf("Storage account '%s' must enforce TLS 1.2 minimum", [resource.name])
}

# Deny storage accounts with public blob access
deny contains msg if {
	resource := input.planned_values.root_module.resources[_]
	resource.type == "azurerm_storage_account"
	resource.values.allow_nested_items_to_be_public == true
	msg := sprintf("Storage account '%s' must not allow public blob access", [resource.name])
}

# Deny VMs with password authentication enabled
deny contains msg if {
	resource := input.planned_values.root_module.resources[_]
	resource.type == "azurerm_linux_virtual_machine"
	resource.values.disable_password_authentication != true
	msg := sprintf("VM '%s' must disable password authentication", [resource.name])
}

# Deny Key Vaults without RBAC authorization
deny contains msg if {
	resource := input.planned_values.root_module.resources[_]
	resource.type == "azurerm_key_vault"
	resource.values.enable_rbac_authorization != true
	msg := sprintf("Key Vault '%s' must use RBAC authorization", [resource.name])
}

# Warn on storage accounts without network rules
warn contains msg if {
	resource := input.planned_values.root_module.resources[_]
	resource.type == "azurerm_storage_account"
	rules := object.get(resource.values, "network_rules", [])
	count(rules) == 0
	msg := sprintf("Storage account '%s' has no network rules configured", [resource.name])
}
