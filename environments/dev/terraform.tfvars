environment              = "dev"
project                  = "opella"
location                 = "eastus"
vnet_address_space       = ["10.0.0.0/16"]
vm_size                  = "Standard_B1s"
vm_admin_username        = "azureadmin"
storage_account_tier     = "Standard"
storage_replication_type = "LRS"

extra_tags = {
  cost_center = "engineering"
}
