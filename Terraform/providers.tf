
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.99.0"
    }
  }


  backend "azurerm" {
     resource_group_name  = "demos006"  
     storage_account_name = "demotfstatedemos006"
     container_name       = "tfstate"
     key                  = "globalazure.tfstate"
     subscription_id      = ""
  }
}

provider "azurerm" {
  features {}
  //skip_provider_registration = true
}
