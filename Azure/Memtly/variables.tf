variable "resource_group_name" {
  description = "Name of the resource group to create"
  type        = string
  default     = "Memtly-Deployment"
}

variable "data_resource_group_name" {
  description = "Name of the existing resource group that contains persistent data resources (storage account/file shares)."
  type        = string
  default     = "Memtly-Data-Storage"
}

variable "storage_account_name" {
  description = "Existing storage account name used by Memtly volumes."
  type        = string
  default     = "memtlysa"
}

variable "manage_storage_in_this_stack" {
  description = "When true, this stack creates/manages storage account and shares. Keep false to isolate app teardown from data resources."
  type        = bool
  default     = false
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "name_prefix" {
  description = "Prefix used for resource names"
  type        = string
  default     = "memtly"
}

variable "dns_label" {
  description = "DNS label for the public IP (unique across region). If empty a generated label will be used."
  type        = string
  default     = ""
}

variable "vm_size" {
  description = "VM SKU (small/cheap default). Change if unsupported in region."
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for admin user (required)"
  type        = string
  default     = ""
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 50
}

variable "file_share_name" {
  description = "Azure File share name for Memtly media"
  type        = string
  default     = "memtlymedia"
}

variable "file_share_thumbnails_name" {
  description = "Azure File share name for Memtly thumbnails"
  type        = string
  default     = "memtlythumbs"
}

variable "file_share_custom_resources_name" {
  description = "Azure File share name for Memtly custom resources"
  type        = string
  default     = "memtlycustom"
}

variable "file_share_mariadb_name" {
  description = "Azure File share name for MariaDB data"
  type        = string
  default     = "memtlymariadb"
}

variable "timezone" {
  description = "Container timezone (used instead of host bind mounts like /etc/timezone and /etc/localtime)."
  type        = string
  default     = "UTC"
}

variable "memtly_compose_repo" {
  description = "Git repo that contains Memtly docker-compose (optional)"
  type        = string
  default     = ""
}

resource "random_id" "unique" {
  byte_length = 2
}

variable "key_vault_name" {
  description = "Name of the Azure Key Vault to create. If empty, a name will be generated."
  type        = string
  default     = ""
}

variable "sp_object_id" {
  description = "Azure AD object id of the service principal to grant access to the Key Vault"
  type        = string
  default     = ""
}

variable "sp_password" {
  description = "Service Principal password (client secret). Provide via environment var or tfvars (sensitive)."
  type        = string
  sensitive   = true
  default     = ""
}

variable "sp_secret_name" {
  description = "Secret name to create in Key Vault for the SP password"
  type        = string
  default     = "tf-memtly-sp-secret"
}

variable "purge_protection_enabled" {
  description = "Enable purge protection for the Key Vault (irreversible). Set true for production if you understand implications."
  type        = bool
  default     = false
}

# Container instance variables (serverless)
variable "container_image" {
  description = "Container image to run in Azure Container Instance (optional additional app container)."
  type        = string
  default     = "memtly/memtly:latest"
}

variable "container_port" {
  description = "Port the container listens on (used for ACI public port)."
  type        = number
  default     = 3000
}

variable "container_cpu" {
  description = "CPU cores for the container instance."
  type        = number
  default     = 0.5
}

variable "container_memory" {
  description = "Memory (GB) for the container instance."
  type        = number
  default     = 1.0
}

variable "container_environment" {
  description = "Map of environment variables to set in the container. Use Key Vault to store secrets and inject at deploy time."
  type        = map(string)
  default     = {}
}

# Container registry credentials (optional) - leave empty for public registries
variable "container_registry_server" {
  description = "Container registry server (e.g., ghcr.io). Leave empty for anonymous/public images."
  type        = string
  default     = ""
}

variable "container_registry_username" {
  description = "Username for the container registry (optional)."
  type        = string
  default     = ""
}

variable "container_registry_password" {
  description = "Password for the container registry (sensitive)."
  type        = string
  sensitive   = true
  default     = ""
}

variable "create_container_registry" {
  description = "Create an Azure Container Registry in this stack for private image pulls."
  type        = bool
  default     = true
}

variable "container_registry_name" {
  description = "Optional name for an Azure Container Registry to create. If empty, a generated name is used."
  type        = string
  default     = ""
}

variable "container_registry_sku" {
  description = "SKU for the Azure Container Registry."
  type        = string
  default     = "Basic"
}

variable "import_images" {
  description = "When true, import public images from Docker Hub into the created ACR."
  type        = bool
  default     = true
}

variable "import_memtly_source" {
  description = "Source image on Docker Hub to import for memtly (repository:tag)."
  type        = string
  default     = "memtly/memtly:latest"
}

variable "import_mariadb_source" {
  description = "Source image on Docker Hub to import for mariadb (repository:tag). For official Docker Hub images, include library/, e.g. library/mariadb:latest."
  type        = string
  default     = "library/mariadb:latest"
}

variable "build_repo_url" {
  description = "Git repo URL used by ACR Task to build the Memtly image."
  type        = string
  default     = "https://github.com/Memtly/Memtly.Community.git"
}

variable "build_repo_branch" {
  description = "Branch or ref to build from."
  type        = string
  default     = "master"
}

variable "build_dockerfile_path" {
  description = "Path to Dockerfile inside the repo (relative)."
  type        = string
  default     = "Memtly.Community/Dockerfile"
}

variable "build_image_name" {
  description = "Image name (and tag) to produce and push into ACR."
  type        = string
  default     = "memtly:latest"
}

variable "dockerhub_username" {
  description = "Docker Hub username used for authenticated pulls/imports."
  type        = string
  default     = ""
}

variable "dockerhub_password" {
  description = "Docker Hub password or access token (sensitive)."
  type        = string
  sensitive   = true
  default     = ""
}

# Memtly + MariaDB settings
variable "memtly_image" {
  description = "Memtly container image"
  type        = string
  default     = "memtly/memtly:latest"
}

variable "memtly_port" {
  description = "Public port for Memtly HTTP"
  type        = number
  default     = 8080
}

variable "mariadb_image" {
  description = "MariaDB image for Memtly"
  type        = string
  default     = "mariadb:latest"
}

variable "mariadb_root_password" {
  description = "MariaDB root password (sensitive)."
  type        = string
  sensitive   = true
  default     = "ChangeMe!"
}

variable "mariadb_database" {
  description = "MariaDB database name for Memtly"
  type        = string
  default     = "memtly"
}

variable "mariadb_user" {
  description = "MariaDB user for Memtly"
  type        = string
  default     = "memtly"
}

variable "mariadb_password" {
  description = "MariaDB user password (sensitive)."
  type        = string
  sensitive   = true
  default     = "ChangeMe!"
}

variable "memtly_admin_password" {
  description = "Memtly admin password (sensitive)."
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "memtly_encryption_key" {
  description = "Memtly encryption key (sensitive)."
  type        = string
  sensitive   = true
  default     = "ChangeMe"
}

variable "memtly_encryption_salt" {
  description = "Memtly encryption salt (sensitive)."
  type        = string
  sensitive   = true
  default     = "ChangeMe"
}

# Toggle deploying Memtly + MariaDB containers
variable "deploy_memtly" {
  description = "When true, deploy Memtly and its MariaDB container in the container group."
  type        = bool
  default     = true
}

# Toggle deploying an optional additional app container inside the container group
variable "enable_extra_app" {
  description = "When true, deploy an optional additional app container alongside Memtly."
  type        = bool
  default     = false
}

# Quick test: deploy a small hello container into the same ACI group
variable "deploy_hello" {
  description = "When true, deploy a small hello-world HTTP container for testing."
  type        = bool
  default     = false
}

variable "hello_image" {
  description = "Image used for the test hello container."
  type        = string
  default     = "mcr.microsoft.com/azuredocs/aci-helloworld"
}
