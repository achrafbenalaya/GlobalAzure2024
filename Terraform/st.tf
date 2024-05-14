resource "azurerm_storage_account" "storage" {
  name                     = "acaglobalazure2024"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}


resource "azurerm_storage_share" "file_share" {
  name                 = "acafileshare"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = 5
}