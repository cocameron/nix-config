# Shared mapping of service names to ports for reverse proxy configuration
# Used by Caddy (networking.nix), Alloy (monitoring/alloy.nix), and Glance
{ lib, ... }:
{
  options.nixlab.reverseProxyServices = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        port = lib.mkOption {
          type = lib.types.port;
          description = "Port number for the service";
        };
        friendlyName = lib.mkOption {
          type = lib.types.str;
          description = "Human-readable name for the service";
        };
        host = lib.mkOption {
          type = lib.types.str;
          default = "localhost";
          description = "Host address for the service";
        };
        scheme = lib.mkOption {
          type = lib.types.enum [ "http" "https" ];
          default = "http";
          description = "URL scheme (http or https)";
        };
      };
    });
    default = {};
    description = "Reverse proxy service definitions";
  };

  config.nixlab.reverseProxyServices = {
    plex = { port = 32400; friendlyName = "Plex"; };
    qbittorrent = { port = 8200; friendlyName = "qBittorrent"; };
    qui = { port = 7476; friendlyName = "Qui"; };
    radarr = { port = 7878; friendlyName = "Radarr"; };
    prowlarr = { port = 9696; friendlyName = "Prowlarr"; };
    sonarr = { port = 8989; friendlyName = "Sonarr"; };
    overseerr = { port = 5055; friendlyName = "Overseerr"; };
    ha = { port = 8123; friendlyName = "Home Assistant"; };
    music-assistant = { port = 8095; friendlyName = "Music Assistant"; };
    slskd = { port = 5030; friendlyName = "Slskd"; };
    grafana = { port = 3000; friendlyName = "Grafana"; };
    profilarr = { port = 6868; friendlyName = "Profilarr"; };
    glance = { port = 8080; friendlyName = "Glance"; };
    wrtagweb = { port = 5031; friendlyName = "wrtagweb"; };
    romm = { port = 8091; friendlyName = "RomM"; };
    zwave = { port = 8092; friendlyName = "Z-Wave JS UI"; };
    proxmox = {
      host = "192.168.1.222";
      port = 8006;
      friendlyName = "Proxmox";
      scheme = "https";
    };
  };
}
