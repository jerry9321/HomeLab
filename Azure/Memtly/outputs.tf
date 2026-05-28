output "storage_account" {
  description = "Storage account name used for Azure Files"
  value       = local.storage_account_name
}

output "file_share" {
  description = "Azure File share name used for Memtly media"
  value       = var.file_share_name
}

output "file_share_config" {
  description = "Azure File share name used for Memtly config"
  value       = lower(replace("${var.name_prefix}-config", "-", ""))
}

output "file_share_thumbnails" {
  description = "Azure File share name used for Memtly thumbnails"
  value       = var.file_share_thumbnails_name
}

output "file_share_custom_resources" {
  description = "Azure File share name used for Memtly custom resources"
  value       = var.file_share_custom_resources_name
}

output "file_share_mariadb" {
  description = "Azure File share name used for MariaDB data"
  value       = var.file_share_mariadb_name
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
