#cloud-config
autoinstall:
  version: 1
  locale: ${vm_os_language}
  keyboard:
    layout: ${vm_os_keyboard}
  identity:
    hostname: ubuntu
    username: ${build_username}
    password: ${build_password_encrypted}
  users:
    - name: ${admin_username}
      groups: [sudo]
      sudo: ["ALL=(ALL) NOPASSWD:ALL"]
      ssh_authorized_keys:
        - ${admin_public_key}
        # - ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBEpHmbodskMq1817IVscW7+0PL1E6w5ab/SnuZwekZwXyWTXQ11Om8PTUGCRHinUVjttosQUdJiVJ/t5aXSKP/I= packer@home.sflab.io
  network:
    network:
      version: 2
      ethernets:
        ens18:
          dhcp4: true
  storage:
    layout:
      name: direct
  ssh:
    install-server: true
    allow-pw: true
  packages:
%{ for item in additional_packages ~}
    - ${item}
%{ endfor ~}
  user-data:
    disable_root: false
    timezone: ${vm_os_timezone}
  late-commands:
    # - curtin in-target --target=/target -- apt update
    # - curtin in-target --target=/target -- apt upgrade -y
    - echo '${build_username} ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/${build_username}
    - curtin in-target --target=/target -- chmod 440 /etc/sudoers.d/${build_username}
