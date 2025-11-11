{ lib, ... }:

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
                      check-url = "http://localhost:5030";
                    }
                    {
                      title = "Caddy";
                      url = "http://localhost:2019/metrics";
                      check-url = "http://localhost:2019/metrics";
                    }
                  ];
                }
                {
                  type = "calendar";
                }
              ];
            }
          ];
        }
      ];
    };
  };
}
