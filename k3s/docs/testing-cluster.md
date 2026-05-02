# testing — k3d / local testing cluster (no Longhorn)

This path mirrors **guenivir** for Flux and app layout, but **does not install Longhorn**. For persistent volumes, use the **Rancher local-path provisioner** that ships with **k3s** (and therefore **k3d**): `StorageClass` **`local-path`** (host directory under the k3s storage path, typically `local-path` is default on k3d).

## Layout

| guenivir (original) | testing (k3d/local) |
|---------------------|---------------------|
| `k3s/clusters/guenivir` | `k3s/clusters/testing` |
| `k3s/infrastructure/controllers/guenivir` (+ Longhorn) | `k3s/infrastructure/controllers/testing` (no Longhorn) |
| `k3s/infrastructure/configs/guenivir` | `k3s/infrastructure/configs/testing` (copied manifests) |
| `k3s/apps/guenivir` | `k3s/apps/testing` (hello message patch) |

Helm charts and HelmRepository definitions under **`testing`** are **copies** of guenivir / base (Kustomize security forbids `../` references outside the build directory). When you bump chart versions on **guenivir**, update **`testing`** the same way.

## PVCs / storage classes

- Prefer **`storageClassName: local-path`** (or omit it if `local-path` is the default StorageClass).
- Do **not** reference **`longhorn`** here unless you intentionally install Longhorn on this cluster.

Verify after cluster up:

```bash
kubectl get storageclass
```

## Flux bootstrap (second cluster)

Install Flux on the **k3d** kubeconfig with **`--path`** pointing at this tree (not `guenivir`):

```bash
flux bootstrap github \
  --owner=<you> \
  --repository=homelab \
  --branch=main \
  --path=k3s/clusters/testing
```

Use a **separate** kube context / cluster from production guenivir. Each cluster has its own Flux `GitRepository` and sync path.

## SealedSecrets and NetBird API key

- **SealedSecrets** are encrypted for a **specific** cluster’s controller key. Sealed files from production **guenivir** will **not** decrypt on k3d unless you use the same controller (you won’t). For NetBird operator: create or copy `netbird-mgmt-api-key` as documented in [secrets-gitops.md](./secrets-gitops.md) **against the k3d cluster**, then add the SealedSecret to `infrastructure/configs/testing/` and list it in that folder’s `kustomization.yaml` if you need the operator on test.

NetBird Helm values use **`cluster.name: testing`** for this cluster.

## Traefik (Flux Helm chart)

The **testing** cluster installs Traefik from the **official Traefik Helm repository** (Flux `HelmRelease` in `infrastructure/controllers/testing/traefik.yaml`) so the ingress controller can track chart releases independently of the k3s static chart tarball.

**Important:** k3d/k3s also deploys Traefik via the built-in `HelmChart` unless you disable it. Run the cluster with **`--k3s-arg '--disable=traefik@server:0'`** (or the equivalent for your k3s install) so only the Flux-managed Traefik runs. Otherwise you will have two controllers and conflicting `IngressClass` / services. If you previously had the bundled chart installed, remove leftover **`HelmChart/traefik-crd`** in `kube-system` if it still exists after disabling, so CRD install jobs do not fight Flux.

`traefik-dashboard`, `traefik-netbird`, and the NetBird `NetworkResource` in `infrastructure/configs/base` select pods with **`app.kubernetes.io/instance: traefik-kube-system`**. The Flux release sets **`instanceLabelOverride: traefik-kube-system`** so those manifests stay valid without per-cluster patches.
