# useful fluxcd commands for gitops management

This cheat sheet provides common FluxCD commands for checking status, debugging, and managing GitOps resources. Each command includes a comment explaining its purpose and when you would use it.

---

## FluxCD Resource Status

```sh
flux get kustomizations # List all Kustomizations and their status (use to check sync and reconciliation)
flux get helmreleases # List all HelmReleases and their status (use to check Helm chart deployments)
flux get sources git # List all Git sources (use to check repo sync status)
flux get sources helm # List all Helm repositories (use to check chart sources)
```

## Sync & Reconciliation

```sh
flux reconcile kustomization <name> # Force a Kustomization to sync (use to apply changes immediately)
flux reconcile helmrelease <name> # Force a HelmRelease to sync (use to apply chart changes immediately)
```

## Debugging & Events

```sh
flux logs # View recent Flux events and logs (use to debug sync or deployment issues)
flux check # Check Flux installation and health (use to verify setup)
```

## Resource YAML & Editing

```sh
flux export kustomization <name> # Output YAML for a Kustomization (use to inspect config)
flux export helmrelease <name> # Output YAML for a HelmRelease (use to inspect config)
```

---

> Replace `<name>` with your actual resource names.
> For more, see the [FluxCD documentation](https://fluxcd.io/docs/).
