terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.73.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = "terraform@pve!adams-terraform=${var.proxmox_api_token}"
  insecure  = true

  # Note:
  # Set PROXMOX_VE_USERNAME and PROXMOX_VE_PASSWORD or PROXMOX_VE_API_TOKEN
  # as environment variables to authenticate.
}
