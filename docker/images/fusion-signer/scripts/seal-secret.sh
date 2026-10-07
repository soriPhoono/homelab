#!/usr/bin/env bash
# Seal one stack secret from stdin into SOPS. The value never touches argv,
# shell history or an unencrypted file outside a private tmpfs file.
set -euo pipefail

name=${1:?usage: seal-secret.sh <secret-file-name> < value}
root=$(git rev-parse --show-toplevel)
dir=${SECRETS_DIR:-$root/docker/stacks/n8n/secrets}
out=$dir/$name
sops=${SOPS:-sops}
recipients="age1y4x8gzzcdhxvqaf9matt0eze3z3yxwx607avq4cexfkgwal4psesj39lvn"
recipients+=",age1t405nrcjuavjg3u3qk65q2vnwkdm9zrc5j04xdk5kwl39kcucp5sscq8z6"

if [[ -e $out ]]; then
  echo "refusing to overwrite $out" >&2
  exit 1
fi

umask 077
tmp=$(mktemp -p "${XDG_RUNTIME_DIR:-/tmp}")
trap 'shred -u "$tmp" 2>/dev/null || rm -f "$tmp"' EXIT
cat >"$tmp"
if [[ ! -s $tmp ]]; then
  echo "empty value, nothing sealed" >&2
  exit 1
fi

"$sops" --encrypt --age "$recipients" \
  --input-type binary --output-type binary "$tmp" >"$out"
echo "sealed $out"
