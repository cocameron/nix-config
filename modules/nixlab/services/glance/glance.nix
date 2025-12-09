{ lib, pkgs, config, ... }:
let
  constants = import ../../common/constants.nix;
  reverseProxyServicesMap = config.nixlab.reverseProxyServices;

  qbittorrent-stats = import ./qbittorrent-stats.nix;
  proxmox = import ./proxmox-detailed-resources.nix;
  plex = import ./plex-playing.nix;

  # Icon mapping for services
  serviceIcons = {
    ha = "si:homeassistant";
    grafana = "si:grafana";
    plex = "si:plex";
    qbittorrent = "si:qbittorrent";
    radarr = "si:radarr";
    sonarr = "si:sonarr";
    prowlarr = "si:prowlarr";
    lidarr = "si:lidarr";
    profilarr = "si:sonarr";
    proxmox = "si:proxmox";
  };

  # Services that need special check URLs
  serviceCheckUrls = {
    plex = "http://localhost:32400/web";
    slskd = "http://127.0.0.1:5030/health";
  };

  # Services that use 127.0.0.1 instead of localhost
  ipv4OnlyServices = [
    "slskd"
    "qbittorrent"
    "romm"
  ];

  # Generate monitor sites from the reverse proxy services map
  generateMonitorSites = lib.mapAttrsToList (
    name: value:
    let
      # Use custom host if provided, otherwise use localhost/127.0.0.1
      host =
        if value ? host then
          value.host
        else if builtins.elem name ipv4OnlyServices then
          "127.0.0.1"
        else
          "localhost";

      # Use custom scheme if provided
      scheme = if value ? scheme then value.scheme else "http";

      # Check if there's a custom check URL, otherwise build from host/scheme/port
      checkUrl = serviceCheckUrls.${name} or "${scheme}://${host}:${toString value.port}";
    in
    {
      title = value.friendlyName;
      url = "https://${name}.${constants.domain.nixlab}";
      check-url = checkUrl;
    }
    // (if serviceIcons ? ${name} then { icon = serviceIcons.${name}; } else { })
  ) reverseProxyServicesMap;
in
{
  services.glance = {
    enable = true;

    settings = {
      server = {
        host = "127.0.0.1";
        port = 8080;
      };

      pages = [
        {
          name = "Home";
          columns = [
            {
              size = "full";
              widgets = [
                {
                  type = "monitor";
                  cache = "1m";
                  title = "Services";
                  hide-header = true;
                  style = "compact";
                  sites = generateMonitorSites;
                }
                qbittorrent-stats
                proxmox
                plex
              ];
            }
            {
              size = "small";
              widgets = [
                {
                  type = "iframe";
                  hide-header = true;
                  source = "https://grafana.nixlab.brucebrus.org/d-solo/ab45f308-4dd8-4010-908c-77a58080ca71/nixlab-system-overview?orgId=1&from=now-6h&to=now&timezone=browser&refresh=30s&panelId=panel-1&__feature.dashboardSceneSolo=true";
                  height = 200;
                }
                {
                  type = "iframe";
                  hide-header = true;
                  source = "https://grafana.nixlab.brucebrus.org/d-solo/ab45f308-4dd8-4010-908c-77a58080ca71/nixlab-system-overview?orgId=1&from=now-6h&to=now&timezone=browser&refresh=30s&panelId=panel-3&__feature.dashboardSceneSolo=true";
                  height = 200;
                }
                {
                  type = "dns-stats";
                  service = "adguard";
                  hide-header = true;
                  url = "http://192.168.1.1:3030"; # Update with your AdGuard Home URL
                  username = "admin";
                  password = {
                    _secret = "/run/secrets/adguard_password";
                  };
                }
              ];
            }
            {
              size = "small";
              widgets = [
                {
                  type = "iframe";
                  hide-header = true;
                  source = "https://grafana.nixlab.brucebrus.org/d-solo/ab45f308-4dd8-4010-908c-77a58080ca71/nixlab-system-overview?orgId=1&from=now-6h&to=now&timezone=browser&refresh=30s&panelId=panel-2&__feature.dashboardSceneSolo=true";
                  height = 200;
                }
                {
                  type = "iframe";
                  hide-header = true;
                  source = "https://grafana.nixlab.brucebrus.org/d-solo/ab45f308-4dd8-4010-908c-77a58080ca71/nixlab-system-overview?orgId=1&from=now-6h&to=now&timezone=browser&refresh=30s&panelId=panel-4&__feature.dashboardSceneSolo=true";
                  height = 200;
                }
              ];
            }
          ];
        }
      ];
    };
  };
}
