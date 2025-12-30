{
  lib,
  config,
  nixosConfig,
  pkgs,
  ...
}:
let
  constants = import ../../common/constants.nix;
  unpackerrPkg = pkgs.callPackage ../packages/unpackerr.nix { };
in
{
  imports = [
    ../../common/home-manager/home.nix
  ];
  config = {
    home.packages = [
      pkgs.wrtag
      pkgs.essentia-extractor
    ];
    services.podman = {
      enable = true;
      networks = {
        romm-network = {
          driver = "bridge";
        };
        gluetun-network = {
          driver = "bridge";
        };
      };
      containers = {
        # Shared gluetun instance for both qBittorrent and Slskd (dual port forwarding)
        gluetun = {
          image = "gluetun:local";
          addCapabilities = [ "NET_ADMIN" ];
          devices = [ "/dev/net/tun:/dev/net/tun" ];
          network = [ "gluetun-network" ];
          extraPodmanArgs = [ "--add-host=host.containers.internal:host-gateway" ];
          volumes = [
            "/home/${constants.primaryUser}/.config/gluetun:/config"
            "/run/secrets/wireguard_private_key:/run/secrets/wireguard_private_key:ro"
          ];
          ports = [
            "8888:8888/tcp" # HTTP proxy
            "8388:8388/tcp" # Shadowsocks
            "8388:8388/udp" # Shadowsocks
            "8200:8200" # qBittorrent web UI
            "5030:5030" # slskd web UI
          ];
          extraConfig = {
            Service.Slice = "media.slice";
            Service.OOMScoreAdjust = 400;
          };
          environment = {
            WIREGUARD_MTU = "1320";
            TZ = constants.timezone;
            VPN_SERVICE_PROVIDER = "protonvpn";
            VPN_TYPE = "wireguard";
            PORT_FORWARD_ONLY = "on";
            VPN_PORT_FORWARDING = "on";
            VPN_PORT_FORWARDING_NUM_PORTS = "2";
            VPN_PORT_FORWARDING_UP_COMMAND = ''"/config/assign-ports.sh {{PORTS}}"'';
            HTTPPROXY = "on";
            SHADOWSOCKS = "on";
            FIREWALL_OUTBOUND_SUBNETS = "169.254.0.0/16";
          };
          environmentFile = [ "/home/colin/.config/gluetun/gluetun.env" ];
        };

        qbittorrent = {
          image = "qbittorrentofficial/qbittorrent-nox";
          userNS = "keep-id";
          volumes = [
            "/home/${constants.primaryUser}/.config/qbittorrent:/config"
            "/mnt/nfs/content:/data"
          ];
          extraConfig = {
            Unit.Requires = "podman-gluetun.service";
            Unit.After = "podman-gluetun.service";
            Service.Slice = "media.slice";
            Service.OOMScoreAdjust = 500;
          };
          network = lib.mkForce [ "container:gluetun" ];
          environment = {
            TZ = constants.timezone;
            QBT_LEGAL_NOTICE = "confirm";
            QBT_VERSION = "latest";
            QBT_WEBUI_PORT = 8200;
            QBT_CONFIG_PATH = "/config";
            QBT_DOWNLOADS_PATH = "/downloads";
          };
        };

        slskd = {
          image = "slskd/slskd";
          userNS = "keep-id";
          volumes = [
            "/home/${constants.primaryUser}/.config/slskd:/app"
            "/mnt/nfs/content:/data"
            "/mnt/nfs/content/media/music:/music:ro"
            "/run/secrets/slskd_pass:/run/secrets/slskd_pass:ro"
          ];
          extraConfig = {
            Unit.Requires = "podman-gluetun.service";
            Unit.After = "podman-gluetun.service";
            Service.Slice = "media.slice";
            Service.OOMScoreAdjust = 600;
          };
          network = lib.mkForce [ "container:gluetun" ];
          environment = {
            TZ = constants.timezone;
            SLSKD_HTTP_PORT = "5030";
            SLSKD_REMOTE_CONFIGURATION = "true";
            # SLSKD_LISTEN_PORT removed - will use YAML config updated by assign-ports.sh
            SLSKD_DOWNLOADS_DIR = "/data/slsk";
          };
        };

        profilarr = {
          image = "santiagosayshey/profilarr:latest";
          extraPodmanArgs = [ "--network=host" ];
          volumes = [
            "/home/${constants.primaryUser}/.config/profilarr:/config"
          ];
          extraConfig = {
            Service.Slice = "media.slice";
            Service.OOMScoreAdjust = 700;
          };
          environment = {
            TZ = constants.timezone;
          };
        };

        romm-db = {
          image = "mariadb:latest";
          network = [ "romm-network" ];
          volumes = [
            "romm-mysql-data:/var/lib/mysql"
          ];
          extraPodmanArgs = [
            "--health-cmd=\"healthcheck.sh --connect --innodb_initialized\""
            "--health-start-period=30s"
            "--health-interval=10s"
            "--health-timeout=5s"
            "--health-retries=5"
          ];
          extraConfig = {
            Service.Slice = "media.slice";
            Service.OOMScoreAdjust = 600;
          };
          environment = {
            MARIADB_DATABASE = "romm";
            MARIADB_USER = "romm-user";
          };
          environmentFile = [ nixosConfig.sops.templates."romm-db-env".path ];
        };

        romm = {
          image = "rommapp/romm:latest";
          network = [ "romm-network" ];
          ports = [
            "8091:8080"
          ];
          volumes = [
            "romm-resources:/romm/resources"
            "romm-redis-data:/redis-data"
            "/mnt/nfs/content/media/games:/romm/library"
            "/mnt/storage/romm/assets:/romm/assets"
            "/mnt/storage/romm/config:/romm/config"
          ];
          extraConfig = {
            Unit.Requires = "podman-romm-db.service";
            Unit.After = "podman-romm-db.service";
            Service.Slice = "media.slice";
            Service.OOMScoreAdjust = 600;
          };
          environment = {
            DB_HOST = "romm-db";
            DB_NAME = "romm";
            DB_USER = "romm-user";
            PLAYMATCH_API_ENABLED = "true";
            HASHEOUS_API_ENABLED = "true";
          };
          environmentFile = [ nixosConfig.sops.templates."romm-env".path ];
        };

      };
    };

    # Service to monitor VPN port changes and update slskd
    systemd.user.services.slskd-port-monitor = {
      Unit = {
        Description = "Monitor VPN port changes and update slskd";
        After = [ "podman-gluetun.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c 'if [ -f /home/${constants.primaryUser}/.config/gluetun/slskd-port ]; then NEW_PORT=$(${pkgs.coreutils}/bin/cat /home/${constants.primaryUser}/.config/gluetun/slskd-port); CURRENT_PORT=$(${pkgs.gnugrep}/bin/grep -oP \"listen_port: \\K[0-9]+\" /home/${constants.primaryUser}/.config/slskd/slskd.yml || echo 0); if [ \"$NEW_PORT\" != \"$CURRENT_PORT\" ]; then echo \"Port changed from $CURRENT_PORT to $NEW_PORT, updating slskd\"; ${pkgs.gnused}/bin/sed -i \"s/listen_port: [0-9]\\+/listen_port: $NEW_PORT/\" /home/${constants.primaryUser}/.config/slskd/slskd.yml && ${pkgs.systemd}/bin/systemctl --user restart podman-slskd.service; else echo \"Port unchanged ($NEW_PORT), skipping restart\"; fi; fi'";
        RemainAfterExit = false;
      };
    };

    systemd.user.timers.slskd-port-monitor = {
      Unit = {
        Description = "Check for slskd port changes every minute";
      };
      Timer = {
        OnCalendar = "*:*:00"; # Every minute
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };

    # wrtagweb service for automatic music tagging from slskd
    systemd.user.services.wrtagweb = {
      Unit = {
        Description = "wrtagweb - web interface for wrtag";
        After = [ "podman-slskd.service" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.wrtag}/bin/wrtagweb";
        Restart = "always";
        RestartSec = "10s";
        Slice = "media.slice";
        OOMScoreAdjust = 700;
        Environment = [
          "WRTAG_CONFIG_PATH=/home/${constants.primaryUser}/.config/wrtag/config"
        ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # Unpackerr - Extract downloads for *arr apps
    systemd.user.services.unpackerr = {
      Unit = {
        Description = "Unpackerr extracts downloads for Radarr, Sonarr, Lidarr, and Readarr";
        After = [ "network.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${unpackerrPkg.unpackerr}/bin/unpackerr -c /home/${constants.primaryUser}/.config/unpackerr/unpackerr.conf";
        Restart = "on-failure";
        RestartSec = "5s";
        Slice = "media.slice";
        OOMScoreAdjust = 800;
        Environment = [
          "TZ=${constants.timezone}"
        ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    # iSponsorBlockTV - Skip SponsorBlock segments on YouTube TV
    systemd.user.services.isponsorblocktv = {
      Unit = {
        Description = "SponsorBlock client for YouTube TV";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.isponsorblocktv}/bin/iSponsorBlockTV";
        Restart = "on-failure";
        RestartSec = "10s";
        Slice = "media.slice";
        OOMScoreAdjust = 800;
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };

    home.stateVersion = "24.11";
  };
}
