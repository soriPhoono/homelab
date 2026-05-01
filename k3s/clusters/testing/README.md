# Flux cluster entry: testing

Contains three `Kustomization` objects (`infrastructure`, `infrastructure-config`, `apps`) targeting the **`testing`** paths under `k3s/`.

Bootstrap Flux with `--path=k3s/clusters/testing`. See [docs/testing-cluster.md](../../docs/testing-cluster.md).
