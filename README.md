# Nix Configuration

Multi-machine NixOS and nix-darwin configuration using flakes.

## 🖥️ Machines

### nixlab (NixOS Server)
- **Platform**: x86_64-linux (Proxmox VM)
- **Purpose**: Home server for media, monitoring, and services
- **Key Services**:
  - Media stack (Plex, Radarr, Sonarr, Lidarr, qBittorrent)
  - Monitoring (VictoriaMetrics, Grafana, Alloy)
  - Reverse proxy (Caddy with Cloudflare DNS)
  - Home Assistant
  - Container services (Podman)

### greenix (NixOS Desktop)
- **Platform**: x86_64-linux
- **Purpose**: Desktop workstation
- **Features**: Gaming, desktop environment, hardware-accelerated graphics

### Colins-MacBook-Pro-3 (macOS)
- **Platform**: aarch64-darwin
- **Purpose**: Development machine
- **Features**: Homebrew integration, development tools

### nixos-wsl (NixOS WSL)
- **Platform**: x86_64-linux
- **Purpose**: Windows Subsystem for Linux development environment

## 📁 Structure

```
.
├── flake.nix                    # Main flake configuration
├── {machine}-config.nix         # Per-machine entry points
├── modules/
│   ├── common/                  # Shared across all machines
│   │   ├── base.nix            # Basic settings (timezone, nix config, etc.)
│   │   ├── nixos-base.nix      # NixOS-specific common settings
│   │   ├── constants.nix       # Centralized constants (user, domain, etc.)
│   │   └── home-manager/       # Shared home-manager configuration
│   ├── nixlab/                 # Server-specific modules
│   │   ├── monitoring/         # Monitoring stack
│   │   ├── services/           # Service configurations
│   │   └── storage.nix         # Storage/NFS configuration
│   ├── greenix/                # Desktop-specific modules
│   ├── mac/                    # macOS-specific modules
│   └── ...
├── scripts/                    # Utility scripts
├── secrets/                    # Secrets (not committed, see secrets/README.md)
└── .sops.yaml                  # SOPS age encryption config
```

## 🚀 Quick Start

### Initial Setup

1. **Clone the repository**:
   ```bash
   git clone <your-repo-url> ~/nix-config
   cd ~/nix-config
   ```

2. **For NixOS systems**:
   ```bash
   # Build and switch
   sudo nixos-rebuild switch --flake .#nixlab
   # or
   sudo nixos-rebuild switch --flake .#greenix
   ```

3. **For macOS**:
   ```bash
   darwin-rebuild switch --flake .#Colins-MacBook-Pro-3
   ```

### Making Changes

1. Edit configuration files in `modules/` or machine-specific configs
2. Test your changes:
   ```bash
   # NixOS
   sudo nixos-rebuild test --flake .#<machine>

   # macOS
   darwin-rebuild check --flake .
   ```
3. Apply changes:
   ```bash
   # NixOS
   sudo nixos-rebuild switch --flake .#<machine>

   # macOS
   darwin-rebuild switch --flake .#<machine>
   ```

### Formatting

Format all Nix files:
```bash
nix fmt
```

## 🔐 Secrets Management

Secrets are managed using [SOPS](https://github.com/getsops/sops) with age encryption.

- **Location**: `/var/lib/sops-nix/` on each deployed machine
- **Not committed**: Encrypted secrets are intentionally kept out of version control
- **See**: `secrets/README.md` for detailed documentation

## 📝 Common Constants

Commonly used values are centralized in `modules/common/constants.nix`:
- Primary user configuration
- Timezone settings
- Domain names
- SSH keys
- GPG keys
- Git configuration

This makes it easy to update values in one place across all machines.

## 🏗️ Adding a New Machine

1. Create a new config file: `{machine}-config.nix`
2. Add machine-specific modules under `modules/{machine}/`
3. Add the configuration to `flake.nix`:
   ```nix
   nixosConfigurations.{machine} = nixpkgs.lib.nixosSystem {
     specialArgs = { inherit inputs pkgs-unstable; };
     system = "x86_64-linux";  # or appropriate architecture
     modules = [ ./{machine}-config.nix ];
   };
   ```
4. Optionally create a home-manager config at `modules/{machine}/home-manager/`

## 🔧 Key Features

- **Flakes**: Reproducible builds with pinned dependencies
- **Home Manager**: Declarative dotfile and user environment management
- **SOPS**: Encrypted secrets management with age
- **Modular**: Clean separation of concerns across modules
- **Multi-platform**: Supports NixOS, macOS (nix-darwin), and WSL

## 📚 Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Darwin](https://github.com/LnL7/nix-darwin)
- [SOPS-nix](https://github.com/Mic92/sops-nix)

## 🐛 Troubleshooting

### Flake evaluation errors
```bash
nix flake check
```

### Check what will be rebuilt
```bash
nixos-rebuild build --flake .#<machine>
nix store diff-closures /run/current-system ./result
```

### Rollback to previous generation
```bash
# NixOS
sudo nixos-rebuild switch --rollback

# macOS
darwin-rebuild --rollback
```

## 📄 License

MIT - See LICENSE file
