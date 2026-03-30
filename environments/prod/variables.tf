variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)."
  type        = string
  default     = "prod"
}

variable "project" {
  description = "Project name used in resource naming and tagging."
  type        = string
  default     = "opella"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "westeurope"
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network."
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "vm_size" {
  description = "Size of the Virtual Machine."
  type        = string
  default     = "Standard_D2als_v7"
}

variable "vm_admin_username" {
  description = "Admin username for the Virtual Machine."
  type        = string
  default     = "azureadmin"
}

variable "storage_account_tier" {
  description = "Performance tier for the Storage Account."
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Replication type for the Storage Account."
  type        = string
  default     = "GRS"
}

variable "extra_tags" {
  description = "Additional tags to merge with default tags."
  type        = map(string)
  default     = {}
}
