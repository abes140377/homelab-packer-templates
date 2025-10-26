vm_id         = 9001
vm_os_family  = "linux"
vm_os_name    = "ubuntu-server"
vm_os_version = "22.04"

iso_file  = "ubuntu-22.04.5-live-server-amd64.iso"
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
