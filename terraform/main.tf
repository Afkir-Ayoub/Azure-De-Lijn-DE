data "azurerm_client_config" "current" {} # info about current Azure user

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "data_lake" {
  name                     = "st${var.prefix}datalake"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

resource "azurerm_key_vault" "main" {
  name                = "kv-${var.prefix}-main"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete"
    ]
  }
}

resource "azurerm_databricks_workspace" "main" {
  name                        = "dbw-${var.prefix}-main"
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  sku                         = "standard"
  managed_resource_group_name = "rg-${var.prefix}-main-managed" # name for the secondary resource group managed by Databricks
}

resource "azurerm_storage_account" "function_app" {
  name                     = "st${var.prefix}functions"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "main" {
  name                = "plan-${var.prefix}-platform"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1" # "Y1" = Consumption (serverless & pay-per-use) tier
}

resource "azurerm_linux_function_app" "main" {
  name                = "func-${var.prefix}-ingestion"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  storage_account_name       = azurerm_storage_account.function_app.name
  storage_account_access_key = azurerm_storage_account.function_app.primary_access_key
  service_plan_id            = azurerm_service_plan.main.id

  site_config {
    application_stack {
      python_version = "3.12"
    }
  }

  identity {
    type = "SystemAssigned" # enables Managed Identity to give Function App its own identity in Azure AD
  }
}
