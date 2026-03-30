locals {
  name_prefix = "${var.project}-${var.environment}-${var.location}"

  # Enforce a standard set of tags on every resource. The merge order ensures
  # default tags can be overridden by extra_tags when needed.
  common_tags = merge(
    {
      environment = var.environment
      project     = var.project
      region      = var.location
      managed_by  = "terraform"
    },
    var.extra_tags,
  )

  # Flatten location for storage account naming (max 24 chars, lowercase alphanumeric only)
  storage_account_name = substr(
    replace("${var.project}sa${var.environment}${var.location}", "-", ""),
    0,
    24,
  )
}

data "azurerm_client_config" "current" {}

# ---------------------------------------------------------------------------
# Resource Group
# ---------------------------------------------------------------------------
# Using resource groups (rather than subscriptions) per environment because:
# 1. Lower operational overhead -- no cross-subscription IAM or billing setup
# 2. Sufficient isolation for dev/prod at this project scale
# 3. Easy to promote to subscription-per-env later if the org grows
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "this" {
  name     = "${local.name_prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

# ---------------------------------------------------------------------------
# Networking -- VNET Module
# ---------------------------------------------------------------------------

module "vnet" {
  source = "../../modules/vnet"

  vnet_name           = "${local.name_prefix}-vnet"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = var.vnet_address_space

  subnets = {
    compute = {
      address_prefixes = ["10.0.1.0/24"]
      nsg_rules = [
        {
          name                       = "allow-ssh"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "22"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "deny-all-inbound"
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
      ]
    }

    storage = {
      address_prefixes  = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
      nsg_rules = [
        {
          name                       = "deny-all-inbound"
          priority                   = 4096
          direction                  = "Inbound"
          access                     = "Deny"
          protocol                   = "*"
          source_port_range          = "*"
          destination_port_range     = "*"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
      ]
    }
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Virtual Machine (Linux)
# ---------------------------------------------------------------------------

resource "tls_private_key" "vm" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_public_ip" "vm" {
  name                = "${local.name_prefix}-vm-pip"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_network_interface" "vm" {
  name                = "${local.name_prefix}-vm-nic"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.vnet.subnet_ids["compute"]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }

  tags = local.common_tags
}

resource "azurerm_linux_virtual_machine" "this" {
  name                            = "${local.name_prefix}-vm"
  resource_group_name             = azurerm_resource_group.this.name
  location                        = var.location
  size                            = var.vm_size
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.vm.id]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = tls_private_key.vm.public_key_openssh
  }

  os_disk {
    name                 = "${local.name_prefix}-vm-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Storage Account + Blob Container
# ---------------------------------------------------------------------------

resource "azurerm_storage_account" "this" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [module.vnet.subnet_ids["storage"]]
    bypass                     = ["AzureServices"]
  }

  tags = local.common_tags
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

# ---------------------------------------------------------------------------
# Key Vault -- secure secret storage for the environment
# ---------------------------------------------------------------------------

resource "azurerm_key_vault" "this" {
  name                        = substr("${var.project}-kv-${var.environment}-${var.location}", 0, 24)
  resource_group_name         = azurerm_resource_group.this.name
  location                    = var.location
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  enable_rbac_authorization   = true
  enabled_for_disk_encryption = true

  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [module.vnet.subnet_ids["storage"]]
  }

  tags = local.common_tags
}

# Store the VM SSH private key in Key Vault
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "vm_ssh_key" {
  name         = "${local.name_prefix}-vm-ssh-private-key"
  value        = tls_private_key.vm.private_key_pem
  key_vault_id = azurerm_key_vault.this.id

  depends_on = [azurerm_role_assignment.kv_admin]
}
