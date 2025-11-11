{ config, lib, ... }:

let
  # Helper function to create Arr exporters with common configuration
  mkArrExporter = service: port: url: {
    enable = true;
    inherit port url;
    apiKeyFile = config.sops.secrets."${service}_api_key".path;
  };
in

{
  # Node Exporter for system metrics
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    listenAddress = "127.0.0.1";
    enabledCollectors = [
      "systemd"
      "processes"
      "cpu"
      "diskstats"
      "filesystem"
      "loadavg"
      "meminfo"
      "netdev"
      "netstat"
      "stat"
      "time"
      "uname"
      "vmstat"
    ];
  };

  # qBittorrent exporter via Podman
  virtualisation.oci-containers.containers.qbittorrent-exporter = {
    image = "ghcr.io/martabal/qbittorrent-exporter:latest";
    environment = {
      QBITTORRENT_BASE_URL = "http://localhost:8200";
      QBITTORRENT_USERNAME = "chumpy";
    };
    environmentFiles = [ config.sops.templates."qbittorrent-exporter-env".path ];
    extraOptions = [ "--network=host" ];
  };

  # Arr services metrics (using helper function)
  # Note: The exportarr module automatically uses systemd LoadCredential
  # to securely pass API keys to services, so no special group permissions needed
  services.prometheus.exporters = {
    exportarr-radarr = mkArrExporter "radarr" 9191 "http://localhost:7878";
    exportarr-sonarr = mkArrExporter "sonarr" 9192 "http://localhost:8989";
    exportarr-prowlarr = mkArrExporter "prowlarr" 9193 "http://localhost:9696";
    exportarr-lidarr = mkArrExporter "lidarr" 9194 "http://localhost:8686";
  };
}
