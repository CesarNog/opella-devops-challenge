terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "test" {
  name     = "test-basic-vnet-rg"
  location = "eastus"
}

module "vnet" {
  source = "../../../"

  vnet_name           = "test-basic-vnet"
  resource_group_name = azurerm_resource_group.test.name
  location            = azurerm_resource_group.test.location
  address_space       = ["10.0.0.0/16"]

  subnets = {
    web = {
      address_prefixes = ["10.0.1.0/24"]
    }
    app = {
      address_prefixes = ["10.0.2.0/24"]
    }
  }

  tags = {
    environment = "test"
    managed_by  = "terratest"
  }
}

output "vnet_name" {
  value = module.vnet.vnet_name
}

output "vnet_id" {
  value = module.vnet.vnet_id
}

output "subnet_ids" {
  value = module.vnet.subnet_ids
}
