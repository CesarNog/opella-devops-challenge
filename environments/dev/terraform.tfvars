environment              = "dev"
project                  = "opella"
location                 = "eastus2"
vnet_address_space       = ["10.0.0.0/16"]
vm_size                  = "Standard_D2als_v7"
vm_admin_username        = "azureadmin"
storage_account_tier     = "Standard"
storage_replication_type = "LRS"

extra_tags = {
  cost_center = "engineering"
}
