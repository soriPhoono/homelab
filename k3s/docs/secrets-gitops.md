# Cluster secrets (Sealed Secrets + Tailscale operator)

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

## Tailscale Kubernetes operator

Flux installs **tailscale-operator** into the `tailscale` namespace. The chart is configured with **empty** `oauth` values so **no** OAuth Secret is created by Helm. You must provide a Secret named **`operator-oauth`** in `tailscale` with keys **`client_id`** and **`client_secret`** (see [Tailscale Kubernetes operator](https://tailscale.com/kb/1236/kubernetes-operator)).

Create an OAuth client in the Tailscale admin console and grant it the **`tag:k8s-operator`** tag (and any extra tags you reference in `operatorConfig.defaultTags`). Then seal the Secret and commit it:

```bash
nix develop
kubectl config use-context <guenivir-context>

kubectl create secret generic operator-oauth \
  --namespace=tailscale \
  --from-literal=client_id='YOUR_CLIENT_ID' \
  --from-literal=client_secret='YOUR_CLIENT_SECRET' \
  --dry-run=client -o yaml \
  | kubeseal --format yaml -o k3s/infrastructure/configs/guenivir/tailscale-operator-oauth.sealedsecret.yaml
```

Add `tailscale-operator-oauth.sealedsecret.yaml` to [`../infrastructure/configs/guenivir/kustomization.yaml`](../infrastructure/configs/guenivir/kustomization.yaml) under `resources:` so Flux applies it **after** controllers (the `infrastructure-config` Kustomization runs second). The `tailscale-operator` HelmRelease uses `install.disableWait: true` so the infrastructure sync can finish before this Secret exists; the operator becomes Ready once the SealedSecret is synced and unsealed.

Until `operator-oauth` exists, the operator Pod may stay unhealthy; that is expected until the SealedSecret is applied.
