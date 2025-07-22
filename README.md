# HomeLab Mono Repo

## Project Overview
This repository serves as the central source of truth for managing all aspects of my homelab infrastructure and applications. It leverages modern DevOps and GitOps methodologies to ensure reproducibility, scalability, and maintainability.

- **Technologies Used:**
  - Kubernetes (Talos)
  - Kustomize
  - Flux (GitOps)
  - Docker
  - YAML-based configuration
  - CI/CD pipelines

## Repository Structure
```
HomeLab/
├── apps/                # Application manifests (by environment & app)
│   ├── base/
│   ├── production/
│   └── staging/
├── clusters/            # Cluster-specific configuration (e.g., talos-cluster)
│   └── talos-cluster/
├── infrastructure/      # Infrastructure-as-code (by environment)
│   ├── base/
│   ├── production/
│   └── staging/
```

- **apps/**: Contains application manifests, organized by environment (`base`, `production`, `staging`) and by app (e.g., `nginx`, `podinfo`).
- **clusters/**: Holds cluster-specific configuration, such as overlays and Flux bootstrap files for `talos-cluster`.
- **infrastructure/**: Infrastructure-as-code for shared resources, also organized by environment.


## GitOps Workflow
- All changes are made via pull requests and reviewed before merging.
- Flux or a similar GitOps operator syncs the cluster state from this repository.
- Kustomize overlays enable environment-specific customization and modularity.

## Deployment & Management
- Use `kubectl apply -k` or let Flux handle deployment of manifests.
- Talos is used for cluster lifecycle management (provisioning, upgrades, etc.).
- (Planned) CI/CD pipeline for manifest validation and automated deployment.

## References & Resources
- [Talos](https://www.talos.dev/)
- [Flux](https://fluxcd.io/)
- [Kustomize](https://kubectl.docs.kubernetes.io/references/kustomize/)
---

> This repository is a work in progress and will continue to evolve as my homelab grows. Contributions and suggestions are welcome!