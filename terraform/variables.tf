variable "proxmox_endpoint" {
  type        = string
  description = "The endpoint URL for the Proxmox Virtual Environment API (e.g., https://192.168.1.10:8006/)"
  default     = "https://pve:8006/"
}

variable "proxmox_node_name" {
  type        = string
  description = "The name of the Proxmox node where resources will be created"
  default     = "pve"
}

variable "proxmox_api_token" {
  type        = string
  description = "The API token for authentication with Proxmox VE"
  sensitive   = true
}

variable "nix_flake_target" {
  type        = string
  description = "The Nix flake target to build for the LXC container (e.g., .#nixosConfigurations.swarm-node.config.system.build.tarball)"
  default     = ".#nixosConfigurations.node.config.system.build.images.proxmox-lxc"
}

variable "lxc_vmid" {
  type        = number
  description = "The ID of the LXC container (e.g. 100). If omitted, the next available ID is used."
  default     = 0
}

variable "lxc_tags" {
  type        = list(string)
  description = "Tags to apply to the LXC container"
  default     = ["terraform", "nix"]
}
