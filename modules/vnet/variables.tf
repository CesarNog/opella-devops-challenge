variable "vnet_name" {
  description = "Name of the Virtual Network."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]{0,62}[a-zA-Z0-9_]$", var.vnet_name))
    error_message = "VNET name must be 2-64 characters, starting with alphanumeric and containing only alphanumerics, dots, hyphens, and underscores."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where the VNET will be created."
  type        = string

  validation {
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be between 1 and 90 characters."
  }
}

variable "location" {
  description = "Azure region for the VNET (e.g., eastus, westeurope)."
  type        = string

  validation {
    condition     = can(regex("^[a-z]+[a-z0-9]*$", var.location))
    error_message = "Location must be a valid Azure region identifier (lowercase, no spaces)."
  }
}

variable "address_space" {
  description = "List of address spaces (CIDR blocks) for the VNET."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "At least one address space CIDR block is required."
  }

  validation {
    condition     = alltrue([for cidr in var.address_space : can(cidrhost(cidr, 0))])
    error_message = "Each address space entry must be a valid CIDR block."
  }
}

variable "dns_servers" {
  description = "Custom DNS servers for the VNET. Empty list uses Azure-provided DNS."
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = <<-EOT
    Map of subnet configurations. Each subnet supports:
    - address_prefixes: list of CIDR blocks
    - nsg_rules: optional list of NSG rules (priority, direction, access, protocol, source/dest port ranges, source/dest address prefixes)
    - service_endpoints: optional list of service endpoints (e.g., Microsoft.Storage)
    - delegation: optional service delegation block
  EOT
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    }), null)
    nsg_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), [])
  }))
  default = {}
}

variable "enable_ddos_protection" {
  description = "Enable DDoS Protection Plan for the VNET. Incurs additional cost."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Map of tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}
