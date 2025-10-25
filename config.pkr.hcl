packer {
  required_plugins {
    proxmox = {
      version = "v1.2.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}
