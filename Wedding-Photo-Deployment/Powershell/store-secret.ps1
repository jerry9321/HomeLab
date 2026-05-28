param(
  [Parameter(Mandatory=$true)]
  [string]$secretValue,

  [Parameter(Mandatory=$false)]
  [string]$secretName = "tf-memtly-sp-secret",

  [Parameter(Mandatory=$false)]
  [string]$tfDir = "."
)

# Reads the Key Vault name from Terraform outputs and sets the secret using Azure CLI.
Push-Location $tfDir
try {
  $kv = terraform output -raw key_vault_name 2>$null
  if (-not $kv) {
    Write-Error "Could not read 'key_vault_name' from terraform outputs. Provide -tfDir where terraform was applied or set -secretName and -secretValue and run az keyvault secret set manually."
    exit 1
  }
  Write-Host "Setting secret '$secretName' in Key Vault: $kv"
  az keyvault secret set --vault-name $kv --name $secretName --value $secretValue | Out-Null
  Write-Host "Secret set successfully."
} finally {
  Pop-Location
}
