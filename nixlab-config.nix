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

let
  unpackerr = pkgs.stdenv.mkDerivation rec {
    pname = "unpackerr";
    version = "0.14.5";

    src = pkgs.fetchurl {
      url = "https://github.com/Unpackerr/unpackerr/releases/download/v${version}/unpackerr.amd64.linux.gz";
      sha256 = "08spf1afi6sgg8321m3fbd0g8rxi45vfrhaf6v298cdqlwir1l3v";
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      gunzip -c $src > $out/bin/unpackerr
      chmod +x $out/bin/unpackerr
    '';

    meta = with pkgs.lib; {
      description = "Extracts downloads for Radarr, Sonarr, Lidarr, Readarr, and/or a watch folder";
      homepage = "https://github.com/Unpackerr/unpackerr";
      license = licenses.mit;
      platforms = platforms.linux;
    };
  };
in

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
        slskd_pass = {
          owner = "colin";
        };
      };

      templates."caddy-cloudflare-env" = {
      content = ''
        # Cloudflare API token for DNS challenges
        CLOUDFLARE_API_TOKEN=${config.sops.placeholder."cloudflare_api_token"}
      '';
      };
    };

    services.tailscale.enable = true;

services.plex = let 
  plexpass = pkgs.plex.override { 
    plexRaw = pkgs.plexRaw.overrideAttrs(old: rec { 
      version = "1.42.2.10156-f737b826c"; # Replace with current Plexpass version
      src = pkgs.fetchurl { 
        url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb"; 
	sha256 = "sha256-1ieh7qc1UBTorqQTKUQgKzM96EtaKZZ8HYq9ILf+X3M=";
      }; 
    }); 
  }; 
in { 
  enable = true; 
  package = plexpass;
  user = "colin";
  # Add any other configuration options here
  # user = "plex";  # Optional: specify user
  # group = "plex"; # Optional: specify group
  # dataDir = "/var/lib/plex"; # Optional: specify data directory
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
	"wemo"
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
    services.lidarr = {
      enable = true;
      user = "colin";
      dataDir = "/mnt/nfs/content/media/music";
      settings = {
        update = {
          mechanism = "builtIn";
        };
      };
    };

    systemd.services.unpackerr = {
      description = "Unpackerr extracts downloads for Radarr, Sonarr, Lidarr, and Readarr";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        User = "colin";
        Group = "users";
        ExecStart = "${unpackerr}/bin/unpackerr -c /home/colin/.config/unpackerr/unpackerr.conf";
        Restart = "on-failure";
        RestartSec = "5s";
        WorkingDirectory = "/home/colin";
        Environment = [
          "TZ=America/Los_Angeles"
        ];
      };
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
      virtualHosts."lidarr.nixlab.brucebrus.org".extraConfig = ''
        reverse_proxy localhost:8686
      '';
      virtualHosts."ha.nixlab.brucebrus.org".extraConfig = ''
        reverse_proxy localhost:8123
      '';
      virtualHosts."slskd.nixlab.brucebrus.org".extraConfig = ''
        reverse_proxy 127.0.0.1:5030
      '';
      virtualHosts."unpackerr.nixlab.brucebrus.org".extraConfig = ''
        reverse_proxy localhost:5656
      '';

      package = pkgs-unstable.caddy.withPlugins {
        plugins = [
          "github.com/lucaslorentz/caddy-docker-proxy/v2@v2.10.0"
          "github.com/caddy-dns/cloudflare@v0.2.1"
        ];
        hash = "sha256-ANoTHDn9Pl+q70k3FRo1cxNYF//uYBQbgW+NFq4EUIo=";
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
      unpackerr
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
        inherit pkgs-unstable;
      };
    };

    services.cloud-init.network.enable = true;
    # Update state version for consistency
    system.stateVersion = lib.mkDefault "25.05";
  };
}
