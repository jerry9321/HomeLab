<#
Runbook: Wire Azure Key Vault to Kubernetes using External Secrets Operator

Preconditions:
- External Secrets Operator installed in the cluster (namespace: external-secrets)
- You have created the Azure Key Vault and stored the private key as a secret named <KEY_VAULT_SECRET_NAME>
- You have an Azure service principal with permissions to read secrets from the Key Vault

Fill the variables in the "Variables" section, then run the steps in order.
This script does not apply secrets containing real credentials to git; it only automates kubectl apply
for template files in the repo when you are ready.
#>

### Variables - fill before running
$VAULT_NAME = '<VAULT_NAME>'            # e.g. homelab-kv
$KV_SECRET_NAME = '<KEY_VAULT_SECRET_NAME>'  # name of secret in Key Vault containing private key
$AZ_TENANT = '<AZURE_TENANT_ID>'
$AZ_CLIENT = '<AZURE_CLIENT_ID>'
$AZ_SECRET = '<AZURE_CLIENT_SECRET>'

Write-Host "1) Create namespace for external-secrets if it doesn't exist"
kubectl create namespace external-secrets -o none -v=0 --ignore-not-found

Write-Host "2) Create azure-creds secret in namespace external-secrets (local only; do not commit)"
$credsYaml = @"
apiVersion: v1
kind: Secret
metadata:
  name: azure-creds
  namespace: external-secrets
type: Opaque
stringData:
  tenantId: "$AZ_TENANT"
  clientId: "$AZ_CLIENT"
  clientSecret: "$AZ_SECRET"
"@
$credsYaml | kubectl apply -f -

Write-Host "3) Edit the SecretStore manifest: replace <VAULT_NAME> with $VAULT_NAME"
Write-Host "   (file: clusters/talos-cluster/democratic-csi/secretstore-azure-keyvault.yaml)"

Write-Host "4) Edit the ExternalSecret manifest: replace <KEY_VAULT_SECRET_NAME> with $KV_SECRET_NAME"
Write-Host "   (file: clusters/talos-cluster/democratic-csi/externalsecret-truenas-ssh.yaml)"

Write-Host "5) Apply SecretStore and ExternalSecret manifests"
kubectl apply -f ..\clusters\talos-cluster\democratic-csi\secretstore-azure-keyvault.yaml
kubectl apply -f ..\clusters\talos-cluster\democratic-csi\externalsecret-truenas-ssh.yaml

Write-Host "6) Verify the Kubernetes secret was created in namespace democratic-csi"
kubectl -n democratic-csi get secret truenas-ssh-secret -o yaml

Write-Host "7) Check democratic-csi pods and Flux/HelmRelease status"
kubectl -n democratic-csi get pods
kubectl -n flux-system get helmreleases

Write-Host "Runbook complete. If the secret is not present, check ExternalSecrets controller logs and the SecretStore configuration."
