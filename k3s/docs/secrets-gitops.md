# Cluster secrets (Sealed Secrets, Tailscale operator, Vault, External Secrets)

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

## HashiCorp Vault (in-cluster, dev mode)

Flux installs the official **Vault** Helm chart into **`vault`** in **dev mode** for bootstrap only: in-memory storage, **no HA**, **not for production**. The chart pins a non-default root token via `server.dev.devRootToken` so it can be referenced consistently from Kubernetes Secrets and [External Secrets Operator](https://external-secrets.io/).

**Security:** The dev root token is stored in [`../infrastructure/configs/guenivir/vault-dev-root-token.yaml`](../infrastructure/configs/guenivir/vault-dev-root-token.yaml). Treat this like any other credential in Git: for anything beyond a lab, **replace it with a SealedSecret** (same name and keys) or move to proper Vault auto-unseal + Kubernetes auth.

After sync, a **Job** [`vault-bootstrap-job.yaml`](../infrastructure/configs/guenivir/vault-bootstrap-job.yaml) enables **KV v2** at `secret/` (if missing) and seeds **`secret/cluster-defaults/sample`** with `msg=hello-from-vault`. You can add more paths with `kubectl exec` into the Vault pod or by extending that Job (delete the old Job before changing its spec).

To migrate off dev mode, install Vault in **standalone** or **HA/Raft** mode, initialize and unseal per HashiCorp docs, then switch the **ClusterSecretStore** to [token, AppRole, or Kubernetes auth](https://external-secrets.io/latest/provider/hashicorp-vault/).

## External Secrets Operator (Vault backend)

Flux installs **external-secrets** into **`external-secrets`** with CRDs enabled. A **ClusterSecretStore** [`clustersecretstore-vault.yaml`](../infrastructure/configs/guenivir/clustersecretstore-vault.yaml) points at `http://vault.vault.svc:8200` with KV **v2** at mount **`secret`**, using the dev root token Secret above.

A sample **ExternalSecret** [`externalsecret-sample-vault.yaml`](../infrastructure/configs/guenivir/externalsecret-sample-vault.yaml) syncs `cluster-defaults/sample` → Kubernetes Secret **`eso-sample-synced`** in the **`external-secrets`** namespace (key **`msg`**). Confirm with:

```bash
kubectl -n external-secrets get externalsecret eso-sample-from-vault
kubectl -n external-secrets get secret eso-sample-synced -o jsonpath='{.data.msg}' | base64 -d
```

For application namespaces, add **ExternalSecret** manifests (or **ClusterExternalSecret**) that target Secrets in those namespaces. See [External Secrets Vault provider](https://external-secrets.io/latest/provider/hashicorp-vault/).
