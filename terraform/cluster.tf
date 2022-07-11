data "azurecaf_name" "k8s_rg" {
  name          = var.name
  resource_type = "azurerm_resource_group"
  prefixes      = [var.prefix]
  suffixes      = ["k8s"]
  random_length = 0
  clean_input   = true
}

data "azurecaf_name" "k8s_nodes_rg" {
  name          = var.name
  resource_type = "azurerm_resource_group"
  prefixes      = [var.prefix]
  suffixes      = ["k8s", "nodes"]
  random_length = 0
  clean_input   = true
}

resource "azurerm_resource_group" "k8s" {
  name     = data.azurecaf_name.k8s_rg.result
  location = var.location
}

data "azurecaf_name" "law" {
  name          = var.name
  resource_type = "azurerm_log_analytics_workspace"
  prefixes      = [var.prefix]
  random_length = 0
  clean_input   = true
}

resource "azurerm_log_analytics_workspace" "k8s" {
  name                = data.azurecaf_name.law.result
  location            = azurerm_resource_group.k8s.location
  resource_group_name = azurerm_resource_group.k8s.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

data "azurecaf_name" "k8s_cluster" {
  name          = var.name
  resource_type = "azurerm_kubernetes_cluster"
  prefixes      = [var.prefix]
  random_length = 0
  clean_input   = true
}

data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "k8s" {
  depends_on = [
    azurerm_role_assignment.kubelet_id_operator,
  ]

  name                       = data.azurecaf_name.k8s_cluster.result
  location                   = azurerm_resource_group.k8s.location
  resource_group_name        = azurerm_resource_group.k8s.name
  kubernetes_version         = var.kubernetes_version
  node_resource_group        = data.azurecaf_name.k8s_nodes_rg.result
  azure_policy_enabled       = true
  local_account_disabled     = true
  dns_prefix = var.name

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.cluster_id.id]
  }

  azure_active_directory_role_based_access_control {
    managed   = true
    tenant_id = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled = true
    admin_group_object_ids = var.aks_admin_group_ids
  }

  kubelet_identity {
    user_assigned_identity_id = azurerm_user_assigned_identity.kubelet_id.id
    client_id                 = azurerm_user_assigned_identity.kubelet_id.client_id
    object_id                 = azurerm_user_assigned_identity.kubelet_id.principal_id
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    service_cidr       = "10.0.50.0/24"
    dns_service_ip     = "10.0.50.8"
    docker_bridge_cidr = "10.0.51.0/24"
  }

  automatic_channel_upgrade = "stable"

  default_node_pool {
    name                         = "default"
    enable_auto_scaling          = true
    max_count                    = 3
    min_count                    = 1
    node_count                   = 1
    vm_size                      = var.node_size
    type                         = "VirtualMachineScaleSets"
    os_disk_type                 = "Ephemeral"
    vnet_subnet_id               = azurerm_subnet.nodes.id
    only_critical_addons_enabled = true
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.k8s.id
  }

#   Not enabled on the subs we deploy to
#   microsoft_defender {
#     log_analytics_workspace_id = azurerm_log_analytics_workspace.k8s.id
#   }

  # We don't want Terraform to apply changes as the cluster auto-scales.
  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "governess" {
  name                  = "governess"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.k8s.id
  enable_auto_scaling   = true
  max_count             = 3
  min_count             = 1
  node_count            = 1
  vm_size               = var.node_size
  os_disk_type          = "Ephemeral"
  vnet_subnet_id        = azurerm_subnet.nodes.id
  lifecycle {
    ignore_changes = [node_count]
  }
}