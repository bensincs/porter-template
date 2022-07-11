resource "azurecaf_name" "networking_rg" {
  name          = var.name
  resource_type = "azurerm_resource_group"
  prefixes      = [var.prefix]
  suffixes      = ["networking"]
  random_length = 0
  clean_input   = true
}

resource "azurerm_resource_group" "networking" {
  name     = azurecaf_name.networking_rg.result
  location = var.location
}

resource "azurecaf_name" "vnet" {
  name          = var.name
  resource_type = "azurerm_virtual_network"
  prefixes      = [var.prefix]
  random_length = 0
  clean_input   = true
}

resource "azurerm_virtual_network" "networking" {
  name                = azurecaf_name.vnet.result
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.networking.location
  resource_group_name = azurerm_resource_group.networking.name
}

resource "azurecaf_name" "node_subnet" {
  name          = var.name
  resource_type = "azurerm_subnet"
  prefixes      = [var.prefix]
  suffixes      = ["nodes"]
  random_length = 0
  clean_input   = true
}

resource "azurerm_subnet" "nodes" {
  name                 = azurecaf_name.node_subnet.result
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.networking.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurecaf_name" "endpoints_subnet" {
  name          = var.name
  resource_type = "azurerm_subnet"
  prefixes      = [var.prefix]
  suffixes      = ["endpoints"]
  random_length = 0
  clean_input   = true
}

resource "azurerm_subnet" "endpoints" {
  name                                           = azurecaf_name.endpoints_subnet.result
  resource_group_name                            = azurerm_resource_group.networking.name
  virtual_network_name                           = azurerm_virtual_network.networking.name
  address_prefixes                               = ["10.0.3.0/24"]
  enforce_private_link_endpoint_network_policies = true
}