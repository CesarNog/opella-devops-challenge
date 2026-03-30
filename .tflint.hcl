plugin "azurerm" {
  enabled = true
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# The azurerm ruleset's VM size list lags behind Azure; newer SKUs
# (e.g., D*als_v7) are valid but not yet recognized by the plugin.
rule "azurerm_linux_virtual_machine_invalid_size" {
  enabled = false
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}
