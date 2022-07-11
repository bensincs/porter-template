data "azurecaf_name" "identities_rg" {
  name          = var.name
  resource_type = "azurerm_resource_group"
  prefixes      = [var.prefix]
  suffixes      = ["identities"]
  random_length = 0
  clean_input   = true
}

resource "azurerm_resource_group" "identities" {
  name     = data.azurecaf_name.identities_rg.result
  location = var.location
}

resource "azurerm_user_assigned_identity" "kubelet_id" {
  resource_group_name = azurerm_resource_group.networking.name
  location            = var.location
  name                = "${var.prefix}-msi-kubelet-${var.name}"
}

resource "azurerm_user_assigned_identity" "cluster_id" {
  resource_group_name = azurerm_resource_group.networking.name
  location            = var.location
  name                = "${var.prefix}-msi-cluster-${var.name}"
}

# Grant the cluster identity permissions to manage the kubelet managed identity.
resource "azurerm_role_assignment" "kubelet_id_operator" {
  scope                            = azurerm_user_assigned_identity.kubelet_id.id
  role_definition_name             = "Managed Identity Operator"
  principal_id                     = azurerm_user_assigned_identity.cluster_id.principal_id
  skip_service_principal_aad_check = true
}

# Assign current user permissions to the cluster
resource "azurerm_role_assignment" "k8s_rbac_cluster_admin" {
  scope                            = azurerm_kubernetes_cluster.k8s.id
  role_definition_name             = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id                     = data.azurerm_client_config.current.object_id
  skip_service_principal_aad_check = true
}