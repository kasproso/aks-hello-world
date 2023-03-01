# Azure Application Gateway
resource "azurerm_application_gateway" "hello-world" {
  name                = "appgw-${random_pet.name.id}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ipconfig"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "appgw-http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appgw-ip"
    public_ip_address_id = azurerm_public_ip.hello-world.id
  }

  http_listener {
    name                           = "appgw-http-listener"
    frontend_ip_configuration_id = azurerm_application_gateway.hello-world.frontend_ip_configuration[0].id
    frontend_port_id              = azurerm_application_gateway.hello-world.frontend_port[0].id
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "appgw-http-rule"
    rule_type                  = "Basic"
    http_listener_id           = azurerm_application_gateway.hello-world.http_listener[0].id
    backend_address_pool_id    = kubernetes_service.iis.spec[0].load_balancer_ingress[0].ip
    backend_http_settings_id   = azurerm_application_gateway_backend_http_settings.iis.id
    backend_address_pool_name  = "iis-pool"
    backend_http_settings_name = "iis-http-settings"
  }
}

resource "azurerm_public_ip" "hello-world" {
  name                = "appgw-publicip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_subnet" "appgw" {
  name                 = "appgw-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
