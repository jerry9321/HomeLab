# HomeLab GitOps Kubernetes Repository
This section provides a high-level overview of how this repository works, its GitOps workflow, and the technologies involved. This repository serves as the central source of truth for managing all aspects of my homelab infrastructure and applications. It leverages modern DevOps and GitOps methodologies to ensure reproducibility, scalability, and maintainability.

## How This Repo Works

- **GitOps with FluxCD:**
  - FluxCD watches this repository and applies changes to the cluster automatically. FluxCD is installed on top of Kubernetes. Which is installed via Talos OS.
  - All resources are managed declaratively; manual changes in the cluster are reverted to match the repo.

- **Kustomize for Resource Grouping:**
  - Kustomization files group related resources for easier management and deployment order.
  - Root Kustomization (`clusters/talos-cluster/kustomization.yaml`) references all major app and infra Kustomizations.

- **Helm Integration:**
  - Helm charts (e.g., for MetalLB and NGINX Ingress) are managed via Flux HelmRepository and HelmRelease resources.
  - Chart versions can be pinned or set to latest as needed. At this time, a fixed release approach is used rather than allowing auto updating.

- **Networking:**
  - MetalLB provides LoadBalancer IPs for bare-metal clusters.
  - NGINX Ingress exposes HTTP/S services to the network.

## Usage

1. **Bootstrap FluxCD** on your cluster (see [FluxCD docs](https://fluxcd.io/docs/get-started/)).
2. **Push changes** to this repository. Flux will detect and apply them automatically.
3. **Monitor resources** with `kubectl` or the Flux CLI.

## Troubleshooting
- If a resource is not updating, check for naming conflicts (Kubernetes does not rename resources on apply).
- Use `kubectl get kustomizations -A` and `kubectl get helmreleases -A` to check reconciliation status.
- Review events and logs in the relevant namespace for errors.

# Repository Structure
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

## Infrastructure

The HomeLab environment is managed using infrastructure-as-code (IaC) principles. All infrastructure resources are defined and versioned in the `infrastructure/` directory, with separate overlays for `base`, `production`, and `staging` environments.

### Key Infrastructure Components
- **Kubernetes Cluster:** Provisioned and managed with Talos for a secure, immutable control plane.
- **Persistent Storage:** Provided by TrueNAS, offering ZFS-backed network volumes for pods.
- **Secret Management:**
  - Azure Key Vault is used to securely store and manage sensitive information such as secrets, credentials, and certificates.
  - Secrets are integrated into the cluster using external secret operators or CSI drivers, ensuring that sensitive data is never stored in plain text within the repository.

This approach ensures that all infrastructure is reproducible, auditable, and secure.
---

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

> This repository is a work in progress and will continue to evolve as my homelab grows. Contributions and suggestions are welcome!