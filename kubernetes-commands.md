# Useful Kubernetes Commands for Status, Debugging, and Troubleshooting

This cheat sheet provides common `kubectl` commands for checking resource status, debugging issues, and understanding your cluster. Each command includes a comment explaining its purpose and when you would use it.

---

## Cluster & Node Status

```sh
kubectl get nodes # List all nodes and their status (use to check if nodes are Ready/NotReady)
kubectl describe node <node-name> # Detailed info about a specific node (use to debug node issues, taints, resource pressure)
kubectl get namespaces # List all namespaces in the cluster (use to see what environments/apps exist)
```

## Pod & Deployment Status

```sh
kubectl get pods -A # List all pods in all namespaces (use to get a cluster-wide view of pod health)
kubectl get pods -n <namespace> # List pods in a specific namespace (use to check app status in a namespace)
kubectl describe pod <pod-name> -n <namespace> # Detailed info and events for a pod (use to debug pod startup, scheduling, or crash issues)
kubectl logs <pod-name> -n <namespace> # View logs for a pod (use to debug app errors or crashes)
kubectl get deployment -n <namespace> # List deployments in a namespace (use to see what apps are managed by Deployments)
kubectl describe deployment <deployment-name> -n <namespace> # Detailed info for a deployment (use to debug rollout, replica, or update issues)
```

## Service & Ingress

```sh
kubectl get svc -A # List all services in all namespaces (use to see how apps are exposed internally/externally)
kubectl describe svc <service-name> -n <namespace> # Detailed info for a service (use to debug connectivity, endpoints, or port issues)
kubectl get ingress -A # List all ingress resources (use to see what apps are exposed via HTTP/S)
kubectl describe ingress <ingress-name> -n <namespace> # Detailed info for an ingress (use to debug routing, host, or TLS issues)
```

## Events & Troubleshooting

```sh
kubectl get events -n <namespace> --sort-by=.metadata.creationTimestamp # Show recent events in a namespace (use to debug scheduling, image pull, or resource errors)
kubectl get kustomizations -A # List all FluxCD Kustomizations and their status (use to check GitOps sync and reconciliation)
kubectl get helmreleases -A # List all FluxCD HelmReleases and their status (use to check Helm chart deployments via Flux)
```

## Resource YAML & Editing

```sh
kubectl get <resource> <name> -n <namespace> -o yaml # Output full YAML for a resource (use to inspect full config, debug, or backup)
kubectl edit <resource> <name> -n <namespace> # Edit a resource live in your editor (use to make quick fixes or changes)
```

## Pod Management

```sh
kubectl delete pod <pod-name> -n <namespace> # Delete a pod (it will be recreated by its controller; use to restart a stuck or unhealthy pod)
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh # Open a shell inside a running pod (use to debug app from inside the container)
```

## PVC & Storage

```sh
kubectl get pvc -n <namespace> # List PersistentVolumeClaims in a namespace (use to check storage usage and status)
kubectl describe pvc <pvc-name> -n <namespace> # Detailed info for a PVC (use to debug storage binding or access issues)
```

## Miscellaneous

```sh
kubectl get all -n <namespace> # List all resources in a namespace (use to get a quick overview of everything running)
kubectl top pod -n <namespace> # Show resource usage for pods (requires metrics-server; use to debug performance or resource pressure)
```

---

> Replace `<namespace>`, `<pod-name>`, `<deployment-name>`, etc. with your actual resource names.
> For more, see the [Kubernetes documentation](https://kubernetes.io/docs/reference/kubectl/).
