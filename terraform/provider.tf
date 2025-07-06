terraform {
  backend "azurerm" {
    resource_group_name  = "De-Lijn-platform"
    storage_account_name = "delijntfstate"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate" # state file name
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}