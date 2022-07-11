terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.13.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "=2.0.0-preview-3"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "=2.24.0"
    }
  }
  backend "azurerm" {
    key = "terraform.tfstate"
  }
}

provider "azurecaf" {
  # Configuration options
}

provider "azuread" {
  # Configuration options
}
provider "azurerm" {
  # Configuration options
  features {
  }
}

variable "location" {
  type = string
}

variable "name" {
  type = string
  default = "porter"
}

variable "prefix" {
  type = string
  default = "bendev"
}

variable "kubernetes_version" {
  type     = string
  default  = "1.23.5"
}

variable "aks_admin_group_ids" {
  description = "The object identifiers of the AAD groups that will have admin permissions on the AKS Cluster"
  type        = list(string)
  default     = []
}

variable "node_size" {
  description = "The size of the node VMs in the node pool."
  default     = "Standard_D4ds_v4"
  type        = string
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.k8s.name
}

output "cluster_resource_group_name" {
  value = azurerm_resource_group.k8s.name
}