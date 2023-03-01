#Helth check executes local curl command to check does newly created applicaiton is responding
resource "null_resource" "health_check" {
  provisioner "local-exec" {
    command = <<EOF
      curl -sSf http://${azurerm_public_ip.hello-world.ip_address} >/dev/null || (echo "Health check failed" && exit 1)
    EOF
  }

  depends_on = [
    azurerm_kubernetes_service.iis,
    azurerm_public_ip.hello-world
  ]
}
