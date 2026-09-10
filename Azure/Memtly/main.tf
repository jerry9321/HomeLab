terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "azurerm" {
  features {}
}

# ------------------------------------------------------------------------------
# Core & Monitoring Resources
# ------------------------------------------------------------------------------

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.name_prefix}-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# ------------------------------------------------------------------------------
# Container Registry & Image Import
# ------------------------------------------------------------------------------

resource "azurerm_container_registry" "acr" {
  count               = var.create_container_registry ? 1 : 0
  name                = length(var.container_registry_name) > 0 ? var.container_registry_name : lower("${var.name_prefix}acr${random_id.unique.hex}")
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.container_registry_sku
  admin_enabled       = true
}

resource "null_resource" "acr_build_and_import" {
  count = var.create_container_registry && var.import_images ? 1 : 0

  triggers = {
    acr_name           = azurerm_container_registry.acr[0].name
    import_mariadb_src = var.import_mariadb_source
    import_memtly_src  = var.import_memtly_source
    dockerhub_username = var.dockerhub_username
    dockerhub_password = var.dockerhub_password
    build_trigger      = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]
    command     = <<-EOT
      $ErrorActionPreference = 'Stop';
      $registryName = "${azurerm_container_registry.acr[0].name}"
      if ([string]::IsNullOrEmpty("${var.dockerhub_username}")) {
        az acr import -n $registryName --source docker.io/${var.import_mariadb_source} --image mariadb:latest --force
      } else {
        az acr import -n $registryName --source docker.io/${var.import_mariadb_source} --image mariadb:latest --username "${var.dockerhub_username}" --password "${var.dockerhub_password}" --force
      }

      if ([string]::IsNullOrEmpty("${var.dockerhub_username}")) {
        az acr import -n $registryName --source docker.io/${var.import_memtly_source} --image memtly:latest --force
      } else {
        az acr import -n $registryName --source docker.io/${var.import_memtly_source} --image memtly:latest --username "${var.dockerhub_username}" --password "${var.dockerhub_password}" --force
      }
    EOT
  }

  depends_on = [azurerm_container_registry.acr]
}

# ------------------------------------------------------------------------------
# Storage Resources
# ------------------------------------------------------------------------------

resource "azurerm_storage_account" "sa" {
  count                    = var.manage_storage_in_this_stack ? 1 : 0
  name                     = var.storage_account_name
  resource_group_name      = var.data_resource_group_name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

data "azurerm_storage_account" "existing_sa" {
  count               = var.manage_storage_in_this_stack ? 0 : 1
  name                = var.storage_account_name
  resource_group_name = var.data_resource_group_name
}

resource "azurerm_storage_share" "memtly_media" {
  count              = var.manage_storage_in_this_stack ? 1 : 0
  name               = var.file_share_name
  storage_account_id = azurerm_storage_account.sa[0].id
  quota              = 128
}

resource "azurerm_storage_share" "memtly_config" {
  count              = var.manage_storage_in_this_stack ? 1 : 0
  name               = lower(replace("${var.name_prefix}-config", "-", ""))
  storage_account_id = azurerm_storage_account.sa[0].id
  quota              = 1
}

resource "azurerm_storage_share" "memtly_thumbnails" {
  count              = var.manage_storage_in_this_stack ? 1 : 0
  name               = var.file_share_thumbnails_name
  storage_account_id = azurerm_storage_account.sa[0].id
  quota              = 32
}

resource "azurerm_storage_share" "memtly_custom_resources" {
  count              = var.manage_storage_in_this_stack ? 1 : 0
  name               = var.file_share_custom_resources_name
  storage_account_id = azurerm_storage_account.sa[0].id
  quota              = 10
}

resource "azurerm_storage_share" "memtly_mariadb" {
  count              = var.manage_storage_in_this_stack ? 1 : 0
  name               = var.file_share_mariadb_name
  storage_account_id = azurerm_storage_account.sa[0].id
  quota              = 32
}

# ------------------------------------------------------------------------------
# Container App Environment & Environment Storage Mounts
# ------------------------------------------------------------------------------

resource "azurerm_container_app_environment" "aca" {
  name                       = "${var.name_prefix}-aca"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

resource "azurerm_container_app_environment_storage" "uploads" {
  name                         = "uploads"
  container_app_environment_id = azurerm_container_app_environment.aca.id
  account_name                 = local.storage_account_name
  share_name                   = var.file_share_name
  access_key                   = local.storage_account_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "mariadb" {
  name                         = "mariadb"
  container_app_environment_id = azurerm_container_app_environment.aca.id
  account_name                 = local.storage_account_name
  share_name                   = var.file_share_mariadb_name
  access_key                   = local.storage_account_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "config" {
  name                         = "config"
  container_app_environment_id = azurerm_container_app_environment.aca.id
  account_name                 = local.storage_account_name
  share_name                   = lower(replace("${var.name_prefix}-config", "-", ""))
  access_key                   = local.storage_account_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "thumbnails" {
  name                         = "thumbnails"
  container_app_environment_id = azurerm_container_app_environment.aca.id
  account_name                 = local.storage_account_name
  share_name                   = var.file_share_thumbnails_name
  access_key                   = local.storage_account_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "custom_resources" {
  name                         = "custom-resources"
  container_app_environment_id = azurerm_container_app_environment.aca.id
  account_name                 = local.storage_account_name
  share_name                   = var.file_share_custom_resources_name
  access_key                   = local.storage_account_key
  access_mode                  = "ReadWrite"
}

# ------------------------------------------------------------------------------
# Container Apps (MariaDB & Memtly)
# ------------------------------------------------------------------------------

resource "azurerm_container_app" "mariadb" {
  name                         = "mariadb"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.aca.id
  revision_mode                = "Single"

  depends_on = [
    azurerm_container_app_environment_storage.mariadb
  ]

  ingress {
    external_enabled = false
    target_port      = 3306
    transport        = "tcp"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  identity {
    type = "SystemAssigned"
  }

  registry {
    server               = local.container_registry_server
    username             = local.container_registry_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = local.container_registry_password
  }

  template {
    container {
      name   = "mariadb"
      image  = local.mariadb_image_local
      cpu    = 2
      memory = "4Gi"

      volume_mounts {
        name = "mariadb"
        path = "/var/lib/mysql"
      }

      liveness_probe {
        transport                = "TCP"
        port                     = 3306
        initial_delay            = 30
        interval_seconds         = 15
        timeout                  = 5
        failure_count_threshold = 3
      }

      env {
        name  = "MYSQL_ROOT_PASSWORD"
        value = var.mariadb_root_password
      }
      env {
        name  = "MYSQL_DATABASE"
        value = var.mariadb_database
      }
      env {
        name  = "MYSQL_USER"
        value = var.mariadb_user
      }
      env {
        name  = "MYSQL_PASSWORD"
        value = var.mariadb_password
      }
      env {
        name  = "MYSQL_ROOT_HOST"
        value = "%"
      }
    }

    volume {
      name         = "mariadb"
      storage_name = azurerm_container_app_environment_storage.mariadb.name
      storage_type = "AzureFile"
    }
  }
}

resource "azurerm_container_app" "memtly" {
  name                         = "memtly"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.aca.id
  revision_mode                = "Single"

  depends_on = [
    azurerm_container_app_environment_storage.uploads,
    azurerm_container_app_environment_storage.mariadb,
    azurerm_container_app_environment_storage.config,
    azurerm_container_app_environment_storage.thumbnails,
    azurerm_container_app_environment_storage.custom_resources,
    azurerm_container_app.mariadb
  ]

  identity {
    type = "SystemAssigned"
  }

  registry {
    server               = local.container_registry_server
    username             = local.container_registry_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = local.container_registry_password
  }

  ingress {
    external_enabled = true
    target_port      = var.memtly_port

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    container {
      name  = "memtly"
      image = local.memtly_image_local

      cpu    = 2
      memory = "4Gi"

      volume_mounts {
        name = "config"
        path = "/app/config"
      }
      volume_mounts {
        name = "thumbnails"
        path = "/app/thumbnails"
      }
      volume_mounts {
        name = "uploads"
        path = "/app/uploads"
      }
      volume_mounts {
        name = "custom-resources"
        path = "/app/custom_resources"
      }

      env {
        name  = "DATABASE_TYPE"
        value = "mariadb"
      }
      env {
        name  = "DATABASE_CONNECTION_STRING"
        value = "Server=mariadb;Port=3306;Database=${var.mariadb_database};User=${var.mariadb_user};Password=${var.mariadb_password};"
      }
      env {
        name  = "ASPNETCORE_URLS"
        value = "http://0.0.0.0:${var.memtly_port}"
      }
      env {
        name  = "TZ"
        value = var.timezone
      }
      env {
        name  = "ASPNETCORE_ENVIRONMENT"
        value = "Development"
      }
      env {
        name  = "ASPNETCORE_DETAILEDERRORS"
        value = "true"
      }
      env {
        name  = "ASPNETCORE_LOGGING__LOGLEVEL__DEFAULT"
        value = "Debug"
      }
      env {
        name  = "TITLE"
        value = "Lackovitch Wedding Photos"
      }
      env {
        name  = "SINGLE_GALLERY_MODE"
        value = "true"
      }
      env {
        name  = "GALLERY_SECRET_KEY"
        value = "test"
      }
      env {
        name  = "GALLERY_SELECTOR_DROPDOWN"
        value = "true"
      }
      env {
        name  = "GALLERY_REQUIRE_REVIEW"
        value = "false"
      }
      env {
        name  = "GALLERY_PREVENT_DUPLICATES"
        value = "true"
      }
      env {
        name  = "GALLERY_UPLOAD"
        value = "true"
      }
      env {
        name  = "GALLERY_DOWNLOAD"
        value = "true"
      }
      env {
        name  = "GUEST_GALLERY_CREATION"
        value = "false"
      }
      env {
        name  = "DATABASE_SYNC_FROM_CONFIG"
        value = "true"
      }
      env {
        name  = "ACCOUNT_ADMIN_PASSWORD"
        value = var.memtly_admin_password
      }
      env {
        name  = "ENCRYPTION_KEY"
        value = var.memtly_encryption_key
      }
      env {
        name  = "ENCRYPTION_SALT"
        value = var.memtly_encryption_salt
      }
      env {
        name  = "MYSQL_PASSWORD"
        value = var.mariadb_password
      }
    }

    volume {
      name         = "config"
      storage_name = "config"
      storage_type = "AzureFile"
    }
    volume {
      name         = "thumbnails"
      storage_name = "thumbnails"
      storage_type = "AzureFile"
    }
    volume {
      name         = "uploads"
      storage_name = "uploads"
      storage_type = "AzureFile"
    }
    volume {
      name         = "custom-resources"
      storage_name = "custom-resources"
      storage_type = "AzureFile"
    }
  }
}

# ------------------------------------------------------------------------------
# Locals
# ------------------------------------------------------------------------------

locals {
  storage_account_name        = var.manage_storage_in_this_stack ? azurerm_storage_account.sa[0].name : data.azurerm_storage_account.existing_sa[0].name
  storage_account_key         = var.manage_storage_in_this_stack ? azurerm_storage_account.sa[0].primary_access_key : data.azurerm_storage_account.existing_sa[0].primary_access_key
  dns_label                   = length(var.dns_label) > 0 ? var.dns_label : "memtly-${random_id.unique.hex}"
  key_vault_name              = length(var.key_vault_name) > 0 ? var.key_vault_name : "memtly-kv-${random_id.unique.hex}"
  container_registry_server   = var.create_container_registry ? azurerm_container_registry.acr[0].login_server : var.container_registry_server
  container_registry_username = var.create_container_registry ? azurerm_container_registry.acr[0].admin_username : var.container_registry_username
  container_registry_password = var.create_container_registry ? azurerm_container_registry.acr[0].admin_password : var.container_registry_password
  memtly_image_local          = var.create_container_registry ? "${azurerm_container_registry.acr[0].login_server}/${var.build_image_name}" : var.memtly_image
  mariadb_image_local         = var.create_container_registry ? "${azurerm_container_registry.acr[0].login_server}/mariadb:latest" : var.mariadb_image
}