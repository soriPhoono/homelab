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
