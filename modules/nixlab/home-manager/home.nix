{
  lib,
  config,
  nixosConfig,
  pkgs-unstable,
  ...
}:
{
  imports = [
    ../../common/home-manager/home.nix
  ];
  config = {
    home.packages = [
      pkgs-unstable.claude-code
    ];
    services.podman = {
      enable = true;
      containers = {
        # First gluetun instance for qBittorrent
        gluetun-qbt = {
          image = "qmcgaw/gluetun";
          addCapabilities = [ "NET_ADMIN" ];
          devices = [ "/dev/net/tun:/dev/net/tun" ];
          volumes = [
            "/home/colin/.config/gluetun:/config"
            "/run/secrets/wireguard_private_key:/run/secrets/wireguard_private_key:ro"
          ];
          ports = [
            "8888:8888/tcp" # Gluetun Local Network HTTP proxy
            "8388:8388/tcp" # Gluetun Local Network Shadowsocks
            "8388:8388/udp" # Gluetun Local Network Shadowsocks
            "8200:8200"     # qbit web ui
          ];
          environment = {
            WIREGUARD_MTU = 1320;
            TZ = "America/Los_Angeles";
            VPN_SERVICE_PROVIDER = "protonvpn";
            VPN_TYPE = "wireguard";
            PORT_FORWARD_ONLY = "on";
            VPN_PORT_FORWARDING = "on";
            VPN_PORT_FORWARDING_UP_COMMAND = "\\\"/bin/sh -c '/config/assign-ports.sh qbit {{PORTS}}'\\\"";
            HTTPPROXY = "on";
            SHADOWSOCKS = "on";
          };
        };
        
        # Second gluetun instance for slskd
        gluetun-slskd = {
          image = "qmcgaw/gluetun";
          addCapabilities = [ "NET_ADMIN" ];
          devices = [ "/dev/net/tun:/dev/net/tun" ];
          volumes = [
            "/home/colin/.config/gluetun:/config"
            "/run/secrets/wireguard_private_key:/run/secrets/wireguard_private_key:ro"
          ];
          ports = [
            "8389:8388/tcp" # Shadowsocks (different port to avoid conflict)
            "5030:5030"     # slskd web ui
          ];
          environment = {
            WIREGUARD_MTU = 1320;
            TZ = "America/Los_Angeles";
            VPN_SERVICE_PROVIDER = "protonvpn";
            VPN_TYPE = "wireguard";
            PORT_FORWARD_ONLY = "on";
            VPN_PORT_FORWARDING = "on";
            VPN_PORT_FORWARDING_UP_COMMAND = "\\\"/bin/sh -c '/config/assign-ports.sh slskd {{PORTS}}'\\\"";
            SHADOWSOCKS = "on";
          };
        };
        
        qbittorrent = {
          image = "qbittorrentofficial/qbittorrent-nox";
          userNS = "keep-id";
          volumes = [
            "/home/colin/.config/qbittorrent:/config"
            "/mnt/nfs/content:/data"
          ];
          extraConfig = {
            Unit.Requires = "podman-gluetun-qbt.service";
            Unit.After = "podman-gluetun-qbt.service";
          };
          network = lib.mkForce [ "container:gluetun-qbt" ];
          environment = {
            TZ = "America/Los_Angeles";
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
            "/home/colin/.config/slskd:/app"
            "/mnt/nfs/content:/data"
            "/run/secrets/slskd_pass:/run/secrets/slskd_pass:ro"
          ];
          extraConfig = {
            Unit.Requires = "podman-gluetun-slskd.service";
            Unit.After = "podman-gluetun-slskd.service";
          };
          network = lib.mkForce [ "container:gluetun-slskd" ];
          environment = {
            TZ = "America/Los_Angeles";
            SLSKD_HTTP_PORT = "5030";
            SLSKD_REMOTE_CONFIGURATION = "true";
            # SLSKD_LISTEN_PORT removed - will use YAML config updated by assign-ports.sh
            SLSKD_SHARED_DIR = "/data/slsk";
            SLSKD_DOWNLOADS_DIR = "/data/slsk";
          };
        };
        
        
      };
    };
    
    # Service to monitor VPN port changes and update slskd
    systemd.user.services.slskd-port-monitor = {
      Unit = {
        Description = "Monitor VPN port changes and update slskd";
        After = [ "podman-gluetun-slskd.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "/bin/sh -c 'if [ -f /home/colin/.config/gluetun/slskd-port ]; then NEW_PORT=$(cat /home/colin/.config/gluetun/slskd-port); echo \"Updating slskd to use port $NEW_PORT\"; sed -i \"s/listen_port: [0-9]\\+/listen_port: $NEW_PORT/\" /home/colin/.config/slskd/slskd.yml && systemctl --user restart podman-slskd.service; fi'";
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
    
    home.stateVersion = "25.05";
  };
}
