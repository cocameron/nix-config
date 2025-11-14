{ config, pkgs-unstable, lib, ... }:

let
  constants = import ../../common/constants.nix;
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
    grafana = 3000;
    profilarr = 6868;
    glance = 8080;
    wrtagweb = 5031;
    romm = 8091;
  };

  # Services that only support IPv4 (typically containerized services)
  ipv4OnlyServices = [ "slskd" "qbittorrent" "romm" ];

  # Helper function to create reverse proxy virtual hosts
  mkVirtualHost = name: port: {
    name = "${name}.${constants.domain.nixlab}";
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
      "*.${constants.domain.nixlab}".extraConfig = ''
        tls {
          dns cloudflare {
            api_token {$CLOUDFLARE_API_TOKEN}
          }
          propagation_timeout 6m
          resolvers 1.1.1.1
        }
      '';
      # Base domain redirects to Glance dashboard
      "${constants.domain.nixlab}".extraConfig = ''
        tls {
          dns cloudflare {
            api_token {$CLOUDFLARE_API_TOKEN}
          }
          propagation_timeout 6m
          resolvers 1.1.1.1
        }
        redir https://glance.${constants.domain.nixlab}{uri} permanent
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
