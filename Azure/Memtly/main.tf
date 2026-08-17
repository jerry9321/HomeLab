# Azure Container Apps Deployment
# Shared infrastructure (storage, registry, LAW, etc.) is defined in main (ACI).tf
# This file defines only Container App Environment and Container Apps

# Azure Container Apps Deployment




resource "azurerm_container_app_environment" "aca" {
  name                       = "${var.name_prefix}-aca"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name

  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
}

resource "azurerm_container_app_environment_storage" "uploads" {
  name                         = "uploads"

  container_app_environment_id = azurerm_container_app_environment.aca.id

  account_name = local.storage_account_name
  share_name   = var.file_share_name
  access_key   = local.storage_account_key

  access_mode = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "mariadb" {
  name                         = "mariadb"

  container_app_environment_id = azurerm_container_app_environment.aca.id

  account_name = local.storage_account_name
  share_name   = var.file_share_mariadb_name
  access_key   = local.storage_account_key

  access_mode = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "config" {
  name                         = "config"

  container_app_environment_id = azurerm_container_app_environment.aca.id

  account_name = local.storage_account_name
  share_name   = lower(replace("${var.name_prefix}-config", "-", ""))
  access_key   = local.storage_account_key

  access_mode = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "thumbnails" {
  name                         = "thumbnails"

  container_app_environment_id = azurerm_container_app_environment.aca.id

  account_name = local.storage_account_name
  share_name   = var.file_share_thumbnails_name
  access_key   = local.storage_account_key

  access_mode = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "custom_resources" {
  name                         = "custom-resources"

  container_app_environment_id = azurerm_container_app_environment.aca.id

  account_name = local.storage_account_name
  share_name   = var.file_share_custom_resources_name
  access_key   = local.storage_account_key

  access_mode = "ReadWrite"
}

resource "azurerm_container_app" "mariadb" {

  depends_on = [
    azurerm_container_app_environment_storage.mariadb
  ]
  name                         = "mariadb"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.aca.id
  revision_mode = "Single"

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

      cpu    = 0.5

      memory = "1Gi"

      liveness_probe {
        transport = "TCP"
        port      = 3306
        initial_delay = 30
        interval_seconds = 15
        timeout = 5
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
  }
}

resource "azurerm_container_app" "memtly" {
  name                         = "memtly"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.aca.id
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_container_app.mariadb
  ]

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
        name       = "config"
        path = "/app/config"
      }

      volume_mounts {
        name       = "thumbnails"
        path = "/app/thumbnails"
      }

      volume_mounts {
        name       = "uploads"
        path = "/app/uploads"
      }

      volume_mounts {
        name       = "custom-resources"
        path = "/app/custom_resources"
      }


      #
      # Database
      #

      env {
        name  = "DATABASE_TYPE"
        value = "mariadb"
      }

      env {
        name  = "DATABASE_CONNECTION_STRING"
        value = "Server=mariadb;Port=3306;Database=${var.mariadb_database};User=${var.mariadb_user};Password=${var.mariadb_password};"
      }


      #
      # ASP.NET
      #

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


      #
      # Gallery configuration
      #

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


      #
      # Database sync
      #

      env {
        name  = "DATABASE_SYNC_FROM_CONFIG"
        value = "true"
      }


      #
      # Application secrets
      #

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


    #
    # Azure File volumes
    #

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