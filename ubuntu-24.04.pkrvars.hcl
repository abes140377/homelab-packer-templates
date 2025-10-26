# renovate: datasource=custom.ubuntuLinuxRelease
vm_id         = 9002
vm_os_family  = "linux"
vm_os_name    = "ubuntu-server"
vm_os_version = "24.04"

iso_file  = "ubuntu-24.04.3-live-server-amd64.iso"
boot_wait = "5s"

additional_packages = [
  "qemu-guest-agent",
]

boot_command = [
  "c<wait> ",
  "linux /casper/vmlinuz --- autoinstall ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'",
  "<enter><wait>",
  "initrd /casper/initrd",
  "<enter><wait>",
  "boot",
  "<enter>"
]

provisioner = [
  "cloud-init clean",
  "rm /etc/cloud/cloud.cfg.d/*",
  "userdel --remove --force packer"
]
