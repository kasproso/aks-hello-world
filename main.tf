# Terraform Azure AKS and IIS example project


provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "example-rg"
  location = "eastus"
}

resource "azurerm_container_registry" "acr" {
  name                = "acr-example"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  admin_enabled       = true
}

resource "azurerm_virtual_network" "vnet" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-example"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  dns_prefix                = "aks-example"
  kubernetes_version        = "1.19.9"
  node_resource_group       = "aks-node-rg"
  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
  }

  service_principal {
    client_id     = var.sp_client_id
    client_secret = var.sp_client_secret
  }

  agent_pool_profile {
    name            = "default"
    count           = 1
    vm_size         = "Standard_B2s"
    os_type         = "Windows"
    vnet_subnet_id  = azurerm_subnet.subnet.id
    availability_zones = [1, 2, 3]
    node_labels = {
      "beta.kubernetes.io/os" = "windows"
    }
  }
  
  kubelet_config {
      enable_custom_metrics = true
      "--windows-allowprivilegeescalation" = "false"
    }

  depends_on = [
    azurerm_container_registry.acr,
    azurerm_subnet.subnet
  ]
}

data "azurerm_container_registry" "acr_admin_creds" {
  name                = azurerm_container_registry.acr.name
  resource_group_name = azurerm_resource_group.rg.name
}

# Docker image build and push to Container Registry
resource "null_resource" "build_and_push" {
  provisioner "local-exec" {
    command = "docker build -t ${azurerm_container_registry.acr.login_server}/iis-hello-world:v1 ./iis-hello-world/ && docker login ${azurerm_container_registry.acr.login_server} -u ${data.azurerm_container_registry.acr_admin_creds.username} -p ${data.azurerm_container_registry.acr_admin_creds.passwords[0].value} && docker push ${azurerm_container_registry.acr.login_server}/iis-hello-world:v1"
  }

  depends_on = [
    azurerm_container_registry.acr
  ]
}

# Kubernetes Deployment
resource "kubernetes_deployment" "iis-hello-world" {
  metadata {
    name = "iis-hello-world"
    labels = {
      app = "iis-hello-world"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "iis-hello-world"
      }
    }

    replicas = 1

    template {
      metadata {
        labels = {
          app = "iis-hello-world"
        }
      }

      spec {
        container {
          name = "iis-hello-world"
          image = "${azurerm_container_registry.acr.login_server}/iis-hello-world:v1"
          ports {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "iis" {
  metadata {
    name = "iis-service"
    labels = {
      app = "iis-app"
    }
  }

  spec {
    type = "LoadBalancer"
    selector = {
      app = "iis-hello-world"
    }

    port {
      name = "http"
      port = 80
      target_port = 80
    }
  }
}