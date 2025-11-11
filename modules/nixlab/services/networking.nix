{ config, pkgs-unstable, lib, ... }:

let
  # Map of service names to their ports
  reverseProxyServices = {
    plex = 32400;
    qbittorrent = 8200;
    radarr = 7878;
    prowlarr = 9696;
    sonarr = 8989;
    lidarr = 8686;
    ha = 8123;
    slskd = 5030;
    unpackerr = 5656;
    grafana = 3000;
    profilarr = 6868;
    glance = 8080;
    wrtagweb = 5031;
  };

  # Services that only support IPv4 (typically containerized services)
  ipv4OnlyServices = [ "slskd" "qbittorrent" ];

  # Helper function to create reverse proxy virtual hosts
  mkVirtualHost = name: port: {
    name = "${name}.nixlab.brucebrus.org";
    value = {
      extraConfig = ''
        reverse_proxy ${if builtins.elem name ipv4OnlyServices then "127.0.0.1" else "localhost"}:${toString port}
      '';
    };
  };
in

{
  # Tailscale VPN
  services.tailscale.enable = true;

  # Caddy Reverse Proxy
  services.caddy = {
    enable = true;
    globalConfig = ''
      auto_https prefer_wildcard
      metrics {
        per_host
      }
    '';
    virtualHosts = {
      # Wildcard TLS configuration
      "*.nixlab.brucebrus.org".extraConfig = ''
        tls {
          dns cloudflare {
            api_token {$CLOUDFLARE_API_TOKEN}
          }
          propagation_timeout 6m
          resolvers 1.1.1.1
        }
      '';
    } // (builtins.listToAttrs (lib.mapAttrsToList mkVirtualHost reverseProxyServices));

    package = pkgs-unstable.caddy.withPlugins {
      plugins = [
        "github.com/lucaslorentz/caddy-docker-proxy/v2@v2.10.0"
        "github.com/caddy-dns/cloudflare@v0.2.2"
      ];
      hash = "sha256-GH7fG4eV+fnQ3hPhX2tvXoZPQUyS71Bbjg2WiIJQcSs=";
    };
  };

  systemd.services.caddy = {
    serviceConfig = {
      EnvironmentFile = config.sops.templates."caddy-cloudflare-env".path;
      TimeoutStartSec = "5m";
    };
  };
}
