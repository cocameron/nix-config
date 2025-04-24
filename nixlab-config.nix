{
  config,
  inputs,
  pkgs,
  pkgs-unstable,
  modulesPath,
  lib,
  system,
  ...
}:

{
  disabledModules = [ "services/web-servers/caddy" ];

  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.home-manager.nixosModules.default
    inputs.sops-nix.nixosModules.default
    ./modules/common/base.nix
    ./modules/common/nixos-base.nix # Import common NixOS settings
  ];

  config = {
    # Hostname and DHCP are handled by nixos-base.nix (using mkDefault)
    # Override hostname here if needed
    environment.variables = {
      GPG_TTY = "$(tty)";
    };
    networking.hostName = "nixlab"; # Set specific hostname for nixlab
    networking.firewall = {
      # Allow the HomeKit bridge port
      allowedTCPPorts = [ 21064 ];

      # Also open UDP port 5353 for mDNS discovery that HomeKit needs
      allowedUDPPorts = [ 5353 ];
    };
    programs.gnupg.agent = {
	    enable = true;
	    # Alternatively, you can specify a custom program:
	    # pinentryPackage = pkgs.pinentry-qt; # or another pinentry package
	  };

	  # If you need to set a specific pinentry program instead of using flavors:
	#  environment.etc."gnupg/gpg-agent.conf".text = ''
	 #   pinentry-program ${pkgs.pinentry-gtk2}/bin/pinentry
	  #;'';
    virtualisation.podman = {
      enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };

    sops = {
      # Ensure the sops file is part of the configuration derivation
      defaultSopsFile = "/var/lib/sops-nix/secrets.yaml"; # Use the new relative path
      age = {
      	keyFile = "/var/lib/sops-nix/keys.txt";
      };
      validateSopsFiles = false; # Keep false for now, can set true later
      secrets = {
        # Secret needed by user 'colin' for a podman container
        wireguard_private_key = {
	  owner = "colin";
        };
	cloudflare_api_token = {};
      };

      templates."caddy-cloudflare-env" = {
      content = ''
        # Cloudflare API token for DNS challenges
        CLOUDFLARE_API_TOKEN=${config.sops.placeholder."cloudflare_api_token"}
      '';
      };
    };

    services.tailscale.enable = true;
    services.plex = {
      enable = true;
    };

    services.home-assistant = {
      enable = true;

      extraComponents = [
        # Components required to complete the onboarding
        "esphome"
        "met"
        "radio_browser"
        "spotify"
        "apple_tv"
        "google_translate"
        "cast"
        "hue"
        "sonos"
        "homekit_controller"
        "ecobee"
        "isal"
        "zha"
        "hassio"
        "homekit"
      ];
      config = {
        # Includes dependencies for a basic setup
        # https://www.home-assistant.io/integrations/default_config/
        default_config = { };
        http = {
          use_x_forwarded_for = true;
          trusted_proxies = [
            "::1"
            "127.0.0.1"
          ];
        };
        zha = {
          usb_path = "/dev/ttyUSB0";
        };
      };
    };
    services.radarr = {
      enable = true;
      user = "colin";
    };
    services.prowlarr = {
      enable = true;
    };
    services.sonarr = {
      enable = true;
      user = "colin";
    };
    services.caddy = {
      enable = true;
      globalConfig = ''
        	  auto_https prefer_wildcard
      '';
      virtualHosts."*.nixlab.brucebrus.org".extraConfig = ''
                tls {
        	  dns cloudflare {
        	    api_token {$CLOUDFLARE_API_TOKEN}
        	  }
        	  propagation_timeout 6m
                  resolvers 1.1.1.1
        	}
      '';
      virtualHosts."plex.nixlab.brucebrus.org".extraConfig = ''
        reverse_proxy localhost:32400
      '';
      virtualHosts."qbittorrent.nixlab.brucebrus.org".extraConfig = ''
        reverse_proxy localhost:8200
      '';
      virtualHosts."radarr.nixlab.brucebrus.org".extraConfig = ''
        reverse_proxy localhost:7878
      '';
      virtualHosts."prowlarr.nixlab.brucebrus.org".extraConfig = ''
        reverse_proxy localhost:9696
      '';
      virtualHosts."sonarr.nixlab.brucebrus.org".extraConfig = ''
        reverse_proxy localhost:8989
      '';
      virtualHosts."ha.nixlab.brucebrus.org".extraConfig = ''
        reverse_proxy localhost:8123
      '';

      package = pkgs-unstable.caddy.withPlugins {
        plugins = [
          "github.com/lucaslorentz/caddy-docker-proxy/v2@v2.9.2"
          "github.com/caddy-dns/cloudflare@v0.1.0"
        ];
        hash = "sha256-OgQy6Fg0zNOUsIrL+cQ/XnJgX+TyfZyu2rjCVdafzyk=";
      };
    };

    systemd.services.caddy = {
      serviceConfig = {
        EnvironmentFile =  config.sops.templates."caddy-cloudflare-env".path;
	TimeoutStartSec = "5m";
      };
    };

    # Enable QEMU Guest for Proxmox
    services.qemuGuest.enable = lib.mkDefault true;

    # Use the boot drive for grub
    boot.loader.grub.enable = lib.mkDefault true;
    boot.loader.grub.devices = [ "nodev" ];

    boot.growPartition = lib.mkDefault true;

    # Allow remote updates with flakes and non-root users
    nix.settings.trusted-users = [
      "root"
      "@wheel"
    ];
    # services.avahi... # Moved to common/nixos-base.nix

    # Specific packages needed for nixlab
    # Common packages (vim, git, python3, pinentry-curses) moved to common/nixos-base.nix
    environment.systemPackages = [
      # Add any nixlab-specific system packages here if needed
    ];

    # security.sudo.wheelNeedsPassword = false; # Moved to common/linux-base.nix

    # Enable ssh
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };
    programs.ssh.startAgent = true;

    # Default filesystem
    fileSystems."/" = lib.mkDefault {
      device = "/dev/disk/by-label/nixos";
      autoResize = true;
      fsType = "ext4";
    };

    services.rpcbind.enable = true;

    fileSystems."/mnt/nfs" = {
      device = "192.168.1.205:/rust";
      fsType = "nfs";
      options = [
        "nfsvers=4.2" # Latest NFS version for best features
        "tcp" # TCP is generally more reliable than UDP
        "noatime" # Don't update access times (reduces writes)
        "nodiratime" # Don't update directory access times
        "rw" # Read-write access
        "soft" # Return errors quickly if server issues occur
        "timeo=15" # Short timeout (1.5 seconds) since it's local
        "rsize=262144" # Large read buffer for local network
        "wsize=262144" # Large write buffer for local network
        "nolock" # Optional: Skip NFS locking since it's local
        "local_lock=none" # Optional: Skip local locking
        "x-systemd.automount" # Automount on access
      ];
    };

    # User 'colin' base defined in common/nixos-base.nix
    # Add machine-specific settings here (e.g., additional keys if needed).
    # users.users.colin.openssh.authorizedKeys.keys = [ ... ]; # Common key moved to nixos-base.nix

    # programs.zsh.enable = true; # Moved to common/linux-base.nix

    users.groups.rust-users = { };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.colin.imports = [ ./modules/nixlab/home-manager/home.nix ];
      extraSpecialArgs = {
        machinePackages = with pkgs; [
          _1password-cli
        ];
        nixosConfig = config;
      };
    };

    services.cloud-init.network.enable = true;
    # Update state version for consistency
    system.stateVersion = lib.mkDefault "24.11";
  };
}
