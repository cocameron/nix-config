# Shared mapping of service names to ports for reverse proxy configuration
# Used by Caddy (networking.nix), Alloy (monitoring/alloy.nix), and Glance
{ lib, ... }:
{
  options.nixlab.reverseProxyServices = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        port = lib.mkOption {
          type = lib.types.port;
          description = "Port the service listens on";
        };
        host = lib.mkOption {
          type = lib.types.str;
          default = "localhost";
          description = "Host the service listens on";
        };
        scheme = lib.mkOption {
          type = lib.types.enum [ "http" "https" ];
          default = "http";
          description = "URL scheme (http or https)";
        };
        friendlyName = lib.mkOption {
          type = lib.types.str;
          description = "Human-readable name for the service";
        };
      };
    });
    default = {};
    description = "Reverse proxy service definitions shared across modules";
  };

  config.nixlab.reverseProxyServices = {
    plex = {
      port = 32400;
      friendlyName = "Plex";
    };
    qbittorrent = {
      port = 8200;
      friendlyName = "qBittorrent";
    };
    radarr = {
      port = 7878;
      friendlyName = "Radarr";
    };
    prowlarr = {
      port = 9696;
      friendlyName = "Prowlarr";
    };
    sonarr = {
      port = 8989;
      friendlyName = "Sonarr";
    };
    lidarr = {
      port = 8686;
      friendlyName = "Lidarr";
    };
    ha = {
      port = 8123;
      friendlyName = "Home Assistant";
    };
    slskd = {
      port = 5030;
      friendlyName = "Slskd";
    };
    grafana = {
      port = 3000;
      friendlyName = "Grafana";
    };
    profilarr = {
      port = 6868;
      friendlyName = "Profilarr";
    };
    glance = {
      port = 8080;
      friendlyName = "Glance";
    };
    wrtagweb = {
      port = 5031;
      friendlyName = "wrtagweb";
    };
    romm = {
      port = 8091;
      friendlyName = "RomM";
    };
    proxmox = {
      host = "192.168.1.222";
      port = 8006;
      friendlyName = "Proxmox";
      scheme = "https"; # Proxmox uses HTTPS
    };
  };
}
