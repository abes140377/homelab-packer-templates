// Proxmox connection variables

variable "proxmox_host" {
  description = "IP and Port of the Proxmox host."
  type        = string
}

variable "proxmox_port" {
  description = "Port of the Proxmox host."
  type        = string
  default     = ""
}

variable "proxmox_user" {
  description = "Username when authenticating to Proxmox, including the realm and token ID (e.g., user@pam!tokenid)."
  type        = string
}

variable "proxmox_token" {
  description = "API token for the Proxmox user."
  type        = string
}

variable "proxmox_insecure_tls" {
  description = "Skip validating the certificate."
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "The name of the Proxmox Node on which to place the VM."
  type        = string
}

// Virtual Machine variables

variable "vm_id" {
  description = "The ID used to reference the virtual machine. If not given, the next free ID on the node will be used."
  type        = number
  default     = 0
}

variable "vm_os_family" {
  type        = string
  description = "The guest operating system family. Used for naming. (e.g. 'linux')"
}

variable "vm_os_name" {
  type        = string
  description = "The guest operating system name. Used for naming. (e.g. 'ubuntu')"
}

variable "vm_os_version" {
  type        = string
  description = "The guest operating system version. Used for naming. (e.g. '22-04-lts')"
}

variable "vm_os_language" {
  type        = string
  description = "The guest operating system language."
  default     = "de_DE"
}

variable "vm_os_keyboard" {
  type        = string
  description = "The guest operating system keyboard layout."
  default     = "de"
}

variable "vm_os_timezone" {
  type        = string
  description = "The guest operating system timezone."
  default     = "Europe/Berlin"
}

variable "vm_os_type" {
  description = "The guest operating system type. (e.g. 'l26')"
  type        = string
  default     = "l26"
}

variable "vm_pool" {
  description = "The resource pool to which the VM will be added."
  type        = string
  default     = ""
}

variable "vm_cpu_type" {
  description = "The type of CPU to emulate in the Guest."
  type        = string
  default     = "host"
}

variable "vm_cpu_sockets" {
  description = "The number of CPU sockets to allocate to the VM."
  type        = number
  default     = 1
}

variable "vm_cpu_cores" {
  description = "The number of CPU cores per CPU socket to allocate to the VM."
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "The amount of memory to allocate to the VM in Megabytes."
  type        = number
  default     = 2048
}

variable "vm_disk_storage_pool" {
  description = "The name of the storage pool on which to store the disks."
  type        = string
  default     = "local-lvm"
}

variable "vm_disk_size" {
  description = "The size of the created disk."
  type        = string
  default     = "5G"
}

variable "vm_disk_format" {
  description = "The drive's backing file's data format."
  type        = string
  default     = "raw"
  # default     = "qcow2"
}

variable "vm_disk_type" {
  description = "The type of disk device to add."
  type        = string
  default     = "scsi"
}

variable "vm_disk_cache" {
  description = "The drive's cache mode."
  type        = string
  default     = "none"
}

variable "vm_network_adapter" {
  description = "Bridge to which the network device should be attached."
  type        = string
  default     = "vmbr0"
}

variable "vm_network_adapter_model" {
  description = "Network Card Model."
  type        = string
  default     = "virtio"
}

variable "vm_network_adapter_mac" {
  description = "Override the randomly generated MAC Address for the VM."
  type        = string
  default     = null
}

variable "vm_network_adapter_vlan" {
  description = "The VLAN tag to apply to packets on this device."
  type        = number
  default     = -1
}

variable "vm_network_adapter_firewall" {
  description = "Whether to enable the Proxmox firewall on this network device."
  type        = bool
  default     = false
}

variable "vm_vga_type" {
  description = "The type of display to virtualize."
  type        = string
  default     = "std"
}

variable "vm_vga_memory" {
  description = "Sets the VGA memory (in MiB)."
  type        = number
  default     = 32
}

variable "vm_scsi_controller" {
  description = "The SCSI controller model to emulate."
  type        = string
  default     = "virtio-scsi-pci"
}

variable "vm_start_at_boot" {
  description = "Whether to have the VM startup after the PVE node starts."
  type        = bool
  default     = true
}

variable "vm_qemu_agent" {
  description = "Whether to enable the QEMU Guest Agent. qemu-guest-agent daemon must run the in the quest."
  type        = bool
  default     = true
}

variable "vm_bios" {
  description = "Set the machine bios."
  type        = string
  default     = "seabios"
}

# Cloud Init variables

variable "cloud_init" {
  description = "Wether to add a Cloud-Init CDROM drive after the virtual machine has been converted to a template."
  type        = bool
  default     = true
}

variable "cloud_init_storage_pool" {
  description = "Name of the Proxmox storage pool to store the Cloud-Init CDROM on."
  type        = string
  default     = "local-lvm"
}

# ISO variables

variable "iso_file" {
  description = "Name of the iso file"
  type        = string
}

variable "iso_storage_pool" {
  description = "Storage pool of the iso file"
  type        = string
  default     = "local"
}

variable "iso_unmount" {
  description = "Wether to remove the mounted ISO from the template after finishing."
  type        = bool
  default     = true
}

variable "boot_command" {
  description = "The keys to type when the virtual machine is first booted in order to start the OS installer."
  type        = list(string)
}

variable "boot_wait" {
  description = "The time to wait before typing boot_command."
  type        = string
  default     = "10s"
}

variable "task_timeout" {
  description = "The timeout for Promox API operations, e.g. clones"
  type        = string
  default     = "5m"
}

variable "http_directory" {
  description = "Path to a directory to serve using an HTTP server."
  type        = string
  default     = "./http"
}

// Communicator Settings and Credentials

variable "communicator" {
  description = "The packer communicator to use"
  type        = string
  default     = "ssh"
}

variable "ssh_username" {
  description = "The ssh username to connect to the guest"
  type        = string
  default     = "packer"
}

variable "ssh_password" {
  description = "The ssh password to connect to the guest"
  type        = string
  default     = "packer"
  sensitive   = true
}

variable "ssh_password_encrypted" {
  type        = string
  description = "The encrypted password to login to the guest operating system."
  default     = "$6$FhcddHFVZ7ABA4Gi$QybBjJXeTESb.NIDf7umP5rubBXM0N.SseGarXYz1kZpit8UgV6CVWo7ubIoacgdBEPUXTWXe92GyAVJ.jOJZ."
}

variable "ssh_timeout" {
  description = "The timeout waiting for ssh connection"
  type        = string
  default     = "30m"
}

// Additional Settings

variable "additional_packages" {
  type        = list(string)
  description = "Additional packages to install."
  default     = []
}

variable "provisioner" {
  description = "The packer provisioner commands."
  type        = list(string)
}
