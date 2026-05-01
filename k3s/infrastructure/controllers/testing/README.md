# testing cluster controllers

Same Helm stack as `../guenivir` **without** Longhorn (use k3s **`local-path`** on k3d).

Manifests are **duplicated** here so `kustomize build` from this directory satisfies load restrictions (no `../` to sibling dirs). When updating chart versions, align with `../guenivir` and `../base` HelmRepository URLs.
