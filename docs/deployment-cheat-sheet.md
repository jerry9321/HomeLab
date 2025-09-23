# Deployment Cheat Sheet — Flux, Kustomize & ExternalSecrets

This is a compact, copy‑ready reference for deploying and troubleshooting Flux + kustomize overlays and the External Secrets Operator (ExternalSecrets). Drop this in the repo and refer to it when you need to debug or perform GitOps operations.

## What this covers
- How repo `kustomization.yaml` and Flux `Kustomization` CR interact
- Minimal checklist to deploy ExternalSecrets and ClusterSecretStore
- Commands to seal secrets, verify resources, and troubleshoot

---

## Key concepts (quick)
- `kustomization.yaml` (in-repo): kustomize build instructions (what files get composed).
- Flux `Kustomization` (CR): tells Flux which repo `path` to `kustomize build` and apply (Git → cluster).
- `ClusterSecretStore` / `SecretStore`: operator config pointing at Azure Key Vault.
- `ExternalSecret`: maps remote secret (Key Vault) → Kubernetes Secret.
- `SealedSecret` (kubeseal) or `SOPS`: recommended ways to store credentials in git safely.

## Minimal checklist before push
- Repo overlay exists (e.g. `clusters/talos-cluster/.../kustomization.yaml`).
- Flux has a `Kustomization` CR pointing at that repo path (`spec.path`).
- Operator manifests (if you want Flux to install operator) are in `infrastructure/controllers/...` and referenced by Flux.
- `ClusterSecretStore` is committed (e.g. `infrastructure/configs/base/external-secrets/external-secret-store.yaml`).
- The cluster has a one-time bootstrap secret `az-creds` (manual) or a sealed secret in git for the SP credentials.

---

## Common PowerShell commands (copy/paste)

### Flux / Kustomize introspection
```powershell
flux get kustomizations -A
flux get helmreleases -A
flux get sources git -A
flux get sources helm -A

# preview what will be applied by a Flux Kustomization
flux build kustomization <name> --namespace <flux-namespace>
```

### Check operator, CRDs and store
```powershell
kubectl -n external-secrets get pods -o wide
kubectl get crds | Select-String external-secrets
kubectl get clustersecretstore -A
kubectl -n democratic-csi get externalsecret -o wide
```

### Seal `az-creds` (preferred GitOps — SealedSecrets)
```powershell
# create plaintext (local, do not commit)
kubectl create secret generic az-creds `
  --namespace external-secrets `
  --from-literal=ClientID="<AZURE_CLIENT_ID>" `
  --from-literal=ClientSecret="<AZURE_CLIENT_SECRET>" `
  --dry-run=client -o yaml > .\az-creds.yaml

# seal using controller (or use --cert with fetched cert)
Get-Content .\az-creds.yaml -Raw | kubeseal --controller-namespace kube-system --format yaml > .\az-creds-sealed.yaml

# move sealed file into repo and commit
Move-Item .\az-creds-sealed.yaml ".\infrastructure\configs\base\external-secrets\az-creds-sealed.yaml"
git add infrastructure/configs/base/external-secrets/az-creds-sealed.yaml
git commit -m "chore(secrets): add sealed az-creds"
git push

# remove plaintext
Remove-Item .\az-creds.yaml
```

### Manual bootstrap (one-time, non-GitOps)
```powershell
kubectl create namespace external-secrets --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic az-creds `
  --namespace external-secrets `
  --from-literal=ClientID="<AZURE_CLIENT_ID>" `
  --from-literal=ClientSecret="<AZURE_CLIENT_SECRET>" `
  --dry-run=client -o yaml | kubectl apply -f -
```

---

## Verification steps (end‑to‑end)
1. Ensure operator pods are running:
```powershell
kubectl -n external-secrets get pods -o wide
```
2. Confirm ClusterSecretStore exists and looks correct:
```powershell
kubectl describe clustersecretstore azure-kv-store
```
3. Confirm ExternalSecret synced and target Secret exists:
```powershell
kubectl -n democratic-csi describe externalsecret <name>
kubectl -n democratic-csi get secret truenas-ssh-secret -o yaml
```
4. (If needed) Inspect operator logs:
```powershell
POD=$(kubectl -n external-secrets get pods -l app.kubernetes.io/name=external-secrets -o jsonpath="{.items[0].metadata.name}")
kubectl -n external-secrets logs $POD
```

---

## Common errors and fixes
- YAML parse errors in Kustomization: remove code fences, shell commands or backticks from `kustomization.yaml` (must be valid YAML).
- Flux Kustomization not applying a folder: ensure Flux `Kustomization` CR `spec.path` points to the repo path containing the `kustomization.yaml` you want applied.
- CRDs missing: install CRDs first or set `installCRDs: true` in HelmRelease if chart supports it.
- Key names mismatch: `ClientID` vs `clientId` are case sensitive — must match `authSecretRef`.
- SP lacks Key Vault permissions: grant `get/list` to secret scope for the SP.
- Operator CrashLoop/ImagePull: inspect pod events, imagePullSecrets, node taints.

---

## Recommended next steps
1. If operator pods are missing: run `flux get helmreleases -A` and `flux describe helmrelease <name>` to find Helm errors (chart fetch, values).
2. Harden `az-creds` with a Role limiting `secrets/get` to only the operator ServiceAccount (example role/rolebinding in repo if you want).
3. Consider migrating `az-creds` into Git as a SealedSecret or SOPS-encrypted file for full GitOps reproducibility.

---

File created: `docs/deployment-cheat-sheet.md` — commit this file to keep the cheatsheet with the repo.
