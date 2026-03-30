locals {
  subnets_with_nsg = {
    for name, subnet in var.subnets : name => subnet
    if length(subnet.nsg_rules) > 0
  }
}

# --- Virtual Network ---

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  tags = var.tags
}

# --- DDoS Protection Plan (optional) ---

resource "azurerm_network_ddos_protection_plan" "this" {
  count = var.enable_ddos_protection ? 1 : 0

  name                = "${var.vnet_name}-ddos-plan"
  resource_group_name = var.resource_group_name
  location            = var.location

  tags = var.tags
}

# --- Subnets ---

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = each.value.address_prefixes
  service_endpoints    = each.value.service_endpoints

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

# --- Network Security Groups (one per subnet that defines rules) ---

resource "azurerm_network_security_group" "this" {
  for_each = local.subnets_with_nsg

  name                = "${var.vnet_name}-${each.key}-nsg"
  resource_group_name = var.resource_group_name
  location            = var.location

  dynamic "security_rule" {
    for_each = each.value.nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = local.subnets_with_nsg

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
