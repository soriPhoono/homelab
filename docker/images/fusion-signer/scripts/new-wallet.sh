#!/usr/bin/env bash
# Create the fusion-signer wallet. The private key goes straight into SOPS;
# only the address is printed.
set -euo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)
cd "$here"
node --input-type=module -e '
  import { Wallet } from "ethers";
  const w = Wallet.createRandom();
  process.stdout.write(w.privateKey);
  process.stderr.write(w.address + "\n");
' 2>"${XDG_RUNTIME_DIR:-/tmp}/fusion-signer-address" |
  "$here/scripts/seal-secret.sh" fusion-signer-key >/dev/null
echo "wallet address: $(cat "${XDG_RUNTIME_DIR:-/tmp}/fusion-signer-address")"
rm -f "${XDG_RUNTIME_DIR:-/tmp}/fusion-signer-address"
