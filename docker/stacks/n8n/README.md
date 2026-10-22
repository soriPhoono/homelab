# n8n VPS stack

Swarm-CD deploys this stack to `sphoono-vps`. The `n8n_data` volume starts as
a fresh n8n instance.

Before the first deployment, create and encrypt these files with SOPS:

```sh
mkdir -p docker/stacks/n8n/secrets
sops docker/stacks/n8n/secrets/cloudflared-tunnel-token
sops docker/stacks/n8n/secrets/n8n-runners-auth-token
```

Set `cloudflared-tunnel-token` to the Cloudflare token for the tunnel. Generate
the runner token with `openssl rand -hex 32`; both n8n and its runners read
that file through Docker secrets.

Configure the tunnel's public hostname as `agents.cryptic-coders.net` with the
service URL `http://n8n:5678`. Do not expose a service port on the VPS.

## Video pipeline storage

n8n and its runners share `/data/vods` through the `vods` volume. The runners
image ships that directory owned by uid 1000, and Docker copies the ownership
onto the empty volume the first time a runner mounts it, so both services can
write to it. Until a runner has started, n8n cannot write there.

The runners image is built from `docker/images/n8n-runners` by the
`n8n-runners image` workflow and published to `ghcr.io/soriphoono/n8n-runners`.
The package must be public so the VPS can pull it without a registry login.

## Fusion signer

`fusion-signer` holds the trading wallet key and places 1inch Fusion orders
on Base for n8n at `http://fusion-signer:8080`. It has no published port.
The source, design spec and image workflow live in the private
`soriPhoono/fusion-signer` repository. Its image is private, so the VPS
needs a registry login with read access to pull it.

Seal its secrets once, from a checkout of `soriPhoono/fusion-signer` with
dependencies installed (`pnpm install`) and `SECRETS_DIR` pointing at
`docker/stacks/n8n/secrets`:

```sh
./scripts/new-wallet.sh            # prints only the wallet address
openssl rand -hex 32 | ./scripts/seal-secret.sh fusion-signer-token
./scripts/seal-secret.sh oneinch-api-key   # paste, then Ctrl-D
./scripts/seal-secret.sh base-rpc-url      # paste, then Ctrl-D
```

Before the first deploy, set `FUSION_SETTLEMENT_ADDRESS` in the compose file.
Run `node dist/quote-check.js` (needs `ONEINCH_API_KEY` and `BASE_RPC_URL`),
verify the printed settlement address on Basescan, and paste it in. The
service refuses to start while it is empty.

`DRY_RUN` stays `"true"` until the rail passes its test layers. Limits,
`WITHDRAW_ADDRESS` and `FUSION_SETTLEMENT_ADDRESS` change only by editing
this stack file.

To halt trading call `POST /halt`. To resume, remove the halt file on the
VPS: `docker exec <container> rm /data/halt`. Withdrawals still work while
halted.

A `POST /withdraw` that returns 502 may still have been sent. Check the
wallet on Basescan before retrying under a new `requestId`.

Recovery without the signer: on a machine with the user's age key, run
`sops --decrypt docker/stacks/n8n/secrets/fusion-signer-key` and import the
key into MetaMask. Use this only when the signer or the VPS is gone.

The image is built by the `fusion-signer image` workflow and published to
`ghcr.io/soriphoono/fusion-signer`. Make the package public after the first
publish so the VPS can pull it.
