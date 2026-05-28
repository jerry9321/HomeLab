#Deploy Resource Group and Key Vault

$resourceGroupName = "Kubernetes"
$location = "eastus"
$vaultName = "jerry-homelab-kube-kv"

# Create resource group
az group create --name $resourceGroupName --location $location

# Create key vault with RBAC authorization
az keyvault create --name $vaultName --resource-group $resourceGroupName --location $location --enable-rbac-authorization true

# create service principal and output credentials
$sp = az ad sp create-for-rbac --name "homelab-extsecrets" --role Reader --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resourceGroupName" | ConvertFrom-Json

# Assign Key Vault Secrets User role to the service principal
az role assignment create --assignee "$($sp.appId)" --role "Key Vault Secrets User" --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$resourceGroupName/providers/Microsoft.KeyVault/vaults/$vaultName"


#az login --tenant 'xyz'
#az account show ## check current account