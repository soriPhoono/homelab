locals {
  projectID = 200

  nodes = [
    {
      name   = "adams-manager-1"
      ip     = "192.168.1.225"
      vmid   = local.projectID
      memory = 4096
      disk   = 40
    },
    {
      name   = "adams-worker-1"
      ip     = "192.168.1.226"
      vmid   = local.projectID + 1
      memory = 8192
      disk   = 255
    },
    {
      name   = "adams-worker-2"
      ip     = "192.168.1.227"
      vmid   = local.projectID + 2
      memory = 8192
      disk   = 255
    }
  ]
}

# 1. Build the Nix flake target and return the output path
# We use a custom external script that runs `nix build` and outputs JSON
data "external" "nix_build" {
  program = ["bash", "-c", <<EOF
    # Run the Nix build and capture the final store path
    OUT_PATH=$(nix build "$1" --print-out-paths)

    # Return the path in a JSON object for Terraform
    jq -n --arg path "$OUT_PATH" '{"path":$path}'
  EOF
  , "dummy_arg", var.nix_flake_target]
}

# 2. Upload the built Nix tarball to the Proxmox node as a container template
resource "proxmox_virtual_environment_file" "nix_lxc_template" {
  content_type = "vztmpl"
  datastore_id = "local" # Change to your datastore name if different
  node_name    = var.proxmox_node_name

  source_file {
    # The path output by the external nix build
    path = data.external.nix_build.result.path
    # We strip the store path hash to give it a clean name on Proxmox
    file_name = "nixos-lxc-template-${md5(data.external.nix_build.result.path)}.tar.xz"
  }
}

# 3. Create the LXC container using the uploaded template
resource "proxmox_virtual_environment_container" "nixos_lxc" {
  for_each = { for n in local.nodes : n.name => n }

  description = "Managed by Terraform (${each.value.name})"

  node_name = var.proxmox_node_name
  vm_id     = each.value.vmid

  unprivileged = true

  features {
    nesting = true
  }

  tags = var.lxc_tags

  initialization {
    hostname = each.value.name
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_file.nix_lxc_template.id
    type             = "nixos"
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = "local-lvm" # Adjust this to your block storage datastore
    size         = each.value.disk
  }

  # Ensure the template is uploaded before creating the container
  depends_on = [
    proxmox_virtual_environment_file.nix_lxc_template
  ]
}
