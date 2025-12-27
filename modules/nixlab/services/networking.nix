{
  config,
  pkgs,
  lib,
  ...
}:

let
  constants = import ../../common/constants.nix;
  # Use shared reverse proxy service definitions from config
  reverseProxyServicesMap = config.nixlab.reverseProxyServices;

  # Services that only support IPv4 (typically containerized services)
  ipv4OnlyServices = [
    "slskd"
    "qbittorrent"
    "romm"
  ];

  # Helper function to create reverse proxy virtual hosts
  mkVirtualHost =
    name: config:
    let
      # Determine the host - use custom host if provided, otherwise localhost/127.0.0.1
      host =
        if config ? host then
          config.host
        else if builtins.elem name ipv4OnlyServices then
          "127.0.0.1"
        else
          "localhost";

      # Determine scheme (http or https)
      scheme = if config ? scheme then config.scheme else "http";

      # Port
      port = config.port;

      # Build the upstream URL
      upstream = "${scheme}://${host}:${toString port}";

      # Additional Caddy config for HTTPS upstreams
      transportConfig =
        if scheme == "https" then
          ''
            transport http {
              tls_insecure_skip_verify
            }
          ''
        else
          "";
    in
    {
      name = "${name}.${constants.domain.nixlab}";
      value = {
        extraConfig = ''
          reverse_proxy ${upstream} {
            ${transportConfig}
          }
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
    }
    // (builtins.listToAttrs (lib.mapAttrsToList mkVirtualHost reverseProxyServicesMap));

    package = pkgs.caddy.withPlugins {
      plugins = [
        "github.com/lucaslorentz/caddy-docker-proxy/v2@v2.10.0"
        "github.com/caddy-dns/cloudflare@v0.2.2"
      ];
      hash = "sha256-IOXnflJxeXCIvKGVpUthGV8EFFtqMZql0MCAF+7TIJY=";
    };
  };

  systemd.services.caddy = {
    serviceConfig = {
      EnvironmentFile = config.sops.templates."caddy-cloudflare-env".path;
      TimeoutStartSec = "5m";
    };
  };
}
