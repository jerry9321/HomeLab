locals {
  mariadb_hostname = "${azurerm_container_app.mariadb.name}.internal.${azurerm_container_app_environment.aca.default_domain}"
}