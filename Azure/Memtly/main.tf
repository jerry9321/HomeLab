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

# Resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# VNet and Subnet
/*
  Replaced VM + networking resources with Azure Container Instance (ACI) based deployment.
  ACI is a serverless container option and supports mounting Azure File shares.
  This module now creates a Log Analytics workspace + a single container group
  that mounts the Azure File share created below. For a more feature-rich
  serverless option consider Azure Container Apps (ACA) — ask if you want that.
*/

# Storage account + Azure File shares can be managed in this stack only when explicitly enabled.
# Default behavior keeps storage external so app teardown cannot destroy data resources.
resource "azurerm_storage_account" "sa" {
  count                    = var.manage_storage_in_this_stack ? 1 : 0
  name                     = var.storage_account_name
  resource_group_name      = var.data_resource_group_name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

resource "azurerm_storage_share" "memtly_media" {
  count              = var.manage_storage_in_this_stack ? 1 : 0
  name               = var.file_share_name
  storage_account_id = azurerm_storage_account.sa[0].id
  quota              = 128 # GiB, sized for ~100 GiB uploads with headroom
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

data "azurerm_storage_account" "existing_sa" {
  count               = var.manage_storage_in_this_stack ? 0 : 1
  name                = var.storage_account_name
  resource_group_name = var.data_resource_group_name
}

# Linux VM (smallest recommended SKU by default is Standard_B1s; override via var)
#+ Log Analytics workspace for container diagnostics
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.name_prefix}-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_registry" "acr" {
  count               = var.create_container_registry ? 1 : 0
  name                = length(var.container_registry_name) > 0 ? var.container_registry_name : lower("${var.name_prefix}acr${random_id.unique.hex}")
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = var.container_registry_sku
  admin_enabled       = true
}

# Import common public images into the ACR so ACI can pull them without manual pushes.
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
      # Import MariaDB from Docker Hub; use Docker Hub credentials when provided.
      if ([string]::IsNullOrEmpty("${var.dockerhub_username}")) {
        az acr import -n $registryName --source docker.io/${var.import_mariadb_source} --image mariadb:latest --force
      } else {
        az acr import -n $registryName --source docker.io/${var.import_mariadb_source} --image mariadb:latest --username "${var.dockerhub_username}" --password "${var.dockerhub_password}" --force
      }

      # Import Memtly from Docker Hub into ACR.
      if ([string]::IsNullOrEmpty("${var.dockerhub_username}")) {
        az acr import -n $registryName --source docker.io/${var.import_memtly_source} --image memtly:latest --force
      } else {
        az acr import -n $registryName --source docker.io/${var.import_memtly_source} --image memtly:latest --username "${var.dockerhub_username}" --password "${var.dockerhub_password}" --force
      }
    EOT
  }

  depends_on = [azurerm_container_registry.acr]
}

# Azure Container Instance using the provided container image
resource "azurerm_container_group" "cg" {
  name                = "${var.name_prefix}-cg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  ip_address_type     = "Public"
  dns_name_label      = length(var.dns_label) > 0 ? var.dns_label : "${var.name_prefix}-${random_id.unique.hex}"


  dynamic "container" {
    for_each = var.enable_extra_app ? [1] : []
    content {
      name   = "app"
      image  = var.container_image
      cpu    = var.container_cpu
      memory = var.container_memory

      ports {
        port     = var.container_port
        protocol = "TCP"
      }

      environment_variables = var.container_environment

      # volume mount removed to avoid provider schema mismatch; consider re-adding
      # Azure File mounting for ACI can be added once provider schema is confirmed.
    }
  }

  dynamic "container" {
    for_each = var.deploy_memtly ? [1] : []
    content {
      # MariaDB for Memtly (runs inside the same container group)
      name  = "mariadb"
      image = local.mariadb_image_local

      cpu    = 0.5
      memory = 1

      ports {
        port     = 3306
        protocol = "TCP"
      }

      environment_variables = {
        MYSQL_ROOT_HOST     = "%"
        MYSQL_ROOT_PASSWORD = var.mariadb_root_password
        MYSQL_DATABASE      = var.mariadb_database
        MYSQL_USER          = var.mariadb_user
        MYSQL_PASSWORD      = var.mariadb_password
        TZ                  = var.timezone
      }

      volume {
        name                 = "memtly-mariadb"
        mount_path           = "/var/lib/mysql"
        read_only            = false
        share_name           = var.file_share_mariadb_name
        storage_account_name = local.storage_account_name
        storage_account_key  = local.storage_account_key
      }
    }
  }

  dynamic "container" {
    for_each = var.deploy_memtly ? [1] : []
    content {
      # Memtly service (connects to local mariadb in the same group)
      name   = "memtly"
      image  = local.memtly_image_local
      cpu    = 0.5
      memory = 1

      ports {
        port     = var.memtly_port
        protocol = "TCP"
      }

      environment_variables = merge(
        var.container_environment,
        {
          DATABASE_TYPE = "mariadb"
          # When containers are in same ACI group, they can access each other via localhost
          DATABASE_CONNECTION_STRING = "Server=127.0.0.1;Port=3306;Database=${var.mariadb_database};User=${var.mariadb_user};Password=${var.mariadb_password};"
          ACCOUNT_ADMIN_PASSWORD     = var.memtly_admin_password
          ENCRYPTION_KEY             = var.memtly_encryption_key
          ENCRYPTION_SALT            = var.memtly_encryption_salt
          ASPNETCORE_URLS            = "http://0.0.0.0:${var.memtly_port}"
          TZ                         = var.timezone
          # enable development logging to capture stack traces in ACI logs
          ASPNETCORE_ENVIRONMENT                = "Development"
          ASPNETCORE_DETAILEDERRORS             = "true"
          ASPNETCORE_LOGGING__LOGLEVEL__DEFAULT = "Debug"
          TITLE                                 = "Lackovitch Wedding Photos" # Display title in application
          SINGLE_GALLERY_MODE                   = "true"             # enable single gallery mode to simplify testing and avoid issues with multiple galleries in a shared ACI environment
          GALLERY_SECRET_KEY                    = "test"                      # required but not used when GALLERY_PREVENT_DUPLICATES is enabled
          GALLERY_SELECTOR_DROPDOWN             = "true"                     # disable gallery selector dropdown to simplify testing and avoid issues with multiple galleries in a shared ACI environment
          GALLERY_REQUIRE_REVIEW                = "false"                     # disable review requirement to simplify testing; re-enable for production use
          GALLERY_PREVENT_DUPLICATES            = "true"                      # prevent duplicate uploads based on hash comparison. This works
          GALLERY_UPLOAD                        = "true"                      # enable uploading of files to test storage connectivity
          GALLERY_DOWNLOAD                      = "true"                      #enable downloading of files
          GUEST_GALLERY_CREATION                = "false"                     # disable guest gallery creation to avoid issues
          DATABASE_SYNC_FROM_CONFIG             = "true"                      #use environment variables for initial DB seeding on startup
        }
      )

      volume {
        name                 = "memtly-config"
        mount_path           = "/app/config"
        read_only            = false
        share_name           = lower(replace("${var.name_prefix}-config", "-", ""))
        storage_account_name = local.storage_account_name
        storage_account_key  = local.storage_account_key
      }

      volume {
        name                 = "memtly-thumbnails"
        mount_path           = "/app/thumbnails"
        read_only            = false
        share_name           = var.file_share_thumbnails_name
        storage_account_name = local.storage_account_name
        storage_account_key  = local.storage_account_key
      }

      volume {
        name                 = "memtly-uploads"
        mount_path           = "/app/uploads"
        read_only            = false
        share_name           = var.file_share_name
        storage_account_name = local.storage_account_name
        storage_account_key  = local.storage_account_key
      }

      volume {
        name                 = "memtly-custom-resources"
        mount_path           = "/app/custom_resources"
        read_only            = false
        share_name           = var.file_share_custom_resources_name
        storage_account_name = local.storage_account_name
        storage_account_key  = local.storage_account_key
      }
    }
  }

  dynamic "container" {
    for_each = var.deploy_hello ? [1] : []
    content {
      name   = "hello"
      image  = var.hello_image
      cpu    = 0.25
      memory = 0.5

      ports {
        port     = 80
        protocol = "TCP"
      }
    }
  }
  # Optional image registry credentials for private registries (GHCR/ACR)
  dynamic "image_registry_credential" {
    for_each = length(local.container_registry_server) > 0 ? [1] : []
    content {
      server   = local.container_registry_server
      username = local.container_registry_username
      password = local.container_registry_password
    }
  }

  # NOTE: Azure File mounting was removed because provider schema mismatches
  # prevented a successful plan. If you want persistent config, I can add the
  # correct mount once we confirm the azurerm provider version and schema.

  tags = {
    project = "memtly"
  }
  timeouts {
    create = "60m"
  }

  depends_on = [null_resource.acr_build_and_import]
}

/* outputs moved to outputs.tf to avoid duplicate definitions */

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
