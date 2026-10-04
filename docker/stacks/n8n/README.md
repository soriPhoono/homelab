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
