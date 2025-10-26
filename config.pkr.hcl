packer {
  required_plugins {
    proxmox = {
      version = "v1.2.3"
      source  = "github.com/hashicorp/proxmox"
    }
    git = {
      version = ">= 0.6.2"
      source  = "github.com/ethanmdavidson/git"
    }
  }
}
