# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains HashiCorp Packer templates for creating Proxmox VM templates for homelab environments. It uses Packer's `proxmox-iso` builder to create cloud-init-enabled VM templates from ISO images.

## Architecture

### Core Template Structure

The repository follows a modular design with three primary HCL files:

1. **config.pkr.hcl** - Packer plugin configuration (proxmox plugin v1.2.3)
2. **variables.pkr.hcl** - Variable declarations (60+ configurable parameters)
3. **generic.pkr.hcl** - Main source and build definitions

### Configuration Layers

Templates use a variable file layering system:

- **Base variables**: `variables.pkr.hcl` declares all available variables with defaults
- **OS-specific vars**: `ubuntu-24.04.pkrvars.hcl`, `ubuntu-22.04.pkrvars.hcl` define OS-specific values (ISO URLs, boot commands, provisioners)
- **Environment vars**: `my.pkrvars.hcl` (gitignored) contains user-specific settings (Proxmox host, credentials)
- **Credentials**: `.creds.env.yaml` (gitignored) loaded via mise.toml for sensitive data

### Source Definition (generic.pkr.hcl)

The `proxmox-iso` source block (lines 1-98) maps variables to Proxmox API parameters:

- VM configuration: CPU, memory, disk, network
- Boot process: ISO handling, boot commands, HTTP server for autoinstall
- Cloud-init: Automatic cloud-init drive attachment
- Communicators: SSH/WinRM for provisioning

### Build Process (generic.pkr.hcl)

The build block (lines 100-109) executes shell provisioners with sudo privileges. Provisioner commands are defined in OS-specific `.pkrvars.hcl` files.

### Autoinstall System (http/ubuntu/)

Ubuntu autoinstall configuration served via Packer's HTTP server:

- **user-data** - Cloud-config with identity, network, storage, packages
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
# Validate and build
./scripts/homelab-packer

# Only validate
./scripts/homelab-packer validate

# Only build (skips validation)
./scripts/homelab-packer build
```

The script initializes Packer and uses `my.pkrvars.hcl` and `ubuntu-24.04.pkrvars.hcl` by default.

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

This project uses `mise` for tool version management (mise.toml:1):

- Installs latest Packer
- Loads environment from `.creds.env.yaml`, `.env`, and `~/.env`
- Adds `./scripts` to PATH
- Maps `PROXMOX_USERNAME` → `PKR_VAR_proxmox_user`
- Maps `PROXMOX_TOKEN` → `PKR_VAR_proxmox_token`

### Credentials Configuration

Create `.creds.env.yaml` (encrypted with SOPS) with Proxmox authentication:

```yaml
PROXMOX_USERNAME: 'root@pam!token-id'
PROXMOX_TOKEN: 'your-token-secret'
```

These variables are automatically mapped to Packer's expected format by mise.toml.

### Local Configuration

Create `my.pkrvars.hcl` with your Proxmox environment settings:

```hcl
proxmox_host = "your-proxmox-host:8006"
node = "your-proxmox-node"
disk_storage_pool = "your-storage-pool"
# ... other environment-specific values
```

## Key Variables

### Critical Required Variables

- `proxmox_host` - Proxmox API endpoint (IP:port)
- `node` - Proxmox node name where VM will be created
- `name` - Template name in Proxmox
- `iso_url` / `iso_checksum` - Source ISO location and verification
- `boot_command` - OS-specific boot sequence
- `provisioner` - Post-install shell commands

### Authentication Variables

Credentials can be provided via environment variables (preferred) or direct variables:

- `PKR_VAR_proxmox_user` / `proxmox_user` - Username with realm and token ID
- `PKR_VAR_proxmox_token` / `proxmox_token` - API token secret

### Hardware Defaults

- CPU: 2 cores, 1 socket, host type
- Memory: 2048 MB
- Disk: 5GB QCOW2 on SCSI with VirtIO controller
- Network: virtio on vmbr0
- QEMU agent: enabled

## Creating New OS Templates

1. Create new `.pkrvars.hcl` file (e.g., `debian-12.pkrvars.hcl`)
2. Define OS-specific variables:
   - `name` - Template identifier
   - `iso_url` and `iso_checksum` - OS installation media
   - `boot_command` - Boot sequence for automated install
   - `provisioner` - Post-install cleanup commands
   - `http_directory` - Path to autoinstall files (if needed)
3. Create autoinstall configuration in `http/<os>/` if required
4. Build: `packer build -var-file="my.pkrvars.hcl" -var-file="new-os.pkrvars.hcl" .`

## File Organization

- `*.pkr.hcl` - Packer HCL2 configuration files
- `*.pkrvars.hcl` - Variable value files (OS/environment-specific)
- `http/` - Autoinstall files served during build
- `scripts/` - Helper scripts (added to PATH by mise)
- `.creds.env.yaml` - Sensitive credentials (gitignored)
- `my.pkrvars.hcl` - Local environment config (gitignored)

## Important Notes

- The `proxmox-iso` builder creates a VM, installs the OS, then converts to a template
- Cloud-init drive is automatically added to templates (configurable via `cloud_init` variable)
- Default credentials during build: `packer/packer` (removed by provisioner)
- ISO files can be downloaded by Packer or pre-uploaded to Proxmox storage
- Templates include QEMU guest agent by default for better Proxmox integration
- Important: Never change files and directories in the ./tmp directory and all its children. This are example repositories that i downloaded from the internet and i always want to be in the original state.
