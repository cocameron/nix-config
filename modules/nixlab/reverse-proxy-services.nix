# Shared mapping of service names to ports for reverse proxy configuration
# Used by both Caddy (networking.nix) and Alloy (monitoring/alloy.nix)
{
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
}
