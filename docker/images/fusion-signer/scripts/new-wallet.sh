#!/usr/bin/env bash
# Create the fusion-signer wallet. The private key goes straight into SOPS;
# only the address is printed.
set -euo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)
cd "$here"

if [[ -n ${XDG_RUNTIME_DIR:-} && -d $XDG_RUNTIME_DIR ]]; then
  ram=$XDG_RUNTIME_DIR
elif [[ -d /dev/shm ]]; then
  ram=/dev/shm
else
  echo "no tmpfs for plaintext (set XDG_RUNTIME_DIR)" >&2
  exit 1
fi

addrfile=$(mktemp -p "$ram")
trap 'rm -f "$addrfile"' EXIT
node --input-type=module -e '
  import fs from "node:fs";
  import { Wallet } from "ethers";
  const w = Wallet.createRandom();
  fs.writeSync(3, w.address + "\n");
  process.stdout.write(w.privateKey);
' 3>"$addrfile" |
  "$here/scripts/seal-secret.sh" fusion-signer-key >/dev/null
echo "wallet address: $(cat "$addrfile")"
