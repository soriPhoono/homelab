# Hermes VPS stack

Swarm-CD deploys this stack to `sphoono-vps`. It runs Hermes Agent always on:
the gateway, cron and the dashboard, supervised by s6-overlay inside the
official `nousresearch/hermes-agent` image. Nothing is published on the VPS's
public address: DockTail serves the dashboard on the tailnet only.

The dashboard, which is also the backend Hermes Desktop connects to, is at
`https://sphoono-vps-hermes.xerus-augmented.ts.net`.

The `hermes-data` volume is Hermes' whole state (`config.yaml`, `.env`,
`SOUL.md`, sessions, memories, skills, cron). It starts as a fresh install
seeded from the image's examples. Run exactly one replica: two gateways on the
same volume corrupt it.

## Secrets

Before the first deployment, create and encrypt these files with SOPS:

```sh
mkdir -p docker/stacks/hermes/secrets
sops docker/stacks/hermes/secrets/hermes-9router-api-key
sops docker/stacks/hermes/secrets/hermes-dashboard-password
sops docker/stacks/hermes/secrets/hermes-dashboard-secret
```

- `hermes-9router-api-key`: a 9router API key, exported as
  `NINEROUTER_API_KEY`. Mint one for Hermes in 9router so it can be revoked
  on its own.
- `hermes-dashboard-password`: the dashboard and Desktop sign-in password for
  the user `sphoono`. Generate it with `openssl rand -base64 24`.
- `hermes-dashboard-secret`: the session signing key, so sign-ins survive
  restarts. Generate it with `openssl rand -base64 32`.

The container refuses to start while any of them is empty.

## First-time setup

Run these on the VPS. The task's container name is random, so look it up:

```sh
hermes=$(docker ps -qf name=hermes_hermes)
```

1. Point Hermes at 9router. It is on the shared `tailscale` overlay, where
   Swarm resolves it by its stack-qualified name, so no tailnet hop is
   needed. Merge this into `/opt/data/config.yaml`
   (`docker exec -it "$hermes" hermes config edit`):

   ```yaml
   providers:
     9router:
       api: http://9router_9router:20128/v1
       key_env: NINEROUTER_API_KEY
       transport: chat_completions
   onboarding:
     run: false
   telemetry:
     shared_metrics:
       enabled: false
       send: false
   ```

   Then pick the default model with `docker exec -it "$hermes" hermes model`.

2. Give it the General Assistant soul, composed from the same documents the
   other agents use:

   ```sh
   cat modules/users/sphoono/assets/documents/identities/general-assistant.md \
     modules/users/sphoono/assets/documents/agent-roles/personal-assistant.md |
     ssh sphoono-vps "docker exec -i \$(docker ps -qf name=hermes_hermes) \
       sh -c 'cat > /opt/data/SOUL.md'"
   ```

3. Check the dashboard's auth gate is on:

   ```sh
   curl -s https://sphoono-vps-hermes.xerus-augmented.ts.net/api/status |
     jq '.auth_required, .auth_providers'
   ```

   It must print `true` and `["basic"]`.

## Connecting Hermes Desktop

In Hermes Desktop, open Settings > Gateways > Remote gateway, set the Remote
URL to `https://sphoono-vps-hermes.xerus-augmented.ts.net` and sign in as
`sphoono` with the dashboard password. Use that exact URL: the dashboard's
DNS-rebinding guard accepts only the host in `HERMES_DASHBOARD_PUBLIC_URL`.

## Upgrading

Bump the tag and digest in `docker-compose.yml`. The image is stateless; the
volume carries everything across upgrades.
