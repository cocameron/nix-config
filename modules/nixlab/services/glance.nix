{ lib, pkgs, ... }:
let
  qbittorrent-stats = import ./qbittorrent-stats.nix;
  proxmox = import ./proxmox-detailed-resources.nix;
  plex = import ./plex-playing.nix;
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
                  sites = [
                    {
                      title = "Home Assistant";
                      url = "https://ha.nixlab.brucebrus.org";
                      check-url = "http://localhost:8123";
                      icon = "si:homeassistant";
                    }
                    {
                      title = "Grafana";
                      url = "https://grafana.nixlab.brucebrus.org";
                      check-url = "http://localhost:3000";
                      icon = "si:grafana";
                    }
                    {
                      title = "Plex";
                      url = "https://plex.nixlab.brucebrus.org";
                      check-url = "http://localhost:32400/web";
                      icon = "si:plex";
                    }
                    {
                      title = "qBittorrent";
                      url = "https://qbittorrent.nixlab.brucebrus.org";
                      check-url = "http://localhost:8200";
                      icon = "si:qbittorrent";
                    }
                    {
                      title = "Radarr";
                      url = "https://radarr.nixlab.brucebrus.org";
                      check-url = "http://localhost:7878";
                      icon = "si:radarr";
                    }
                    {
                      title = "Sonarr";
                      url = "https://sonarr.nixlab.brucebrus.org";
                      check-url = "http://localhost:8989";
                      icon = "si:sonarr";
                    }
                    {
                      title = "Prowlarr";
                      url = "https://prowlarr.nixlab.brucebrus.org";
                      check-url = "http://localhost:9696";
                      icon = "si:prowlarr";
                    }
                    {
                      title = "Lidarr";
                      url = "https://lidarr.nixlab.brucebrus.org";
                      check-url = "http://localhost:8686";
                      icon = "si:lidarr";
                    }
                    {
                      title = "Slskd";
                      url = "https://slskd.nixlab.brucebrus.org";
                      check-url = "http://127.0.0.1:5030/health";
                    }
                    {
                      title = "Profilarr";
                      url = "https://profilarr.nixlab.brucebrus.org";
                      check-url = "http://localhost:6868";
                      icon = "si:sonarr";
                    }
                    {
                      title = "wrtagweb";
                      url = "https://wrtagweb.nixlab.brucebrus.org";
                    }
                  ];
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
                  url = "http://192.168.1.1:3030";  # Update with your AdGuard Home URL
                  username = "admin";
                  password = { _secret = "/run/secrets/adguard_password"; };
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
