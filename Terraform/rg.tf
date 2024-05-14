resource "azurerm_resource_group" "rg" {
  name     = "rg-containerapps-globalazure-2024"
  location = var.location
}