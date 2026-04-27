# Docker Tailscale DNS Collision Fix

## Objective

Configure Docker to explicitly use external DNS servers (e.g., 1.1.1.1, 1.0.0.1) instead of the host's Tailscale-managed resolv.conf. This prevents Docker containers from losing internet access or internal resolution when Tailscale's "Override Local DNS" or stateful filtering is active.

## Key Files & Context

- `nix/modules/nixos/desktop/tools/docker.nix`

## Implementation Steps

1. Update `virtualisation.docker.daemon.settings` in `docker.nix` to include a default `dns` array, merged with any `extraSettings` provided by the user.
   - **Target:** `nix/modules/nixos/desktop/tools/docker.nix`
   - **Change:**
     ```nix
     # Old
     daemon.settings = cfg.extraSettings;

     # New
     daemon.settings = {
       dns = [ "1.1.1.1" "1.0.0.1" ];
     } // cfg.extraSettings;
     ```

## Verification & Testing

1. Apply the configuration using `nh os switch .`.
1. Ensure Docker restarts successfully.
1. Test internet connectivity and DNS resolution inside a container:
   `docker run --rm alpine nslookup google.com`
1. Confirm this works while Tailscale is connected.
