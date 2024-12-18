provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "best-approach-rg"
  location = "East US"
}

# Virtual Networks
resource "azurerm_virtual_network" "notification_service_vnet" {
  name                = "NotificationServiceVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_virtual_network" "input_service_vnet" {
  name                = "InputServiceVNet"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_virtual_network" "timeline_service_vnet" {
  name                = "TimelineServiceVNet"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_virtual_network" "search_service_vnet" {
  name                = "SearchServiceVNet"
  address_space       = ["10.3.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Transit Network (Azure Virtual Network Peering)
resource "azurerm_virtual_network_peering" "notification_to_input" {
  name                      = "NotificationToInput"
  resource_group_name       = azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.notification_service_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.input_service_vnet.id
  allow_forwarded_traffic   = true
}

# Functions (Azure Function Apps)
resource "azurerm_function_app" "analytics_function" {
  name                       = "analytics-function"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  app_service_plan_id        = azurerm_app_service_plan.main.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  app_settings = {
    FUNCTIONS_EXTENSION_VERSION = "~4"
    FUNCTION_APP_EDIT_MODE      = "readOnly"
  }
}

resource "azurerm_function_app" "compute_function" {
  name                       = "compute-function"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  app_service_plan_id        = azurerm_app_service_plan.main.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  app_settings = {
    FUNCTIONS_EXTENSION_VERSION = "~4"
    FUNCTION_APP_EDIT_MODE      = "readOnly"
  }
}

# Storage Account for Function Apps
resource "azurerm_storage_account" "main" {
  name                     = "bestapproachstorage"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# App Service Plan for Function Apps
resource "azurerm_app_service_plan" "main" {
  name                = "bestapproach-app-service-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "FunctionApp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

# Storage Account for General Data
resource "azurerm_storage_account" "data_storage" {
  name                     = "datastorageaccount"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Event Hub (Equivalent to Kinesis)
resource "azurerm_eventhub_namespace" "data_namespace" {
  name                = "dataeventhubnamespace"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
}

resource "azurerm_eventhub" "data_eventhub" {
  name                = "dataeventhub"
  namespace_name      = azurerm_eventhub_namespace.data_namespace.name
  resource_group_name = azurerm_resource_group.main.name
  partition_count     = 2
  message_retention   = 1
}

# Redis Cache
resource "azurerm_redis_cache" "main" {
  name                = "redis-cache"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  capacity            = 1
  family              = "C"
  sku_name            = "Basic"
}

# Azure Cognitive Search
resource "azurerm_search_service" "main" {
  name                = "search-service"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku {
    name     = "basic"
    capacity = 1
  }
}

output "vnet_ids" {
  value = [
    azurerm_virtual_network.notification_service_vnet.id,
    azurerm_virtual_network.input_service_vnet.id,
    azurerm_virtual_network.timeline_service_vnet.id,
    azurerm_virtual_network.search_service_vnet.id
  ]
}
