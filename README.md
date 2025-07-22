## Project Overview
This repository serves as the central source of truth for managing all aspects of my homelab infrastructure and applications. It leverages modern DevOps and GitOps methodologies to ensure reproducibility, scalability, and maintainability.

## Hardware Overview

The HomeLab Kubernetes cluster is built on three Lenovo M920q mini-PCs:

- **Nodes:**
  - 1x Control Plane Node
  - 2x Worker Nodes
- **Each Node Specs:**
  - Intel Core i5-8500T CPU
  - 32GB RAM
  - 256GB SSD

## Storage Overview
Persistent storage for Kubernetes pods is provided by a TrueNAS server, which supplies network-attached volumes to the cluster. The TrueNAS system is configured with two storage pools:

- **Pool 1:**
  - 3 × 18TB drives
  - ZFS RAIDZ1 (single parity)
- **Pool 2:**
  - 2 × 4TB drives
  - ZFS mirror (redundant)

## Tech Stack 
- **Technologies Used:**
  - Kubernetes (Talos)
  - Kustomize
  - Flux (GitOps)
  - Docker
  - YAML-based configuration
  - CI/CD pipelines

## Deployed Applications

The following core applications are deployed and managed within the HomeLab Kubernetes cluster:
- **nginx**
  - Purpose: Web server and reverse proxy for internal and external services.
  - Image: `nginx:stable-alpine`
  - Replicas: 2

- **podinfo**
  - Purpose: Microservice for testing, demo, and observability.
  - Image: `ghcr.io/stefanprodan/podinfo:latest`
  - Replicas: 2

Additional applications and services can be added by updating the manifests in the `apps/` directory.

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

## Infrastructure

The HomeLab environment is managed using infrastructure-as-code (IaC) principles. All infrastructure resources are defined and versioned in the `infrastructure/` directory, with separate overlays for `base`, `production`, and `staging` environments.

### Key Infrastructure Components
- **Kubernetes Cluster:** Provisioned and managed with Talos for a secure, immutable control plane.
- **Persistent Storage:** Provided by TrueNAS, offering ZFS-backed network volumes for pods.
- **Secret Management:**
  - Azure Key Vault is used to securely store and manage sensitive information such as secrets, credentials, and certificates.
  - Secrets are integrated into the cluster using external secret operators or CSI drivers, ensuring that sensitive data is never stored in plain text within the repository.

This approach ensures that all infrastructure is reproducible, auditable, and secure.

## References & Resources
- [Talos](https://www.talos.dev/)
- [Flux](https://fluxcd.io/)
- [Kustomize](https://kubectl.docs.kubernetes.io/references/kustomize/)
---

> This repository is a work in progress and will continue to evolve as my homelab grows. Contributions and suggestions are welcome!