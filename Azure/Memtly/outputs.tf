output "storage_account" {
  description = "Storage account name used for Azure Files"
  value       = azurerm_storage_account.sa.name
}

output "file_share" {
  description = "Azure File share name used for Memtly media"
  value       = azurerm_storage_share.memtly_media.name
}

output "file_share_config" {
  description = "Azure File share name used for Memtly config"
  value       = azurerm_storage_share.memtly_config.name
}

output "file_share_thumbnails" {
  description = "Azure File share name used for Memtly thumbnails"
  value       = azurerm_storage_share.memtly_thumbnails.name
}

output "file_share_custom_resources" {
  description = "Azure File share name used for Memtly custom resources"
  value       = azurerm_storage_share.memtly_custom_resources.name
}

output "file_share_mariadb" {
  description = "Azure File share name used for MariaDB data"
  value       = azurerm_storage_share.memtly_mariadb.name
}

output "container_fqdn" {
  description = "Container group FQDN (if public)"
  value       = azurerm_container_group.cg.fqdn
}

output "container_ip" {
  description = "Container group public IP"
  value       = azurerm_container_group.cg.ip_address
}

output "container_ip_type" {
  description = "Container group IP address type (Public/Private)"
  value       = azurerm_container_group.cg.ip_address_type
}

output "key_vault_name" {
  description = "Name of the Key Vault created for secrets"
  value       = azurerm_key_vault.kv.name
}
