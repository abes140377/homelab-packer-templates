//  BLOCK: data
//  Defines the data sources.

data "git-repository" "cwd" {}

//  BLOCK: locals
//  Defines the local variables.

locals {
  build_by            = "Built by: HashiCorp Packer ${packer.version}"
  build_date          = formatdate("DD-MM-YYYY hh:mm ZZZ", "${timestamp()}" )
  build_version       = data.git-repository.cwd.head
  build_description   = "Version: ${local.build_version}\nBuilt on: ${local.build_date}\n${local.build_by}\nCloud-Init: ${var.cloud_init}"
  manifest_date       = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
  manifest_path       = "${path.cwd}/manifests/"
  manifest_output     = "${local.manifest_path}${local.manifest_date}.json"
  data_source_content = {
    "/meta-data" = file("${abspath(path.root)}/http/ubuntu/meta-data")
    "/user-data" = templatefile("${abspath(path.root)}/http/ubuntu/user-data.pkrtpl.hcl", {
      build_username           = var.ssh_username
      build_password_encrypted = var.ssh_password_encrypted
      admin_username           = "admin"
      admin_public_key         = file("${abspath(path.root)}/keys/admin_id_ecdsa.pub")
      vm_os_language           = var.vm_os_language
      vm_os_keyboard           = var.vm_os_keyboard
      vm_os_timezone           = var.vm_os_timezone
      additional_packages      = var.additional_packages
    })
  }
  vm_name = "tpl-${var.vm_os_family}-${var.vm_os_name}-${var.vm_os_version}"
  port = var.proxmox_port == "" ? "" : ":${var.proxmox_port}"
}

//  BLOCK: source
//  Defines the builder configuration blocks.
//
source "proxmox-iso" "vm" {
  // Proxmox Connection Settings and Credentials
  proxmox_url              = "https://${var.proxmox_host}${local.port}/api2/json"
  username                 = var.proxmox_user
  token                    = var.proxmox_token
  insecure_skip_tls_verify = var.proxmox_insecure_tls

  // Proxmox Settings
  node = var.proxmox_node

  // Virtual Machine Settings
  vm_id   = var.vm_id
  vm_name = local.vm_name
  pool    = var.vm_pool

  cpu_type = var.vm_cpu_type
  sockets  = var.vm_cpu_sockets
  cores    = var.vm_cpu_cores
  memory   = var.vm_memory

  disks {
    storage_pool = var.vm_disk_storage_pool
    disk_size    = var.vm_disk_size
    format       = var.vm_disk_format
    type         = var.vm_disk_type
    cache_mode   = var.vm_disk_cache
  }

  network_adapters {
    bridge      = var.vm_network_adapter
    model       = var.vm_network_adapter_model
    mac_address = var.vm_network_adapter_mac
    vlan_tag    = var.vm_network_adapter_vlan == -1 ? "" : "${var.vm_network_adapter_vlan}"
    firewall    = var.vm_network_adapter_firewall
  }

  vga {
    type   = var.vm_vga_type
    memory = var.vm_vga_memory
  }

  os              = var.vm_os_type
  scsi_controller = var.vm_scsi_controller
  onboot          = var.vm_start_at_boot
  qemu_agent      = var.vm_qemu_agent
  bios            = var.vm_bios

  ssh_username   = var.ssh_username
  ssh_password   = var.ssh_password
  ssh_timeout    = var.ssh_timeout

  // Removable Media Settings
  http_content = local.data_source_content

  // Boot and Provisioning Settings
  boot         = "order=${var.vm_disk_type}0;ide2;net0"
  boot_command = var.boot_command
  boot_wait    = var.boot_wait

  boot_iso {
    iso_file         = "${var.iso_storage_pool}:iso/${var.iso_file}"
    iso_storage_pool = var.iso_storage_pool
    # iso_checksum     = var.iso_checksum
    unmount          = var.iso_unmount
  }

  template_name        = local.vm_name
  template_description = local.build_description

  # VM Cloud Init Settings
  cloud_init              = var.cloud_init
  cloud_init_storage_pool = var.cloud_init == true ? var.cloud_init_storage_pool : null
}

build {
  sources = ["source.proxmox-iso.vm"]

  provisioner "shell" {
    execute_command = "echo 'packer' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    inline          = var.provisioner
    skip_clean      = true
  }

  post-processor "manifest" {
    output     = local.manifest_output
    strip_path = true
    strip_time = true
    custom_data = {
      build_username = "${var.ssh_username}"
      build_date     = "${local.build_date}"
      build_version  = "${local.build_version}"
      vm_cpu_sockets = "${var.vm_cpu_sockets}"
      vm_cpu_cores   = "${var.vm_cpu_cores}"
      vm_memory      = "${var.vm_memory}"
      vm_bios        = "${var.vm_bios}"
      vm_os_type     = "${var.vm_os_type}"
      cloud_init     = "${var.cloud_init}"
    }
  }
}
