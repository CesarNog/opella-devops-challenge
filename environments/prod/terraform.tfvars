environment              = "prod"
project                  = "opella"
location                 = "westeurope"
vnet_address_space       = ["10.1.0.0/16"]
vm_size                  = "Standard_D2als_v7"
vm_admin_username        = "azureadmin"
storage_account_tier     = "Standard"
storage_replication_type = "GRS"

extra_tags = {
  cost_center = "production"
  compliance  = "soc2"
}
