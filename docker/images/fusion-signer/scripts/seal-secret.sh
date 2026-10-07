#!/usr/bin/env bash
# Seal one stack secret from stdin into SOPS. The value never touches argv,
# shell history or an unencrypted file outside a private tmpfs file
# ($XDG_RUNTIME_DIR or /dev/shm). Ciphertext is written to a partial file and
# moved into place only after sops succeeds, so a failure leaves nothing.
set -euo pipefail

name=${1:?usage: seal-secret.sh <secret-file-name> < value}
if [[ -n ${SECRETS_DIR:-} ]]; then
  dir=$SECRETS_DIR
else
  dir=$(git rev-parse --show-toplevel)/docker/stacks/n8n/secrets
fi
out=$dir/$name
sops=${SOPS:-sops}
# SOPS_AGE_RECIPIENTS overrides the committed recipients; it exists for tests.
recipients=${SOPS_AGE_RECIPIENTS:-age1y4x8gzzcdhxvqaf9matt0eze3z3yxwx607avq4cexfkgwal4psesj39lvn,age1t405nrcjuavjg3u3qk65q2vnwkdm9zrc5j04xdk5kwl39kcucp5sscq8z6}

if [[ -n ${XDG_RUNTIME_DIR:-} && -d $XDG_RUNTIME_DIR ]]; then
  ram=$XDG_RUNTIME_DIR
elif [[ -d /dev/shm ]]; then
  ram=/dev/shm
else
  echo "no tmpfs for plaintext (set XDG_RUNTIME_DIR)" >&2
  exit 1
fi

if [[ -e $out ]]; then
  echo "refusing to overwrite $out" >&2
  exit 1
fi

umask 077
tmp=
part=
cleanup() {
  [[ -n $tmp ]] && { shred -u "$tmp" 2>/dev/null || rm -f "$tmp"; }
  [[ -n $part ]] && rm -f "$part"
  return 0
}
trap cleanup EXIT
tmp=$(mktemp -p "$ram")
cat >"$tmp"
if [[ ! -s $tmp ]]; then
  echo "empty value, nothing sealed" >&2
  exit 1
fi

part=$(mktemp -p "$dir" ".${name}.XXXXXX")
# --config /dev/null: recipients come from --age only; without it sops reads
# the repo .sops.yaml and fails with "no matching creation rules".
"$sops" --config /dev/null --encrypt --age "$recipients" \
  --input-type binary --output-type binary "$tmp" >"$part"
mv -n "$part" "$out"
if [[ -e $part || ! -e $out ]]; then
  echo "refusing to overwrite $out" >&2
  exit 1
fi
part=
echo "sealed $out"
