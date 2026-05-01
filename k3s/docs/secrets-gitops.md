# Cluster secrets (Sealed Secrets + NetBird Kubernetes operator)

## Sealed Secrets controller

Flux installs the Bitnami Labs **sealed-secrets** chart into `kube-system` with `fullnameOverride: sealed-secrets-controller`, which matches the defaults expected by the **`kubeseal`** CLI (same namespace and Deployment name as upstream docs).

The Helm chart version is pinned in [`../infrastructure/controllers/guenivir/sealed-secrets.yaml`](../infrastructure/controllers/guenivir/sealed-secrets.yaml). The dev shell includes `kubeseal` from Nixpkgs; **keep the controller image version and `kubeseal` CLI version aligned** (same minor line). Today the chart `2.18.3` ships app **v0.36.0**, which matches `kubeseal version: 0.36.0` from `nix develop`. When you bump the chart, update Nixpkgs (or call `kubeseal --controller-version=<version>`) so sealing stays reproducible.

SealedSecrets are **cluster-specific**: encryption uses the controller’s key on that cluster. Generate secrets while `kubectl` points at **guenivir**, or pass `--cert` from `kubeseal --fetch-cert`.

Typical workflow:

```bash
nix develop
kubectl config use-context <guenivir-context>

kubectl create secret generic example \
  --namespace=my-namespace \
  --from-literal=key=value \
  --dry-run=client -o yaml \
  | kubeseal --format yaml -o my-sealedsecret.yaml
```

Commit `my-sealedsecret.yaml` and reference it from the appropriate Kustomize `resources` list.

## NetBird Kubernetes operator

Flux installs the **NetBird Kubernetes operator** (`kubernetes-operator` Helm chart) into the **`netbird`** namespace. It uses **cert-manager** for admission webhook TLS (`webhook.enableCertManager: true`), so **cert-manager** must be Ready before the operator can become healthy.

Create a **personal access token** in the NetBird dashboard (see [NetBird access tokens](https://docs.netbird.io/manage/peers/access-tokens)), then seal a Secret that matches the Helm values (`netbirdAPI.keyFromSecret`):

```bash
nix develop
kubectl config use-context <guenivir-context>

kubectl create secret generic netbird-mgmt-api-key \
  --namespace=netbird \
  --from-literal=NB_API_KEY='YOUR_NETBIRD_PAT' \
  --dry-run=client -o yaml \
  | kubeseal --format yaml -o k3s/infrastructure/configs/guenivir/netbird-mgmt-api-key.sealedsecret.yaml
```

Add `netbird-mgmt-api-key.sealedsecret.yaml` to [`../infrastructure/configs/guenivir/kustomization.yaml`](../infrastructure/configs/guenivir/kustomization.yaml) under `resources:` so Flux applies it **after** controllers (the `infrastructure-config` Kustomization runs second). The operator HelmRelease uses `install.disableWait: true` so the infrastructure sync can finish before this Secret exists; the operator becomes Ready once the SealedSecret is synced and unsealed.

Until `netbird-mgmt-api-key` exists, the operator Pod may stay unhealthy; that is expected until the SealedSecret is applied.

For exposing workloads and routing peers, see [NetBird Kubernetes operator](https://docs.netbird.io/how-to/kubernetes-operator). Optional **`netbird-operator-config`** chart values (routing peers, policies, ingress-style exposure) are not installed here by default; add a second HelmRelease if you need that layer.

### Replacing Tailscale

If this cluster previously ran the **Tailscale Kubernetes operator**, remove its namespace and CRs after Flux drops the old HelmRelease (and delete any committed Tailscale SealedSecrets). Example:

```bash
kubectl delete namespace tailscale --wait=false
```

Confirm nothing still references Tailscale-only Ingress classes or annotations before deleting workloads.
