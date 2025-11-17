{
  config,
  inputs,
  pkgs,
  pkgs-unstable,
  modulesPath,
  lib,
  ...
}:
let
  constants = import ./modules/common/constants.nix;
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.default
    ./modules/common/base.nix
    ./modules/common/nixos-base.nix
    ./modules/nixlab/monitoring
    ./modules/nixlab/services/media.nix
    ./modules/nixlab/services/networking.nix
    ./modules/nixlab/services/home-assistant.nix
    ./modules/nixlab/services/glance.nix
    ./modules/nixlab/services/romm.nix
    ./modules/nixlab/storage.nix
    ./modules/nixlab/system-resources.nix
  ];

  config = {
    # Hostname
    networking.hostName = "nixlab";

    # GPG agent
    programs.gnupg.agent = {
      enable = true;
    };

    # Podman for containers
    virtualisation.podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    # SOPS secrets management
    sops = {
      defaultSopsFile = "/var/lib/sops-nix/secrets.yaml";
      age = {
        keyFile = "/var/lib/sops-nix/keys.txt";
      };
      validateSopsFiles = false;
      secrets = {
        wireguard_private_key = {
          owner = constants.primaryUser;
        };
        cloudflare_api_token = {};
        slskd_pass = {
          owner = constants.primaryUser;
        };
        grafana_admin_password = {
          owner = "grafana";
          group = "grafana";
          mode = "0440";
        };
        grafana_secret_key = {
          owner = "grafana";
          group = "grafana";
          mode = "0440";
        };
        # qBittorrent password used by SOPS template (needs root for template rendering)
        qbittorrent_password = {
          owner = "root";
          mode = "0400";
        };
        # Arr API keys - Maximum security with systemd LoadCredential
        # The exportarr module automatically uses LoadCredential to pass secrets
        # to services, so we can use restrictive permissions without group access
        radarr_api_key = {
          owner = "root";
          mode = "0400";
        };
        sonarr_api_key = {
          owner = "root";
          mode = "0400";
        };
        prowlarr_api_key = {
          owner = "root";
          mode = "0400";
        };
        lidarr_api_key = {
          owner = "root";
          mode = "0400";
        };
        proxmox_token = {
          owner = "root";
          mode = "0400";
        };
        plex_token = {
          owner = "root";
          mode = "0400";
        };
        adguard_password = {
          owner = "root";
          mode = "0400";
        };
        romm_db_password = {
          owner = "root";
          mode = "0400";
        };
        romm_db_root_password = {
          owner = "root";
          mode = "0400";
        };
        romm_auth_secret_key = {
          owner = "root";
          mode = "0400";
        };
        igdb_client_id = {
          owner = "root";
          mode = "0400";
        };
        igdb_client_secret = {
          owner = "root";
          mode = "0400";
        };
      };

      templates."caddy-cloudflare-env" = {
        content = ''
          CLOUDFLARE_API_TOKEN=${config.sops.placeholder."cloudflare_api_token"}
        '';
      };
      templates."qbittorrent-exporter-env" = {
        content = ''
          QBITTORRENT_PASSWORD=${config.sops.placeholder."qbittorrent_password"}
        '';
      };
      templates."romm-env" = {
        content = ''
          DB_PASSWD=${config.sops.placeholder."romm_db_password"}
          ROMM_AUTH_SECRET_KEY=${config.sops.placeholder."romm_auth_secret_key"}
          IGDB_CLIENT_ID=${config.sops.placeholder."igdb_client_id"}
          IGDB_CLIENT_SECRET=${config.sops.placeholder."igdb_client_secret"}
        '';
      };
      templates."romm-db-env" = {
        content = ''
          MARIADB_ROOT_PASSWORD=${config.sops.placeholder."romm_db_root_password"}
          MARIADB_PASSWORD=${config.sops.placeholder."romm_db_password"}
        '';
      };
    };

    # QEMU Guest for Proxmox
    services.qemuGuest.enable = lib.mkDefault true;

    # Boot configuration
    boot.loader.grub.enable = lib.mkDefault true;
    boot.loader.grub.devices = [ "nodev" ];
    boot.growPartition = lib.mkDefault true;

    # Nix settings
    nix.settings.trusted-users = [
      "root"
      "@wheel"
    ];

    # SSH configuration
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };
    programs.ssh.startAgent = true;

    # Home Manager configuration
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${constants.primaryUser}.imports = [ ./modules/nixlab/home-manager/home.nix ];
      extraSpecialArgs = {
        machinePackages = with pkgs; [ _1password-cli ];
        nixosConfig = config;
        inherit inputs pkgs-unstable;
      };
    };

    # Cloud-init
    services.cloud-init.network.enable = true;

    # State version
    system.stateVersion = lib.mkDefault "24.11";
  };
}
