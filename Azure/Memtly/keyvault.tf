data "azurerm_client_config" "current" {}

locals {
  kv_policy_object_id = length(var.sp_object_id) > 0 ? var.sp_object_id : data.azurerm_client_config.current.object_id
}

# Key Vault to store sensitive values (e.g. SP password)
resource "azurerm_key_vault" "kv" {
  name                = local.key_vault_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Note: soft-delete and purge protection settings can be added depending on provider version.

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = local.kv_policy_object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
    ]
  }

  tags = {
    project = "memtly"
  }
}

# Store the SP password as a secret in Key Vault. Pass the secret value via a sensitive variable.
resource "azurerm_key_vault_secret" "sp_password" {
  count        = var.sp_password != "" ? 1 : 0
  name         = var.sp_secret_name
  value        = var.sp_password
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [azurerm_key_vault.kv]
}
