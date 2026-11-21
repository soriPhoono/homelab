# Syncthing VPS stack

Swarm-CD deploys this stack to `sphoono-vps`. It is an always-on Syncthing
node that keeps the Obsidian vault synchronised. Nothing is published on the
VPS's public address: DockTail serves it on the tailnet only.

| Endpoint                            | Purpose       |
| ----------------------------------- | ------------- |
| `tcp://sphoono-vps-syncthing:22000` | Sync protocol |
| `https://sphoono-vps-syncthing`     | Web GUI       |

The `syncthing-data` volume holds the config, the device key and the vault at
`/var/syncthing/Vault`. It starts empty.

## First-time setup

1. Open the GUI on the tailnet and set a GUI password (Actions > Settings >
   GUI). Without one, any tailnet member with ACL access can administer it.
2. Under Actions > Settings > Connections, disable Global Discovery, Local
   Discovery, Enable Relaying and NAT Traversal. Peers connect by address.
3. On each device, add the VPS with address
   `tcp://sphoono-vps-syncthing:22000`, and accept the device on the VPS.
4. Share the vault folder, with the VPS path set to `/var/syncthing/Vault`.
   Consider Receive Only on the VPS until the first sync is confirmed.

## Hermes

The [hermes](../hermes/README.md) stack mounts the `Vault` folder of this
volume, and runs as the same uid and gid (1000) so each side can edit the
other's files. It cannot start until that folder exists.
