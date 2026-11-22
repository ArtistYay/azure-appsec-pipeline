# tflint catches things terraform validate doesn't: unused variables, missing types,
# deprecated syntax, and (with the azurerm plugin) invalid Azure values like SKU names.
config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "azurerm" {
  enabled = true
  version = "0.33.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}
