# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains HashiCorp Packer templates for creating Proxmox VM templates for homelab environments. It uses Packer's `proxmox-iso` builder to create cloud-init-enabled VM templates from ISO images.

## Architecture

### Core Template Structure

The repository follows a modular design with three primary HCL files:

1. **config.pkr.hcl** - Packer plugin configuration (proxmox plugin v1.2.3, git plugin >= 0.6.2)
2. **variables.pkr.hcl** - Variable declarations (60+ configurable parameters)
3. **generic.pkr.hcl** - Main source and build definitions with data sources, locals, source block, and build configuration

### Configuration Layers

Templates use a variable file layering system:

- **Base variables**: `variables.pkr.hcl` declares all available variables with defaults
- **OS-specific vars**: `ubuntu-24.04.pkrvars.hcl`, `ubuntu-22.04.pkrvars.hcl` define OS-specific values (ISO URLs, boot commands, provisioners)
- **Environment vars**: `my.pkrvars.hcl` (gitignored) contains user-specific settings (Proxmox host, credentials)
- **Credentials**: `.creds.env.yaml` (gitignored) loaded via mise.toml for sensitive data

### Data Sources and Locals (generic.pkr.hcl)

The file begins with data sources and local variables (lines 1-32):

- **Data source** (line 4): Uses git plugin to retrieve current repository HEAD commit
- **Locals**: Define build metadata, manifest output paths, VM naming convention, and cloud-init data sources
- Template naming: `tpl-{vm_os_family}-{vm_os_name}-{vm_os_version}`
- Cloud-init data: Loads `meta-data` and renders `user-data.pkrtpl.hcl` with variables including SSH keys from `keys/admin_id_ecdsa.pub`

### Source Definition (generic.pkr.hcl)

The `proxmox-iso` source block (lines 37-109) maps variables to Proxmox API parameters:

- VM configuration: CPU, memory, disk, network, VGA
- Boot process: ISO handling, boot commands, HTTP content served inline
- Cloud-init: Automatic cloud-init drive attachment
- Communicators: SSH for provisioning
- Template metadata: Description includes build version, date, and Packer version

### Build Process (generic.pkr.hcl)

The build block (lines 111-136) includes:

- **Shell provisioner**: Executes inline commands with sudo privileges. Provisioner commands are defined in OS-specific `.pkrvars.hcl` files
- **Manifest post-processor**: Outputs build metadata to `manifests/` directory with custom data including VM specs and build information

### Autoinstall System (http/ubuntu/)

Ubuntu autoinstall configuration served via Packer's HTTP server:

- **user-data.pkrtpl.hcl** - Templated cloud-config with:
  - Identity: hostname, build user (packer), and admin user with SSH key
  - Locale, keyboard, and timezone configuration
  - Network: DHCP on ens18
  - Storage: direct layout
  - Packages: qemu-guest-agent and additional packages from variables
  - Late commands: Sets up sudoers for build user
- **meta-data** - Empty file required by cloud-init
- Boot command in `.pkrvars.hcl` files references HTTP server: `ds='nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/'`

## Common Commands

### Initialize Packer

```bash
packer init config.pkr.hcl
```

Required after cloning or when plugin versions change.

### Build Template

Using the helper script (recommended):

```bash
# Validate and build (includes initialization)
./scripts/homelab-packer build

# Only validate (includes initialization)
./scripts/homelab-packer validate

# Create hashed password for user-data
./scripts/homelab-packer create-password <password>

# Create SSH key pair in keys/ directory
./scripts/homelab-packer create-ssh-key <keyname> <email>
```

The script automatically initializes Packer and uses `my.pkrvars.hcl` and `ubuntu-24.04.pkrvars.hcl` by default.

Manual build with custom variable files:

```bash
# Validate
packer validate \
  -var-file="my.pkrvars.hcl" \
  -var-file="ubuntu-24.04.pkrvars.hcl" \
  .

# Build
packer build \
  -var-file="my.pkrvars.hcl" \
  -var-file="ubuntu-24.04.pkrvars.hcl" \
  .
```

### Format HCL Files

```bash
packer fmt -recursive .
```

## Required Environment Setup

### Mise Tool Configuration

This project uses `mise` for tool version management (mise.toml):

- Installs latest Packer
- Loads environment from `~/.env`, `.env`, and `.creds.env.yaml` (redacted)
- Adds `./scripts` to PATH for easy access to homelab-packer script
- Automatically exports `PROXMOX_USERNAME` as `PKR_VAR_proxmox_user`
- Automatically exports `PROXMOX_TOKEN` as `PKR_VAR_proxmox_token`
- On enter: Initializes mise and sets up SSH key from `ADMIN_PRIVATE_KEY` environment variable to `keys/admin_id_ecdsa`

### Credentials Configuration

Create `.creds.env.yaml` (encrypted with SOPS) with Proxmox authentication and SSH keys:

```yaml
PROXMOX_USERNAME: 'root@pam!token-id'
PROXMOX_TOKEN: 'your-token-secret'
ADMIN_PRIVATE_KEY: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  your-private-key-content
  -----END OPENSSH PRIVATE KEY-----
```

These variables are automatically mapped to Packer's expected format by mise.toml. The `ADMIN_PRIVATE_KEY` is written to `keys/admin_id_ecdsa` during mise activation.

### Local Configuration

Create `my.pkrvars.hcl` with your Proxmox environment settings:

```hcl
proxmox_host = "your-proxmox-host:8006"
proxmox_node = "your-proxmox-node"
vm_disk_storage_pool = "your-storage-pool"
cloud_init_storage_pool = "your-storage-pool"
iso_storage_pool = "local"
# ... other environment-specific values
```

### SSH Keys Setup

The repository uses SSH keys for the admin user created in templates:

- Public key: `keys/admin_id_ecdsa.pub` - Must exist and is embedded in cloud-init user-data
- Private key: `keys/admin_id_ecdsa` - Created from `ADMIN_PRIVATE_KEY` environment variable during mise activation
- Keys directory is gitignored except for `.gitignore` and the public key
- Use `./scripts/homelab-packer create-ssh-key admin user@example.com` to generate a new key pair

## Key Variables

### Critical Required Variables

- `proxmox_host` - Proxmox API endpoint (IP or hostname, port added via `proxmox_port` variable)
- `proxmox_node` - Proxmox node name where VM will be created
- `vm_os_family`, `vm_os_name`, `vm_os_version` - Used to generate template name: `tpl-{family}-{name}-{version}`
- `iso_file` - Name of the ISO file in Proxmox storage (e.g., "ubuntu-24.04.3-live-server-amd64.iso")
- `iso_storage_pool` - Storage pool where ISO is located (default: "local")
- `boot_command` - OS-specific boot sequence as list of strings
- `provisioner` - Post-install shell commands as list of strings
- `vm_id` - Optional VM ID (default: 0 for auto-assign)

### Authentication Variables

Credentials can be provided via environment variables (preferred) or direct variables:

- `PKR_VAR_proxmox_user` / `proxmox_user` - Username with realm and token ID
- `PKR_VAR_proxmox_token` / `proxmox_token` - API token secret

### Hardware Defaults

- CPU: 2 cores, 1 socket, host type
- Memory: 2048 MB
- Disk: 5GB raw format on SCSI with VirtIO-SCSI-PCI controller (cache mode: none)
- Network: virtio model on vmbr0 bridge
- VGA: std type with 32 MiB memory
- BIOS: seabios (default)
- QEMU agent: enabled
- Start at boot: enabled

## Creating New OS Templates

1. Ensure ISO file is uploaded to Proxmox storage or accessible via URL
2. Create new `.pkrvars.hcl` file (e.g., `debian-12.pkrvars.hcl`)
3. Define OS-specific variables:
   - `vm_id` - Optional fixed VM ID for the template
   - `vm_os_family` - OS family (e.g., "linux")
   - `vm_os_name` - OS name (e.g., "debian-server")
   - `vm_os_version` - OS version (e.g., "12")
   - `iso_file` - Filename of the ISO in Proxmox storage
   - `boot_command` - Boot sequence for automated install (list of strings)
   - `boot_wait` - Time to wait before sending boot commands (e.g., "5s")
   - `provisioner` - Post-install cleanup commands (list of strings)
   - `additional_packages` - Extra packages to install (list of strings)
4. Create autoinstall configuration in `http/<os>/` if required (Ubuntu uses `http/ubuntu/`)
5. Update the `VAR_FILES` array in `scripts/homelab-packer` if you want it as default
6. Build: `./scripts/homelab-packer build` or manually with `packer build -var-file="my.pkrvars.hcl" -var-file="new-os.pkrvars.hcl" .`

## File Organization

- `*.pkr.hcl` - Packer HCL2 configuration files (config, variables, generic)
- `*.pkrvars.hcl` - Variable value files (OS/environment-specific)
- `http/` - Autoinstall files served during build (inline via http_content)
  - `http/ubuntu/` - Ubuntu autoinstall configuration (user-data.pkrtpl.hcl, meta-data)
- `scripts/` - Helper scripts (added to PATH by mise)
  - `scripts/homelab-packer` - Main build script with validate, build, create-password, and create-ssh-key commands
- `keys/` - SSH key storage (gitignored except .gitignore and public keys)
  - `keys/admin_id_ecdsa.pub` - Admin user public key (committed to repo)
  - `keys/admin_id_ecdsa` - Admin user private key (created from env var, gitignored)
- `manifests/` - Build output metadata (created during build)
- `.creds.env.yaml` - Sensitive credentials (gitignored, encrypted with SOPS)
- `my.pkrvars.hcl` - Local environment config (gitignored)
- `tmp/` - Example repositories from internet (never modify)

## Important Notes

- The `proxmox-iso` builder creates a VM, installs the OS, then converts to a template
- Cloud-init drive is automatically added to templates (configurable via `cloud_init` variable)
- Default credentials during build: `packer/packer` (removed by provisioner)
- Admin user with SSH key is created during cloud-init: username `admin` with key from `keys/admin_id_ecdsa.pub`
- ISO files must be pre-uploaded to Proxmox storage (referenced by `iso_file` variable)
- HTTP content is served inline via `http_content` parameter (not via `http_directory`)
- Templates include QEMU guest agent by default for better Proxmox integration
- Build metadata is saved to `manifests/` directory with timestamp and git commit info
- Template naming follows pattern: `tpl-{vm_os_family}-{vm_os_name}-{vm_os_version}`
- The homelab-packer script automatically runs `packer init` before validate/build
- **CRITICAL**: Never change files and directories in the `./tmp` directory and all its children. These are example repositories downloaded from the internet and must remain in their original state.
