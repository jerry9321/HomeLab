# useful talosctl commands for talos kubernetes management

This cheat sheet provides common `talosctl` commands for managing, debugging, and troubleshooting Talos-based Kubernetes clusters. Each command includes a comment explaining its purpose and when you would use it.

---

## Initial Installation & Upgrade Notes

- **Initial Installation (non-disk image boot):**
  Add this installer image to your machine configuration:
  `factory.talos.dev/metal-installer-secureboot/60139abf2cf501c2d9ecdfcabb2952d0aee9245a6ef0eeac0a0df3f035fb18c4:v1.10.5`
- **Upgrading Talos Linux:**
  Use the same image for upgrades:
  `factory.talos.dev/metal-installer-secureboot/60139abf2cf501c2d9ecdfcabb2952d0aee9245a6ef0eeac0a0df3f035fb18c4:v1.10.5`

## Windows Setup & Environment

- Get version:
  Download talosctl (https://github.com/siderolabs/talos/releases/)
  Install https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
  ```
- Add talosctl to PATH (Windows Devices only):
  - talosctl-windows-amd64.exe`
- Talosctl config file location (Windows Devices only):
  - `C:\Users\User1\.talos\config`
- Kubectl config file location (Windows Devices only):
  - `C:\Users\User1\.kube\config`

## Node IPs

- Worker Node 1: `192.168.100.25`
- Worker Node 2: `192.168.100.24` #Modified
- Control Plane (Kubernetes Endpoint): `https://192.168.100.26:6443`
- MetalLB IP: `192.168.100.27`

## Common Cluster Operations

- Generate Machine Config:
  ```sh
  talosctl gen config Jerry-Homelab-Cluster-v1-PC https://192.168.100.26:6443
  ```

- Apply machine configuration (during initial setup, use --insecure after config flag):
  ```sh
  talosctl apply-config --nodes 192.168.100.26 --file controlplane.yaml
  talosctl apply-config --nodes 192.168.100.25 --file worker.yaml
  talosctl apply-config --nodes 192.168.100.22 --file worker.yaml
  ```
- Print Version of Talos running:
  ```sh
  talosctl --talosconfig=./talosconfig --nodes 192.168.100.26 -e 192.168.100.26 version
  ```
- Bootstrap Kubernetes cluster:
  ```sh
  talosctl bootstrap --nodes 192.168.100.26 --endpoints 192.168.100.26 --talosconfig=./talosconfig
  ```
- Get Kubernetes client config:
  ```sh
  talosctl kubeconfig --nodes 192.168.100.26 --endpoints 192.168.100.26 --talosconfig=./talosconfig
  ```
- get health and dashboard info of talos:
  ```sh
  talosctl --nodes 192.168.100.26 --endpoints 192.168.100.26 health --talosconfig=./talosconfig
  talosctl --nodes 192.168.100.26 --endpoints 192.168.100.26 dashboard --talosconfig=./talosconfig
  ```
- Maintenance mode: Hold shift during boot to enter maintenance mode and re-configure config file. 

## Talosctl Config Usage

- Get info from config file:
  ```sh
  talosctl config info
  ```
- Set endpoints/worker nodes on talos config file:
  ```sh
  talosctl config endpoint 192.168.100.26 --talosconfig=./talosconfig
  talosctl config node 192.168.100.25,192.168.100.22 --talosconfig=./talosconfig
  ```
- Only use --talosconfig if config file is not in default location.

## Disk & Resource Queries

- Get disk info from node:
  ```sh
  talosctl -n 192.168.100.25 --endpoints 192.168.100.26 get disks --talosconfig=./talosconfig
  ```
- Get resource definitions:
  ```sh
  talosctl -n 192.168.100.26 --endpoints 192.168.100.26 get resourcedefinitions --talosconfig=./talosconfig
  ```
- Get namespaces on talos:
  ```sh
  talosctl -n 192.168.100.26 --endpoints 192.168.100.26 get namespaces
  ```

---

## Cluster & Node Management

```sh
talosctl config endpoint <ip> # Set the Talos API endpoint (use to target a specific node)
talosctl config nodes <ip1> <ip2> ... # Set the list of Talos nodes (use to target multiple nodes)
talosctl get nodes # List all Talos nodes and their status (use to check node health)
talosctl describe node <node-name> # Detailed info about a node (use to debug node issues)
```

## System & Service Status

```sh
talosctl get machines # List all machines managed by Talos (use to check machine status)
talosctl get services # List all Talos services (use to check service health)
talosctl service status kubelet # Check status of kubelet service (use to debug pod scheduling)
talosctl logs kubelet # View logs for the kubelet service (use to debug pod issues)
```

## Configuration & Upgrades

```sh
talosctl edit machineconfig <node-name> # Edit the machine configuration (use to change settings)
talosctl upgrade --image <image> # Upgrade Talos OS on all nodes (use to update Talos version)
```

## Troubleshooting & Recovery

```sh
talosctl reset --reboot # Reset a node and reboot (use to recover from major issues)
talosctl containers # List containers running on a node (use to debug container issues)
talosctl events # Show recent Talos events (use to debug system or cluster events)
```

---

> Replace `<ip>`, `<node-name>`, `<image>`, etc. with your actual values.
> For more, see the [Talos documentation](https://www.talos.dev/docs/cli/talosctl/).
